extends Node3D

const TIME_LIMIT := 60.0
const RAT_COUNT := 10
const RAT_SCENE := preload("res://scenes/Rat.tscn")
const SPAWN_AREA_MIN := Vector3(-20.0, 0.67, -20.0)
const SPAWN_AREA_MAX := Vector3(20.0, 0.67, 20.0)

var game_over: bool = false
var game_won: bool = false
var time_remaining: float = TIME_LIMIT
var last_second: int = int(TIME_LIMIT)
var score: int = 0

@onready var timer_label: Label3D = $Player/XRCamera3D/TimerLabel
@onready var score_label: Label3D = $Player/XRCamera3D/ScoreLabel

func _ready() -> void:
	randomize()
	_spawn_rats()
	score_label.text = "Score: 0"
	timer_label.text = "Time: %02d" % int(TIME_LIMIT)

func _spawn_rats() -> void:
	# Remove pre-placed rats if any exist in the scene.
	for child in get_children():
		if child is Node3D and child.is_in_group("rats"):
			child.queue_free()

	for i in range(RAT_COUNT):
		var rat := RAT_SCENE.instantiate()
		rat.name = "Rat_%d" % i
		add_child(rat)
		rat.global_position = Vector3(
			randf_range(SPAWN_AREA_MIN.x, SPAWN_AREA_MAX.x),
			SPAWN_AREA_MIN.y,
			randf_range(SPAWN_AREA_MIN.z, SPAWN_AREA_MAX.z)
		)
		rat.is_inside_music_area = false
		rat.is_inside_trash_area = false
		rat.tree_exiting.connect(_on_rat_killed)

func _process(delta: float) -> void:
	if game_over:
		return

	time_remaining -= delta
	var seconds := maxi(0, int(ceil(time_remaining)))
	if seconds != last_second:
		last_second = seconds
		timer_label.text = "Time: %02d" % seconds
		if seconds <= 10:
			timer_label.modulate = Color.RED

	if time_remaining <= 0.0:
		game_over = true
		get_tree().change_scene_to_file("res://scenes/Medieval_Town_1.tscn")
		return

	if get_tree().get_nodes_in_group("rats").is_empty() and not game_won:
		game_won = true
		game_over = true
		get_tree().change_scene_to_file("res://scenes/GameWon.tscn")

func _on_death_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("rats") and body.has_method("die"):
		body.die()

func _on_rat_killed() -> void:
	score += 1
	score_label.text = "Score: %d" % score

func _on_trash_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("rats"):
		body.is_inside_trash_area = true
