"""Declare only project formats; audio and MIDI default handlers are preserved."""
import plistlib
import sys
from pathlib import Path


def configure(app):
    path = Path(app) / 'Contents/Info.plist'
    info = plistlib.loads(path.read_bytes())
    bundle_id = 'moe.kakaru.openutau.logic-au'
    info.update(CFBundleIdentifier='com.stakira.openutau', CFBundleName='OpenUtau AU',
                CFBundleDisplayName='OpenUtau AU', CFBundleShortVersionString='0.1.576',
                CFBundleVersion='0.1.576.5')
    info['UTExportedTypeDeclarations'] = [
        {'UTTypeIdentifier': bundle_id + '.' + ext, 'UTTypeDescription': name,
         'UTTypeConformsTo': ['public.data'],
         'UTTypeTagSpecification': {'public.filename-extension': [ext]}}
        for ext, name in [('ust', 'UTAU Sequence'), ('ustx', 'OpenUtau Project')]]
    info['CFBundleDocumentTypes'] = [
        {'CFBundleTypeName': name, 'CFBundleTypeExtensions': extensions,
         'CFBundleTypeRole': 'Editor', 'LSHandlerRank': rank,
         'LSItemContentTypes': [uti], 'CFBundleTypeIconFile': 'OpenUtau.icns'}
        for name, extensions, uti, rank in [
            ('UTAU Sequence', ['ust'], bundle_id + '.ust', 'Owner'),
            ('OpenUtau Project', ['ustx'], bundle_id + '.ustx', 'Owner'),
            ('MIDI Sequence', ['mid', 'midi'], 'public.midi-audio', 'Alternate')]]
    path.write_bytes(plistlib.dumps(info, sort_keys=False))


if __name__ == '__main__':
    configure(sys.argv[1])
