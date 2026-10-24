class_name RailModel
extends RefCounted
## The single authoritative graph simulator. Rendering consumes its exact events.

var board: Dictionary = {}
var points: Dictionary = {}
var at := "start"
var collected: Array[String] = []
var picked: Array[String] = []
var trace: Array[String] = []
var steps := 0
var status := "planning"
var message := "Set the points, then Dispatch."
var assisted := false
var undo_count := 0
var history: Array[Dictionary] = []

func begin(definition: Dictionary, switches: Dictionary = {}) -> void:
	board = definition.duplicate(true)
	points = board.get("opening", {}).duplicate(true)
	for key in switches:
		if points.has(key): points[key] = clampi(int(switches[key]), 0, 1)
	at = "start"
	collected.clear(); picked.clear(); trace.assign(["start"])
	steps = 0; status = "planning"; assisted = false; undo_count = 0; history.clear()
	message = "Set the points, then Dispatch."

func node(key: String) -> Dictionary:
	for value in board.get("nodes", []):
		if value.id == key: return value
	return {}

func outgoing(key: String) -> Array[Dictionary]:
	var values: Array[Dictionary] = []
	for value in board.get("edges", []):
		if value.a == key: values.append(value)
	return values

func snapshot() -> Dictionary:
	return {"board":board.get("id", ""), "points":points.duplicate(),"at":at,"collected":collected.duplicate(),"picked":picked.duplicate(),"trace":trace.duplicate(),"steps":steps,"status":status,"message":message,"assisted":assisted,"undo_count":undo_count}

func restore(data: Dictionary) -> bool:
	# Validate the whole candidate before mutating the live route. JSON corruption
	# is recoverable data, never an unchecked Array.assign or dictionary access.
	if data.get("board", "") != board.get("id", "") or not data.get("at") is String or node(data.at).is_empty():return false
	if not data.get("points") is Dictionary or not data.get("trace") is Array or not data.get("collected") is Array or not data.get("picked") is Array:return false
	if not data.get("status") is String or data.status not in ["planning","paused","running","won","failed"]:return false
	if not data.get("message") is String or not data.get("assisted") is bool:return false
	for key in ["steps","undo_count"]:
		if not (data.get(key) is int or data.get(key) is float) or not is_finite(float(data[key])) or float(data[key])!=floor(float(data[key])) or int(data[key])<0:return false
	if data.trace.size()!=int(data.steps)+1 or data.trace.is_empty() or data.trace[0]!="start" or data.trace[-1]!=data.at:return false
	if data.trace.size()>board.nodes.size()*3+2 or data.picked.size()!=data.collected.size() or data.collected.size()>board.manifest.size():return false
	for i in range(data.trace.size()):
		if not data.trace[i] is String or node(data.trace[i]).is_empty():return false
		if i>0:
			var connected:=false
			for edge in outgoing(data.trace[i-1]):
				if edge.b==data.trace[i]:connected=true;break
			if not connected:return false
	for i in range(data.collected.size()):
		if not data.collected[i] is String or data.collected[i]!=board.manifest[i] or not data.picked[i] is String:return false
		var pickup:=node(data.picked[i])
		if pickup.is_empty() or pickup.kind!="cargo" or pickup.cargo!=data.collected[i] or not data.trace.has(data.picked[i]):return false
	var restored_points: Dictionary = data.points
	for key in points:
		if not restored_points.has(key) or not (restored_points[key] is int or restored_points[key] is float) or float(restored_points[key]) not in [0.0,1.0]:return false
	if data.status=="won" and (node(data.at).kind!="goal" or data.collected!=_manifest()):return false
	var restored_history: Array[Dictionary]=[]
	if data.has("undo_history"):
		if not data.undo_history is Array or data.undo_history.size()>256:return false
		for record in data.undo_history:
			if not record is Dictionary or record.has("undo_history"):return false
			var validator:=RailModel.new();validator.begin(board)
			if not validator.restore(record):return false
			restored_history.append(record.duplicate(true))
	for key in points:
		points[key] = clampi(int(restored_points.get(key, 0)), 0, 1)
	at = str(data.at); collected.assign(data.get("collected", [])); picked.assign(data.get("picked", [])); trace.assign(data.get("trace", ["start"]))
	steps = maxi(0,int(data.get("steps",0))); status = str(data.get("status","planning")); message = str(data.get("message","Route restored."))
	assisted = bool(data.get("assisted",false)); undo_count = maxi(0,int(data.get("undo_count",0)))
	if data.has("undo_history"):history.assign(restored_history)
	return status in ["planning","paused","running","won","failed"]

func set_point(key: String, branch: int) -> bool:
	if status not in ["planning", "paused"] or not points.has(key): return false
	# A turnout underneath the locomotive or a newly coupled wagon is occupied.
	var clearance := mini(collected.size()+1, trace.size())
	for i in range(clearance):
		if trace[trace.size()-1-i] == key: return false
	if int(points[key]) == branch: return true
	_remember(); points[key] = clampi(branch,0,1)
	message = "%s → %s" % [key, choice_label(board,key,branch)]
	return true

func dispatch() -> bool:
	if status not in ["planning", "paused"]: return false
	status = "running"; message = "Lanterns green. Follow the manifest."
	return true

func pause() -> void:
	if status == "running": status = "paused"; message = "Safely paused. Change clear points or Step."

func step() -> Dictionary:
	if status not in ["planning","running","paused"]: return {}
	_remember()
	var edges := outgoing(at)
	if edges.is_empty(): return _fail("The line ends here. Undo or Reset the route.")
	var choice := int(points.get(at,0))
	if choice >= edges.size(): return _fail("These points do not connect to a route.")
	var edge := edges[choice]
	if int(edge.get("limit",0)) > 0 and collected.size() > int(edge.limit): return _fail("Bridge limit: %d wagons; your train has %d. Undo to choose another route."%[int(edge.limit),collected.size()])
	var previous := at
	at = str(edge.b); steps += 1; trace.append(at)
	var next := node(at)
	var event := {"from":previous,"to":at,"edge":edge.duplicate(true),"coupled":"","status":status,"message":""}
	if next.is_empty(): return _fail("A track connection is missing.")
	if next.kind == "buffer":
		status = "failed"; message = "Buffer stop ahead. Nothing lost — Undo or Reset."
	elif next.kind == "cargo" and not picked.has(at):
		var cargo := str(next.cargo)
		var expected: Array = board.get("manifest",[])
		if collected.size() >= expected.size() or cargo != str(expected[collected.size()]):
			status = "failed"; message = "Wrong wagon order. Next is %s. Undo or Reset." % (str(expected[collected.size()]) if collected.size()<expected.size() else "the station")
		else:
			picked.append(at); collected.append(cargo); event.coupled = cargo
			message = "Wagon coupled — %d of %d." % [collected.size(),expected.size()]
	elif next.kind == "goal":
		if collected == _manifest():
			status = "won"; message = "Every wagon in place. Welcome home!"
		else:
			status = "failed"; message = "The station is waiting for the rest of the manifest. Undo or Reset."
	elif steps > board.get("nodes",[]).size()*3:
		status = "failed"; message = "This route circles the yard. Undo or Reset."
	event.status = status; event.message = message
	return event

func _manifest() -> Array[String]:
	var values: Array[String] = []; values.assign(board.get("manifest",[])); return values

func _remember() -> void:
	history.append(snapshot())
	if history.size()>256:history.pop_front()

func _fail(text: String) -> Dictionary:
	status = "failed"; message = text; return {"status":status,"message":message}

func undo() -> bool:
	if history.is_empty() or status == "won": return false
	var previous: Dictionary = history.pop_back()
	var count := undo_count+1
	var received_hint: bool=assisted
	if not restore(previous): return false
	assisted=assisted or received_hint
	undo_count = count; status = "paused" if steps>0 else "planning"; message = "One free step back. Try another route."
	return true

func preview() -> Dictionary:
	var test := RailModel.new(); test.begin(board); test.restore(snapshot()); test.status="running"
	var events: Array[Dictionary] = []
	for i in range(256):
		if test.status in ["won","failed"]: break
		var event := test.step(); events.append(event)
	return {"status":test.status,"message":test.message,"events":events,"collected":test.collected.duplicate(),"steps":test.steps}

func stars() -> int:
	if status != "won": return 0
	var total := 1
	if not assisted and steps <= int(board.get("par_steps",999)): total += 1
	if not assisted and undo_count == 0: total += 1
	return total


static func choice_label(definition: Dictionary,key: String,choice: int) -> String:
	# Observer direction is the screen horizontal projection of the actual fork,
	# not locomotive heading. The fixed camera looks from +X,+Z, so its right
	# vector is proportional to (29, -8) in ground X/Z coordinates.
	var exits: Array=[]
	for edge in definition.get("edges",[]):
		if str(edge.a)==key:exits.append(edge)
	if exits.size()!=2:return "L" if choice==0 else "R"
	var scores: Array[float]=[]
	for edge in exits:
		var first: Array=edge.points[0]
		var next: Array=edge.points[mini(1,edge.points.size()-1)]
		scores.append((float(next[0])-float(first[0]))*29.0-(float(next[1])-float(first[1]))*8.0)
	var left: int=0 if scores[0]<=scores[1] else 1
	return "L" if choice==left else "R"
