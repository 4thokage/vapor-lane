class_name HUD
extends Control

@onready var label: Label = %TimerLabel
@onready var timer: Timer = $Timer
@onready var play_pause_btn: Button = %PlayPauseBtn
var pomodoro_time: int = 10
var small_break_time: int = 3
var big_break_time: int = 7
var auto_advance: bool = true
@onready var car_sounds: AudioStreamPlayer = $CarSounds
@onready var rain_sounds: AudioStreamPlayer = $RainSounds

var is_focus = true
var is_small_break = false
var breaks_count := 0

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("mute_radio"):
		pass

func _ready() -> void:
	_on_reload_hud()
	start_pomodoro()


func _process(_delta: float) -> void:
	update_timer_display()

func start_pomodoro():
	timer.wait_time = pomodoro_time
	timer.start()

func next_pomodoro():
	is_focus = !is_focus
	if(!is_focus):
		if breaks_count % 3 == 0:
			timer.wait_time = big_break_time
		else:
			timer.wait_time = small_break_time
		timer.start()
		label.add_theme_color_override("font_color", Color(0, 1, 0))
	else:
		breaks_count += 1
		timer.wait_time = pomodoro_time
		timer.start()
		label.add_theme_color_override("font_color", Color(1, 1, 1))

func update_timer_display() -> void:
	var time_left = int(timer.time_left)  # Get remaining time in seconds
	var minutes : int = time_left / 60
	var seconds : int = time_left % 60
	label.text = "%02d:%02d" % [minutes, seconds]  # Format as MM:SS
	if time_left == 30:
		label.add_theme_color_override("font_color", Color(1, 0, 0))

func _on_reload_hud():
	pomodoro_time = SettingsData.pomodoro["pomodoro_time"] * 60
	small_break_time = SettingsData.pomodoro["small_break_time"] * 60
	big_break_time = SettingsData.pomodoro["big_break_time"] * 60
	auto_advance = SettingsData.pomodoro["auto_advance"]


func _on_car_sounds_btn_toggled(toggled_on: bool) -> void:
	if toggled_on:
		car_sounds.play()
	else:
		car_sounds.stop()


func _on_rain_btn_toggled(toggled_on: bool) -> void:
	if toggled_on:
		rain_sounds.play()
	else:
		rain_sounds.stop()

func _on_timer_timeout() -> void:
	%Horn.play()
	is_focus = !is_focus
	if auto_advance:
		next_pomodoro()
		

func _on_reset_btn_pressed() -> void:
	timer.stop()
	timer.wait_time = pomodoro_time
	timer.start()


func _on_next_btn_pressed() -> void:
	next_pomodoro()


func _on_play_pause_btn_toggled() -> void:
	timer.paused = !timer.paused
	play_pause_btn.text = "Start" if timer.paused else "Pause"
