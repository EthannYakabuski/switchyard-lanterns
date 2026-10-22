class_name RailwayProfile
extends RefCounted
## Gameplay persistence only. Native service queue lives independently in Services.
const SAVE := "user://railway_v1.json"
var data: Dictionary = {}
var recovered := false
var load_message := ""

func _init() -> void:
	data = defaults()

func defaults() -> Dictionary:
	return {"schema":1,"coins":0,"xp":0,"clears":0,"cargo_total":0,"largest_manifest":0,"records":{},"banked":[],"next_run":1,"draft":{},"login_day":"","login_streak":0,"login_last":"","daily_days":[],"day":"","day_clears":0,"day_claimed":false,"settings":{"music":true,"effects":true,"speed":1.0,"livery":0},"unlocked":[]}

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
		if not value.has(key):return false
	for key in ["schema","coins","xp","clears","cargo_total","largest_manifest","next_run","login_streak","day_clears"]:
		if not _integer(value[key]) or float(value[key])<0 or float(value[key])>9007199254740000.0:return false
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
		if not _integer(value.draft.get("index")) or int(value.draft.index)<0 or int(value.draft.index)>=48:return false
		if not value.draft.get("daily") is bool or not value.draft.get("run_id") is String or not value.draft.get("state") is Dictionary:return false
	return true

func _integer(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value)==floor(float(value))

func _normalize(value: Dictionary) -> Dictionary:
	var result: Dictionary=value.duplicate(true)
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

func new_run(board_id: String, daily: bool) -> String:
	var id := "%s:%d:%s" % [board_id,int(data.next_run),"daily" if daily else "campaign"]
	var previous: Dictionary=data.duplicate(true)
	data.next_run = int(data.next_run)+1
	if not save():data=previous;return ""
	return id

func level() -> int:
	return 1+int(sqrt(float(data.xp)/45.0))

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
	data.coins=int(data.coins)+coins;data.xp=int(data.xp)+5
	if not save():data=previous;return {"ok":false,"reason":"save_failed"}
	return {"ok":true,"coins":coins,"xp":5,"streak":data.login_streak}

func claim_freight(day: String) -> bool:
	var previous: Dictionary=data.duplicate(true)
	rollover(day)
	if day != str(data.day) or bool(data.day_claimed) or int(data.day_clears)<3: return false
	data.day_claimed=true;data.coins=int(data.coins)+60;data.xp=int(data.xp)+20
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
	data.coins=int(data.coins)+earned_coins;data.xp=int(data.xp)+earned_xp
	data.clears=int(data.clears)+1;data.cargo_total=int(data.cargo_total)+board.manifest.size()
	data.largest_manifest=maxi(int(data.largest_manifest),board.manifest.size())
	if day == str(data.day):data.day_clears=int(data.day_clears)+1
	if daily and not data.daily_days.has(day): data.daily_days.append(day)
	var old: Dictionary = data.records.get(board.id,{"stars":0,"best_unassisted":0})
	old.stars=maxi(int(old.get("stars",0)),stars)
	if not assisted:old.best_unassisted=maxi(int(old.get("best_unassisted",0)),stars)
	data.records[board.id]=old;data.draft={}
	if not save():data=previous;return {"ok":false,"reason":"save_failed"}
	return {"ok":true,"coins":earned_coins,"xp":earned_xp,"first":first,"stars":stars}

func stats(boards: Array) -> Dictionary:
	var result: Dictionary = {"clears":int(data.clears),"cargo_total":int(data.cargo_total),"largest_manifest":int(data.largest_manifest),"xp":int(data.xp),"level":level(),"daily_clears":data.daily_days.size(),"campaign_cleared":data.records.size(),"campaign_stars":0,"perfect":0}
	for i in range(6):result["district_%d"%i]=0
	for board in boards:
		if not data.records.has(board.id):continue
		var rec: Dictionary=data.records[board.id]
		result["district_%d"%int(board.district)]=int(result["district_%d"%int(board.district)])+1
		result.campaign_stars=int(result.campaign_stars)+int(rec.get("best_unassisted",0))
		if int(rec.get("best_unassisted",0))==3:result.perfect=int(result.perfect)+1
	return result

func is_open(index: int, boards: Array) -> bool:
	return index==0 or (index>0 and data.records.has(boards[index-1].id))
