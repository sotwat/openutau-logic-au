#!/usr/bin/env python3
"""Loopback relay for Audio Units hosted without incoming socket permission."""

import json
import os
import select
import socket
import tempfile
import threading
from pathlib import Path


RELAY_PORT = 46783
DIRECTORY = Path(tempfile.gettempdir()) / "OpenUtau" / "PluginServers"


def relay(plugin: socket.socket) -> None:
    listener = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    client = None
    advertisement = None
    try:
        listener.bind(("127.0.0.1", 0))
        listener.listen(1)
        port = listener.getsockname()[1]
        DIRECTORY.mkdir(parents=True, exist_ok=True)
        advertisement = DIRECTORY / f"OpenUtau Bridge Relay {port}.json"
        staging = advertisement.with_suffix(".json.tmp")
        staging.write_text(
            json.dumps({"port": port, "name": f"OpenUtau Bridge Relay {port}", "apiVersion": "1.2"}),
            encoding="utf-8",
        )
        os.replace(staging, advertisement)
        while client is None:
            readable, _, _ = select.select([plugin, listener], [], [], 0.25)
            if plugin in readable and not plugin.recv(1, socket.MSG_PEEK):
                return
            if listener in readable:
                client, _ = listener.accept()
        plugin.sendall(b"R")
        sockets = (plugin, client)
        while True:
            readable, _, _ = select.select(sockets, [], [])
            for source in readable:
                data = source.recv(65536)
                if not data:
                    return
                destination = client if source is plugin else plugin
                destination.sendall(data)
    except OSError as exc:
        print(f"OpenUtau relay connection ended: {exc}", flush=True)
    finally:
        if advertisement is not None:
            advertisement.unlink(missing_ok=True)
        listener.close()
        if client is not None:
            client.close()
        plugin.close()


def main() -> None:
    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.bind(("127.0.0.1", RELAY_PORT))
    server.listen(16)
    DIRECTORY.mkdir(parents=True, exist_ok=True)
    for stale in DIRECTORY.glob("OpenUtau Bridge Relay *.json"):
        stale.unlink(missing_ok=True)
    print(f"OpenUtau relay listening on 127.0.0.1:{RELAY_PORT}", flush=True)
    while True:
        plugin, _ = server.accept()
        threading.Thread(target=relay, args=(plugin,), daemon=True).start()


if __name__ == "__main__":
    main()
