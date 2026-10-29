extends Control
## Portrait dispatcher UI with saved energy and genuine native reward callbacks.
const Rail = preload("res://game/rail_model.gd")
const Profile = preload("res://game/profile.gd")
const Yard = preload("res://scripts/yard.gd")
const INK := Color("172936")
const PANEL := Color("233e49")
const CREAM := Color("f6e4bd")
@onready var services: Node = get_node("/root/Services")
const GOLD := Color("e9b569")
const MUTED := Color("b3c8c7")
var content: Dictionary = {}
var catalog: Dictionary = {}
var profile: RailwayProfile
var model: RailModel
var stage: VBoxContainer
var header: HBoxContainer
var body: Control
var nav_title: Label
var wallet: Label
var notice: Label
var banner_pad: Control
var yard: SubViewportContainer
var scene_page := "home"
var board_index := 0
var daily := false
var run_id := ""
var pending_event: Dictionary = {}
var is_dispatching := false
var step_animating := false
var reward_pending := false
var request_token := 0
var settled_tokens: Dictionary = {}
var app_background := false
var ad_resume_gate := false
var bank_pending := false
var seen_fullscreen := false
var pause_label: Label
var resume_button: Button
var gate_row: HBoxContainer
var retry_save_button: Button
var dispatch_button: Button
var step_button: Button
var undo_button: Button
var status_label: Label
var manifest_label: Label
var manifest_chips: Array[Label] = []
var view_button: Button
var last_service_notice := ""
var point_buttons: Dictionary = {}
var action_buttons: Array[Button] = []
var reward_button: Button
var result_award: Dictionary = {}
var hinted_text := ""
var music: AudioStreamPlayer
var effects: Array[AudioStreamPlayer] = []
var music_key := ""
var soundtrack: Dictionary = {}
var sfx: Dictionary = {}
var auto_clock := 0.0
var home_backdrop: TextureRect
var energy_button: Button

func _ready() -> void:
	get_tree().auto_accept_quit=false
	content=JSON.parse_string(FileAccess.get_file_as_string("res://game/boards.json"))
	catalog=JSON.parse_string(FileAccess.get_file_as_string("res://game/catalog.json"))
	profile=Profile.new();profile.load_file();profile.rollover(_today());profile.refresh_energy()
	_setup_audio();_setup_theme();_shell()
	services.menu_bottom_reserve_changed.connect(_banner_space)
	services.availability_changed.connect(_availability)
	services.service_notice.connect(_service_notice)
	resized.connect(_banner_space)
	_show_home()
	if profile.load_message!="":_toast(profile.load_message)
	elif not profile.data.draft.is_empty():_toast("Your paused route is ready under Continue route.")

func _setup_theme() -> void:
	var skin:=Theme.new();skin.default_font_size=30
	skin.set_color("font_color","Label",CREAM)
	skin.set_color("font_color","Button",CREAM)
	skin.set_color("font_hover_color","Button",Color.WHITE)
	skin.set_color("font_disabled_color","Button",Color("809398"))
	for state in ["normal","hover","pressed","disabled","focus"]:
		var box:=StyleBoxFlat.new();box.bg_color=PANEL if state!="pressed" else Color("48665f")
		if state=="disabled":box.bg_color=Color("23353d")
		# Focus is drawn on top of the active style; its fill must not hide a
		# primary button's amber surface behind an ink-colored label.
		if state=="focus":box.draw_center=false
		box.border_color=GOLD if state in ["focus","hover"] else Color("61736c")
		box.set_border_width_all(3 if state=="focus" else 2);box.set_corner_radius_all(20)
		box.content_margin_left=18;box.content_margin_right=18;box.content_margin_top=14;box.content_margin_bottom=14
		skin.set_stylebox(state,"Button",box)
	skin.set_constant("separation","VBoxContainer",16);skin.set_constant("separation","HBoxContainer",14)
	theme=skin
	var backdrop:=ColorRect.new();backdrop.color=INK;backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);backdrop.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(backdrop)
	home_backdrop=TextureRect.new();home_backdrop.name="MenuValleyIllustration";home_backdrop.texture=load("res://assets/art/menu-valley-r4.png") as Texture2D;home_backdrop.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;home_backdrop.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED;home_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);home_backdrop.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(home_backdrop)

func _shell() -> void:
	var margin:=MarginContainer.new();margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left",28);margin.add_theme_constant_override("margin_right",28);margin.add_theme_constant_override("margin_top",24);margin.add_theme_constant_override("margin_bottom",12);add_child(margin)
	stage=VBoxContainer.new();margin.add_child(stage)
	header=HBoxContainer.new();header.custom_minimum_size.y=104;stage.add_child(header)
	var back:=_button("‹",_back,112);back.name="BackButton";header.add_child(back)
	back.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN
	var title_column:=VBoxContainer.new();title_column.size_flags_horizontal=Control.SIZE_EXPAND_FILL;header.add_child(title_column)
	nav_title=_label("SWITCHYARD LANTERNS",32,GOLD);title_column.add_child(nav_title)
	wallet=_label("",25,MUTED);title_column.add_child(wallet)
	nav_title.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;wallet.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	body=Control.new();body.size_flags_vertical=Control.SIZE_EXPAND_FILL;body.size_flags_horizontal=Control.SIZE_EXPAND_FILL;stage.add_child(body)
	notice=_label("",24,MUTED);notice.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;notice.visible=false;stage.add_child(notice)
	gate_row=HBoxContainer.new();stage.add_child(gate_row);pause_label=_paragraph("",25,GOLD);pause_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;gate_row.add_child(pause_label)
	resume_button=Button.new();resume_button.text="Resume";resume_button.custom_minimum_size=Vector2(220,112);resume_button.pressed.connect(_resume_gate);gate_row.add_child(resume_button);gate_row.visible=false
	retry_save_button=Button.new();retry_save_button.text="Retry save";retry_save_button.custom_minimum_size=Vector2(240,112);retry_save_button.pressed.connect(_retry_save);gate_row.add_child(retry_save_button);retry_save_button.visible=false
	banner_pad=Control.new();stage.add_child(banner_pad)
	_banner_space()

func _label(text: String,size_px: int=30,color: Color=CREAM) -> Label:
	var label:=Label.new();label.text=text;label.add_theme_font_size_override("font_size",size_px);label.add_theme_color_override("font_color",color);return label

func _paragraph(text: String,size_px: int=29,color: Color=MUTED) -> Label:
	var label:=_label(text,size_px,color);label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;return label

func _button(text: String,callback: Callable,min_width: float=0,height: float=112) -> Button:
	var button:=Button.new();button.text=text;button.custom_minimum_size=Vector2(min_width,height);button.size_flags_horizontal=Control.SIZE_EXPAND_FILL;button.add_theme_font_size_override("font_size",28)
	button.pressed.connect(func():
		if _blocked():return
		_sound("click");callback.call())
	return button

func _panel(parent: Node,color: Color=PANEL,padding: int=22) -> VBoxContainer:
	var panel:=PanelContainer.new();var style:=StyleBoxFlat.new();style.bg_color=color;style.set_corner_radius_all(22);style.border_color=Color("68776d");style.set_border_width_all(2)
	style.content_margin_left=padding;style.content_margin_right=padding;style.content_margin_top=padding;style.content_margin_bottom=padding;panel.add_theme_stylebox_override("panel",style);parent.add_child(panel)
	var column:=VBoxContainer.new();panel.add_child(column);return column

func _clear(page: String,title: String,menu: bool=true) -> VBoxContainer:
	request_token+=1
	reward_pending=false
	_toast("")
	if is_instance_valid(yard):yard.shutdown()
	yard=null
	# Keep the control dispatching this pressed signal inside the tree until its
	# deferred deletion; Android may still query its can_process() during return.
	for child in body.get_children():
		if child is CanvasItem:child.hide()
		if child is Control:child.mouse_filter=Control.MOUSE_FILTER_IGNORE
		child.process_mode=Node.PROCESS_MODE_DISABLED;child.queue_free()
	point_buttons.clear();action_buttons.clear();status_label=null;manifest_label=null;reward_button=null;dispatch_button=null;step_button=null;undo_button=null
	scene_page=page;nav_title.text=title
	home_backdrop.visible=page=="home"
	services.set_menu_visible(menu);_banner_space();_wallet()
	var column:=VBoxContainer.new();column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);body.add_child(column);return column

func _scroll(column: VBoxContainer) -> VBoxContainer:
	var scroll:=ScrollContainer.new();scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;scroll.size_flags_horizontal=Control.SIZE_EXPAND_FILL;column.add_child(scroll)
	var list:=VBoxContainer.new();list.size_flags_horizontal=Control.SIZE_EXPAND_FILL;list.add_theme_constant_override("separation",18);scroll.add_child(list);return list

func _wallet() -> void:
	profile.refresh_energy()
	wallet.text="Energy %d/%d  |  Lv %d dispatcher   •   %d XP   •   %d brass" % [int(profile.data.energy),Profile.ENERGY_MAX,profile.level(),int(profile.data.xp),int(profile.data.coins)]

func _banner_space() -> void:
	if is_instance_valid(banner_pad):banner_pad.custom_minimum_size.y=float(services.menu_bottom_reserve(self))

func _availability() -> void:
	_banner_space()
	if is_instance_valid(reward_button):reward_button.disabled=not services.can_reward()
	if is_instance_valid(energy_button):energy_button.disabled=not services.can_reward()

func _toast(text: String) -> void:
	if is_instance_valid(notice):notice.text=text;notice.visible=not text.is_empty()

func _service_notice(text: String) -> void:
	last_service_notice=text
	if scene_page in ["journal","settings"]:_toast(text)

func _primary(button: Button) -> void:
	for state in ["normal","hover","pressed"]:
		var style: StyleBoxFlat=button.get_theme_stylebox(state,"Button").duplicate() as StyleBoxFlat
		style.bg_color=GOLD if state!="pressed" else Color("c8964c");style.border_color=Color("ffe0a3");button.add_theme_stylebox_override(state,style)
	button.add_theme_color_override("font_color",INK);button.add_theme_color_override("font_hover_color",INK);button.add_theme_color_override("font_pressed_color",INK)

func _tertiary(button: Button) -> void:
	var style: StyleBoxFlat=button.get_theme_stylebox("normal","Button").duplicate() as StyleBoxFlat
	style.bg_color=Color("1c303d");style.border_color=Color("4f6870");button.add_theme_stylebox_override("normal",style)

func _today() -> String:
	return Time.get_date_string_from_system(true)

func _yesterday() -> String:
	return Time.get_datetime_string_from_unix_time(int(Time.get_unix_time_from_system())-86400).left(10)

func _daily_index() -> int:
	return posmod(int(floor(Time.get_unix_time_from_system()/86400.0))+11,content.boards.size())

func _hero(column: VBoxContainer,index: int,height: float=390) -> void:
	yard=Yard.new();yard.custom_minimum_size.y=height;yard.size_flags_vertical=Control.SIZE_EXPAND_FILL;column.add_child(yard)
	var board: Dictionary=content.boards[index];yard.build(board,content.districts[int(board.district)],content.cargo,true)
	yard.apply_livery(int(profile.data.settings.livery))

func _brand_hero(column: VBoxContainer) -> void:
	var frame:=AspectRatioContainer.new();frame.ratio=1024.0/500.0;frame.stretch_mode=AspectRatioContainer.STRETCH_FIT;frame.custom_minimum_size.y=320;frame.size_flags_vertical=Control.SIZE_EXPAND_FILL;column.add_child(frame)
	var image:=TextureRect.new();image.texture=load("res://marketing/branding/feature_graphic.png") as Texture2D;image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;image.mouse_filter=Control.MOUSE_FILTER_IGNORE;frame.add_child(image)

func _show_home() -> void:
	is_dispatching=false;step_animating=false;pending_event={}
	var column:=_clear("home","SWITCHYARD LANTERNS")
	_music("menu")
	var head:=_panel(column,PANEL,16)
	head.add_child(_label("Set the points. Light the route.",32,GOLD))
	head.add_child(_paragraph("Untimed railway puzzles. Every wagon in its place.",25))
	var valley_space:=Control.new();valley_space.custom_minimum_size.y=200;valley_space.size_flags_vertical=Control.SIZE_EXPAND_FILL;column.add_child(valley_space)
	var buttons:=VBoxContainer.new();column.add_child(buttons)
	var energy:=_panel(buttons,PANEL,12);energy.add_child(_paragraph("2 energy per new yard. +3 per new level or +1 every 10 minutes (also offline). No completion refund. Earned ads refill. Continue, Undo and Reset are free.",24))
	energy_button=_button("Refill energy (ad)",_request_energy);energy_button.disabled=not services.can_reward();energy.add_child(energy_button)
	if not profile.data.draft.is_empty():
		var continue_row:=HBoxContainer.new();buttons.add_child(continue_row);continue_row.add_child(_button("Continue route",_continue_route));continue_row.add_child(_button("Campaign - 100 yards",_show_campaign))
	else:
		var campaign:=_button("Campaign - 100 lantern yards",_show_campaign);_primary(campaign);buttons.add_child(campaign)
	var row:=HBoxContainer.new();buttons.add_child(row)
	row.add_child(_button("Daily freight",_show_daily));row.add_child(_button("Keeper's journal",_show_journal))
	var last:=HBoxContainer.new();buttons.add_child(last)
	last.add_child(_button("Sound & settings",_show_settings));last.add_child(_button("How to dispatch",_show_help))

func _show_campaign() -> void:
	var column:=_clear("campaign","VALLEY TIMETABLE")
	column.add_child(_paragraph("Every delivery opens the next yard. New loads cost 2 energy; Continue, Reset and Undo are free. Three stars reward an unassisted clean route.",27))
	var list:=_scroll(column)
	for district_index in range(content.districts.size()):
		var section:=_panel(list)
		section.add_child(_label(str(content.districts[district_index].name).to_upper(),32,GOLD))
		var grid:=GridContainer.new();grid.columns=2;grid.add_theme_constant_override("h_separation",14);grid.add_theme_constant_override("v_separation",14);section.add_child(grid)
		for offset in range(8):
			var index:=district_index*8+offset
			if index>=content.boards.size():break
			var board: Dictionary=content.boards[index]
			var record: Dictionary=profile.data.records.get(board.id,{})
			var stars: int=int(record.get("stars",0))
			var button:=_button("%02d  %s\n%s"%[index+1,str(board.title),"★".repeat(stars)+"☆".repeat(3-stars)],_start_board.bind(index,false),0,142)
			button.add_theme_font_size_override("font_size",25);button.disabled=not profile.is_open(index,content.boards);grid.add_child(button)

func _show_daily() -> void:
	profile.rollover(_today());profile.save()
	var column:=_clear("daily","DAILY FREIGHT")
	var list:=_scroll(column);var daily_board: Dictionary=content.boards[_daily_index()]
	var card:=_panel(list);card.add_child(_label("TODAY'S LANTERN ROUTE",32,GOLD));card.add_child(_label(str(daily_board.title),36));card.add_child(_paragraph("%s UTC · A curated yard from the campaign. Daily progress stays local when offline. No clock changes are needed."%_today()))
	card.add_child(_button("Dispatch today's freight",_start_board.bind(_daily_index(),true)))
	var goal:=_panel(list);goal.add_child(_label("THREE DELIVERIES FOR THE VALLEY",31,GOLD));goal.add_child(_paragraph("Complete any three dispatches today: %d / 3. Earn 60 brass and 20 XP."%mini(3,int(profile.data.day_clears))))
	var claim:=_button("Claim freight goal" if not profile.data.day_claimed else "Freight goal collected",_claim_freight);claim.disabled=profile.data.day_claimed or int(profile.data.day_clears)<3;goal.add_child(claim)
	var login:=_panel(list);login.add_child(_label("SEVEN-DAY LANTERN POST",31,GOLD));login.add_child(_paragraph("Current stamp: %d / 7. A small free daily thank-you; missing a date restarts the stamp row, never your railway."%int(profile.data.login_streak)))
	var login_button:=_button("Collect today's post" if str(profile.data.login_last)<_today() else "Today's post collected",_claim_login);login_button.disabled=str(profile.data.login_last)>=_today();login.add_child(login_button)

func _claim_login() -> void:
	var result:=profile.claim_login(_today(),_yesterday());_show_daily()
	if result.get("ok",false):_toast("Post delivered: +%d brass, +5 XP. Stamp %d / 7."%[result.coins,result.streak]+_level_gift_text(int(result.level_from),int(result.level_to)));_sync_services()
	elif result.get("reason","")=="save_failed":_toast("The post could not be saved. Nothing was claimed; please retry.")

func _claim_freight() -> void:
	var before: int=profile.level()
	var claimed: bool=profile.claim_freight(_today())
	var after: int=profile.level()
	_show_daily()
	if claimed:_toast("Valley freight goal: +60 brass, +20 XP."+_level_gift_text(before,after));_sync_services()
	else:_toast("The goal was not claimed. If storage is unavailable, free space and retry.")

func _level_gift_text(before: int,after: int) -> String:
	if after<=before:return ""
	return "  Level %d! +%d brass level gift."%[after,(after-before)*Profile.LEVEL_GIFT]

func _show_journal() -> void:
	var column:=_clear("journal","KEEPER'S JOURNAL");var list:=_scroll(column)
	var stats:=profile.stats(content.boards)
	var summary:=_panel(list);summary.add_child(_label("YOUR RAILWAY",34,GOLD));summary.add_child(_paragraph("%d / 100 yards  •  %d / 300 unassisted stars\n%d wagons delivered  •  %d dispatches\nDispatcher level %d  •  %d daily routes"%[stats.campaign_cleared,stats.campaign_stars,stats.cargo_total,stats.clears,stats.level,stats.daily_clears]))
	var services_row:=HBoxContainer.new();summary.add_child(services_row);services_row.add_child(_button("Sign in to Play Games",func():services.sign_in()));services_row.add_child(_button("Native achievements",func():services.open_achievements()))
	for achievement in catalog.achievements:
		var row:=_panel(list);var box:=HBoxContainer.new();row.add_child(box)
		_icon(box,str(achievement.icon),96)
		var text:=VBoxContainer.new();text.size_flags_horizontal=Control.SIZE_EXPAND_FILL;box.add_child(text)
		var have: int=int(stats.get(str(achievement.metric),0));var target: int=int(achievement.target)
		text.add_child(_label(("✓  " if have>=target else "")+str(achievement.title),30,GOLD if have>=target else CREAM))
		text.add_child(_paragraph(str(achievement.description)+"  %d / %d"%[mini(have,target),target],25))
	for board in catalog.leaderboards:
		var row:=_panel(list);var box:=HBoxContainer.new();row.add_child(box);_icon(box,str(board.icon),96)
		var text:=VBoxContainer.new();text.size_flags_horizontal=Control.SIZE_EXPAND_FILL;box.add_child(text);text.add_child(_label(str(board.title),30,GOLD));text.add_child(_paragraph("Local best: %d. Higher is better. Production IDs are configured by the owner."%int(stats.get(str(board.metric),0)),25));row.add_child(_button("Open Play Games board",func():services.open_leaderboards(str(board.key))))

func _icon(parent: Node,path: String,pixels: float) -> void:
	if not ResourceLoader.exists("res://"+path):return
	var image:=TextureRect.new();image.texture=load("res://"+path);image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;image.custom_minimum_size=Vector2(pixels,pixels);parent.add_child(image)

func _show_settings() -> void:
	var column:=_clear("settings","SOUND & RAILWAY");var list:=_scroll(column);var card:=_panel(list)
	card.add_child(_label("YOUR COMFORT",34,GOLD))
	card.add_child(_button("Music: "+("on" if profile.data.settings.music else "off"),func():profile.data.settings.music=not profile.data.settings.music;profile.save();_audio_levels();_show_settings()))
	card.add_child(_button("Sound effects: "+("on" if profile.data.settings.effects else "off"),func():profile.data.settings.effects=not profile.data.settings.effects;profile.save();_audio_levels();_show_settings()))
	card.add_child(_paragraph("Dispatch speed affects animation only. Planning and paused points never run on a timer."))
	for speed in [0.7,1.0,1.5]:card.add_child(_button("%s animation%s"%["Gentle" if speed<1 else ("Express" if speed>1 else "Standard"),"  ✓" if is_equal_approx(float(profile.data.settings.speed),speed) else ""],_set_speed.bind(speed)))
	card.add_child(_label("ENGINE LIVERIES",32,GOLD))
	for i in range(3):
		var needed: int=[1,5,10][i]
		var livery:=_button(["Lantern teal","Orchard green","Midnight blue"][i]+("  ✓" if int(profile.data.settings.livery)==i else "")+"  · Lv %d"%needed,_set_livery.bind(i));livery.disabled=profile.level()<needed;card.add_child(livery)
	card.add_child(_button("Ad privacy choices",func():services.privacy_options()))
	card.add_child(_paragraph(str(services.status()),24,MUTED))
	card.add_child(_paragraph("All ordinary play, retries and Undo are free. Optional earned hints mark a run assisted. Native services may be unavailable offline; local progress still works.",26))

func _set_speed(value: float) -> void:
	profile.data.settings.speed=value;profile.save();_show_settings()

func _set_livery(index: int) -> void:
	profile.data.settings.livery=index;profile.save();_show_settings()

func _show_help() -> void:
	var column:=_clear("help","THE DISPATCHER'S DESK");var list:=_scroll(column);var card:=_panel(list)
	for title_text in ["1  Read the manifest","2  Set the points","3  Preview, then Dispatch","4  Pause or Step","5  Deliver home"]:
		card.add_child(_label(title_text,34,GOLD))
		var index: int=["1  Read the manifest","2  Set the points","3  Preview, then Dispatch","4  Pause or Step","5  Deliver home"].find(title_text)
		card.add_child(_paragraph(["Collect the pictured wagons left to right. Parcel crates, blue mail, timber logs and water tanks have names as well as colors.","Each numbered turnout has L (screen-left) and R (screen-right) exits from your viewpoint, independent of train direction. Tap its large chip or its world lantern to choose. Points beneath the train stay locked; plan ahead or Undo.","The brass trail previews the same simulator used by your train. It tells you where the route ends without changing your save.","Pause freezes the railway. Step travels one track connection. Unlimited free Undo and Reset let you learn without losing brass.","Reach Lantern station with exactly the requested wagons. Earn XP, brass and optional mastery stars. Three-star routes use no hint or Undo."][index]))
	card.add_child(_button("Start the first lantern yard",_start_board.bind(0,false)))

func _start_board(index: int,is_daily: bool) -> void:
	var candidate:=Rail.new();candidate.begin(content.boards[index])
	var initial_state: Dictionary=candidate.snapshot();initial_state.undo_history=[]
	var draft: Dictionary={"index":index,"daily":is_daily,"run_id":"","state":initial_state,"hint":""}
	var next_id: String=profile.new_run(str(content.boards[index].id),is_daily,draft)
	if next_id=="":_toast("A new yard needs 2 energy and a saved ticket. Wait for recharge or refill on Home; check storage if energy is available.");_wallet();return
	board_index=index;daily=is_daily;model=candidate;run_id=next_id
	hinted_text="";result_award={};pending_event={};is_dispatching=false;step_animating=false
	_show_game()

func _continue_route() -> void:
	var draft: Dictionary=profile.data.draft
	var index: int=int(draft.get("index",-1))
	if index<0 or index>=content.boards.size():_toast("That draft cannot be opened. Your campaign is safe.");return
	board_index=index;daily=bool(draft.get("daily",false));run_id=str(draft.get("run_id",""));model=Rail.new();model.begin(content.boards[index])
	if not model.restore(draft.get("state",{})) or profile.data.banked.has(run_id):profile.data.draft={};profile.save();_show_home();return
	if model.status=="running":model.pause()
	is_dispatching=false;step_animating=false;pending_event={};hinted_text=str(draft.get("hint",""));_show_game();_toast("Paused route restored. Resume when you're ready.")

func _show_game() -> void:
	var column:=_clear("game",str(model.board.title).to_upper(),false)
	column.add_theme_constant_override("separation",12)
	_music(str(content.districts[int(model.board.district)].music))
	var manifest_card:=_panel(column,Color("263e4c"),12);manifest_card.add_theme_constant_override("separation",6)
	manifest_chips.clear()
	var manifest_scroll:=ScrollContainer.new();manifest_scroll.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;manifest_scroll.custom_minimum_size.y=112;manifest_card.add_child(manifest_scroll)
	var manifest_row:=HBoxContainer.new();manifest_row.add_theme_constant_override("separation",8);manifest_scroll.add_child(manifest_row)
	manifest_label=_label("LOAD",25,GOLD);manifest_label.custom_minimum_size=Vector2(78,84);manifest_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;manifest_row.add_child(manifest_label)
	var cargo_icons: Dictionary={"R":"parcel","B":"mail","L":"timber","T":"water"}
	for i in range(model.board.manifest.size()):
		var code: String=str(model.board.manifest[i]);var cargo: Dictionary=content.cargo[code]
		var cell:=VBoxContainer.new();cell.custom_minimum_size=Vector2(110,84);cell.add_theme_constant_override("separation",0);manifest_row.add_child(cell)
		var picture:=TextureRect.new();picture.custom_minimum_size=Vector2(68,56);picture.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;picture.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;picture.mouse_filter=Control.MOUSE_FILTER_IGNORE
		var path: String="res://assets/art/cargo/%s.png"%str(cargo_icons[code])
		if ResourceLoader.exists(path):picture.texture=load(path) as Texture2D
		cell.add_child(picture)
		var chip:=_label("",22,CREAM);chip.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;cell.add_child(chip);manifest_chips.append(chip)
	if model.board.tutorial:
		manifest_card.add_child(_paragraph("L is screen-left. R is screen-right. Preview the brass route, then Dispatch." if board_index==0 else "Set both points before leaving. Pause, Step and free Undo let you learn safely.",22,GOLD))
	elif bool(model.board.get("has_capacity_limits",false)):
		manifest_card.add_child(_paragraph("Bridge MAX = wagons already coupled. The engine does not count.",22,GOLD))
	yard=Yard.new();yard.custom_minimum_size.y=300;yard.size_flags_vertical=Control.SIZE_EXPAND_FILL;column.add_child(yard);yard.build(model.board,content.districts[int(model.board.district)],content.cargo);yard.sync_snapshot(model.snapshot())
	yard.apply_livery(int(profile.data.settings.livery));yard.point_requested.connect(_toggle_point)
	status_label=_paragraph(model.message,25,CREAM);status_label.custom_minimum_size.y=42;column.add_child(status_label)
	var point_scroll:=ScrollContainer.new();point_scroll.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;point_scroll.custom_minimum_size.y=136;column.add_child(point_scroll)
	var point_row:=HBoxContainer.new();point_row.add_theme_constant_override("separation",10);point_scroll.add_child(point_row)
	for key in model.points:
		var button:=_button(str(key),_toggle_point.bind(str(key)),112,112);button.add_theme_font_size_override("font_size",26)
		if model.points.size()<=2:button.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN
		point_row.add_child(button);point_buttons[key]=button;action_buttons.append(button)
	var primary_row: HBoxContainer=point_row
	if model.points.size()>2:primary_row=HBoxContainer.new();column.add_child(primary_row)
	dispatch_button=_button("Dispatch",_dispatch);_primary(dispatch_button);primary_row.add_child(dispatch_button);action_buttons.append(dispatch_button)
	step_button=_button("Step",_step);primary_row.add_child(step_button);action_buttons.append(step_button)
	var preview:=_button("Preview",_preview);primary_row.add_child(preview);action_buttons.append(preview)
	view_button=_button("Train",_toggle_view);primary_row.add_child(view_button);action_buttons.append(view_button)
	var second:=HBoxContainer.new();column.add_child(second)
	undo_button=_button("Undo",_undo);_tertiary(undo_button);second.add_child(undo_button);action_buttons.append(undo_button)
	var reset:=_button("Reset",_reset);_tertiary(reset);second.add_child(reset);action_buttons.append(reset)
	reward_button=_button("Hint (ad)",_request_hint);_tertiary(reward_button);second.add_child(reward_button);action_buttons.append(reward_button)
	_update_game()

func _toggle_view() -> void:
	if not is_instance_valid(yard):return
	view_button.text="Fit yard" if yard.toggle_view() else "Train"

func _manifest_text() -> String:
	var names: Array[String]=[]
	for i in range(model.board.manifest.size()):
		var code: String=str(model.board.manifest[i]);var name_text: String=str(content.cargo[code].name)
		names.append(("✓ " if i<model.collected.size() else "")+name_text)
	return "MANIFEST  →  "+"  ›  ".join(names)

func _toggle_point(key: String) -> void:
	if _blocked() or is_dispatching or step_animating or not pending_event.is_empty():return
	if model.set_point(key,1-int(model.points[key])):_sound("switch");yard.set_points(model.points);yard.clear_preview();_save_draft()
	else:_toast("Those points are occupied. Undo to clear them, or set the next turnout.")
	_update_game()

func _dispatch() -> void:
	if is_dispatching:
		is_dispatching=false;model.pause();_save_draft();_update_game();return
	if model.status in ["failed","won"] and pending_event.is_empty():return
	if model.status in ["planning","paused"]:model.dispatch()
	is_dispatching=true;step_animating=false;yard.clear_preview();_sound("whistle");_update_game()

func _step() -> void:
	if is_dispatching or step_animating or not pending_event.is_empty() or model.status in ["won","failed"]:return
	model.pause();step_animating=true;_advance();_update_game()

func _advance() -> void:
	pending_event=model.step()
	if pending_event.has("edge"):yard.append_event(pending_event)
	else:_settle()

func _settle() -> void:
	var event:=pending_event.duplicate(true);pending_event={}
	if not event.is_empty():yard.settle_event(event)
	if str(event.get("coupled",""))!="":_sound("coupling")
	if step_animating:step_animating=false;model.pause()
	_save_draft()
	if model.status=="won":
		is_dispatching=false;_complete();return
	if model.status=="failed":is_dispatching=false;_sound("error")
	_update_game()

func _preview() -> void:
	if is_dispatching or step_animating or not pending_event.is_empty():return
	var route_preview:=model.preview();yard.show_preview(route_preview)
	_toast("Route preview: "+str(route_preview.message))

func _undo() -> void:
	if is_dispatching or step_animating or not pending_event.is_empty():return
	if model.undo():yard.sync_snapshot(model.snapshot());yard.clear_preview();_save_draft()
	_update_game()

func _reset() -> void:
	if is_dispatching or step_animating:return
	var kept_assistance: bool=model.assisted
	model.begin(content.boards[board_index]);model.assisted=kept_assistance;hinted_text="";pending_event={};step_animating=false
	_save_draft();_show_game()

func _save_draft() -> void:
	if model==null or model.status=="won":return
	var state: Dictionary=model.snapshot();state.undo_history=model.history.duplicate(true)
	profile.data.draft={"index":board_index,"daily":daily,"run_id":run_id,"state":state,"hint":hinted_text}
	if not profile.save():_toast("The route could not be saved. Check device storage before leaving.")

func _complete() -> void:
	if model.status!="won":return
	if profile.data.banked.has(run_id):bank_pending=false;_show_result();return
	result_award=profile.bank(run_id,model.board,model.stars(),model.assisted,daily,_today())
	if result_award.get("ok",false):
		bank_pending=false;_sound("arrival");_sync_services();services.round_finished(int(profile.data.clears));_show_result()
	else:
		bank_pending=true;_toast("Delivery reached home, but storage could not save its award. Nothing was banked. Retry save to continue.");_gate_ui();_update_game()

func _retry_save() -> void:
	if not bank_pending or app_background or reward_pending or services.fullscreen_ad_active():return
	_complete()

func _show_result() -> void:
	var final_state:=model.snapshot()
	var page:=_clear("result","WELCOME HOME")
	var column:=_scroll(page)
	var card:=_panel(column);card.add_child(_label(str(model.board.title),38,GOLD));card.add_child(_paragraph("Every wagon in its place. %s"%("Assisted route — ordinary progress earned; efficiency record excluded." if model.assisted else "Unassisted dispatch."),28))
	var stars_row:=HBoxContainer.new();stars_row.alignment=BoxContainer.ALIGNMENT_CENTER;card.add_child(stars_row)
	for i in range(3):_icon(stars_row,"assets/kenney/ui/PNG/Yellow/Double/star.png" if i<model.stars() else "assets/kenney/ui/PNG/Grey/Double/star_outline.png",90)
	card.add_child(_paragraph("%d track steps  •  %d Undo  •  %d wagons"%[model.steps,model.undo_count,model.collected.size()],28))
	card.add_child(_label("+%d brass   +%d XP"%[int(result_award.get("coins",0)),int(result_award.get("xp",0))],36,GOLD))
	if int(result_award.get("level_bonus",0))>0:
		card.add_child(_paragraph("Dispatcher level %d! An extra %d brass from the lantern post."%[int(result_award.level_to),int(result_award.level_bonus)],30,GOLD))
	_hero(column,board_index,260);yard.sync_snapshot(final_state)
	var row:=HBoxContainer.new();column.add_child(row)
	if not daily and board_index<content.boards.size()-1:row.add_child(_button("Next yard",_start_board.bind(board_index+1,false)))
	else:row.add_child(_button("Daily freight",_show_daily))
	row.add_child(_button("Replay",_start_board.bind(board_index,daily)))
	column.add_child(_button("Valley timetable",_show_campaign))
	# A fullscreen dismissal always returns to a neutral explicit Resume action.
	_gate_ui()

func _sync_services() -> void:
	var stats:=profile.stats(content.boards)
	for achievement in catalog.achievements:
		var key: String=str(achievement.key)
		if int(stats.get(str(achievement.metric),0))>=int(achievement.target) and not profile.data.unlocked.has(key):profile.data.unlocked.append(key);services.unlock(key)
	for board in catalog.leaderboards:services.submit(str(board.key),int(stats.get(str(board.metric),0)))
	profile.save();_wallet()

func _request_hint() -> void:
	if model==null or reward_pending or not services.can_reward() or is_dispatching or step_animating:return
	model.pause();is_dispatching=false;request_token+=1
	var token:=request_token;var owner:=run_id
	reward_pending=true;ad_resume_gate=true;_update_game()
	services.reward_requested("route_hint",_hint_callback.bind(token,owner))

func _hint_callback(earned: bool,token: int,owner: String) -> void:
	if settled_tokens.has(token):return
	settled_tokens[token]=true
	if token!=request_token or owner!=run_id or scene_page!="game" or model==null:return
	reward_pending=false;ad_resume_gate=true;model.pause();is_dispatching=false;step_animating=false
	if earned:
		model.assisted=true
		var hints: Array[String]=[]
		for key in model.board.solution:hints.append(str(key).trim_prefix("P")+" "+Rail.choice_label(model.board,str(key),int(model.board.solution[key])))
		hinted_text="Suggested points: "+"  ·  ".join(hints)
		_toast(hinted_text);_save_draft()
	else:_toast("No hint earned. Ordinary planning, Preview and Undo remain free.")
	_update_game()

func _blocked() -> bool:
	return app_background or reward_pending or services.fullscreen_ad_active() or ad_resume_gate or bank_pending

func _resume_gate() -> void:
	if app_background or reward_pending or services.fullscreen_ad_active():return
	ad_resume_gate=false;_gate_ui()
	if scene_page=="game":_update_game()

func _gate_ui() -> void:
	if is_instance_valid(gate_row):gate_row.visible=_blocked()
	if is_instance_valid(pause_label):
		pause_label.text="Delivery needs storage. Retry save." if bank_pending else ("Waiting for the ad to close…" if reward_pending or services.fullscreen_ad_active() else ("Paused after returning. Resume when ready." if ad_resume_gate else ""))
		pause_label.visible=_blocked()
	if is_instance_valid(resume_button):resume_button.visible=ad_resume_gate;resume_button.disabled=app_background or reward_pending or services.fullscreen_ad_active()
	if is_instance_valid(retry_save_button):retry_save_button.visible=bank_pending;retry_save_button.disabled=app_background or reward_pending or services.fullscreen_ad_active()

func _update_game() -> void:
	if scene_page!="game" or model==null:return
	for i in range(manifest_chips.size()):
		var code: String=str(model.board.manifest[i]);var cargo: Dictionary=content.cargo[code]
		manifest_chips[i].text=("Done " if i<model.collected.size() else str(i+1)+" ")+str(cargo.name)
		manifest_chips[i].add_theme_color_override("font_color",GOLD if i<model.collected.size() else CREAM)
	status_label.text=model.message+("  •  Assisted" if model.assisted else "")
	if hinted_text!="" and not is_dispatching:status_label.text=hinted_text
	for key in point_buttons:
		var button: Button=point_buttons[key];button.text=str(key).trim_prefix("P")+" "+Rail.choice_label(model.board,str(key),int(model.points[key]));button.disabled=_blocked() or is_dispatching or step_animating or not pending_event.is_empty() or model.status in ["won","failed"]
	dispatch_button.text="Pause" if is_dispatching else ("Dispatch" if model.steps==0 else "Resume")
	dispatch_button.disabled=_blocked() or step_animating or (model.status in ["won","failed"] and pending_event.is_empty())
	step_button.disabled=_blocked() or is_dispatching or step_animating or not pending_event.is_empty() or model.status in ["won","failed"]
	undo_button.disabled=_blocked() or is_dispatching or step_animating or not pending_event.is_empty() or model.history.is_empty() or model.status=="won"
	reward_button.disabled=_blocked() or is_dispatching or step_animating or not pending_event.is_empty() or not services.can_reward() or model.assisted or model.status in ["won","failed"]
	_gate_ui()

func _process(delta: float) -> void:
	if profile==null:return
	var fullscreen: bool=services.fullscreen_ad_active()
	if fullscreen:
		seen_fullscreen=true;ad_resume_gate=true
		if model!=null:model.pause()
		is_dispatching=false;step_animating=false
	elif seen_fullscreen:
		seen_fullscreen=false;ad_resume_gate=true;_gate_ui()
	var allowed: bool=not _blocked()
	if is_instance_valid(music):
		var pause_music: bool = not allowed
		# Web samples restart their buffer on redundant unpause calls.
		if music.stream_paused != pause_music:
			music.stream_paused = pause_music
	if scene_page=="game" and model!=null and is_instance_valid(yard):
		if allowed and (is_dispatching or step_animating):
			if not pending_event.is_empty():
				if yard.animate(delta,float(profile.data.settings.speed),true):_settle()
			elif is_dispatching:_advance()
	_gate_ui()
	auto_clock+=delta
	if auto_clock>30.0:auto_clock=0.0;profile.rollover(_today());profile.refresh_energy();profile.save();_wallet()

func _notification(what: int) -> void:
	if what==NOTIFICATION_WM_GO_BACK_REQUEST:_back()
	elif what==NOTIFICATION_APPLICATION_PAUSED:
		app_background=true;ad_resume_gate=true;is_dispatching=false;step_animating=false
		if model!=null:model.pause();_save_draft()
		if is_instance_valid(music):music.stream_paused=true
		for player in effects:
			if is_instance_valid(player):player.stop()
	elif what==NOTIFICATION_APPLICATION_RESUMED:
		app_background=false;ad_resume_gate=true
	elif what==NOTIFICATION_WM_CLOSE_REQUEST:
		_save_draft();_shutdown();get_tree().quit()

func _back() -> void:
	if _blocked():return
	if scene_page=="game":
		is_dispatching=false;step_animating=false;model.pause()
		# Settle an already simulated edge visually before leaving; the saved state
		# is that exact model position, never a second pickup or payout.
		if not pending_event.is_empty():yard.settle_event(pending_event);pending_event={}
		_save_draft();_show_home()
	elif scene_page=="home":_show_exit()
	else:_show_home()

func _show_exit() -> void:
	var column:=_clear("exit","UNTIL THE NEXT LANTERN")
	var card:=_panel(column);card.add_child(_label("Your railway is saved.",36,GOLD));card.add_child(_paragraph("Leave the valley for now? Your draft, deliveries and daily stamps stay on this device."));card.add_child(_button("Keep playing",_show_home));card.add_child(_button("Save and exit",func():profile.save();_shutdown();get_tree().quit()))

func _setup_audio() -> void:
	for bus_name in ["Music","Effects"]:
		if AudioServer.get_bus_index(bus_name)<0:AudioServer.add_bus();AudioServer.set_bus_name(AudioServer.bus_count-1,bus_name)
	music=AudioStreamPlayer.new();music.bus="Music";music.volume_db=-16.0;add_child(music)
	for i in range(4):
		var player:=AudioStreamPlayer.new();player.bus="Effects";player.volume_db=-7.0;add_child(player);effects.append(player)
	for key in ["click","switch","coupling","arrival","error"]:
		var path: String="res://assets/audio/sfx/%s.ogg"%key
		if ResourceLoader.exists(path):sfx[key]=load(path)
	if ResourceLoader.exists("res://assets/audio/sfx/whistle.wav"):sfx.whistle=load("res://assets/audio/sfx/whistle.wav")
	_audio_levels()

func _audio_levels() -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Music"),not bool(profile.data.settings.music))
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Effects"),not bool(profile.data.settings.effects))

func _music(key: String) -> void:
	if music_key==key:return
	music.stop();music.stream=null;music_key=key
	var path: String="res://assets/audio/music/%s.wav"%key
	if not ResourceLoader.exists(path):return
	if not soundtrack.has(key):soundtrack[key]=load(path)
	music.stream=soundtrack[key];music.play()

func _sound(key: String) -> void:
	if app_background or services.fullscreen_ad_active() or not sfx.has(key) or not bool(profile.data.settings.effects):return
	for player in effects:
		if not player.playing:player.stream=sfx[key];player.play();return

func _shutdown() -> void:
	if is_instance_valid(music):music.stop();music.stream=null
	for player in effects:
		if is_instance_valid(player):player.stop();player.stream=null
	soundtrack.clear();sfx.clear()
	if is_instance_valid(yard):yard.shutdown()
	model=null;profile=null

func _exit_tree() -> void:
	_shutdown()


func _request_energy() -> void:
	if _blocked() or not services.can_reward():return
	var serial: int=profile.issue_energy_reward()
	if serial==0:_toast("Could not save the refill request. Check device storage.");return
	request_token+=1
	var token: int=request_token
	reward_pending=true;ad_resume_gate=true;_gate_ui()
	services.reward_requested("energy_refill",_energy_callback.bind(token,serial))

func _energy_callback(earned: bool,token: int,serial: int) -> void:
	if settled_tokens.has(token):return
	settled_tokens[token]=true
	if token!=request_token or scene_page!="home":return
	reward_pending=false;ad_resume_gate=true
	var granted: bool=profile.settle_energy_reward(serial,earned)
	_wallet();_gate_ui()
	_toast("Energy restored to full. Resume when ready." if granted else "No energy granted. Ordinary timed recharge continues.")
