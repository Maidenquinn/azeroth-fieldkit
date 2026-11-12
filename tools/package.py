"""Build a deterministic runtime ZIP. Does not install or modify any addon.
Run audit.py and verify.py first; stale evidence is rejected.
"""
from pathlib import Path
import hashlib,json,subprocess,zipfile
base=Path(__file__).resolve().parent.parent;root=base/'AzerothFieldKit'
version=next(s.split(':',1)[1].strip() for s in (root/'AzerothFieldKit.toc').read_text().splitlines() if s.startswith('## Version:'))
publication=json.loads((base/'data/publication-status.json').read_text(encoding='utf8'))
assert publication['version']==version,'Refresh publication metadata explicitly for this version'
validation=json.loads((base/'build/validation.json').read_text())
inventory=json.loads((base/'docs/AUDIT_INVENTORY.json').read_text())
for name,result in validation['files'].items():
 assert hashlib.sha256((root/name).read_bytes()).hexdigest()==result['sha256'],('Stale validation',name)
for name,result in inventory['files'].items():
 assert hashlib.sha256((root/name).read_bytes()).hexdigest()==result['sha256'],('Stale inventory',name)
for result in inventory['textures']:
 assert hashlib.sha256((root/result['path']).read_bytes()).hexdigest()==result['sha256'],'Stale texture inventory'
for name,result in inventory.get('themeMedia',{}).items():
 assert hashlib.sha256((root/name).read_bytes()).hexdigest()==result['sha256'],'Stale theme media inventory'
# Explicit install payload: TOC, loaded Lua and audited assets only. Review
# documents/JSON remain in the repository or separate release attachments.
modules=[line for line in (root/'AzerothFieldKit.toc').read_text(encoding='utf8').splitlines() if line.endswith('.lua')]
expected=set(modules)|{'AzerothFieldKit.toc'}|{item['path'] for item in inventory['textures']}|set(inventory['themeMedia'])
actual={p.relative_to(root).as_posix() for p in root.rglob('*') if p.is_file()}
assert actual==expected,('Unexpected/missing runtime files',actual^expected)
assert all(not (root/name).is_symlink() for name in expected),'No symlinks in package'
payload={name:(root/name).read_bytes() for name in sorted(expected)}
# Attribution and licenses must travel with the addon. Plain-text filenames also
# avoid distributing review/document formats inside the install archive.
for name in ('NOTICE','LICENSE'):
 payload[name+'.txt']=(base/(name+'.md')).read_bytes()
payload['README.txt']=('Azeroth FieldKit '+version+'\n\n'
 'Install the AzerothFieldKit folder in your launched client AddOns directory, enable it and restart the game.\n'
 'Open settings with /fieldkit. No external application is required.\n\n'
 'Maintained by Kevin Radlowski / Maidenhead; derived from MASH by Malk.\n'
 'See NOTICE.txt, LICENSE.txt and media/OFL-NotoSans.txt for credits and rights.\n'
 'Documentation, changelog, audit evidence and source:\n'
 'https://github.com/Maidenquinn/azeroth-fieldkit\n').encode('utf8')
payload['RECETTE.txt']=(base/'docs/RECEPTION_0.6.0.txt').read_bytes()
assert all(Path(name).suffix in {'.lua','.toc','.tga','.ttf','.txt'} for name in payload)
assert not any(name.startswith('docs/') or Path(name).suffix=='.json' for name in payload)
# Historical guides and raw baseline source are deliberately not in the runtime.
# Package the committed review snapshot. The current verification report stays a
# separate build artifact, so differing CI capabilities do not alter the ZIP.
snapshot=json.loads((base/'docs/validation.json').read_text(encoding='utf8'))
for name,result in snapshot['files'].items():
 assert hashlib.sha256((root/name).read_bytes()).hexdigest()==result['sha256'],'Stale committed validation snapshot'
try:
 commit=subprocess.check_output(['git','rev-parse','HEAD'],cwd=base,text=True,stderr=subprocess.DEVNULL).strip()
 dirty=subprocess.check_output(['git','status','--porcelain'],cwd=base,text=True)
 # CI freshly regenerates only these review evidence files after auditing the
 # committed runtime. Keep all runtime, packaging and release source clean.
 generated={'docs/AUDIT_INVENTORY.json','docs/CODE_INDEX.md','docs/validation.json'}
 changed={line[3:].strip() for line in dirty.splitlines() if line.strip()}
 assert changed.issubset(generated),('Unreviewed dirty source',sorted(changed-generated))
except (subprocess.CalledProcessError,FileNotFoundError):commit=None
manifest={'name':'Azeroth FieldKit','version':version,'sourceCommit':commit,'approval':('maintainer accepted for publication; not independently certified' if publication['maintainerAcceptedForPublication'] else 'development candidate; not accepted for publication'),'publication':publication,
 'distribution':'versioned addon package; maturity/permission scope in publication metadata','inGameTest':publication.get('inGameTestByAgent',False),'inGameTestScope':publication.get('inGameTestScope'),
 'files':{name:{'sha256':hashlib.sha256(data).hexdigest(),'bytes':len(data)} for name,data in sorted(payload.items())}}
out=base/'dist';out.mkdir(exist_ok=True);archive=out/f'AzerothFieldKit-{version}.zip'
with zipfile.ZipFile(archive,'w',compression=zipfile.ZIP_DEFLATED,compresslevel=9) as z:
 for name,data in sorted(payload.items()):
  entry=zipfile.ZipInfo('AzerothFieldKit/'+name,(2026,10,27,0,0,0))
  entry.create_system=3;entry.external_attr=0o100644<<16;entry.compress_type=zipfile.ZIP_DEFLATED
  z.writestr(entry,data,compress_type=zipfile.ZIP_DEFLATED,compresslevel=9)
with zipfile.ZipFile(archive) as z:
 assert z.testzip() is None
 installed={name.removeprefix('AzerothFieldKit/') for name in z.namelist()}
 assert installed==set(payload)==set(manifest['files']),'Archive/sidecar manifest mismatch'
 assert all(Path(name).suffix in {'.lua','.toc','.tga','.ttf','.txt'} for name in installed),'Non-install file leaked into addon ZIP'
 assert not any(name.startswith('docs/') for name in installed),'Review docs leaked into addon ZIP'
 for name,record in manifest['files'].items():
  assert hashlib.sha256(z.read('AzerothFieldKit/'+name)).hexdigest()==record['sha256'],name
checksum=hashlib.sha256(archive.read_bytes()).hexdigest()
(out/'SHA256SUMS.txt').write_text(checksum+'  '+archive.name+'\n',encoding='ascii',newline='\n')
(out/'MANIFEST.json').write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf8',newline='\n')
print(f'{archive.name}: {len(payload)} files; SHA256 {checksum}; source {commit}')
