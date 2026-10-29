extends SceneTree
## Synthetic profile transactions in process-isolated storage, not native-ad proof.
const Profile = preload("res://game/profile.gd")
var checks := 0
var failures := 0
func require(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	if not OS.get_cmdline_user_args().has("--qa-isolated"):
		push_error("Isolated test storage is required."); quit(2); return
	var content: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://game/boards.json"))
	var p := Profile.new()
	p.data.energy = 4; p.data.energy_time = int(Time.get_unix_time_from_system()); p.data.xp = 10000
	var before_level: int = p.level()
	var ticket: String = p.new_run(str(content.boards[0].id), false)
	require(ticket != "" and p.data.energy == 2, "A new puzzle still costs two energy")
	var result: Dictionary = p.bank(ticket, content.boards[0], 3, false, false, "2026-10-29")
	require(result.ok and p.level() == before_level and p.data.energy == 2, "Completing a puzzle without a promotion refunds no energy")
	require(int(p.data.clears) == 1 and int(p.data.xp) > 10000 and int(p.data.coins) > 0, "Completion still grants ordinary saved progression")
	var held: Dictionary = p.data.duplicate(true)
	require(not p.bank(ticket, content.boards[0], 3, false, false, "2026-10-29").ok and p.data == held, "Duplicate completion grants no energy or awards")
	p.data.energy = 4; p.data.xp = 10000; p.data.energy_time = int(Time.get_unix_time_from_system())
	var login: Dictionary = p.claim_login("2026-10-29", "2026-10-28")
	require(login.ok and p.level() == before_level and p.data.energy == 4, "Daily login has no direct energy reward")
	p.data.day_clears = 3
	require(p.claim_freight("2026-10-29") and p.data.energy == 4, "Daily freight claim has no direct energy reward")
	var promotion: Dictionary = p._earn_xp(200)
	require(int(promotion.level_to) > int(promotion.level_from) and p.data.energy == mini(12,4+3*(int(promotion.level_to)-int(promotion.level_from))), "Real level crossings remain an allowed energy source")
	p.data.energy = 0; p.data.energy_time = 1000
	require(p.refresh_energy(1599) == 0 and p.energy_wait(1599) == 1, "Timed recovery keeps a complete ten-minute interval")
	require(p.refresh_energy(1600) == 1 and p.energy_wait(1600) == 600, "Exactly one energy arrives at the interval boundary")
	require(p.refresh_energy(2800) == 3 and p.refresh_energy(2700) == 3, "Offline intervals accumulate without clock-rollback duplication")
	require(p.refresh_energy(100000) == 12, "Offline recovery remains capped")
	p.data.energy = 0; p.data.energy_time = int(Time.get_unix_time_from_system())
	var serial: int = p.issue_energy_reward()
	require(serial > 0 and not p.settle_energy_reward(serial,false) and p.data.energy == 0, "An unearned callback never restores energy")
	serial = p.issue_energy_reward()
	require(p.settle_energy_reward(serial,true) and p.data.energy == 12, "An actual earned-callback handler can still settle a full refill")
	p.data.energy = 5; p.save()
	require(not p.settle_energy_reward(serial,true) and p.data.energy == 5, "Duplicate callback cannot restore energy a second time")
	var restored := Profile.new(); restored.load_file()
	require(restored.data == p.data, "Energy and earned progression survive a cold profile load")
	print("SWITCHYARD_ROUND_FIVE checks=%d failures=%d; isolated transactions only" % [checks, failures])
	quit(0 if failures == 0 else 1)
