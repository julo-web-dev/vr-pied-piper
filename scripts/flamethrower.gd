extends Node3D

const FIRE_DPS := 100.0

@onready var particles: GPUParticles3D = $FireParticles
@onready var fire_area: Area3D = $FireArea

var _controller: XRController3D
var _is_firing: bool = false
var _hitting_rats: bool = false
var _rumble_event: XRToolsRumbleEvent


func _ready() -> void:
	_controller = get_parent() as XRController3D
	particles.emitting = false
	fire_area.monitoring = false

	_rumble_event = XRToolsRumbleEvent.new()
	_rumble_event.magnitude = 0.4
	_rumble_event.indefinite = true


func _process(delta: float) -> void:
	var should_fire: bool
	if _controller and _controller.get_is_active():
		should_fire = _controller.get_float("trigger") > 0.5
	else:
		should_fire = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)

	if should_fire != _is_firing:
		_is_firing = should_fire
		particles.emitting = _is_firing
		fire_area.monitoring = _is_firing
		if not _is_firing:
			_stop_rumble()

	if _is_firing:
		_burn_rats(delta)


func _burn_rats(delta: float) -> void:
	var hit_any := false
	var damage := FIRE_DPS * delta
	for body in fire_area.get_overlapping_bodies():
		if body.is_in_group("rats") and body.has_method("take_damage"):
			body.take_damage(damage)
			hit_any = true

	if hit_any and not _hitting_rats:
		_hitting_rats = true
		if _controller and _controller.get_is_active():
			XRToolsRumbleManager.add("flamethrower", _rumble_event, [&"right_hand"])
	elif not hit_any and _hitting_rats:
		_stop_rumble()


func _stop_rumble() -> void:
	_hitting_rats = false
	XRToolsRumbleManager.clear("flamethrower", [&"right_hand"])
