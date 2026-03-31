extends Node3D

const TIME_LIMIT = 60.0

var îs_game_won : bool = false
var time_remaining : float = TIME_LIMIT
var last_second : int = int(TIME_LIMIT)

@onready var timer_label : Label3D = $Player/XRCamera3D/TimerLabel

func _process(delta):
	if get_tree().get_nodes_in_group("rats").size() == 0:
		îs_game_won = true

	if îs_game_won:
		get_tree().change_scene_to_file("res://scenes/GameWon.tscn")

	time_remaining -= delta
	var seconds = max(0, int(ceil(time_remaining)))
	if seconds != last_second:
		last_second = seconds
		timer_label.text = "Time: %02d" % seconds
		if seconds <= 10:
			timer_label.modulate = Color.RED
	if time_remaining <= 0.0:
		get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_death_area_body_entered(body):
	if body.name.contains("Rat"):
		body.is_alive = false
		body.queue_free()
		
		%ScoreLabel.increase_score()


func _on_trash_area_body_entered(body):
	if body.name.contains("Rat"):
		body.is_inside_trash_area = true
		print("rat is inside trash area")
