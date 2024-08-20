extends CharacterBody2D
class_name Player

@onready var animation = $AnimationPlayer
@onready var sprite = $Sprite2D

@export var move_speed = 200.0
@export var dash_speed = 400.0
@export var dash_time = 0.2
@export var double_jump_allowed = true
@export var attacking = false

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

var max_health = 2
var health = 0
var can_take_damage = true
@export var hit = false

var movement_velocity := Vector2.ZERO

const wall_jump_pushback = 200
const wall_slide_gravity = 100

var is_wall_sliding = false
var has_double_jumped = false
var is_dashing = false
var dash_timer = 0.0

const jump_height : float = 100
const jump_time_to_peak : float = 0.5
const jump_time_to_descent : float = 0.5

# Modified double jump settings
const double_jump_height : float = 5  # Higher jump height for a bursty feel
const double_jump_time_to_peak : float = 0.02  # Shorter time to peak for a bursty feel

@onready var jump_velocity : float = ((2.0 * jump_height) / jump_time_to_peak) * -1.0
@onready var double_jump_velocity : float = ((2.0 * double_jump_height) / double_jump_time_to_peak) * -1.0
@onready var jump_gravity : float = ((-2.0 * jump_height) / (jump_time_to_peak * jump_time_to_peak)) * -1.0
@onready var double_jump_gravity : float = ((-2.0 * double_jump_height) / (double_jump_time_to_peak * double_jump_time_to_peak)) * -1.0
@onready var fall_gravity : float = ((-2.0 * jump_height) / (jump_time_to_descent * jump_time_to_descent)) * -1.0

func _ready():
	GameManager.damage_taken = 0
	health = max_health
	GameManager.player = self

func _process(_delta):
	if Input.is_action_just_pressed("attack") and not hit:
		attack()

func _physics_process(delta):
	if is_dashing:
		dash_timer -= delta
		if dash_timer <= 0.0:
			is_dashing = false
		move_and_slide()
		return
	
	velocity.x = get_input_velocity() * move_speed
	
	jump(delta)
	dash(delta)
	
	move_and_slide()
	wall_slide(delta)
	update_animation()
	
	if position.y >= 700:
		die()

func get_gravity() -> float:
	return jump_gravity if velocity.y < 0.0 else fall_gravity

func jump(delta):
	velocity.y += get_gravity() * delta
	if Input.is_action_just_pressed("jump"):
		if is_on_floor():
			velocity.y = jump_velocity
			has_double_jumped = false
		elif double_jump_allowed and not has_double_jumped:
			velocity.y = double_jump_velocity  # Use the bursty double jump velocity
			has_double_jumped = true
		elif is_on_wall() and Input.is_action_pressed("right"):
			velocity.y = jump_velocity
			velocity.x = -wall_jump_pushback
			has_double_jumped = false
		elif is_on_wall() and Input.is_action_pressed("left"):
			velocity.y = jump_velocity
			velocity.x = wall_jump_pushback
			has_double_jumped = false

func dash(delta):
	if Input.is_action_just_pressed("dash") and not is_dashing:
		is_dashing = true
		dash_timer = dash_time
		if Input.is_action_pressed("right"):
			velocity.x = dash_speed
		elif Input.is_action_pressed("left"):
			velocity.x = -dash_speed

func wall_slide(delta):
	if is_on_wall() and !is_on_floor():
		if Input.is_action_pressed("left") or Input.is_action_pressed("right"):
			is_wall_sliding = true
		else:
			is_wall_sliding = false
	else:
		is_wall_sliding = false
	
	if is_wall_sliding:
		velocity.y += (wall_slide_gravity * delta)
		velocity.y = min(velocity.y, wall_slide_gravity)		

func get_input_velocity() -> float:
	var horizontal := 0.0
	
	if Input.is_action_pressed("left"):
		horizontal -= 1.0
		sprite.scale.x = abs(sprite.scale.x) * -1
		$AttackArea.scale.x = abs($AttackArea.scale.x) * -1
	if Input.is_action_pressed("right"):
		horizontal += 1.0
		sprite.scale.x = abs(sprite.scale.x)
		$AttackArea.scale.x = abs($AttackArea.scale.x)
	
	return horizontal

func attack():
	var overlapping_objects = $AttackArea.get_overlapping_areas()
	
	for area in overlapping_objects:
		if area.get_parent().is_in_group("Enemies"):
			area.get_parent().take_damage(1)
			area.get_parent().get_hit(self)  # Pass the player as the attacker
	
	attacking = true
	animation.play("Attack")

func update_animation():
	if not attacking and not hit:
		if velocity.x != 0 and is_on_floor():
			animation.play("Run")
		elif velocity.y < 0:
			animation.play("Jump")
		elif velocity.y > 0:
			animation.play("Fall")
		else:
			animation.play("Idle")

func take_damage(damage_amount: int):
	if can_take_damage:
		iframes()
		hit = true
		attacking = false
		velocity.x = 0  # Stop movement
		animation.play("Hit")
		await get_tree().create_timer(0.3).timeout  # Recovery time
		
		GameManager.damage_taken += 1
		health -= damage_amount
		
		if health <= 0:
			die()
		else:
			hit = false

func iframes():
	can_take_damage = false
	await get_tree().create_timer(1).timeout
	can_take_damage = true

func die():
	velocity.x = 0
	animation.play("Die")
	await animation.animation_finished
	GameManager.respawn_player()
