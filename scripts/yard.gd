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
var focused := false
var fit_size := 18.0
var camera_target := Vector3.ZERO
var labels: Array[Label3D] = []
var track_parts: Array[Dictionary] = []
var track_transforms: Array[Transform3D] = []
var steel: SurfaceTool
var ballast: SurfaceTool
const VIEW_OFFSET := Vector3(8,24,29)
const TRAIN_SCALE := 1.0
const WAGON_SPACING := 2.85
const TRACK_HEIGHT := 0.03
const VEHICLE_LIFT := 0.15

func _ready() -> void:
	stretch=true;mouse_filter=Control.MOUSE_FILTER_STOP
	view=SubViewport.new();view.own_world_3d=true;view.transparent_bg=false
	view.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	add_child(view)
	resized.connect(_fit)

func build(definition: Dictionary, district: Dictionary, cargos: Dictionary, is_background: bool=false) -> void:
	board=definition;cargo_types=cargos;background=is_background
	if is_instance_valid(world):world.free()
	cached.clear();node_positions.clear();edge_curves.clear();cargo_models.clear();point_lamps.clear();wagons.clear();labels.clear();track_parts.clear();track_transforms.clear();focused=false
	route=PackedVector3Array();route_distances=PackedFloat32Array();travel=0;target_travel=0;last_travel=0;motion=false
	world=Node3D.new();view.add_child(world)
	accent=Color(str(district.get("accent","e9b569")))
	var environment:=WorldEnvironment.new();var settings:=Environment.new()
	var sky:=Sky.new();var sky_color:=ProceduralSkyMaterial.new()
	sky_color.sky_top_color=Color("18253e");sky_color.sky_horizon_color=Color("9b6c78");sky_color.ground_horizon_color=Color("6c596a");sky_color.ground_bottom_color=Color("1c2c39")
	sky.sky_material=sky_color;settings.background_mode=Environment.BG_SKY;settings.sky=sky
	settings.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;settings.ambient_light_color=Color("a9b2d0");settings.ambient_light_energy=0.5
	settings.tonemap_mode=Environment.TONE_MAPPER_FILMIC
	environment.environment=settings;world.add_child(environment)
	var sun:=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-48,-32,0);sun.light_color=Color("ffdaab");sun.light_energy=1.25;sun.shadow_enabled=true;sun.directional_shadow_mode=DirectionalLight3D.SHADOW_ORTHOGONAL;sun.directional_shadow_max_distance=90;world.add_child(sun)
	var min_x:=0.0;var max_x:=0.0;var min_z:=0.0;var max_z:=0.0
	for node_data in board.nodes:
		var pos:=Vector3(float(node_data.pos[0]),0.0,float(node_data.pos[1]))
		node_positions[str(node_data.id)]=pos
		min_x=minf(min_x,pos.x);max_x=maxf(max_x,pos.x);min_z=minf(min_z,pos.z);max_z=maxf(max_z,pos.z)
	fit_width=max_x-min_x+6.0;fit_depth=max_z-min_z+7.0;focus=Vector3((max_x+min_x)*0.5,0,(max_z+min_z)*0.5)
	_terrain(min_x,max_x,min_z,max_z,district)
	_prepare_track()
	for edge_data in board.edges:_track(edge_data)
	_finish_track()
	for node_data in board.nodes:_yard_prop(node_data)
	engine=_instance("train","train-locomotive-a.glb",world);engine.scale=Vector3.ONE*TRAIN_SCALE
	route.append(node_positions.start+Vector3.UP*TRACK_HEIGHT);route_distances.append(0.0);engine.position=node_positions.start+Vector3.UP*(TRACK_HEIGHT+VEHICLE_LIFT)
	engine.rotation.y=0.0
	var headlight:=MeshInstance3D.new();var lens:=SphereMesh.new();lens.radius=0.14;lens.height=0.28;headlight.mesh=lens;headlight.position=Vector3(0,0.84,1.31);headlight.material_override=_material(Color("ffd78e"),true);engine.add_child(headlight)
	var beam:=SpotLight3D.new();beam.position=Vector3(0,0.84,1.35);beam.rotation.y=PI;beam.light_color=Color("ffdc9d");beam.light_energy=1.2;beam.spot_range=7;beam.spot_angle=28;beam.shadow_enabled=false;engine.add_child(beam)
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
	var ground:=Color(str(district.ground)).lightened(0.08)
	var width: float=max_x-min_x+11.0;var depth: float=max_z-min_z+10.0
	# An irregular low-poly island replaces the bare rectangular board. Actual
	# Kenney rocks, foliage and station models provide the scene detail.
	var base:=MeshInstance3D.new();var bank:=CylinderMesh.new();bank.top_radius=1;bank.bottom_radius=0.91;bank.height=1.25;bank.radial_segments=36
	base.mesh=bank;base.scale=Vector3(width*0.5,1,depth*0.5);base.position=focus+Vector3(0,-0.72,0);base.material_override=_material(Color("4a423e"));world.add_child(base)
	var surface:=SurfaceTool.new();surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for segment in range(48):
		var a: float=TAU*float(segment)/48.0;var b: float=TAU*float(segment+1)/48.0
		var pa:=focus+Vector3(cos(a)*width*0.5,0,sin(a)*depth*0.5)
		var pb:=focus+Vector3(cos(b)*width*0.5,0,sin(b)*depth*0.5)
		for vertex in [focus,pb,pa]:
			var shade: float=0.025*sin(vertex.x*1.4+vertex.z*0.7)
			surface.set_color(ground.lightened(shade) if shade>=0 else ground.darkened(-shade));surface.add_vertex(vertex)
	surface.generate_normals();var ground_mesh:=MeshInstance3D.new();ground_mesh.mesh=surface.commit();var ground_material:=_material(Color.WHITE);ground_material.vertex_color_use_as_albedo=true;ground_mesh.material_override=ground_material;world.add_child(ground_mesh)
	var count: int=18+int(depth/6.0)
	for i in range(count):
		var angle: float=TAU*(float(i)+0.2)/float(count)
		var tree_pos:=focus+Vector3(cos(angle)*width*0.44,0,sin(angle)*depth*0.44)
		var tree_file: String="tree_oak_fall.glb" if int(board.district)==1 else ("tree_pineTallA_detailed.glb" if i%3!=0 else "tree_pineRoundA.glb")
		var tree:=_instance("nature",tree_file,world);tree.position=tree_pos;tree.scale=Vector3.ONE*[3.0,3.5,2.8,3.8][i%4];tree.rotation.y=float(i)*1.13
		var rock:=_instance("nature",["rock_largeA.glb","rock_largeB.glb","rock_largeE.glb"][i%3],world);rock.position=tree_pos+Vector3(-0.65,-0.06,0.6);rock.scale=Vector3.ONE*(1.7+0.3*float(i%3));rock.rotation.y=angle
		if i%4==0:
			var cliff:=_instance("nature","cliff_rock.glb",world);cliff.position=tree_pos+Vector3(0,-0.8,0);cliff.scale=Vector3(2.2,1.2,2.0);cliff.rotation.y=angle
		if i%2==0:
			var bush:=_instance("nature","plant_bushDetailed.glb",world);bush.position=tree_pos+Vector3(0.7,0,0.4);bush.scale=Vector3.ONE*2.5
	# Readable depot, settlement and supplies at actual train-compatible units.
	for i in range(3):
		var house:=_instance("modular","building-sample-house-a.glb",world);house.position=Vector3(min_x+float(i)*3.4,0,min_z-3.0);house.scale=Vector3.ONE*(1.65+0.15*float(i%2));house.rotation.y=PI
	var depot:=_instance("industrial","building-e.glb",world);depot.position=Vector3(max_x+2.7,0,max_z-2.6);depot.scale=Vector3.ONE*1.8;depot.rotation.y=PI/2
	var tower:=_instance("industrial","water-tower.glb",world);tower.position=Vector3(min_x-2.0,0,max_z-1.8);tower.scale=Vector3.ONE*1.6
	var logs:=_instance("nature","log_stack.glb",world);logs.position=Vector3(max_x+1.5,0,min_z+3.0);logs.scale=Vector3.ONE*3.0
	for i in range(10):
		var grass:=_instance("nature","grass_large.glb",world);grass.position=Vector3(min_x-1.4+float(i%2)*(max_x-min_x+2.8),0,min_z+float(i/2)*3.2);grass.scale=Vector3.ONE*2.0
	if int(board.district) in [1,2,4,5]:
		var water:=_material(Color("466b81"));water.metallic=0.25;water.roughness=0.2
		var river:=_box(world,Vector3(1.5,0.08,depth*0.75),Vector3(min_x-2.8,-0.04,focus.z),Color("466b81"));river.material_override=water
		var bridge:=_instance("nature","bridge_wood.glb",world);bridge.position=Vector3(min_x-2.8,0.02,focus.z);bridge.scale=Vector3(2.2,1.4,1.5)
	if int(board.district) in [3,5]:
		for i in range(3):
			var container:=_instance("industrial","shipping-container-a.glb",world);container.position=Vector3(max_x+2.8,0,focus.z+float(i)*3.1);container.scale=Vector3.ONE*1.2
	for position in [Vector3(min_x-1.3,0,min_z),Vector3(max_x+1.4,0,max_z-0.5)]:_lantern(position,true)
	var station_light:=OmniLight3D.new();station_light.position=Vector3(max_x+1.7,2.0,max_z-2.0);station_light.light_color=Color("ffcb87");station_light.light_energy=1.4;station_light.omni_range=6;station_light.shadow_enabled=false;world.add_child(station_light)

func _curve(points: Array) -> Curve3D:
	var curve:=Curve3D.new();curve.bake_interval=0.16
	for i in range(points.size()):
		var p:=Vector3(float(points[i][0]),TRACK_HEIGHT,float(points[i][1]))
		var before:=p if i==0 else Vector3(float(points[i-1][0]),TRACK_HEIGHT,float(points[i-1][1]))
		var after:=p if i==points.size()-1 else Vector3(float(points[i+1][0]),TRACK_HEIGHT,float(points[i+1][1]))
		var tangent: Vector3=(after-before)*0.18
		curve.add_point(p,-tangent if i>0 else Vector3.ZERO,tangent if i<points.size()-1 else Vector3.ZERO)
	return curve

func _prepare_track() -> void:
	steel=SurfaceTool.new();steel.begin(Mesh.PRIMITIVE_TRIANGLES)
	ballast=SurfaceTool.new();ballast.begin(Mesh.PRIMITIVE_TRIANGLES)
	var path: String="res://assets/kenney/train/track.glb"
	var packed: PackedScene=load(path) as PackedScene
	if packed==null:push_error("Missing actual Kenney track scene");return
	var sample: Node=packed.instantiate()
	_collect_track_parts(sample,Transform3D.IDENTITY)
	sample.free()

func _collect_track_parts(node: Node,parent_transform: Transform3D) -> void:
	var transform: Transform3D=parent_transform
	if node is Node3D:transform=parent_transform*node.transform
	if node is MeshInstance3D and node.mesh!=null:track_parts.append({"mesh":node.mesh,"transform":transform})
	for child in node.get_children():_collect_track_parts(child,transform)

func _ribbon(tool: SurfaceTool,curve: Curve3D,width: float,height: float,offset: float=0.0) -> void:
	var points: PackedVector3Array=curve.get_baked_points()
	for i in range(1,points.size()):
		var a: Vector3=points[i-1];var b: Vector3=points[i]
		var direction: Vector3=(b-a).normalized();var right:=Vector3(direction.z,0,-direction.x)
		var center_a: Vector3=a+right*offset+Vector3.UP*height;var center_b: Vector3=b+right*offset+Vector3.UP*height
		var al: Vector3=center_a-right*width*0.5;var ar: Vector3=center_a+right*width*0.5
		var bl: Vector3=center_b-right*width*0.5;var br: Vector3=center_b+right*width*0.5
		for vertex in [al,bl,ar,ar,bl,br]:tool.add_vertex(vertex)

func _finish_track() -> void:
	# The real one-metre Kenney scene is batched on ALL edges. One geometry
	# convention removes imported-straight-root/curve height mismatches at joins.
	for part in track_parts:
		var instances:=MultiMesh.new();instances.transform_format=MultiMesh.TRANSFORM_3D;instances.mesh=part.mesh;instances.instance_count=track_transforms.size()
		for i in range(track_transforms.size()):instances.set_instance_transform(i,track_transforms[i]*part.transform)
		var render:=MultiMeshInstance3D.new();render.multimesh=instances;world.add_child(render)
	var rail_mesh:=MeshInstance3D.new();steel.generate_normals();rail_mesh.mesh=steel.commit()
	var iron:=_material(Color("959b99"));iron.metallic=0.5;iron.roughness=0.35;rail_mesh.material_override=iron;world.add_child(rail_mesh)
	var bed:=MeshInstance3D.new();ballast.generate_normals();bed.mesh=ballast.commit();bed.material_override=_material(Color("6d655b"));world.add_child(bed)
	steel=null;ballast=null;track_parts.clear();track_transforms.clear()

func _track(edge: Dictionary) -> void:
	var curve:=_curve(edge.points);edge_curves[str(edge.id)]=curve
	var length:=curve.get_baked_length()
	if int(edge.get("limit",0))>0:
		var center: Vector3=curve.sample_baked(length*0.56)
		var direction: Vector3=curve.sample_baked(minf(length,length*0.56+0.2))-curve.sample_baked(maxf(0,length*0.56-0.2))
		var bridge:=_instance("nature","bridge_wood.glb",world);bridge.position=center+Vector3(0,-0.18,0);bridge.rotation.y=atan2(direction.x,direction.z);bridge.scale=Vector3(1.5,0.65,3.2)
		_label("MAX %d"%int(edge.limit),center+Vector3(1.15,2.1,0),Color("f5cc8f"),38)
	var count:=maxi(1,int(ceil(length/0.65)))
	for i in range(count):
		var d: float=(float(i)+0.5)*length/float(count)
		var p: Vector3=curve.sample_baked(d)
		var direction: Vector3=curve.sample_baked(minf(length,d+0.08))-curve.sample_baked(maxf(0,d-0.08))
		var rotation: float=atan2(direction.x,direction.z)
		track_transforms.append(Transform3D(Basis(Vector3.UP,rotation)*Basis.from_scale(Vector3(1,1,length/float(count))),p))
	_ribbon(ballast,curve,1.25,-0.015)
	_ribbon(steel,curve,0.08,0.16,-0.35);_ribbon(steel,curve,0.08,0.16,0.35)

func _label(text: String,position: Vector3,color: Color=Color("fff0d0"),font_size: int=44) -> Label3D:
	var label:=Label3D.new();label.text=text;label.font_size=font_size;label.pixel_size=0.017;label.outline_size=10
	label.modulate=color;label.billboard=BaseMaterial3D.BILLBOARD_ENABLED;label.no_depth_test=true;label.position=position;world.add_child(label);labels.append(label);return label

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
			var wagon:=_instance("train",str(cargo_types[cargo].model),world);wagon.position=pos+Vector3.UP*(TRACK_HEIGHT+VEHICLE_LIFT);wagon.scale=Vector3.ONE*TRAIN_SCALE
			cargo_models[str(node_data.id)]=wagon
			_label(str(cargo_types[cargo].name).to_upper(),pos+Vector3(0,2.2,0),Color(str(cargo_types[cargo].color)),32)
		"junction":
			var lamp:=_lantern(pos+Vector3(0.85,0,0),true);point_lamps[str(node_data.id)]=lamp
			_label(str(node_data.id).trim_prefix("P")+" A",pos+Vector3(0,2.35,0),accent,44).name="Label_"+str(node_data.id)
			_box(world,Vector3(1.4,0.04,1.0),pos+Vector3(0,-0.03,0),Color("826f55"))
		"start":
			_label("ENGINE SHED",pos+Vector3(0,2.4,-1.4),Color("e9c38a"),34)
		"goal":
			var station:=_instance("modular","building-sample-house-a.glb",world);station.position=pos+Vector3(3.0,0,0.8);station.scale=Vector3.ONE*2.0
			_lantern(pos+Vector3(-1.2,0,0),true);_label("HOME",pos+Vector3(0,2.6,0),Color("f6d992"),46)
		"buffer":
			_box(world,Vector3(1.55,0.2,0.22),pos+Vector3(0,0.5,0.2),Color("cb7462"))
			_box(world,Vector3(0.18,0.6,0.65),pos+Vector3(-0.5,0.25,0.4),Color("48434a"));_box(world,Vector3(0.18,0.6,0.65),pos+Vector3(0.5,0.25,0.4),Color("48434a"))

func set_points(points: Dictionary) -> void:
	for key in points:
		var label: Label3D=world.get_node_or_null("Label_"+str(key)) as Label3D
		if label!=null:label.text=str(key).trim_prefix("P")+(" A" if int(points[key])==0 else " B")

func apply_livery(index: int) -> void:
	if not is_instance_valid(engine):return
	var tint: Color=Color("a1d5d9") if index==0 else (Color("a6d3b0") if index==1 else Color("a9b9e4"))
	for mesh_node in engine.find_children("*","MeshInstance3D",true,false):
		var mesh_instance: MeshInstance3D=mesh_node as MeshInstance3D
		if mesh_instance.mesh==null:continue
		for surface in range(mesh_instance.mesh.get_surface_count()):
			var original: Material=mesh_instance.get_active_material(surface)
			if original is StandardMaterial3D:
				var replacement: StandardMaterial3D=original.duplicate() as StandardMaterial3D
				replacement.albedo_color=tint;mesh_instance.set_surface_override_material(surface,replacement)

func _fit() -> void:
	if view==null or not is_inside_tree() or not is_instance_valid(camera) or not camera.is_inside_tree():return
	var aspect: float=maxf(0.2,size.x/maxf(1.0,size.y))
	camera_target=focus+Vector3.UP*0.8
	camera.position=camera_target+VIEW_OFFSET;camera.look_at(camera_target,Vector3.UP)
	var right: Vector3=camera.basis.x;var up: Vector3=camera.basis.y
	var left:=INF;var right_edge: float=-INF;var low:=INF;var high: float=-INF
	# Fit the actual projected rail/train/label envelope, not the oversized floor.
	for position in node_positions.values():
		for x in [-1.1,1.1]:
			for y in [0.0,2.8]:
				for z in [-1.5,1.5]:
					var p: Vector3=position+Vector3(x,y,z)-camera_target
					left=minf(left,p.dot(right));right_edge=maxf(right_edge,p.dot(right));low=minf(low,p.dot(up));high=maxf(high,p.dot(up))
	fit_size=maxf((high-low)*1.1,(right_edge-left)*1.1/aspect)
	fit_size=maxf(12.0,fit_size)
	if focused and is_instance_valid(engine):
		camera_target=engine.position+Vector3(0,0.7,2.0)
		camera.size=minf(fit_size,14.0)
	else:
		camera_target+=right*(right_edge+left)*0.5+up*(high+low)*0.5
		camera.size=fit_size
	camera.position=camera_target+VIEW_OFFSET;camera.look_at(camera_target,Vector3.UP)
	for label in labels:
		if is_instance_valid(label):label.pixel_size=clampf(30.0*camera.size/(maxf(1.0,size.y)*float(label.font_size)),0.008,0.065)

func toggle_view() -> bool:
	focused=not focused;_fit();return focused

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
	route=PackedVector3Array([node_positions.start+Vector3.UP*TRACK_HEIGHT]);route_distances=PackedFloat32Array([0.0]);travel=0;target_travel=0
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
	var wagon:=_instance("train",str(cargo_types[cargo].model),world);wagon.scale=Vector3.ONE*TRAIN_SCALE;wagons.append(wagon)

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
	node_3d.position=p+Vector3.UP*VEHICLE_LIFT
	if tangent.length_squared()>0.00001:node_3d.rotation.y=atan2(tangent.x,tangent.z)

func _position_train() -> void:
	if not is_instance_valid(engine):return
	_pose(engine,travel)
	for i in range(wagons.size()):_pose(wagons[i],travel-WAGON_SPACING*float(i+1))
	if focused:_fit()

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
	cached.clear();edge_curves.clear();cargo_models.clear();point_lamps.clear();wagons.clear();labels.clear();track_parts.clear();track_transforms.clear();steel=null;ballast=null
	if is_instance_valid(world):world.free()
