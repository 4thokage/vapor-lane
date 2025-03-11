class_name SettingsUI 
extends Control

var awaiting_input : bool = false
var is_pop_up : bool = false
@onready var pomo_time_box: SpinBox = %PomoTimeBox
@onready var small_break_time_box: SpinBox = %SmallBreakTimeBox
@onready var big_break_time_box: SpinBox = %BigBreakTimeBox
@onready var auto_advance_flag: CheckBox = %AutoAdvanceFlag

signal reload_ui

func _ready() -> void:
	pomo_time_box.value = SettingsData.pomodoro["pomodoro_time"]
	small_break_time_box.value = SettingsData.pomodoro["small_break_time"]
	big_break_time_box.value = SettingsData.pomodoro["big_break_time"]
	auto_advance_flag.set_pressed_no_signal(SettingsData.pomodoro["auto_advance"])

func _on_quit_btn_pressed() -> void:
	get_tree().paused = false
	self.visible = false

#save and quit
func _on_save_button_pressed() -> void:
	SettingsData.save_settings()
	_on_quit_btn_pressed()
	reload_ui.emit()


func _on_pomo_time_box_value_changed(value: float) -> void:
	SettingsData.pomodoro["pomodoro_time"] = value


func _on_small_break_time_box_value_changed(value: float) -> void:
	SettingsData.pomodoro["small_break_time"] = value
