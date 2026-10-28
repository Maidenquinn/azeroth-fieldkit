-- Offline protocol/security tests. An accepted native call is NOT a transport
-- echo and must never be advertised as a received peer snapshot.
FieldKitDB={partyDetailSync=false}
fire(FieldKitFrame,"VARIABLES_LOADED")
local S=FieldKitPartySync
local sends=0
function UnitName(unit) return unit=="player" and "Maiden" or (unit=="party1" and "Denza") end
function UnitExists(unit) return unit=="player" or unit=="party1" end
function SendAddonMessage(prefix,body,channel)
 assert(prefix=="AFKDETAIL1" and channel=="PARTY" and string.len(body)<=230)
 sends=sends+1
end
assert(not FieldKit.SendPartyDetail("Q:1-1:Denza:100") and sends==0)
S.Request("Denza");S.Tick();assert(sends==0 and table.getn(S.queue)==0)
FieldKitDB.partyDetailSync=true
assert(not FieldKit.SendPartyDetail("X|arbitrary") and sends==0)
assert(not FieldKit.SendPartyDetail("Q:\n") and sends==0)
assert(not FieldKit.SendPartyDetail(string.rep("Q",231)) and sends==0)
S.Request("Stranger");assert(table.getn(S.queue)==0)
S.Request("Denza");S.Tick();assert(sends==1)
assert(S.completed==0 and S.Get("Denza")==nil,"API queue acceptance was treated as delivery")
assert(not FieldKit.SendPartyDetail("Q:1-2:Denza:100"))
NOW=NOW+.3
assert(FieldKit.SendPartyDetail("Q:1-3:Denza:100") and sends==2)

-- Reserved separators, percent signs and UTF-8 survive printable-only packets.
local spell="Éclair; feu, 100%"
assert(S.Decode(S.Encode(spell))==spell)
local native={}
for i=1,129 do native[i]={name=i==1 and spell or "Source "..i,dmg=123456789012+i,dps=12.125,share=.01} end
function AZS_GetMeter() return native,123456789013,24.25 end
S.Watch();local body=S.Snapshot();local data=S.Parse(body)
assert(data and data.truncated and table.getn(data.rows)==128)
local found=false
for i=1,table.getn(data.rows) do
 if data.rows[i].name==spell then found=true;assert(data.rows[i].dmg==123456789013 and data.rows[i].dps==12.125) end
end
assert(found,"Shared damage was rounded or the native name changed")
assert(not S.Parse("100,10,1,1,0;Spell,-1,1,.5,0"))
assert(not S.Parse("100,10,1,1,0;Spell,10,1,2,0"))
assert(not S.Parse("100,10,1,129,0;"))
assert(not S.Parse("100,10,1,1,0;Spell,10,1,.5,0;extra"))

-- Wrong channel/sender/nonce and oversized messages cannot create cache entries.
S.Receive("AFKDETAIL1","R:1-1:1:1:"..body,"WHISPER","Denza")
S.Receive("AFKDETAIL1","R:1-1:1:1:bad","PARTY","Stranger")
S.Receive("AFKDETAIL1","R:999-999:1:65:bad","PARTY","Denza")
assert(S.cache.Denza==nil)
local pendingId=S.pending.Denza.id
S.pending.Denza.at=GetTime()-11;S.requested.Denza=GetTime()-11
S.Request("Denza");assert(S.pending.Denza.id==pendingId,"A refresh replaced an in-flight fragmented response")
S.pending.Denza.at=GetTime()
local queued=table.getn(S.queue)
S.Receive("AFKDETAIL1","Q:1-100:Maiden:100","PARTY","Maiden")
assert(table.getn(S.queue)==queued,"Self echo caused an answer loop")
-- Fragmentation, reverse order and exact large integer damage round-trip.
local id=S.pending.Denza.id
local parts=math.ceil(string.len(body)/160)
assert(parts<=64)
for i=parts,1,-1 do
 NOW=NOW+.1
 S.Receive("AFKDETAIL1","R:"..id..":"..i..":"..parts..":"..string.sub(body,(i-1)*160+1,i*160),"PARTY","Denza")
end
assert(S.completed==1 and S.cache.Denza.damage==123456789013 and S.cache.Denza.truncated)
local completed=S.completed
S.Receive("AFKDETAIL1","R:"..id..":1:1:old","PARTY","Denza")
assert(S.completed==completed,"A replay replaced the snapshot without a pending request")
S.cache.Denza={received=GetTime(),rows={}};S.pending.Denza={at=GetTime(),id="1-2"}
AZS_RUN.t=0;S.Watch();assert(S.cache.Denza==nil and S.pending.Denza==nil and table.getn(S.queue)==0)
FieldKitDB.partyDetailSync=false;S.Watch()
assert(not FieldKit.SendPartyDetail("Q:1-4:Denza:0"))
local exists,name=UnitExists,UnitName
function UnitExists(unit) return unit=="player" or unit=="party1" or unit=="party2" end
function UnitName(unit) return unit=="player" and "Maiden" or "Denza" end
assert(not S.Peer("Denza"),"Duplicate roster names were treated as one authenticated peer")
UnitExists=exists;UnitName=name
print("Opt-in party sync boundary, bounded protocol, precision and no-delivery assumptions passed")
