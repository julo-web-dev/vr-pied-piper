@tool
extends XRToolsPickable

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var root_node: Node3D = $Sketchfab_Scene/Sketchfab_model/RAT_fbx/Object_2/RootNode
@onready var animation_player: AnimationPlayer = $Sketchfab_Scene/AnimationPlayer

@export var is_inside_music_area: bool = false
@export var is_inside_trash_area: bool = false
@export var is_alive: bool = true

const MOVE_SPEED := 1.6
const GRAVITY := 9.8
const TURN_SPEED := 8.0
const MAX_HEALTH := 100.0
const HEALTH_BAR_WIDTH := 0.4
const HEALTH_BAR_HEIGHT := 0.05

var _player: Node3D
var health: float = MAX_HEALTH
var _burn_cooldown: float = 0.0
var _burn_particles: GPUParticles3D
var _health_bar_container: Node3D
var _health_bar_fg: MeshInstance3D
var _fg_material: StandardMaterial3D

func _ready() -> void:
	super._ready()
	_player = _find_player()

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if not is_alive:
		return
	if is_picked_up():
		linear_velocity = Vector3.ZERO
		return

	if _burn_cooldown > 0.0:
		_burn_cooldown -= delta
		if _burn_particles and _burn_cooldown <= 0.0:
			_burn_particles.emitting = false

	var lv := linear_velocity
	lv.y -= GRAVITY * delta

	if is_inside_music_area and is_instance_valid(_player):
		nav_agent.target_position = _player.global_position
		var next_pos := nav_agent.get_next_path_position()
		var to_next := Vector3(next_pos.x - global_position.x, 0.0, next_pos.z - global_position.z)
		if to_next.length() > 0.1:
			var move_dir := to_next.normalized()
			lv.x = move_dir.x * MOVE_SPEED
			lv.z = move_dir.z * MOVE_SPEED
			root_node.rotation.y = lerpf(root_node.rotation.y, atan2(move_dir.x, move_dir.z), TURN_SPEED * delta)
		else:
			lv.x = move_toward(lv.x, 0.0, MOVE_SPEED * delta)
			lv.z = move_toward(lv.z, 0.0, MOVE_SPEED * delta)
	else:
		lv.x = move_toward(lv.x, 0.0, MOVE_SPEED * delta)
		lv.z = move_toward(lv.z, 0.0, MOVE_SPEED * delta)

	linear_velocity = lv

	if Vector2(lv.x, lv.z).length() > 0.05:
		animation_player.play("Run")
	else:
		animation_player.stop()

func pick_up(by: Node3D) -> void:
	super.pick_up(by)
	linear_velocity = Vector3.ZERO

func let_go(by: Node3D, p_linear_velocity: Vector3, p_angular_velocity: Vector3) -> void:
	linear_velocity = p_linear_velocity
	super.let_go(by, p_linear_velocity, p_angular_velocity)

func take_damage(amount: float) -> void:
	if not is_alive:
		return
	health -= amount
	_burn_cooldown = 0.3

	if not _burn_particles:
		_create_burn_particles()
	_burn_particles.emitting = true

	if not _health_bar_container:
		_create_health_bar()
	_update_health_bar()

	if health <= 0.0:
		die()


func _create_burn_particles() -> void:
	var material := ParticleProcessMaterial.new()
	material.direction = Vector3(0, 1, 0)
	material.spread = 35.0
	material.initial_velocity_min = 0.3
	material.initial_velocity_max = 0.8
	material.gravity = Vector3.ZERO
	material.scale_min = 0.03
	material.scale_max = 0.1

	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	gradient.colors = PackedColorArray([
		Color(1, 0.9, 0.3, 1),
		Color(1, 0.3, 0, 0.8),
		Color(0.3, 0.05, 0, 0),
	])
	var grad_tex := GradientTexture1D.new()
	grad_tex.gradient = gradient
	material.color_ramp = grad_tex

	var quad := QuadMesh.new()
	quad.size = Vector2(0.08, 0.08)
	var mat3d := StandardMaterial3D.new()
	mat3d.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat3d.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat3d.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat3d.vertex_color_use_as_albedo = true
	mat3d.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	quad.material = mat3d

	_burn_particles = GPUParticles3D.new()
	_burn_particles.process_material = material
	_burn_particles.draw_pass_1 = quad
	_burn_particles.amount = 32
	_burn_particles.lifetime = 0.4
	_burn_particles.position = Vector3(0, 0.15, 0)
	_burn_particles.emitting = false
	add_child(_burn_particles)


func _create_health_bar() -> void:
	_health_bar_container = Node3D.new()
	_health_bar_container.position = Vector3(0, 0.4, 0)
	add_child(_health_bar_container)

	var bg_mesh := QuadMesh.new()
	bg_mesh.size = Vector2(HEALTH_BAR_WIDTH, HEALTH_BAR_HEIGHT)
	var bg_mat := StandardMaterial3D.new()
	bg_mat.albedo_color = Color(0.15, 0.15, 0.15, 0.8)
	bg_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bg_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bg_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	bg_mat.no_depth_test = true
	bg_mesh.material = bg_mat
	var bg := MeshInstance3D.new()
	bg.mesh = bg_mesh
	_health_bar_container.add_child(bg)

	_fg_material = StandardMaterial3D.new()
	_fg_material.albedo_color = Color.GREEN
	_fg_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_fg_material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	_fg_material.no_depth_test = true
	_fg_material.render_priority = 1
	var fg_mesh := QuadMesh.new()
	fg_mesh.size = Vector2(HEALTH_BAR_WIDTH, HEALTH_BAR_HEIGHT)
	fg_mesh.material = _fg_material
	_health_bar_fg = MeshInstance3D.new()
	_health_bar_fg.mesh = fg_mesh
	_health_bar_container.add_child(_health_bar_fg)


func _update_health_bar() -> void:
	var ratio := clampf(health / MAX_HEALTH, 0.0, 1.0)
	_health_bar_fg.scale.x = ratio
	_health_bar_fg.position.x = (HEALTH_BAR_WIDTH / 2.0) * (ratio - 1.0)
	if ratio > 0.5:
		_fg_material.albedo_color = Color.GREEN.lerp(Color.YELLOW, (1.0 - ratio) * 2.0)
	else:
		_fg_material.albedo_color = Color.YELLOW.lerp(Color.RED, (0.5 - ratio) * 2.0)


func die() -> void:
	if not is_alive:
		return
	is_alive = false
	if is_picked_up():
		drop()
	queue_free()

func _find_player() -> Node3D:
	var parent := get_parent()
	if parent:
		return parent.get_node_or_null("Player") as Node3D
	return null
