"""Verify a built setup archive without changing the logged-in user's installation."""
import json
import os
from pathlib import Path
import plistlib
import subprocess
import sys
import tempfile

def main():
    archive = Path(sys.argv[1]).resolve()
    with tempfile.TemporaryDirectory(prefix='openutau-setup-') as tmp:
        root = Path(tmp)
        subprocess.run(['ditto', '-x', '-k', str(archive), str(root)], check=True)
        setup = next(root.glob('*/セットアップ.app'))
        subprocess.run(['codesign', '--verify', '--deep', '--strict', str(setup)], check=True)
        resources = setup / 'Contents/Resources'
        home = root / 'home'
        prefs = home / 'Library/OpenUtau/prefs.json'
        prefs.parent.mkdir(parents=True)
        prefs.write_text(json.dumps({'Channel': 'stable', 'Beta': True, 'UserSetting': 42}))
        singer = home / 'Library/OpenUtau/Singers/keep.txt'
        singer.parent.mkdir(parents=True)
        singer.write_text('user data')
        env = dict(os.environ, OPENUTAU_INSTALL_HOME=str(home), OPENUTAU_INSTALL_TEST='1')
        command = ['/bin/sh', str(resources / 'install.sh')]
        for _ in range(2):
            result = subprocess.run(command, env=env, capture_output=True, text=True)
            assert result.returncode == 0, result.stdout + result.stderr
        assert json.loads(prefs.read_text()) == {'Channel': 'alpha', 'Beta': False, 'UserSetting': 42}
        assert singer.read_text() == 'user data'
        agent = plistlib.loads((home / 'Library/LaunchAgents/moe.kakaru.openutau-bridge-relay.plist').read_bytes())
        assert agent['ProgramArguments'] == [str(home / 'Library/Application Support/OpenUtau Bridge/openutau-bridge-relay')]
        assert agent['RunAtLoad'] and agent['KeepAlive']
        backups = list((home / 'Applications/OpenUtau Bridge Backups').iterdir())
        assert len(backups) == 2
        assert any((b / 'OpenUtau AU.app').exists() and (b / 'prefs.json').exists() for b in backups)
        before = prefs.read_bytes()
        relay = resources / 'payload/openutau-bridge-relay'
        with relay.open('ab') as f:
            f.write(b'tampered')
        result = subprocess.run(command, env=env, capture_output=True, text=True)
        assert result.returncode != 0 and 'Package verification failed' in result.stderr
        assert prefs.read_bytes() == before
        assert len(list((home / 'Applications/OpenUtau Bridge Backups').iterdir())) == 2
        env.pop('OPENUTAU_INSTALL_TEST')
        result = subprocess.run(command, env=env, capture_output=True, text=True)
        assert result.returncode != 0 and 'only supported for tests' in result.stderr
    print('PASS: archive signature, fresh install, reinstall backups, user data, agent, tamper rejection, test-home guard')


if __name__ == "__main__":
    main()
