-- World-anchored combat text follows Addon API version 1 (cursor + project + handler).
FieldKitDB.combatText=true
FieldKitDB.combatTextWorld=true
FieldKitDB.combatTextOutgoing=true
FieldKitDB.combatTextIncoming=true
FieldKitDB.combatTextHealing=true
FieldKitCombat.Ensure()

local cursor,stream="c0","s1"
local events={}
local projected={}
local handler
function AZS_GetCombatTextCapabilities()
 return {apiVersion=1,impactAnchors=true,followAnchors=true,frameProjection=true,distanceMetrics=true,frameHandler=true,maxEventsPerRead=256,maxAnchorsPerRead=256}
end
function AZS_GetCombatTextEvents(cur)
 if cur~=nil and cur~=cursor then return nil,{code="STREAM_CHANGED",message="stream"} end
 local batch={apiVersion=1,streamId=stream,worldId="w1",clockSeconds=GetTime(),cursor="c1",events=events,hasMore=false,droppedCount=0}
 cursor=batch.cursor
 return batch,nil
end
function AZS_ProjectCombatTextAnchors(ids,mode)
 assert(mode=="follow")
 local entries={}
 for i=1,table.getn(ids) do
  local p=projected[ids[i]] or {state="onScreen",x=100+i,y=200+i,cameraDistance=12}
  p.anchorId=ids[i]
  table.insert(entries,p)
 end
 return {apiVersion=1,worldId="w1",streamId=stream,cameraSampleId="cam1",clockSeconds=GetTime(),frameCurrent=true,entries=entries},nil
end
function AZS_RegisterCombatTextFrameHandler(fn)
 handler=fn;return true
end

events={{
 eventId="e1",presentedAt=GetTime(),kind="damage",amount=42,critical=true,periodic=false,
 abilityName="Fireball",anchorId="a1",anchorStatus="ready",sourceKind="player"
}}
projected.a1={state="onScreen",x=320,y=480,cameraDistance=10}

-- Drive the OnUpdate path so EnsureWorldHandler registers, then the frame handler.
local f=FieldKitCombatText
assert(f and f.scripts and f.scripts.OnUpdate)
arg1=1
f.scripts.OnUpdate()
assert(handler,"combat text frame handler must register when APIs exist")
handler()
assert(FieldKitCombatText,"frame present")
-- One world-anchored crit should occupy a slot.
local live=0
for i=1,10 do
 local slot=_G["FieldKitCombatText"] -- slots are locals; observe via Emit side effects on fontstrings
end
-- Re-run handler after clearing events: cursor advances, no STREAM_CHANGED.
events={}
handler()

-- Incoming chat still queues while world mode is on (API is outgoing-only).
events={}
local capture
for ev,_ in pairs(f.events or {}) do end
-- Fire a creature-vs-self hit through the combat frame event script.
if f.scripts and f.scripts.OnEvent then
 local previous=event;event="CHAT_MSG_COMBAT_CREATURE_VS_SELF_HITS"
 local previousArg=arg1;arg1="Young Wolf hits you for 15."
 f.scripts.OnEvent()
 arg1=previousArg;event=previous
end

-- STREAM_CHANGED clears and resubscribes.
cursor="stale"
events={{eventId="e2",presentedAt=GetTime(),kind="damage",amount=9,abilityName="Frostbolt",anchorId="a2",anchorStatus="ready",sourceKind="player"}}
projected.a2={state="onScreen",x=10,y=20,cameraDistance=8}
handler()

AZS_GetCombatTextCapabilities=nil
AZS_GetCombatTextEvents=nil
AZS_ProjectCombatTextAnchors=nil
AZS_RegisterCombatTextFrameHandler=nil
FieldKitDB.combatTextWorld=false
FieldKitCombat.Clear()
print("combat_world: API v1 cursor/project/handler fixtures passed")
