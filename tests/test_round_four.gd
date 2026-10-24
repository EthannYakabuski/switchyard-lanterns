extends SceneTree
## Isolated source tests. Clock values and profile edits are fixtures only.
const Profile=preload("res://game/profile.gd")
const Model=preload("res://game/rail_model.gd")
var checks:=0
var failures:=0
class FaultProfile:
	extends "res://game/profile.gd"
	func save() -> bool:return false
func require(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1;push_error("Assertion failed: "+label)
func _initialize() -> void:call_deferred("run")
func run() -> void:
	if not OS.get_cmdline_user_args().has("--qa-isolated"):
		push_error("Isolated test storage is required.");quit(2);return
	var content: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://game/boards.json"))
	var p:=Profile.new()
	var old: Dictionary=p.defaults()
	for field in Profile.ENERGY_FIELDS:old.erase(field)
	old.coins=235;old.xp=126;old.records={"yard_01":{"stars":3,"best_unassisted":3}}
	require(p._valid(old),"legacy schema1 profile accepted before energy fields")
	var partial: Dictionary=old.duplicate(true);partial.energy=4
	require(not p._valid(partial),"partial damaged energy migration cannot silently refill")
	p.data=p._normalize(old)
	require(p.data.coins==235 and p.data.xp==126 and p.data.records==old.records,"legacy genuine fields not rewritten by migration")
	require(p.data.energy==12,"legacy energy starts full without changing existing awards")
	p.data.energy=0;p.data.energy_time=1000
	require(p.refresh_energy(1299)==0,"partial five-minute recharge retains fraction")
	require(p.refresh_energy(1300)==1 and p.data.energy_time==1300,"one energy at five minutes")
	require(p.refresh_energy(1900)==3,"offline catchup earns every completed interval")
	require(p.refresh_energy(1800)==3 and p.data.energy_time==1900,"backward time cannot reissue recharge")
	require(p.refresh_energy(100000)==12,"offline energy is capped")
	p.data.energy=12;p.data.energy_time=int(Time.get_unix_time_from_system());p.save()
	var run: String=p.new_run("yard_49",false)
	require(run!="" and p.data.energy==10,"new load ticket costs two energy atomically")
	var award: Dictionary=p.bank(run,content.boards[48],3,false,false,"2026-10-24")
	require(award.ok and p.data.energy>=11,"delivery restores one energy plus legitimate promotions")
	var held: Dictionary=p.data.duplicate(true)
	require(not p.bank(run,content.boards[48],3,false,false,"2026-10-24").ok and p.data==held,"duplicate result restores no extra energy")
	p.data.energy=0;p.data.energy_time=int(Time.get_unix_time_from_system());held=p.data.duplicate(true)
	require(p.new_run("yard_50",false)=="" and p.data==held,"no energy creates no ticket or partial mutation")
	var issued: int=p.issue_energy_reward()
	require(issued>0 and not p.settle_energy_reward(issued,false) and p.data.energy==0,"unearned native callback grants nothing")
	require(not p.settle_energy_reward(issued,true) and p.data.energy==0,"unearned callback cannot later become earned")
	issued=p.issue_energy_reward()
	require(p.settle_energy_reward(issued,true) and p.data.energy==12,"earned callback refills full")
	p.data.energy=4;p.save()
	require(not p.settle_energy_reward(issued,true) and p.data.energy==4,"duplicate earned callback cannot refill again")
	var obsolete: int=p.issue_energy_reward();issued=p.issue_energy_reward()
	require(not p.settle_energy_reward(obsolete,true) and p.data.energy==4,"older request cannot grant newer energy")
	require(p.settle_energy_reward(issued,true) and p.data.energy==12,"repeat watch is allowed with a new valid request")
	var loaded:=Profile.new();loaded.load_file()
	require(loaded.data==p.data and not loaded.settle_energy_reward(issued,true),"cold load retains consumed callback receipt")
	var fault:=FaultProfile.new();fault.data=p.data.duplicate(true);held=fault.data.duplicate(true)
	require(fault.new_run("yard_50",false)=="" and fault.data==held,"failed ticket write rolls back energy")
	require(fault.issue_energy_reward()==0 and fault.data==held,"failed issue write rolls back serial")
	fault.data.energy_issued=int(fault.data.energy_issued)+1;held=fault.data.duplicate(true)
	require(not fault.settle_energy_reward(int(fault.data.energy_issued),true) and fault.data==held,"failed earned write rolls back refill and receipt")
	var mirrored: Dictionary={"edges":[{"a":"P1","points":[[0,0],[3,1]]},{"a":"P1","points":[[0,0],[-3,1]]}]}
	require(Model.choice_label(mirrored,"P1",0)=="R" and Model.choice_label(mirrored,"P1",1)=="L","observer labels follow actual geometry rather than branch indices")
	var previous_choices:=6
	for i in range(48,100):
		var board: Dictionary=content.boards[i]
		require(board.number==i+1 and board.solution.size()>=previous_choices,"extension difficulty retains/increases actual turnout count %d"%(i+1))
		previous_choices=board.solution.size()
		var model:=Model.new();model.begin(board,board.solution);model.dispatch()
		for step in range(256):
			if model.status in ["won","failed"]:break
			model.step()
		require(model.status=="won" and model.trace.slice(1)==board.solution_trace,"actual extension solution %d"%(i+1))
		for key in board.solution:
			require(Model.choice_label(board,key,0)!=Model.choice_label(board,key,1),"distinct observer exits %s/%s"%[board.id,key])
	require(content.districts.size()==13 and previous_choices==11,"100 yards in thirteen districts finish at eleven choices")
	print("SWITCHYARD ROUND4 SOURCE %s: %d checks. No native reward/gameplay evidence."%["PASS" if failures==0 else "FAIL",checks])
	quit(0 if failures==0 else 1)
