"""Read-only export of base class spell names/icons from the local Vanilla DBCs.
No Azerloot code, catalogs, translations or artwork are used.
"""
from pathlib import Path
import struct,json,hashlib,argparse
p=argparse.ArgumentParser();p.add_argument('--spell',type=Path,required=True);p.add_argument('--icons',type=Path,required=True);args=p.parse_args()
base=Path(__file__).resolve().parent.parent
def dbc(path):
 b=path.read_bytes();magic,n,f,size,ss=struct.unpack_from('<4s4I',b);assert magic==b'WDBC' and size==f*4
 return b,[struct.unpack_from('<'+'I'*f,b,20+i*size) for i in range(n)],b[20+n*size:],f
def txt(strings,off):return strings[off:strings.index(0,off)].decode('utf8')
sb,spells,ss,fields=dbc(args.spell);ib,icons,ist,_=dbc(args.icons);assert fields==173
icons={r[0]:txt(ist,r[1]) for r in icons};records={}
racials={'War Stomp','Berserking','Blood Fury','Perception','Stoneform','Shadowmeld','Will of the Forsaken','Escape Artist'}
for r in spells:
 if (3<=r[160]<=11 or txt(ss,r[120]) in racials) and txt(ss,r[129]) in ('','Rank 1') and r[117] in icons:
  records[r[0]]={'name':txt(ss,r[120]),'icon':icons[r[117]]}
assert records[133]['icon'].endswith('Spell_Fire_FlameBolt') and records[1680]['icon'].endswith('Ability_Whirlwind')
lines=['-- Generated directly from local Spell.dbc (173 fields) and SpellIcon.dbc.', '-- Base class spell assets only; not an ability/rank/bonus prediction table.','FieldKitSpellAssets={']
for key,r in sorted(records.items()):lines.append(' ['+str(key)+']={name='+json.dumps(r['name'],ensure_ascii=False)+',icon='+json.dumps(r['icon'],ensure_ascii=False)+'},')
lines.append('}')
(base/'AzerothFieldKit/SpellAssets.lua').write_text('\n'.join(lines)+'\n',encoding='utf8',newline='\n')
(base/'data/spell-assets-evidence.json').write_text(json.dumps({'source':'independent local DBC extraction','spellSha256':hashlib.sha256(sb).hexdigest(),'iconsSha256':hashlib.sha256(ib).hexdigest(),'records':len(records),'fields':{'name':120,'rank':129,'iconId':117,'family':160},'inGameTest':False},indent=2)+'\n',encoding='utf8')
print(len(records),'native base class spell icon/name entries')
