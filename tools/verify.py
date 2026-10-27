"""Offline verification, never executed by the addon. Requires lupa==2.8.
Optional --lua50 PATH also runs the fixtures under native Lua 5.0.3.
No game saves, installed addons, executable or MPQs are read or written.
"""
from pathlib import Path
import argparse,hashlib,json,re,subprocess,sys
from lupa.lua51 import LuaRuntime
from prototypes import Chunk

base=Path(__file__).resolve().parent.parent
root=base/'AzerothFieldKit'
parser=argparse.ArgumentParser();parser.add_argument('--lua50',type=Path);args=parser.parse_args()
toc=(root/'AzerothFieldKit.toc').read_text(encoding='utf8')
files=[s for s in toc.splitlines() if s.endswith('.lua')]
assert len(files)==len(set(files)) and set(files)=={p.name for p in root.glob('*.lua')}
assert '## SavedVariables: FieldKitDB' in toc

def runtime(saved=None):
 l=LuaRuntime(unpack_returned_tuples=True)
 l.execute((base/'tests/mock.lua').read_text(encoding='utf8'))
 l.execute('string.match=nil;string.gmatch=nil')
 if saved:l.execute('FieldKitDB='+saved)
 for name in files:l.execute((root/name).read_text(encoding='utf8'),name=name)
 return l

fresh=runtime();fresh.execute('fire(FieldKitFrame,"VARIABLES_LOADED")')
fresh.execute((base/'tests/security.lua').read_text(encoding='utf8'))
defaults=runtime()
defaults.execute('''
local writes=0
SetCVar=function() writes=writes+1 end
AZS_SetHudShown=function() writes=writes+1 end
fire(FieldKitFrame,"VARIABLES_LOADED");fire(FieldKitFrame,"PLAYER_ENTERING_WORLD")
SlashCmdList.FieldKit("");update(FieldKitFrame,.1)
assert(writes==0,"Fresh configuration wrote native CVars/HUD settings")
''')
secure=runtime()
secure.execute('''
function hooksecurefunc(object,key,callback)
 local original=object[key]
 object[key]=function(self,msg,r,g,b,id)
  local result=original(self,msg,r,g,b,id);callback(self,msg);return result
 end
end
fire(FieldKitFrame,"VARIABLES_LOADED")
''')
secure.execute((base/'tests/security.lua').read_text(encoding='utf8'))
effects=runtime();effects.execute((base/'tests/action_effects.lua').read_text(encoding='utf8'))
l=runtime('{compactBar=true,bossFrame=true,hidePlates=true,replaceTally=true,chestPins=true,guardianPins=true,moneyDetached=true,pos={FieldKitMoneyFrame={-2.5374755859375,-348.0493927001953}}}')
l.execute('fire(FieldKitFrame,"VARIABLES_LOADED");SlashCmdList.FieldKit("")')
for name in ('test_money.lua','tests.lua','test_worldpins.lua','test_combat_editor.lua','test_localization.lua'):
 l.execute((base/'tests'/name).read_text(encoding='utf8'),name=name)
 print('PASS',name)
l.execute((base/'tests/snapshot.lua').read_text(encoding='utf8'))
saved=l.eval('SNAPSHOT(FieldKitDB)')
again=runtime(saved);again.execute('fire(FieldKitFrame,"VARIABLES_LOADED");SlashCmdList.FieldKit("")')
again.execute('assert(FieldKitDB.language=="fr");assert(FieldKitDB.guardianPins==false);assert(FieldKitDB.targetHealthMode==2);assert(FieldKitDB.combatTextX==-123);assert(FieldKitDB.combatEvents.crit.size=="31");assert(FieldKitDB.chatCopy==false)')
# Walk every compiled nested function, even callbacks the mock did not reach.
compiler=LuaRuntime(encoding=None);prototypes={}
for name in files:
 data=(root/name).read_bytes();assert not data.startswith(b'\xef\xbb\xbf')
 c=Chunk(compiler.eval(b'function(s) return string.dump(assert(loadstring(s))) end')(data))
 assert c.maximum<=32,(name,c.maximum)
 prototypes[name]={'maxUpvalues':c.maximum,'functions':c.count,'sha256':hashlib.sha256(data).hexdigest()}
native=None
if args.lua50:
 run=subprocess.run([str(args.lua50.resolve()),'tests/native50.lua'],cwd=base,capture_output=True,text=True,encoding='utf8',timeout=60)
 assert run.returncode==0,run.stdout+run.stderr
 native=run.stdout.strip()
result={'version':'0.1.0-review.1','lua51':True,'nativeLua50':native,'persistence':True,'securityFixtures':True,
 'freshDefaultsNoCVarOrHudWrites':True,'manualActionSwapFixture':True,'bothChatHookPaths':True,
 'inGameTest':False,'approval':'not approved','files':prototypes}
out=base/'build';out.mkdir(exist_ok=True)
(out/'validation.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf8',newline='\n')
print(json.dumps(result,indent=2))
