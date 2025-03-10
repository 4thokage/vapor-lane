extends Control

@onready var radio = $Radio
@onready var label_radio_name: Label = $CanvasLayer/MarginContainer/VBoxContainer/LabelRadioName
@onready var label_radio_desc: Label = $CanvasLayer/MarginContainer/VBoxContainer/LabelRadioDesc
@onready var label: Label = %TimerLabel
@onready var timer: Timer = $Timer
@onready var play_pause_btn: Button = $CanvasLayer/PomodoroContainer/PlayPauseBtn
@export var pomodoro_time: int = 1500
@export var small_break_time: int = 300
@onready var car_sounds: AudioStreamPlayer = $CarSounds
@onready var rain_sounds: AudioStreamPlayer = $RainSounds

var is_focus = true
var is_small_break = false

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("mute_radio"):
		if radio.playing:
			radio.stop_radio()
		else:
			radio.play_radio()

func _ready() -> void:
	radio.station_is_changed.connect(update_info)
	radio.started.connect(update_info)
	radio.play_radio()
	timer.wait_time = pomodoro_time
	timer.start()

func _process(delta: float) -> void:
	update_timer_display()
	
func update_info() -> void:
	label_radio_desc.text = radio.get_station_name()
	label_radio_name.text = radio.get_station_description()

func _on_button_next_pressed() -> void:
	radio.switch_to_next()

func _on_button_prev_pressed() -> void:
	radio.switch_to_prev()

func update_timer_display() -> void:
	var time_left = int(timer.time_left)  # Get remaining time in seconds
	var minutes = time_left / 60
	var seconds = time_left % 60
	label.text = "%02d:%02d" % [minutes, seconds]  # Format as MM:SS


func _on_pause_pressed() -> void:
	timer.paused = !timer.paused
	if(play_pause_btn.text == "Start"):
		play_pause_btn.text = "Pause"
	else:
		play_pause_btn.text = "Start"


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
	is_focus = !is_focus
	if(!is_focus):
		timer.wait_time = small_break_time
		timer.start()
		label.add_theme_color_override("font_color", Color(0, 1, 0))
	else:
		timer.wait_time = pomodoro_time
		timer.start()
		label.add_theme_color_override("font_color", Color(1, 0, 0))
