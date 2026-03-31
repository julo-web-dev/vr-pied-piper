extends Node3D

const TIME_LIMIT = 60.0

var îs_game_won : bool = false
var time_remaining : float = TIME_LIMIT

@onready var timer_label : Label = $UserInterface/TimerLabel

func _process(delta):
	if get_tree().get_nodes_in_group("rats").size() == 0:
		îs_game_won = true

	if îs_game_won:
		get_tree().change_scene_to_file("res://scenes/GameWon.tscn")

	time_remaining -= delta
	var seconds = max(0, ceil(time_remaining))
	timer_label.text = "Time: %02d" % seconds
	if time_remaining <= 10.0:
		timer_label.add_theme_color_override("font_color", Color.RED)
	if time_remaining <= 0.0:
		get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_death_area_body_entered(body):
	if body.name.contains("Rat"):
		body.is_alive = false
		body.queue_free()
		
		$UserInterface/ScoreLabel.increase_score()


func _on_trash_area_body_entered(body):
	if body.name.contains("Rat"):
		body.is_inside_trash_area = true
		print("rat is inside trash area")
