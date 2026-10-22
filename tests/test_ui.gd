extends SceneTree
## Isolated source fixtures only. No native ad/gameplay evidence is claimed.
const MainScene=preload("res://scenes/main.tscn")
var checks:=0
var failures:=0

class FaultProfile:
	extends "res://game/profile.gd"
	var refuse_writes:=true
	func save() -> bool:return false if refuse_writes else super.save()

class FixtureServices:
	extends Node
	signal menu_bottom_reserve_changed
	signal availability_changed
	signal service_notice(message: String)
	var fullscreen:=false
	var finished:=0
	var callback: Callable
	var scores: Dictionary={}
	var signins:=0
	var achievement_opens:=0
	var board_opens:=0
	func set_menu_visible(_value: bool) -> void:pass
	func menu_bottom_reserve(_reference: CanvasItem=null) -> float:return 0.0
	func fullscreen_ad_active() -> bool:return fullscreen
	func can_reward() -> bool:return true
	func reward_requested(_context: String,receiver: Callable) -> void:callback=receiver
	func round_finished() -> void:finished+=1
	func unlock(_key: String) -> void:pass
	func submit(key: String,score: int) -> void:scores[key]=score
	func sign_in() -> void:signins+=1
	func open_achievements() -> void:achievement_opens+=1
	func open_leaderboards(_key: String="") -> void:board_opens+=1
	func privacy_options() -> void:pass
	func status() -> String:return "Isolated source fixture; native services are tested separately."

func _initialize() -> void:call_deferred("run")

func require(value: bool,text: String) -> void:
	checks+=1
	if not value:failures+=1;push_error("Assertion failed: "+text)

func _dispose_app(scene: Control) -> void:
	# Linux verbose diagnostics identified owned coupling/arrival Ogg and pine
	# WAV playbacks still fading in AudioServer after fast frame-only teardown.
	# Quiesce this fixture, release streams while its tree remains alive, and
	# preserve a bounded amount of real mixer time before deleting the owner.
	scene.set_process(false)
	scene._shutdown()
	var drain_seconds: float=clampf(AudioServer.get_time_to_next_mix()*3.0,0.1,0.25)
	var deadline_us: int=Time.get_ticks_usec()+int(drain_seconds*1000000.0)
	while Time.get_ticks_usec()<deadline_us:
		await process_frame
	await process_frame
	scene.queue_free()
	await process_frame
	await process_frame

func run() -> void:
	var actual:=root.get_node_or_null("Services")
	if actual!=null:root.remove_child(actual);actual.queue_free()
	await process_frame
	var service:=FixtureServices.new();service.name="Services";root.add_child(service)
	var app: Control=MainScene.instantiate();root.add_child(app)
	await process_frame;await process_frame
	require(app.scene_page=="home","real scene opens home")
	var back: Button=app.header.get_node("BackButton") as Button
	require(back.size.x>=112.0 and back.size.x<=130.0,"Back retains a touch target without expanding across the header")
	app._notification(MainLoop.NOTIFICATION_APPLICATION_PAUSED);app._notification(MainLoop.NOTIFICATION_APPLICATION_RESUMED);app._process(0.1)
	require(app.gate_row.visible and app.resume_button.visible,"Home foreground exposes actual Resume")
	app.resume_button.pressed.emit();require(not app._blocked(),"Home Resume returns menu controls")
	app._show_campaign();await process_frame
	require(app.scene_page=="campaign","campaign navigation")
	require(app.profile.is_open(0,app.content.boards) and not app.profile.is_open(1,app.content.boards),"actual sequential campaign gate")
	app._start_board(0,false);await process_frame;await process_frame
	require(app.yard.engine!=null and app.yard.cargo_models.size()==1,"actual train and freight scene present")
	require(app.point_buttons.size()==1,"large mirrored point control")
	var a_screen: Vector2=app.yard.camera.unproject_position(app.yard.node_positions.P1A)
	var b_screen: Vector2=app.yard.camera.unproject_position(app.yard.node_positions.P1B)
	require(a_screen.x<b_screen.x,"A really appears left of B in the live camera")
	require(app.dispatch_button.custom_minimum_size.y>=112,"minimum practical primary touch target")
	app.dispatch_button.grab_focus();await process_frame
	var focus_style: StyleBoxFlat=app.dispatch_button.get_theme_stylebox("focus","Button") as StyleBoxFlat
	var primary_style: StyleBoxFlat=app.dispatch_button.get_theme_stylebox("normal","Button") as StyleBoxFlat
	require(app.dispatch_button.has_focus() and not focus_style.draw_center and primary_style.bg_color==app.GOLD,"focused primary keeps its amber surface beneath a border-only focus ring")
	app._toggle_view();require(app.yard.focused and app.view_button.text=="Fit yard","actual Train control offers a readable close view")
	app._toggle_view();require(not app.yard.focused,"Fit yard restores the complete planned railway")
	var before: Dictionary=app.model.snapshot();app._preview()
	require(app.model.snapshot()==before,"UI preview cannot change progression")
	# Source-fixture dispatch follows the exact model trace and the UI's ordinary
	# event settlement/banking function; native testing must play it separately.
	for i in range(30):
		if app.scene_page=="result":break
		app._advance();app.yard.motion=false;app.yard.travel=app.yard.target_travel;app._settle()
	require(app.scene_page=="result","UI ordered delivery reaches result")
	var result_annotations_hidden: bool=not app.yard.labels.is_empty()
	for annotation in app.yard.labels:result_annotations_hidden=result_annotations_hidden and not annotation.visible
	require(result_annotations_hidden and app.yard.engine!=null and app.yard.wagons.size()==1,"result preserves the actual completed train without overlapping world labels")
	require(int(app.profile.data.clears)==1 and service.finished==1,"once-only UI award and service cadence")
	var coins: int=int(app.profile.data.coins);app._complete()
	require(int(app.profile.data.coins)==coins and service.finished==1,"repeat result cannot bank or trigger ad cadence")
	app._start_board(1,false);await process_frame
	app._request_hint();var held: Dictionary=app.model.snapshot()
	require(app.reward_pending and app._blocked(),"pending native show freezes immediately")
	app._process(5.0);require(app.model.snapshot()==held,"pending gap cannot advance")
	service.fullscreen=true;service.callback.call(true);app._process(5.0)
	require(app.model.assisted and app._blocked() and not app.is_dispatching,"earned callback remains frozen behind endcard")
	app._resume_gate();require(app._blocked(),"cannot resume while fullscreen")
	var hint: String=app.hinted_text;service.callback.call(true)
	require(app.hinted_text==hint and int(app.profile.data.coins)==coins,"duplicate reward callback no extra benefit")
	service.fullscreen=false;app._process(1.0)
	require(app.ad_resume_gate and app._blocked(),"dismissal requires neutral Resume")
	app._resume_gate();require(not app._blocked() and not app.is_dispatching,"Resume unlocks input without automatically dispatching")
	var old_callback: Callable=service.callback
	app._start_board(2,false);await process_frame
	old_callback.call(true);require(not app.model.assisted,"stale earned callback cannot affect replacement route")
	app._request_hint();old_callback=service.callback
	app._start_board(2,false);await process_frame;app._resume_gate();old_callback.call(true)
	require(not app.model.assisted and not app.reward_pending,"replaced pending request cannot grant or leave a permanent input lock")
	app._request_hint();service.callback.call(false);service.fullscreen=false;app._resume_gate()
	require(not app.model.assisted,"unearned hint grants nothing")
	app._show_journal();await process_frame;require(app.scene_page=="journal","20+3 icon journal opens")
	for button in app.find_children("*","Button",true,false):
		if button.text in ["Sign in to Play Games","Native achievements","Open Play Games board"]:button.pressed.emit()
	require(service.signins==1 and service.achievement_opens==1 and service.board_opens==3,"actual journal buttons call service adapter")
	app._notification(MainLoop.NOTIFICATION_APPLICATION_PAUSED);app._notification(MainLoop.NOTIFICATION_APPLICATION_RESUMED);app._process(0.1)
	require(app.gate_row.visible and app.resume_button.visible,"journal foreground exposes Resume")
	app._resume_gate()
	app._show_settings();await process_frame;require(app.scene_page=="settings","audio and livery settings open")
	app._start_board(1,false);app.model.points=app.model.board.solution.duplicate();app._advance();app.yard.motion=false;app._settle();app._back()
	require(app.scene_page=="home" and not app.profile.data.draft.is_empty(),"Back preserves actual paused route")
	var draft: Dictionary=app.profile.data.draft.duplicate(true)
	await _dispose_app(app)
	app=MainScene.instantiate();root.add_child(app);await process_frame;await process_frame
	require(int(app.profile.data.clears)==1,"cold UI profile retains once-only award")
	app._continue_route();await process_frame
	require(app.model.at==draft.state.at and app.model.collected==draft.state.collected,"cold draft retains exact cursor and freight")
	app._notification(MainLoop.NOTIFICATION_APPLICATION_PAUSED);var paused: Dictionary=app.model.snapshot();app._process(10.0)
	require(app.model.snapshot()==paused and app._blocked(),"application background freezes simulation")
	app._notification(MainLoop.NOTIFICATION_APPLICATION_RESUMED);app._resume_gate()
	require(not app._blocked() and not app.is_dispatching,"foreground returns to neutral controls")
	for resolution in [Vector2i(720,1280),Vector2i(1200,1920),Vector2i(1600,2560)]:
		root.size=resolution;await process_frame;await process_frame
		require(app.yard.size.x>0 and app.yard.size.y>0 and app.yard.camera.size>0,"live positive phone/tablet yard fit")
		require(absf(float(app.yard.view.size.x)-app.yard.size.x)<=1.0 and absf(float(app.yard.view.size.y)-app.yard.size.y)<=1.0,"container alone owns actual phone/tablet viewport size")
	var fault:=FaultProfile.new();fault.data=app.profile.data.duplicate(true);app.profile=fault
	var unpaid: int=int(fault.data.coins)
	for i in range(40):
		if app.bank_pending:break
		app._advance();app.yard.motion=false;app.yard.travel=app.yard.target_travel;app._settle()
	require(app.bank_pending and app.scene_page=="game" and app.retry_save_button.visible,"failed durable award exposes Retry save before Next")
	require(int(app.profile.data.coins)==unpaid and service.finished==1,"failed durable award neither pays nor advances ad cadence")
	fault.refuse_writes=false;app.retry_save_button.pressed.emit()
	require(app.scene_page=="result" and not app.bank_pending and int(app.profile.data.clears)==2 and service.finished==2,"Retry save durably banks exactly once")
	fault=null
	await _dispose_app(app)
	service.queue_free();service=null;app=null;actual=null
	await process_frame
	if failures==0:print("SWITCHYARD UI SOURCE PASS: %d checks. Native gameplay/ads remain separate."%checks)
	else:print("SWITCHYARD UI SOURCE FAIL: %d / %d"%[failures,checks])
	quit(0 if failures==0 else 1)
