extends XROrigin3D

## VR player controller that replaces the desktop CharacterBody3D player.
## Handles XR-specific logic while preserving the music area mechanic
## for attracting rats.

const SPEED = 5.0

@onready var camera: XRCamera3D = $XRCamera3D
@onready var left_controller: XRController3D = $LeftController
@onready var right_controller: XRController3D = $RightController
@onready var player_body: XRToolsPlayerBody = $PlayerBody
@onready var music_area: Area3D = $PlayerBody/MusicArea


func _ready() -> void:
	# PlayerBody handles gravity, collisions, and movement providers automatically
	pass


func _on_music_area_body_entered(body: Node3D) -> void:
	if body.name.contains("Rat"):
		body.is_inside_music_area = true


func _on_music_area_body_exited(body: Node3D) -> void:
	if body.name.contains("Rat"):
		body.is_inside_music_area = false
