class_name YardDiorama
extends SubViewportContainer
signal point_requested(key: String)
## Actual licensed train/scenery scenes, fitted to the live UI rectangle.
var view: SubViewport
var world: Node3D
var camera: Camera3D
var board: Dictionary = {}
var cargo_types: Dictionary = {}
var cached: Dictionary = {}
var node_positions: Dictionary = {}
var edge_curves: Dictionary = {}
var cargo_models: Dictionary = {}
var point_lamps: Dictionary = {}
var engine: Node3D
var wagons: Array[Node3D] = []
var route: PackedVector3Array = []
var route_distances: PackedFloat32Array = []
var travel := 0.0
var last_travel := 0.0
var target_travel := 0.0
var motion := false
var background := false
var focus := Vector3.ZERO
var fit_width := 20.0
var fit_depth := 20.0
var accent := Color("e9b569")
var preview_root: Node3D

func _ready() -> void:
	stretch=true;mouse_filter=Control.MOUSE_FILTER_STOP
	view=SubViewport.new();view.own_world_3d=true;view.transparent_bg=false
	view.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	add_child(view)
	resized.connect(_fit)

func build(definition: Dictionary, district: Dictionary, cargos: Dictionary, is_background: bool=false) -> void:
	board=definition;cargo_types=cargos;background=is_background
	if is_instance_valid(world):world.free()
	cached.clear();node_positions.clear();edge_curves.clear();cargo_models.clear();point_lamps.clear();wagons.clear()
	route=PackedVector3Array();route_distances=PackedFloat32Array();travel=0;target_travel=0;last_travel=0;motion=false
	world=Node3D.new();view.add_child(world)
	accent=Color(str(district.get("accent","e9b569")))
	var environment:=WorldEnvironment.new();var settings:=Environment.new()
	settings.background_mode=Environment.BG_COLOR;settings.background_color=Color("172634")
	settings.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;settings.ambient_light_color=Color("a5b9d0");settings.ambient_light_energy=0.75
	settings.tonemap_mode=Environment.TONE_MAPPER_FILMIC
	environment.environment=settings;world.add_child(environment)
	var sun:=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-52,-32,0);sun.light_color=Color("ffdc9e");sun.light_energy=1.15;sun.shadow_enabled=false;world.add_child(sun)
	var min_x:=0.0;var max_x:=0.0;var min_z:=0.0;var max_z:=0.0
	for node_data in board.nodes:
		var pos:=Vector3(float(node_data.pos[0]),0.0,float(node_data.pos[1]))
		node_positions[str(node_data.id)]=pos
		min_x=minf(min_x,pos.x);max_x=maxf(max_x,pos.x);min_z=minf(min_z,pos.z);max_z=maxf(max_z,pos.z)
	fit_width=max_x-min_x+6.0;fit_depth=max_z-min_z+7.0;focus=Vector3((max_x+min_x)*0.5,0,(max_z+min_z)*0.5)
	_terrain(min_x,max_x,min_z,max_z,district)
	for edge_data in board.edges:_track(edge_data)
	for node_data in board.nodes:_yard_prop(node_data)
	engine=_instance("train","train-locomotive-a.glb",world);engine.scale=Vector3.ONE*0.83
	route.append(node_positions.start);route_distances.append(0.0);engine.position=node_positions.start+Vector3.UP*0.13
	engine.rotation.y=0.0
	camera=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.keep_aspect=Camera3D.KEEP_HEIGHT;world.add_child(camera);camera.current=true
	preview_root=Node3D.new();world.add_child(preview_root)
	_fit()

func _material(color: Color, emission: bool=false) -> StandardMaterial3D:
	var material:=StandardMaterial3D.new();material.albedo_color=color;material.roughness=0.85
	if emission:material.emission_enabled=true;material.emission=color;material.emission_energy_multiplier=0.7
	return material

func _box(parent: Node3D, dimensions: Vector3, position: Vector3, color: Color) -> MeshInstance3D:
	var mesh:=MeshInstance3D.new();var shape:=BoxMesh.new();shape.size=dimensions;mesh.mesh=shape;mesh.material_override=_material(color);mesh.position=position;parent.add_child(mesh);return mesh

func _instance(pack: String, filename: String, parent: Node3D) -> Node3D:
	var path: String="res://assets/kenney/%s/%s"%[pack,filename]
	if not cached.has(path):cached[path]=load(path)
	var packed: PackedScene=cached[path] as PackedScene
	if packed==null:
		push_error("Missing licensed scene asset: "+path)
		var missing:=Node3D.new();parent.add_child(missing);return missing
	var result: Node3D=packed.instantiate() as Node3D;parent.add_child(result);return result

func _terrain(min_x: float,max_x: float,min_z: float,max_z: float,district: Dictionary) -> void:
	var ground:=Color(str(district.ground))
	_box(world,Vector3(fit_width+5,0.9,fit_depth+4),focus+Vector3(0,-0.65,0),ground.darkened(0.1))
	_box(world,Vector3(fit_width+5.2,0.3,fit_depth+4.2),focus+Vector3(0,-1.15,0),Color("263b3b"))
	# Layered actual Kenney pine/cliff scenes frame the usable yard, never cover it.
	var depth:=max_z-min_z+8.0
	for side in [-1,1]:
		var x: float=min_x-3.4 if side==-1 else max_x+3.4
		for i in range(int(depth/3.5)+1):
			var z: float=min_z-3.0+float(i)*3.5
			var cliff:=_instance("nature","cliff_block_rock.glb",world);cliff.position=Vector3(x,-0.65,z);cliff.scale=Vector3(1.3,1.4,1.3);cliff.rotation.y=float(i%4)*PI/2.0
			if i%2==0:
				var tree:=_instance("nature","tree_pineTallA.glb" if i%3!=0 else "tree_pineRoundA.glb",world)
				tree.position=Vector3(x-float(side)*0.5,0,z);tree.scale=Vector3.ONE*(0.85+float(i%3)*0.12);tree.rotation.y=float(i)*0.8
	for i in range(5):
		var house:=_instance("modular","building-sample-house-a.glb",world)
		house.position=Vector3(min_x-1.5+float(i)*3.0,0,min_z-3.8);house.scale=Vector3.ONE*0.45;house.rotation.y=PI
	var depot:=_instance("industrial","building-e.glb",world);depot.position=Vector3(max_x+0.7,0,max_z-2.2);depot.scale=Vector3.ONE*0.7;depot.rotation.y=PI/2
	var tower:=_instance("industrial","water-tower.glb",world);tower.position=Vector3(min_x-1.2,0,max_z-1.5);tower.scale=Vector3.ONE*0.8
	var logs:=_instance("nature","log_stack.glb",world);logs.position=Vector3(max_x+0.8,0,min_z+3);logs.scale=Vector3.ONE*1.2
	if int(board.district) in [1,2,4,5]:
		# Canal ribbon is outside active rails, with a real timber footbridge.
		_box(world,Vector3(1.2,0.08,fit_depth+2),Vector3(min_x-2.0,-0.08,focus.z),Color("538895"))
		var bridge:=_instance("nature","bridge_wood.glb",world);bridge.position=Vector3(min_x-2.0,0.02,focus.z);bridge.scale=Vector3.ONE*0.65
	if int(board.district) in [3,5]:
		for i in range(3):
			var container:=_instance("industrial","shipping-container-a.glb",world);container.position=Vector3(max_x+1.0,0,focus.z+float(i)*3);container.scale=Vector3.ONE*0.65
	for side in [-1,1]:
		for z in [min_z-1,max_z+1]:
			_lantern(Vector3((min_x-1 if side==-1 else max_x+1),0,float(z)),true)

func _curve(points: Array) -> Curve3D:
	var curve:=Curve3D.new();curve.bake_interval=0.16
	for i in range(points.size()):
		var p:=Vector3(float(points[i][0]),0.06,float(points[i][1]))
		var before:=p if i==0 else Vector3(float(points[i-1][0]),0.06,float(points[i-1][1]))
		var after:=p if i==points.size()-1 else Vector3(float(points[i+1][0]),0.06,float(points[i+1][1]))
		var tangent: Vector3=(after-before)*0.18
		curve.add_point(p,-tangent if i>0 else Vector3.ZERO,tangent if i<points.size()-1 else Vector3.ZERO)
	return curve

func _track(edge: Dictionary) -> void:
	var curve:=_curve(edge.points);edge_curves[str(edge.id)]=curve
	var length:=curve.get_baked_length()
	if int(edge.get("limit",0))>0:
		var center: Vector3=curve.sample_baked(length*0.56)
		var direction: Vector3=curve.sample_baked(minf(length,length*0.56+0.2))-curve.sample_baked(maxf(0,length*0.56-0.2))
		var bridge:=_instance("nature","bridge_wood.glb",world);bridge.position=center+Vector3(0,-0.06,0);bridge.rotation.y=atan2(direction.x,direction.z);bridge.scale=Vector3.ONE*0.65
		_label("MAX %d"%int(edge.limit),center+Vector3(1.15,2.1,0),Color("f5cc8f"),38)
	if edge.points.size()==2:
		var a: Vector3=curve.sample_baked(0.0);var b: Vector3=curve.sample_baked(length)
		var wrapper:=Node3D.new();world.add_child(wrapper);wrapper.position=a+Vector3.UP;wrapper.rotation.y=atan2(b.x-a.x,b.z-a.z)
		# Retain the imported rail node's actual -1Y root transform; its parent
		# supplies +1Y. Assigning rail.position=+1 would lift the mesh incorrectly.
		var rail:=_instance("train","railroad-straight.glb",wrapper);rail.scale=Vector3(1,1,length/4.0)
	else:
		# Use the actual matching Kenney one-metre sleeper/rail scene, fitted along
		# the same baked curve sampled by the locomotive and wagons.
		var count:=maxi(1,int(ceil(length/0.8)))
		for i in range(count):
			var d: float=(float(i)+0.5)*length/float(count)
			var p: Vector3=curve.sample_baked(d);var next: Vector3=curve.sample_baked(minf(length,d+0.1))
			if d+0.1>length:next=p+(p-curve.sample_baked(maxf(0,d-0.1)))
			var rail:=_instance("train","track.glb",world);rail.position=p;rail.rotation.y=atan2(next.x-p.x,next.z-p.z);rail.scale=Vector3(1,1,length/float(count))

func _label(text: String,position: Vector3,color: Color=Color("fff0d0"),font_size: int=44) -> Label3D:
	var label:=Label3D.new();label.text=text;label.font_size=font_size;label.pixel_size=0.017;label.outline_size=10
	label.modulate=color;label.billboard=BaseMaterial3D.BILLBOARD_ENABLED;label.no_depth_test=true;label.position=position;world.add_child(label);return label

func _lantern(position: Vector3,lit: bool) -> Node3D:
	var root:=Node3D.new();world.add_child(root);root.position=position
	_box(root,Vector3(0.12,1.5,0.12),Vector3(0,0.75,0),Color("3a3436"))
	_box(root,Vector3(0.42,0.48,0.42),Vector3(0,1.65,0),Color("2e353e"))
	var globe:=_box(root,Vector3(0.3,0.32,0.3),Vector3(0,1.65,-0.02),accent if lit else Color("697988"));globe.material_override=_material(accent if lit else Color("697988"),lit)
	_box(root,Vector3(0.58,0.1,0.58),Vector3(0,1.93,0),Color("47383c"))
	return root

func _yard_prop(node_data: Dictionary) -> void:
	var pos: Vector3=node_positions[str(node_data.id)]
	match str(node_data.kind):
		"cargo":
			var cargo: String=str(node_data.cargo)
			var wagon:=_instance("train",str(cargo_types[cargo].model),world);wagon.position=pos+Vector3.UP*0.13;wagon.scale=Vector3.ONE*0.83
			cargo_models[str(node_data.id)]=wagon
			_label(str(cargo_types[cargo].name).to_upper(),pos+Vector3(0,2.2,0),Color(str(cargo_types[cargo].color)),32)
		"junction":
			var lamp:=_lantern(pos+Vector3(0.85,0,0),true);point_lamps[str(node_data.id)]=lamp
			_label(str(node_data.id).trim_prefix("P")+" A",pos+Vector3(0,2.35,0),accent,44).name="Label_"+str(node_data.id)
			_box(world,Vector3(1.4,0.04,1.0),pos+Vector3(0,-0.03,0),Color("826f55"))
		"start":
			_label("ENGINE SHED",pos+Vector3(0,2.4,-1.4),Color("e9c38a"),34)
		"goal":
			var station:=_instance("modular","building-sample-house-a.glb",world);station.position=pos+Vector3(2.4,0,1.0);station.scale=Vector3.ONE*0.65
			_lantern(pos+Vector3(-1.2,0,0),true);_label("HOME",pos+Vector3(0,2.6,0),Color("f6d992"),46)
		"buffer":
			_box(world,Vector3(1.55,0.2,0.22),pos+Vector3(0,0.5,0.2),Color("cb7462"))
			_box(world,Vector3(0.18,0.6,0.65),pos+Vector3(-0.5,0.25,0.4),Color("48434a"));_box(world,Vector3(0.18,0.6,0.65),pos+Vector3(0.5,0.25,0.4),Color("48434a"))

func set_points(points: Dictionary) -> void:
	for key in points:
		var label: Label3D=world.get_node_or_null("Label_"+str(key)) as Label3D
		if label!=null:label.text=str(key).trim_prefix("P")+(" A" if int(points[key])==0 else " B")

func apply_livery(index: int) -> void:
	if not is_instance_valid(engine) or index==0:return
	var tint: Color=Color("a6d3b0") if index==1 else Color("a9b9e4")
	for mesh_node in engine.find_children("*","MeshInstance3D",true,false):
		var mesh_instance: MeshInstance3D=mesh_node as MeshInstance3D
		if mesh_instance.mesh==null:continue
		for surface in range(mesh_instance.mesh.get_surface_count()):
			var original: Material=mesh_instance.get_active_material(surface)
			if original is StandardMaterial3D:
				var replacement: StandardMaterial3D=original.duplicate() as StandardMaterial3D
				replacement.albedo_color=tint;mesh_instance.set_surface_override_material(surface,replacement)

func _fit() -> void:
	if view==null:return
	if not is_instance_valid(camera):return
	var aspect: float=maxf(0.2,size.x/maxf(1,size.y))
	# stretch=true gives size ownership to SubViewportContainer. Its actual
	# live rectangle also supplies the camera aspect; never fight that ownership.
	# Viewing from +Z keeps the authored A/-X branch on the player's left.
	camera.position=focus+Vector3(0,30,22)
	camera.look_at(focus,Vector3.UP)
	# Orthographic fit uses the actual live viewport aspect, with scenery margin.
	camera.size=maxf(fit_depth*0.82+5.0,(fit_width+2.0)/aspect)

func append_event(event: Dictionary) -> void:
	if not event.has("edge"):return
	var edge: Dictionary=event.edge
	var curve: Curve3D=edge_curves[str(edge.id)] as Curve3D
	var length:=curve.get_baked_length()
	var samples:=maxi(2,int(ceil(length/0.18)))
	for i in range(1,samples+1):
		var p: Vector3=curve.sample_baked(length*float(i)/float(samples))
		var previous: Vector3=route[route.size()-1]
		route_distances.append(route_distances[route_distances.size()-1]+previous.distance_to(p));route.append(p)
	last_travel=travel;target_travel=route_distances[route_distances.size()-1];motion=true

func sync_snapshot(state: Dictionary) -> void:
	for wagon in wagons:
		if is_instance_valid(wagon):wagon.free()
	wagons.clear()
	for key in cargo_models:cargo_models[key].visible=not state.picked.has(key)
	route=PackedVector3Array([node_positions.start]);route_distances=PackedFloat32Array([0.0]);travel=0;target_travel=0
	var traced: Array=state.trace
	for i in range(1,traced.size()):
		var edge_id: String=str(traced[i-1])+">"+str(traced[i])
		if not edge_curves.has(edge_id):continue
		var curve: Curve3D=edge_curves[edge_id];var length:=curve.get_baked_length();var count:=maxi(2,int(ceil(length/0.18)))
		for n in range(1,count+1):
			var p: Vector3=curve.sample_baked(length*float(n)/float(count));var previous: Vector3=route[route.size()-1]
			route_distances.append(route_distances[route_distances.size()-1]+previous.distance_to(p));route.append(p)
	travel=route_distances[route_distances.size()-1];target_travel=travel;motion=false
	for cargo in state.collected:_add_wagon(str(cargo))
	set_points(state.points);_position_train()

func settle_event(event: Dictionary) -> void:
	if str(event.get("coupled",""))!="":
		var key: String=str(event.to)
		if cargo_models.has(key):cargo_models[key].visible=false
		_add_wagon(str(event.coupled))
	_position_train()

func _add_wagon(cargo: String) -> void:
	var wagon:=_instance("train",str(cargo_types[cargo].model),world);wagon.scale=Vector3.ONE*0.83;wagons.append(wagon)

func animate(delta: float,speed: float,allowed: bool) -> bool:
	if not motion or not allowed:return false
	travel=move_toward(travel,target_travel,delta*speed*5.0)
	_position_train()
	if is_equal_approx(travel,target_travel):motion=false;return true
	return false

func _sample(distance: float) -> Vector3:
	if route.is_empty():return Vector3.ZERO
	if distance<=0:
		var facing: Vector3=(route[1]-route[0]).normalized() if route.size()>1 else Vector3.BACK
		return route[0]+facing*distance
	for i in range(1,route_distances.size()):
		if route_distances[i]>=distance:
			var part: float=inverse_lerp(route_distances[i-1],route_distances[i],distance)
			return route[i-1].lerp(route[i],part)
	return route[route.size()-1]

func _pose(node_3d: Node3D,distance: float) -> void:
	var p:=_sample(distance);var tangent: Vector3=_sample(distance+0.12)-_sample(distance-0.12)
	node_3d.position=p+Vector3.UP*0.13
	if tangent.length_squared()>0.00001:node_3d.rotation.y=atan2(tangent.x,tangent.z)

func _position_train() -> void:
	if not is_instance_valid(engine):return
	_pose(engine,travel)
	for i in range(wagons.size()):_pose(wagons[i],travel-2.35*float(i+1))

func show_preview(result: Dictionary) -> void:
	for child in preview_root.get_children():child.free()
	for event in result.get("events",[]):
		if not event.has("edge"):continue
		var curve: Curve3D=edge_curves[str(event.edge.id)];var length:=curve.get_baked_length()
		for i in range(int(length/1.2)):
			var p: Vector3=curve.sample_baked(float(i)*1.2+0.5)
			var dot:=_box(preview_root,Vector3(0.13,0.08,0.32),p+Vector3.UP*0.2,accent);dot.material_override=_material(accent,true)

func clear_preview() -> void:
	for child in preview_root.get_children():child.free()

func _gui_input(event: InputEvent) -> void:
	if background or not is_instance_valid(camera):return
	var pressed:=false;var tap:=Vector2.ZERO
	if event is InputEventScreenTouch and event.pressed:pressed=true;tap=event.position
	elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed and event.device!=InputEvent.DEVICE_ID_EMULATION:pressed=true;tap=event.position
	if not pressed:return
	var closest: String="";var distance:=60.0
	for key in point_lamps:
		var screen: Vector2=camera.unproject_position(node_positions[key]+Vector3(0,1.0,0))
		var candidate: float=tap.distance_to(screen)
		if candidate<distance:closest=str(key);distance=candidate
	if closest!="":accept_event();point_requested.emit(closest)

func shutdown() -> void:
	cached.clear();edge_curves.clear();cargo_models.clear();point_lamps.clear();wagons.clear()
	if is_instance_valid(world):world.free()
