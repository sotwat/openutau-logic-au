import json
import os
import re
import socket
import subprocess
import sys
import tempfile
import time
import unittest
from pathlib import Path

RELAY_PATH = Path(os.environ.get("OPENUTAU_RELAY_BINARY", Path(__file__).resolve().parents[1] / "build" / "openutau-bridge-relay"))


class NativeRelayTest(unittest.TestCase):
    def test_multiple_connections_and_cleanup(self):
        if sys.platform != "darwin" or not RELAY_PATH.exists():
            self.skipTest("native macOS relay binary is not built")
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary) / "PluginServers"
            process = subprocess.Popen(
                [str(RELAY_PATH), "--port", "0", "--directory", str(directory)],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
            )
            try:
                line = process.stdout.readline()
                port = int(re.search(r"127\.0\.0\.1:(\d+)", line).group(1))
                self.assertIsNone(process.poll())
                for _ in range(2):
                    with socket.create_connection(("127.0.0.1", port)) as plugin:
                        deadline = time.monotonic() + 3
                        advertisements = []
                        while not advertisements and time.monotonic() < deadline:
                            advertisements = list(directory.glob("*.json"))
                            time.sleep(0.01)
                        self.assertEqual(len(advertisements), 1)
                        info = json.loads(advertisements[0].read_text())
                        self.assertEqual(info["apiVersion"], "1.2")
                        with socket.create_connection(("127.0.0.1", info["port"])) as editor:
                            plugin.settimeout(2)
                            editor.settimeout(2)
                            self.assertEqual(plugin.recv(1), b"R")
                            plugin.sendall(b"plugin-data")
                            self.assertEqual(editor.recv(11), b"plugin-data")
                            editor.sendall(b"editor-data")
                            self.assertEqual(plugin.recv(11), b"editor-data")
                    deadline = time.monotonic() + 3
                    while list(directory.glob("*.json")) and time.monotonic() < deadline:
                        time.sleep(0.01)
                    self.assertEqual(list(directory.glob("*.json")), [])
            finally:
                process.terminate()
                process.wait(timeout=3)
                process.stdout.close()
                process.stderr.close()


if __name__ == "__main__":
    if len(sys.argv) > 1 and Path(sys.argv[1]).exists():
        RELAY_PATH = Path(sys.argv.pop(1))
    unittest.main()
