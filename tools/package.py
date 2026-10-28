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
payload={p.relative_to(root).as_posix():p.read_bytes() for p in root.rglob('*') if p.is_file()}
for name in ('README.md','README.fr.md','NOTICE.md','LICENSE.md','SECURITY.md','CHANGELOG.md'):
 payload[name]=(base/name).read_bytes()
for p in (base/'docs').glob('*'):
 if p.is_file():payload['docs/'+p.name]=p.read_bytes()
# Historical guides and raw baseline source are deliberately not in the runtime.
# Package the committed review snapshot. The current verification report stays a
# separate build artifact, so differing CI capabilities do not alter the ZIP.
snapshot=json.loads((base/'docs/validation.json').read_text(encoding='utf8'))
for name,result in snapshot['files'].items():
 assert hashlib.sha256((root/name).read_bytes()).hexdigest()==result['sha256'],'Stale committed validation snapshot'
try:
 commit=subprocess.check_output(['git','rev-parse','HEAD'],cwd=base,text=True,stderr=subprocess.DEVNULL).strip()
 dirty=subprocess.check_output(['git','status','--porcelain'],cwd=base,text=True)
 assert not dirty,'Commit reviewed source/docs first; refusing a dirty sourceCommit claim'
except (subprocess.CalledProcessError,FileNotFoundError):commit=None
manifest={'name':'Azeroth FieldKit','version':version,'sourceCommit':commit,'approval':'maintainer accepted for publication; not independently certified','publication':publication,
 'distribution':'public maintainer-accepted update; GitHub prerelease; inherited rights unresolved','inGameTest':False,
 'files':{name:{'sha256':hashlib.sha256(data).hexdigest(),'bytes':len(data)} for name,data in sorted(payload.items())}}
payload['MANIFEST.json']=(json.dumps(manifest,indent=2)+'\n').encode()
out=base/'dist';out.mkdir(exist_ok=True);archive=out/f'AzerothFieldKit-{version}.zip'
with zipfile.ZipFile(archive,'w',compression=zipfile.ZIP_DEFLATED,compresslevel=9) as z:
 for name,data in sorted(payload.items()):
  entry=zipfile.ZipInfo('AzerothFieldKit/'+name,(2026,10,27,0,0,0))
  entry.create_system=3;entry.external_attr=0o100644<<16;entry.compress_type=zipfile.ZIP_DEFLATED
  z.writestr(entry,data,compress_type=zipfile.ZIP_DEFLATED,compresslevel=9)
with zipfile.ZipFile(archive) as z:assert z.testzip() is None
checksum=hashlib.sha256(archive.read_bytes()).hexdigest()
(out/'SHA256SUMS.txt').write_text(checksum+'  '+archive.name+'\n',encoding='ascii',newline='\n')
(out/'MANIFEST.json').write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf8',newline='\n')
print(f'{archive.name}: {len(payload)} files; SHA256 {checksum}; source {commit}')
