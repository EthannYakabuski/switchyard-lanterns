extends SceneTree
const Model = preload("res://game/rail_model.gd")
const Profile = preload("res://game/profile.gd")
var checks := 0
var failures := 0

class FaultProfile:
	extends "res://game/profile.gd"
	var refuse_writes := false
	func save() -> bool:
		return false if refuse_writes else super.save()

func require(value: bool, text: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error("Assertion failed: "+text)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var content: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://game/boards.json"))
	var boards: Array = content.boards
	require(boards.size()==100,"100 authored yards")
	var fingerprints := {}
	for board in boards:
		var model := Model.new(); model.begin(board,board.solution)
		var before := model.snapshot()
		var preview := model.preview()
		require(preview.status=="won","solution preview "+board.id)
		require(model.snapshot()==before,"preview is nonmutating "+board.id)
		require(model.dispatch(),"dispatch "+board.id)
		for step_index in range(256):
			if model.status in ["won","failed"]: break
			model.step()
		require(model.status=="won","same engine solution "+board.id)
		require(model.trace.slice(1)==board.solution_trace,"stored trace "+board.id)
		require(model.collected==board.manifest,"exact ordered manifest "+board.id)
		require(model.stars()==3,"clean solution mastery "+board.id)
		require(model.step().is_empty(),"terminal cannot pay another transition")
		var restored := Model.new();restored.begin(board);require(restored.restore(model.snapshot()),"serialized simulation restores")
		require(restored.collected==model.collected and restored.steps==model.steps,"draft state exact")
		var fingerprint: String = JSON.stringify({"nodes":board.nodes,"edges":board.edges,"manifest":board.manifest})
		require(not fingerprints.has(fingerprint),"distinct authored yard "+board.id);fingerprints[fingerprint]=true
		model=null;restored=null
	var teaching := Model.new();teaching.begin(boards[0],{"P1":1});teaching.dispatch()
	teaching.step();teaching.step()
	require(teaching.status=="failed","genuine buffer failure")
	require(teaching.undo(),"free undo after failure")
	require(teaching.status=="paused","undo does not auto-dispatch")
	var order := Model.new();order.begin(boards[1],{"P1":1,"P2":0});order.dispatch();order.step();order.step()
	require(order.status=="failed" and order.collected.is_empty(),"wrong order cannot collect")
	var pause := Model.new();pause.begin(boards[2],boards[2].solution);pause.dispatch()
	require(not pause.set_point("P1",0),"running points cannot change")
	pause.pause();require(pause.set_point("P1",0),"clear points may change while paused")
	var profile := Profile.new()
	require(profile.save(),"first atomic save")
	var run_id := profile.new_run(boards[0].id,false)
	var award := profile.bank(run_id,boards[0],3,false,false,"2026-10-22")
	require(award.ok,"first result banks")
	var saved := profile.data.duplicate(true)
	require(not profile.bank(run_id,boards[0],3,false,false,"2026-10-22").ok,"same run cannot bank twice")
	require(saved==profile.data,"duplicate bank changes nothing")
	var loaded := Profile.new();loaded.load_file()
	if loaded.data!=profile.data:
		for key in profile.data:
			if loaded.data.get(key)!=profile.data[key]:print("Roundtrip mismatch field %s: restored type %d / source type %d"%[key,typeof(loaded.data.get(key)),typeof(profile.data[key])])
	require(loaded.data==profile.data,"genuine serialized profile roundtrip")
	require(not loaded.bank(run_id,boards[0],3,false,false,"2026-10-22").ok,"cold duplicate result cannot bank")
	require(profile.claim_login("2026-10-22","2026-10-21").ok,"daily login claim")
	require(not profile.claim_login("2026-10-22","2026-10-21").ok,"login only once per date")
	require(not profile.claim_login("2026-10-21","2026-10-20").ok,"backward clock no gift")
	profile.rollover("2026-10-23");profile.data.day_clears=3
	require(profile.claim_freight("2026-10-23"),"earned daily freight goal")
	require(not profile.claim_freight("2026-10-23"),"goal once only")
	profile.rollover("2026-10-22");require(profile.data.day=="2026-10-23","backward clock no goal reset")
	profile.save();profile.save()
	var broken := FileAccess.open(Profile.SAVE,FileAccess.WRITE);broken.store_string("broken-profile");broken.close()
	var backup := Profile.new();backup.load_file();require(backup.recovered,"verified backup recovery")
	var stats: Dictionary=profile.stats(boards);require(stats.campaign_stars==3 and stats.campaign_cleared==1,"record accounting")
	var faulty:=FaultProfile.new();faulty.refuse_writes=true
	var pristine: Dictionary=faulty.data.duplicate(true)
	require(faulty.new_run(boards[0].id,false)=="" and faulty.data==pristine,"run ID not consumed on write failure")
	require(not faulty.bank("yard_01:1:campaign",boards[0],3,false,false,"2026-10-22").ok and faulty.data==pristine,"award rolled back on write failure")
	require(not faulty.claim_login("2026-10-22","2026-10-21").ok and faulty.data==pristine,"login rolled back on write failure")
	faulty.data.day="2026-10-22";faulty.data.day_clears=3;pristine=faulty.data.duplicate(true)
	require(not faulty.claim_freight("2026-10-22") and faulty.data==pristine,"freight goal rolled back on write failure")
	var corrupt: Dictionary=profile.defaults();corrupt.settings={}
	require(not profile._valid(corrupt),"missing nested settings rejected")
	corrupt=profile.defaults();corrupt.records={"yard_01":0}
	require(not profile._valid(corrupt),"malformed nested record rejected")
	var route_before: Dictionary=pause.snapshot();corrupt=route_before.duplicate(true);corrupt.collected="not an array"
	require(not pause.restore(corrupt) and pause.snapshot()==route_before,"corrupt collected candidate rejected without mutation")
	corrupt=route_before.duplicate(true);corrupt.status="unknown"
	require(not pause.restore(corrupt) and pause.snapshot()==route_before,"invalid status rejected without mutation")
	corrupt=route_before.duplicate(true);corrupt.points={"P1":47}
	require(not pause.restore(corrupt) and pause.snapshot()==route_before,"invalid turnout rejected without mutation")
	var bridge:=Model.new();var switches: Dictionary=boards[16].solution.duplicate();switches.P3=0;bridge.begin(boards[16],switches);bridge.dispatch()
	for i in range(40):
		if bridge.status in ["won","failed"]:break
		bridge.step()
	require(bridge.status=="failed" and bridge.message.begins_with("Bridge limit"),"visible real overloaded bridge blocks otherwise matching cargo")
	require(bridge.collected.size()==2,"bridge counts actually coupled wagons")
	var history_model:=Model.new();history_model.begin(boards[1],boards[1].solution);history_model.dispatch();history_model.step();history_model.pause()
	var draft_state: Dictionary=history_model.snapshot();draft_state.undo_history=history_model.history.duplicate(true)
	var cold:=Model.new();cold.begin(boards[1]);require(cold.restore(draft_state),"validated cold undo history restores")
	require(cold.undo() and cold.at=="start","Undo remains free after cold draft reload")
	history_model.assisted=true
	require(history_model.undo() and history_model.assisted,"Undo cannot erase a legitimately earned hint flag")
	history_model.begin(boards[1]);require(not history_model.assisted,"genuine new run resets assistance")
	var legacy:=Profile.new();legacy.data.coins=50;legacy.data.xp=30
	require(legacy.save(),"existing valid profile remains serializable without migration")
	var retained:=Profile.new();retained.load_file()
	require(int(retained.data.coins)==50 and int(retained.data.xp)==30 and retained.level()==1,"existing profile receives no synthetic or retroactive gift")
	var next_run: String=retained.new_run(boards[1].id,false)
	var promotion: Dictionary=retained.bank(next_run,boards[1],3,false,false,"2026-10-22")
	require(promotion.ok and promotion.level_from==1 and promotion.level_to==2 and promotion.level_bonus==25,"real XP threshold grants exactly one level gift")
	require(int(retained.data.coins)==130 and int(retained.data.xp)==63,"bank pays base delivery plus level gift atomically")
	var promoted: Dictionary=retained.data.duplicate(true)
	require(not retained.bank(next_run,boards[1],3,false,false,"2026-10-22").ok and retained.data==promoted,"repeat result cannot pay a second level gift")
	var cold_level:=Profile.new();cold_level.load_file()
	require(cold_level.data==promoted and cold_level.level()==2,"cold load does not duplicate level-up gifts")
	var login_level:=Profile.new();login_level.data.xp=44
	var login_promotion: Dictionary=login_level.claim_login("2026-10-22","2026-10-21")
	require(login_promotion.ok and login_promotion.level_bonus==25 and int(login_level.data.coins)==50,"login XP threshold pays its level gift in the same claim")
	var login_before: Dictionary=login_level.data.duplicate(true)
	require(not login_level.claim_login("2026-10-22","2026-10-21").ok and login_level.data==login_before,"repeat post cannot repeat promotion gift")
	var freight_level:=Profile.new();freight_level.data.xp=44;freight_level.data.day="2026-10-22";freight_level.data.day_clears=3
	require(freight_level.claim_freight("2026-10-22") and int(freight_level.data.coins)==85 and freight_level.level()==2,"freight XP threshold pays its level gift atomically")
	var freight_before: Dictionary=freight_level.data.duplicate(true)
	require(not freight_level.claim_freight("2026-10-22") and freight_level.data==freight_before,"repeat freight goal cannot repeat promotion gift")
	var fault_level:=FaultProfile.new();fault_level.data.xp=44;fault_level.refuse_writes=true
	var fault_before: Dictionary=fault_level.data.duplicate(true)
	require(not fault_level.bank("yard_01:threshold:campaign",boards[0],3,false,false,"2026-10-22").ok and fault_level.data==fault_before,"failed bank rolls back XP crossing and gift together")
	require(not fault_level.claim_login("2026-10-22","2026-10-21").ok and fault_level.data==fault_before,"failed login rolls back XP crossing and gift together")
	fault_level.data.day="2026-10-22";fault_level.data.day_clears=3;fault_before=fault_level.data.duplicate(true)
	require(not fault_level.claim_freight("2026-10-22") and fault_level.data==fault_before,"failed freight save rolls back XP crossing and gift together")
	legacy=null;retained=null;cold_level=null;login_level=null;freight_level=null;fault_level=null
	bridge=null;history_model=null;cold=null
	teaching=null;order=null;pause=null;profile=null;loaded=null;backup=null
	faulty=null
	if failures==0:print("SWITCHYARD MODEL PASS: %d meaningful checks, all 100 authored solutions." % checks)
	else:print("SWITCHYARD MODEL FAIL: %d of %d checks failed."%[failures,checks])
	await process_frame
	quit(0 if failures==0 else 1)
