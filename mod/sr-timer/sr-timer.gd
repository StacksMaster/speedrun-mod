extends Node

signal world_initialized
signal game_loaded

const MOD_ID = "sr-timer"

enum TimerModes {
	ON_INPUT,
	ON_LOAD,
	ON_KEY
}

var current_scene_name: String = ""
var mode: TimerModes = TimerModes.ON_LOAD
var real_time: float = 0.0

var is_world_init: bool = false
var is_game_loaded: bool = false
var run_finish: bool = false
var fire_start: bool = false
var igt_fire: bool = false

var timer_ui_scene: PackedScene = preload("res://mod/sr-timer/scenes/TimerUI.tscn")
var timer_ui_instance: Control = null

var rta_label: Label = null
var igt_label: Label = null

func _mod_setting_update(_setting_id: String, _new_value: Variant) -> Dictionary:
	mode = _new_value as TimerModes
	DuckLoader.log_message("[SR-MOD] Timer mode updated to: " + str(mode))
	return {"valid": true}

func _ready() -> void:
	get_tree().tree_changed.connect(_on_tree_changed)
	
	timer_ui_instance = timer_ui_scene.instantiate() as Control
	rta_label = timer_ui_instance.get_node_or_null("PanelContainer/Root/Timers/RTA") as Label
	igt_label = timer_ui_instance.get_node_or_null("PanelContainer/Root/Timers/IGT") as Label
	
	get_tree().root.add_child.call_deferred(timer_ui_instance)
	DuckLoader.log_message("[SR-MOD] Mod loaded successfully")

func _process(delta: float) -> void:
	if is_world_init and fire_start and not run_finish:
		real_time += delta
		
		if is_instance_valid(rta_label):
			rta_label.text = get_real_time_formatted()
		
		if is_instance_valid(igt_label) and igt_fire:
			igt_label.text = get_in_game_time_formatted()

func _unhandled_input(event: InputEvent) -> void:
	if fire_start or mode != TimerModes.ON_INPUT:
		return
		
	var has_moved: bool = Input.get_vector("move_left", "move_right", "move_up", "move_down") != Vector2.ZERO
	var has_jumped: bool = event.is_action_pressed("jump")
	
	if has_jumped or has_moved:
		_start_timer(false)

func _on_tree_changed() -> void:
	var active_scene = get_tree().current_scene
	if active_scene and active_scene.name != current_scene_name:
		current_scene_name = active_scene.name
		_on_scene_changed(active_scene)

func _on_scene_changed(new_scene: Node) -> void:
	match new_scene.name:
		"World":
			_reset_timer()
			is_world_init = true
			world_initialized.emit()
			DuckLoader.log_message("World initialized: " + GameState.get_play_time_formatted())
			
			if mode == TimerModes.ON_LOAD:
				_start_timer(false)
				
		"MainMenu":
			_reset_timer()
			is_world_init = false
			is_game_loaded = true
			game_loaded.emit()
			DuckLoader.log_message("Main menu loaded")

func _start_timer(force: bool) -> void:
	if force or not fire_start:
		fire_start = true
		igt_fire = true
		DuckLoader.log_message("Speedrun Timer Started")

func _reset_timer() -> void:
	real_time = 0.0
	fire_start = false
	igt_fire = false
	run_finish = false

func get_real_time_formatted() -> String:
	var total_sec: int = int(real_time)
	var hours: int = total_sec / 3600
	var minutes: int = (total_sec % 3600) / 60
	var seconds: int = total_sec % 60
	var milliseconds: int = int((real_time - float(total_sec)) * 1000.0)
	
	if hours > 0:
		return "%02d:%02d:%02d.%03d" % [hours, minutes, seconds, milliseconds]
	return "%02d:%02d.%03d" % [minutes, seconds, milliseconds]

func get_in_game_time_formatted() -> String:
	var igt = GameState.total_play_time
	var total_sec: int = int(igt)
	var hours: int = total_sec / 3600
	var minutes: int = (total_sec % 3600) / 60
	var seconds: int = total_sec % 60
	var milliseconds: int = int((igt - float(total_sec)) * 1000.0)
	
	if hours > 0:
		return "%02d:%02d:%02d.%03d" % [hours, minutes, seconds, milliseconds]
	return "%02d:%02d.%03d" % [minutes, seconds, milliseconds]
