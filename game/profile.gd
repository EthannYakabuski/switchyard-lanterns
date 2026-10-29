class_name RailwayProfile
extends RefCounted
## Gameplay persistence only. Native service queue lives independently in Services.
const SAVE := "user://railway_v1.json"
const LEVEL_GIFT := 25
const ENERGY_MAX := 12
const ENERGY_COST := 2
const ENERGY_SECONDS := 600
const BOARD_COUNT := 100
const ENERGY_FIELDS := ["energy","energy_time","energy_issued","energy_settled"]
var data: Dictionary = {}
var recovered := false
var load_message := ""

func _init() -> void:
	data = defaults()

func defaults() -> Dictionary:
	return {"energy":ENERGY_MAX,"energy_time":int(Time.get_unix_time_from_system()),"energy_issued":0,"energy_settled":0,"schema":1,"coins":0,"xp":0,"clears":0,"cargo_total":0,"largest_manifest":0,"records":{},"banked":[],"next_run":1,"draft":{},"login_day":"","login_streak":0,"login_last":"","daily_days":[],"day":"","day_clears":0,"day_claimed":false,"settings":{"music":true,"effects":true,"speed":1.0,"livery":0},"unlocked":[]}

func load_file() -> void:
	var damaged:=false
	for path in [SAVE,SAVE+".bak"]:
		if not FileAccess.file_exists(path): continue
		var parsed: Dictionary=_read_valid(path)
		if not parsed.is_empty():
			data = _normalize(parsed); recovered = path.ends_with(".bak")
			if recovered:load_message="Your previous verified railway profile was recovered."
			return
		damaged=true
		_preserve_unreadable(path)
	if damaged:load_message="The saved profile could not be read. Its original bytes are kept locally; a new profile is ready."

func _read_valid(path: String) -> Dictionary:
	var parser:=JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path))!=OK:return {}
	if parser.data is Dictionary and _valid(parser.data):return parser.data
	return {}

func _preserve_unreadable(path: String) -> bool:
	var digest: String=FileAccess.get_sha256(path)
	var destination: String=path+".unreadable-"+digest.left(12)
	if FileAccess.file_exists(destination):return FileAccess.get_sha256(destination)==digest
	return DirAccess.copy_absolute(path,destination)==OK and FileAccess.get_sha256(destination)==digest

func _valid(value: Dictionary) -> bool:
	for key in defaults():
		if not value.has(key) and key not in ENERGY_FIELDS:return false
	for key in ["schema","coins","xp","clears","cargo_total","largest_manifest","next_run","login_streak","day_clears"]:
		if not _integer(value[key]) or float(value[key])<0 or float(value[key])>9007199254740000.0:return false
	var energy_fields_present: int=0
	for key in ENERGY_FIELDS:
		if value.has(key):energy_fields_present+=1
		if value.has(key) and (not _integer(value[key]) or int(value[key])<0 or float(value[key])>9007199254740000.0):return false
	if energy_fields_present not in [0,ENERGY_FIELDS.size()]:return false
	if value.has("energy") and int(value.energy)>ENERGY_MAX:return false
	if int(value.get("energy_settled",0))>int(value.get("energy_issued",0)):return false
	if int(value.schema)!=1 or int(value.next_run)<1 or int(value.login_streak)>7:return false
	if not value.records is Dictionary or not value.settings is Dictionary or not value.draft is Dictionary:return false
	for key in value.records:
		if not key is String:return false
		var record: Variant=value.records[key]
		if not record is Dictionary:return false
		for field in ["stars","best_unassisted"]:
			if not record.has(field) or not _integer(record[field]) or int(record[field])<0 or int(record[field])>3:return false
	var settings: Dictionary=value.settings
	for key in ["music","effects"]:
		if not settings.get(key) is bool:return false
	if not _integer(settings.get("livery")) or int(settings.livery)<0 or int(settings.livery)>2:return false
	if not (settings.get("speed") is float or settings.get("speed") is int) or float(settings.speed) not in [0.7,1.0,1.5]:return false
	for key in ["banked","daily_days","unlocked"]:
		if not value[key] is Array:return false
		for item in value[key]:
			if not item is String:return false
	for key in ["day","login_day","login_last"]:
		if not value[key] is String:return false
	if not value.day_claimed is bool:return false
	if not value.draft.is_empty():
		if not _integer(value.draft.get("index")) or int(value.draft.index)<0 or int(value.draft.index)>=BOARD_COUNT:return false
		if not value.draft.get("daily") is bool or not value.draft.get("run_id") is String or not value.draft.get("state") is Dictionary:return false
	return true

func _integer(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value)==floor(float(value))

func _normalize(value: Dictionary) -> Dictionary:
	var result: Dictionary=value.duplicate(true)
	var initial: Dictionary=defaults()
	for key in ENERGY_FIELDS:result[key]=int(value.get(key,initial[key]))
	# JSON numbers arrive as floats. Normalize the documented integer schema so
	# in-memory and restored records have identical types as well as values.
	for key in ["schema","coins","xp","clears","cargo_total","largest_manifest","next_run","login_streak","day_clears"]:result[key]=int(result[key])
	result.settings.livery=int(result.settings.livery);result.settings.speed=float(result.settings.speed)
	for key in result.records:
		result.records[key].stars=int(result.records[key].stars);result.records[key].best_unassisted=int(result.records[key].best_unassisted)
	if not result.draft.is_empty():result.draft.index=int(result.draft.index)
	return result

func save() -> bool:
	if not _valid(data):return false
	var serialized := JSON.stringify(data,"\t")
	var handle := FileAccess.open(SAVE+".tmp", FileAccess.WRITE)
	if handle == null: return false
	handle.store_string(serialized); handle.flush()
	var write_ok: bool=handle.get_error()==OK
	handle.close()
	if not write_ok or _read_valid(SAVE+".tmp").is_empty() or FileAccess.get_sha256(SAVE+".tmp")!=serialized.sha256_text():return false
	# Keep the previous verified profile before the atomic same-volume replace.
	if FileAccess.file_exists(SAVE):
		var old: Dictionary=_read_valid(SAVE)
		if not old.is_empty():
			if FileAccess.file_exists(SAVE+".bak") and _read_valid(SAVE+".bak").is_empty() and not _preserve_unreadable(SAVE+".bak"):return false
			if DirAccess.copy_absolute(SAVE,SAVE+".bak.tmp")!=OK:return false
			if _read_valid(SAVE+".bak.tmp").is_empty():return false
			if DirAccess.rename_absolute(SAVE+".bak.tmp",SAVE+".bak")!=OK:return false
		elif not _preserve_unreadable(SAVE):return false
	return DirAccess.rename_absolute(SAVE+".tmp",SAVE) == OK

func new_run(board_id: String, daily: bool,initial_draft: Dictionary={}) -> String:
	var id := "%s:%d:%s" % [board_id,int(data.next_run),"daily" if daily else "campaign"]
	var previous: Dictionary=data.duplicate(true)
	refresh_energy()
	if int(data.energy)<ENERGY_COST:data=previous;return ""
	data.energy=int(data.energy)-ENERGY_COST
	data.next_run = int(data.next_run)+1
	if not initial_draft.is_empty():
		data.draft=initial_draft.duplicate(true);data.draft.run_id=id;data.draft.daily=daily
	if not save():data=previous;return ""
	return id

func level() -> int:
	return 1+int(sqrt(float(data.xp)/45.0))

func _earn_xp(amount: int) -> Dictionary:
	# XP only increases through durable, once-only claim transactions. Comparing
	# the persisted before/after levels awards each crossing exactly once without
	# adding a save field or retroactively altering older legitimate profiles.
	var before: int=level()
	data.xp=int(data.xp)+amount
	var after: int=level()
	var gift: int=maxi(0,after-before)*LEVEL_GIFT
	data.coins=int(data.coins)+gift
	if after>before:add_energy((after-before)*3)
	return {"level_from":before,"level_to":after,"level_bonus":gift}

func rollover(day: String) -> void:
	# Advancing UTC dates only. A backward clock does not re-enable any claim.
	if str(data.day)=="" or day > str(data.day):
		data.day=day; data.day_clears=0; data.day_claimed=false

func claim_login(day: String, yesterday: String) -> Dictionary:
	if day <= str(data.login_last): return {"ok":false}
	var previous: Dictionary=data.duplicate(true)
	data.login_streak = mini(7,int(data.login_streak)+1) if str(data.login_last)==yesterday else 1
	data.login_last=day;data.login_day=day
	var coins := 20+int(data.login_streak)*5
	data.coins=int(data.coins)+coins
	var levels: Dictionary=_earn_xp(5)
	if not save():data=previous;return {"ok":false,"reason":"save_failed"}
	return {"ok":true,"coins":coins,"xp":5,"streak":data.login_streak,"level_from":levels.level_from,"level_to":levels.level_to,"level_bonus":levels.level_bonus}

func claim_freight(day: String) -> bool:
	var previous: Dictionary=data.duplicate(true)
	rollover(day)
	if day != str(data.day) or bool(data.day_claimed) or int(data.day_clears)<3: return false
	data.day_claimed=true;data.coins=int(data.coins)+60;_earn_xp(20)
	if not save():data=previous;return false
	return true

func bank(run_id: String, board: Dictionary, stars: int, assisted: bool, daily: bool, day: String) -> Dictionary:
	if run_id == "" or data.banked.has(run_id): return {"ok":false,"reason":"already_banked"}
	var expected_prefix := str(board.id)+":"
	if not run_id.begins_with(expected_prefix): return {"ok":false}
	var previous: Dictionary=data.duplicate(true)
	rollover(day)
	data.banked.append(run_id)
	var first: bool = not data.records.has(board.id)
	var earned_coins: int = 25+board.manifest.size()*5+(20 if first else 0)
	var earned_xp: int = 12+board.manifest.size()*3+(15 if first else 0)
	data.coins=int(data.coins)+earned_coins
	var levels: Dictionary=_earn_xp(earned_xp)
	data.clears=int(data.clears)+1;data.cargo_total=int(data.cargo_total)+board.manifest.size()
	data.largest_manifest=maxi(int(data.largest_manifest),board.manifest.size())
	if day == str(data.day):data.day_clears=int(data.day_clears)+1
	if daily and not data.daily_days.has(day): data.daily_days.append(day)
	var old: Dictionary = data.records.get(board.id,{"stars":0,"best_unassisted":0})
	old.stars=maxi(int(old.get("stars",0)),stars)
	if not assisted:old.best_unassisted=maxi(int(old.get("best_unassisted",0)),stars)
	data.records[board.id]=old;data.draft={}
	if not save():data=previous;return {"ok":false,"reason":"save_failed"}
	return {"ok":true,"coins":earned_coins,"xp":earned_xp,"first":first,"stars":stars,"level_from":levels.level_from,"level_to":levels.level_to,"level_bonus":levels.level_bonus}

func stats(boards: Array) -> Dictionary:
	var result: Dictionary = {"clears":int(data.clears),"cargo_total":int(data.cargo_total),"largest_manifest":int(data.largest_manifest),"xp":int(data.xp),"level":level(),"daily_clears":data.daily_days.size(),"campaign_cleared":data.records.size(),"campaign_stars":0,"perfect":0}
	for i in range(13):result["district_%d"%i]=0
	for board in boards:
		if not data.records.has(board.id):continue
		var rec: Dictionary=data.records[board.id]
		result["district_%d"%int(board.district)]=int(result["district_%d"%int(board.district)])+1
		result.campaign_stars=int(result.campaign_stars)+int(rec.get("best_unassisted",0))
		if int(rec.get("best_unassisted",0))==3:result.perfect=int(result.perfect)+1
	return result

func is_open(index: int, boards: Array) -> bool:
	return index==0 or (index>0 and data.records.has(boards[index-1].id))


func refresh_energy(now: int=-1) -> int:
	if now<0:now=int(Time.get_unix_time_from_system())
	var prior: int=int(data.energy_time)
	if now<=prior:return int(data.energy)
	if int(data.energy)>=ENERGY_MAX:data.energy_time=now;return int(data.energy)
	var ticks: int=int((now-prior)/ENERGY_SECONDS)
	if ticks>0:
		data.energy=mini(ENERGY_MAX,int(data.energy)+ticks)
		data.energy_time=now if int(data.energy)==ENERGY_MAX else prior+ticks*ENERGY_SECONDS
	return int(data.energy)

func energy_wait(now: int=-1) -> int:
	if now<0:now=int(Time.get_unix_time_from_system())
	refresh_energy(now)
	return 0 if int(data.energy)>=ENERGY_MAX else maxi(0,ENERGY_SECONDS-maxi(0,now-int(data.energy_time)))

func add_energy(amount: int) -> void:
	refresh_energy()
	data.energy=clampi(int(data.energy)+amount,0,ENERGY_MAX)

func issue_energy_reward() -> int:
	var before: Dictionary=data.duplicate(true)
	data.energy_issued=int(data.energy_issued)+1
	if not save():data=before;return 0
	return int(data.energy_issued)

func settle_energy_reward(serial: int,earned: bool) -> bool:
	if serial!=int(data.energy_issued) or serial<=int(data.energy_settled):return false
	var before: Dictionary=data.duplicate(true)
	data.energy_settled=serial
	if earned:
		refresh_energy();data.energy=ENERGY_MAX
	if not save():data=before;return false
	return earned
