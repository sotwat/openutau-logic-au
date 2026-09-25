#include <arpa/inet.h>
#include <poll.h>
#include <signal.h>
#include <sys/socket.h>
#include <unistd.h>

#include <cerrno>
#include <cstdlib>
#include <cstring>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <string>
#include <thread>
#include <utility>

namespace fs = std::filesystem;

namespace {

class Socket {
public:
    Socket(int fd = -1) : fd_(fd) {}
    ~Socket() { if (fd_ >= 0) close(fd_); }
    Socket(const Socket &) = delete;
    Socket &operator=(const Socket &) = delete;
    Socket(Socket &&other) noexcept : fd_(std::exchange(other.fd_, -1)) {}
    Socket &operator=(Socket &&other) noexcept {
        if (this != &other) {
            if (fd_ >= 0) close(fd_);
            fd_ = std::exchange(other.fd_, -1);
        }
        return *this;
    }
    int get() const { return fd_; }
private:
    int fd_;
};

Socket Listen(unsigned short port) {
    Socket socket(::socket(AF_INET, SOCK_STREAM, 0));
    if (socket.get() < 0) return {};
    int reuse = 1;
    setsockopt(socket.get(), SOL_SOCKET, SO_REUSEADDR, &reuse, sizeof(reuse));
    sockaddr_in address{};
    address.sin_family = AF_INET;
    address.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
    address.sin_port = htons(port);
    if (bind(socket.get(), reinterpret_cast<sockaddr *>(&address), sizeof(address)) != 0 ||
        listen(socket.get(), 16) != 0) return {};
    return socket;
}

unsigned short Port(int fd) {
    sockaddr_in address{};
    socklen_t length = sizeof(address);
    if (getsockname(fd, reinterpret_cast<sockaddr *>(&address), &length) != 0) return 0;
    return ntohs(address.sin_port);
}

bool SendAll(int fd, const char *data, size_t count) {
    while (count > 0) {
        ssize_t written = send(fd, data, count, 0);
        if (written <= 0) return false;
        data += written;
        count -= static_cast<size_t>(written);
    }
    return true;
}

void Bridge(int plugin_fd, const fs::path &directory) {
    Socket plugin(plugin_fd);
    Socket listener = Listen(0);
    if (listener.get() < 0) return;
    unsigned short port = Port(listener.get());
    if (port == 0) return;

    std::error_code error;
    fs::create_directories(directory, error);
    if (error) return;
    fs::path advertisement = directory / ("OpenUtau Bridge Relay " + std::to_string(port) + ".json");
    fs::path staging = advertisement;
    staging += ".tmp";
    {
        std::ofstream output(staging);
        output << "{\"port\":" << port << ",\"name\":\"OpenUtau Bridge Relay " << port
               << "\",\"apiVersion\":\"1.2\"}";
        if (!output.good()) return;
    }
    fs::rename(staging, advertisement, error);
    if (error) return;

    Socket client;
    while (client.get() < 0) {
        pollfd waiting[] = {{plugin.get(), POLLIN, 0}, {listener.get(), POLLIN, 0}};
        if (poll(waiting, 2, -1) <= 0) break;
        if (waiting[0].revents) {
            char byte;
            if (recv(plugin.get(), &byte, 1, MSG_PEEK) <= 0) break;
        }
        if (waiting[1].revents & POLLIN) client = Socket(accept(listener.get(), nullptr, nullptr));
    }

    if (client.get() >= 0 && SendAll(plugin.get(), "R", 1)) {
        char buffer[65536];
        while (true) {
            pollfd waiting[] = {{plugin.get(), POLLIN, 0}, {client.get(), POLLIN, 0}};
            if (poll(waiting, 2, -1) <= 0) break;
            bool finished = false;
            for (int index = 0; index < 2; ++index) {
                if (!waiting[index].revents) continue;
                int from = index == 0 ? plugin.get() : client.get();
                int to = index == 0 ? client.get() : plugin.get();
                ssize_t count = recv(from, buffer, sizeof(buffer), 0);
                if (count <= 0 || !SendAll(to, buffer, static_cast<size_t>(count))) {
                    finished = true;
                    break;
                }
            }
            if (finished) break;
        }
    }
    fs::remove(advertisement, error);
}

}  // namespace

int main(int argc, char **argv) {
    signal(SIGPIPE, SIG_IGN);
    unsigned short port = 46783;
    const char *temp = std::getenv("TMPDIR");
    fs::path directory = fs::path(temp && *temp ? temp : "/tmp") / "OpenUtau" / "PluginServers";
    for (int index = 1; index < argc; ++index) {
        if (std::strcmp(argv[index], "--port") == 0 && index + 1 < argc) {
            long selected = std::strtol(argv[++index], nullptr, 10);
            if (selected < 0 || selected > 65535) return 2;
            port = static_cast<unsigned short>(selected);
        } else if (std::strcmp(argv[index], "--directory") == 0 && index + 1 < argc) {
            directory = argv[++index];
        } else {
            std::cerr << "Usage: openutau-bridge-relay [--port 0-65535] [--directory path]\n";
            return 2;
        }
    }

    Socket server = Listen(port);
    if (server.get() < 0) {
        std::cerr << "Cannot listen on 127.0.0.1:" << port << ": " << std::strerror(errno) << '\n';
        return 1;
    }
    std::error_code error;
    fs::create_directories(directory, error);
    if (error) return 1;
    for (const auto &entry : fs::directory_iterator(directory)) {
        std::string name = entry.path().filename().string();
        if (name.starts_with("OpenUtau Bridge Relay ") && name.ends_with(".json")) {
            fs::remove(entry.path(), error);
        }
    }
    std::cout << "OpenUtau relay listening on 127.0.0.1:" << Port(server.get()) << std::endl;
    while (true) {
        int plugin = accept(server.get(), nullptr, nullptr);
        if (plugin >= 0) std::thread(Bridge, plugin, directory).detach();
        else if (errno != EINTR) return 1;
    }
}
