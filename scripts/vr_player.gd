extends XROrigin3D

## VR player controller that replaces the desktop CharacterBody3D player.
## Handles XR-specific logic while preserving the music area mechanic
## for attracting rats. Falls back to WASD + mouse when VR is not active.

const SPEED = 5.0
const MOUSE_SENSITIVITY = 0.002

@onready var camera: XRCamera3D = $XRCamera3D
@onready var left_controller: XRController3D = $LeftController
@onready var right_controller: XRController3D = $RightController
@onready var player_body: XRToolsPlayerBody = $PlayerBody
@onready var music_area: Area3D = $PlayerBody/MusicArea

var _pitch: float = 0.0


func _ready() -> void:
	await get_tree().process_frame
	if not XRToolsStartXR.is_xr_active():
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _unhandled_input(event: InputEvent) -> void:
	if XRToolsStartXR.is_xr_active():
		return

	if event is InputEventMouseMotion:
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
			_pitch = clampf(_pitch - event.relative.y * MOUSE_SENSITIVITY, -PI / 3.0, PI / 3.0)
			camera.rotation.x = _pitch

	if event.is_action_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _physics_process(delta: float) -> void:
	if XRToolsStartXR.is_xr_active():
		return

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (global_basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()
	global_position += direction * SPEED * delta

	right_controller.global_transform = camera.global_transform
	right_controller.global_position += camera.global_basis * Vector3(0.2, -0.1, -0.2)


func _on_music_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("rats"):
		body.is_inside_music_area = true


func _on_music_area_body_exited(body: Node3D) -> void:
	if body.is_in_group("rats"):
		body.is_inside_music_area = false
