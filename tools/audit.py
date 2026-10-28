"""Static runtime capability gate and inventory, using only Python's stdlib.
This does not prove game-rule compliance or inspect the host client for malware.
"""
from pathlib import Path
import hashlib,json,re,struct
base=Path(__file__).resolve().parent.parent;root=base/'AzerothFieldKit'
toc=(root/'AzerothFieldKit.toc').read_text(encoding='utf8')
version=next(s.split(':',1)[1].strip() for s in toc.splitlines() if s.startswith('## Version:'))
publication=json.loads((base/'data/publication-status.json').read_text(encoding='utf8'))
assert publication['version']==version,'Refresh publication metadata explicitly for this version'
loaded=[line for line in toc.splitlines() if line.endswith('.lua')]
assert set(loaded)=={p.name for p in root.glob('*.lua')},'Unexpected/unloaded Lua file'
# Quoted text and comments must not make a documented example look executable.
tokens=re.compile(r'"(?:\\.|[^"\\])*"|\'(?:\\.|[^\'\\])*\'|--[^\n]*')
forbidden={'load','loadstring','loadfile','dofile','require','getfenv','setfenv','RunScript',
 'SendChatMessage','SendAddonMessage','CastSpellByName','CastSpell','UseAction','TargetUnit',
 'MoveForwardStart','InteractUnit','EquipItemByName','io','os','package','debug'}
files={};index=['# Named function index','',
 'Generated from runtime declarations. Read the preceding source comments for contracts.',
 'Anonymous handlers are explained by their constructor and API_SURFACE.md.','']
for name in loaded:
 p=root/name;raw=p.read_bytes();text=raw.decode('utf8')
 assert b'\r' not in raw,'Normalize runtime text to LF before verification/packaging'
 assert '--[[' not in text and '[[' not in text,'Update tokenizer before adding long literals'
 code=tokens.sub(' ',text)
 identifiers=set(re.findall(r'\b[A-Za-z_]\w*\b',code))
 allowed={'SendAddonMessage'} if name=='Runtime.lua' else set()
 assert not identifiers&(forbidden-allowed),(name,identifiers&(forbidden-allowed))
 if name=='Runtime.lua':
  assert 'pcall(SendAddonMessage,"AFKDETAIL1",payload,"PARTY")' in text,'Unexpected outbound transport boundary'
  assert len(re.findall(r'pcall\(SendAddonMessage\b',code))==1,'Unexpected additional send call'
 assert not re.search(r'\bAZS_\w+\s*=(?!=)',code),(name,'native AZS write')
 assert 'MASHDB' not in identifiers,(name,'old DB access')
 if name!='Runtime.lua':
  assert not re.search(r'(?<![.\w])SetCVar\s*\(',code),(name,'unmediated CVar write')
  assert not re.search(r'(?<![.\w])AZS_SetHudShown\s*\(',code),(name,'unmediated HUD write')
 assert 'string.match' not in code and 'string.gmatch' not in code
 events=re.findall(r':RegisterEvent\("([^"\n]+)"\)',text)
 functions=[]
 for line,source in enumerate(text.splitlines(),1):
  m=re.match(r'\s*(?:local )?function ([\w_.]+)\(',source)
  if m:
   functions.append({'name':m[1],'line':line})
   index.append(f'- [{name}: {m[1]}](../AzerothFieldKit/{name}#L{line})')
 files[name]={'bytes':len(raw),'sha256':hashlib.sha256(raw).hexdigest(),'namedFunctions':functions,'literalEvents':events}
media=json.loads((base/"data/theme-assets.json").read_text(encoding="utf8"))["files"]
textures=[];portraits=0
for p in sorted(root.rglob('*'),key=lambda p:p.relative_to(root).as_posix()):
 assert not p.is_symlink(),'No symlinks in runtime'
 if not p.is_file():continue
 relative=p.relative_to(root).as_posix()
 if relative in media:
  raw=p.read_bytes();expected=media[relative]
  assert len(raw)==expected['bytes'] and hashlib.sha256(raw).hexdigest()==expected['sha256'],relative
 else:
  assert p.suffix in ('.lua','.toc','.tga'),('Unexpected runtime file',p.name)
 if p.suffix=='.tga':
  raw=p.read_bytes();width,height=struct.unpack_from('<HH',raw,12)
  assert raw[1]==0 and raw[2]==2 and raw[16]==32 and (width,height) in ((128,128),(256,256)),p.name
  if not relative.startswith('media/'):
   assert (width,height)==(128,128),p.name
   portraits+=1
  assert len(raw)>=18+raw[0]+width*height*4,p.name
  textures.append({'path':p.relative_to(root).as_posix(),'bytes':len(raw),'sha256':hashlib.sha256(raw).hexdigest()})
assert portraits==98
assert all((root/name).is_file() for name in media)
report={'kind':'maintainer static inventory; not certification','candidate':version,
 'runtimeModules':len(loaded),'textureCount':len(textures),'forbiddenTokenGatePassed':True,
 'dynamicCombatEventNames':'See CombatText.lua events list; not all registrations are string literals.',
 'files':files,'textures':textures,'themeMedia':media,'inGameTest':False,'approval':'maintainer accepted for publication; not independently certified','publication':publication,
 'optionalPartyDetailTransport':{'defaultEnabled':False,'nativeCallBoundary':'Runtime.lua','prefix':'AFKDETAIL1','distribution':'PARTY','maxBytes':230,'maxCallsPerSecond':4,'liveCoopTransportConfirmed':False}}
docs=base/'docs';docs.mkdir(exist_ok=True)
(docs/'AUDIT_INVENTORY.json').write_text(json.dumps(report,indent=2,ensure_ascii=False)+'\n',encoding='utf8',newline='\n')
(docs/'CODE_INDEX.md').write_text('\n'.join(index)+'\n',encoding='utf8',newline='\n')
print(f'Static gate passed: {len(loaded)} Lua modules, {len(textures)} verified TGA assets; no approval implied.')
