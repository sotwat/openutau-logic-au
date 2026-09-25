import importlib.util
import json
import socket
import tempfile
import threading
import time
import unittest
from pathlib import Path


SCRIPT = Path(__file__).resolve().parents[1] / "scripts" / "logic_relay.py"
spec = importlib.util.spec_from_file_location("logic_relay", SCRIPT)
relay_module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(relay_module)


class LogicRelayTest(unittest.TestCase):
    def test_discovery_and_bidirectional_stream(self):
        with tempfile.TemporaryDirectory() as temporary:
            relay_module.DIRECTORY = Path(temporary) / "OpenUtau" / "PluginServers"
            plugin, relay_end = socket.socketpair()
            worker = threading.Thread(target=relay_module.relay, args=(relay_end,))
            worker.start()
            try:
                deadline = time.monotonic() + 2
                advertisements = []
                while not advertisements and time.monotonic() < deadline:
                    advertisements = list(relay_module.DIRECTORY.glob("*.json"))
                    time.sleep(0.01)
                self.assertEqual(len(advertisements), 1)
                info = json.loads(advertisements[0].read_text(encoding="utf-8"))
                self.assertEqual(info["apiVersion"], "1.2")
                with socket.create_connection(("127.0.0.1", info["port"])) as openutau:
                    plugin.settimeout(2)
                    openutau.settimeout(2)
                    self.assertEqual(plugin.recv(1), b"R")
                    plugin.sendall(b"plugin-data")
                    self.assertEqual(openutau.recv(11), b"plugin-data")
                    openutau.sendall(b"editor-data")
                    self.assertEqual(plugin.recv(11), b"editor-data")
            finally:
                plugin.close()
                worker.join(timeout=2)
            self.assertFalse(worker.is_alive())
            self.assertEqual(list(relay_module.DIRECTORY.glob("*.json")), [])


if __name__ == "__main__":
    unittest.main()
