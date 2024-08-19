extends CharacterBody2D
class_name Player

@onready var animation = $AnimationPlayer
@onready var sprite = $Sprite2D
@onready var left_raycast = $LeftRayCast
@onready var right_raycast = $RightRayCast

@export var move_speed = 200.0
@export var attacking = false

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

var max_health = 2
var health = 0
var can_take_damage = true
@export var hit = false

var movement_velocity := Vector2.ZERO

@export var jump_height : float = 300.0
@export var jump_time_to_peak : float = 0.5
@export var jump_time_to_descent : float = 0.5

@onready var jump_velocity : float = ((2.0 * jump_height) / jump_time_to_peak) * -1.0
@onready var jump_gravity : float = ((-2.0 * jump_height) / (jump_time_to_peak * jump_time_to_peak)) * -1.0
@onready var fall_gravity : float = ((-2.0 * jump_height) / (jump_time_to_descent * jump_time_to_descent)) * -1.0

var wall_jump_force : float = 900.0
var wall_jump_cooldown : float = 0.6  # Increased cooldown period
var wall_jump_timer : float = 0.0
var wall_contact_duration : float = 0.0
var wall_jump_cooldown_timer : float = 0.0
var wall_disable_duration : float = 0.2  # Duration to disable raycast
var left_raycast_disabled : bool = false
var right_raycast_disabled : bool = false
var can_wall_jump : bool = false

func _ready():
	GameManager.damage_taken = 0
	health = max_health
	GameManager.player = self

func _process(delta):
	if Input.is_action_just_pressed("attack") and not hit:
		attack()

	if wall_jump_cooldown_timer > 0:
		wall_jump_cooldown_timer -= delta

	# Re-enable raycasts if their disable duration has expired
	if left_raycast_disabled:
		if wall_disable_duration > 0:
			wall_disable_duration -= delta
		else:
			left_raycast.enabled = true
			left_raycast_disabled = false
			print("Left raycast re-enabled")

	if right_raycast_disabled:
		if wall_disable_duration > 0:
			wall_disable_duration -= delta
		else:
			right_raycast.enabled = true
			right_raycast_disabled = false
			print("Right raycast re-enabled")

	# Reset wall jump status if not touching walls
	if not (left_raycast.is_colliding() or right_raycast.is_colliding()):
		can_wall_jump = false
		wall_contact_duration = 0.0
	else:
		wall_contact_duration += delta

	# Ensure wall jump cooldown
	if wall_jump_timer > 0:
		wall_jump_timer -= delta

	if is_on_floor():
		can_wall_jump = false

func _physics_process(delta):
	velocity.y += get_gravity() * delta
	velocity.x = get_input_velocity() * move_speed

	var on_left_wall = left_raycast.is_colliding()
	var on_right_wall = right_raycast.is_colliding()
	var is_on_wall = on_left_wall or on_right_wall

	if is_on_wall and not is_on_floor():
		can_wall_jump = true

		if Input.is_action_just_pressed("jump") and wall_jump_timer <= 0 and wall_jump_cooldown_timer <= 0:
			wall_jump(on_left_wall, on_right_wall)
	
	if Input.is_action_just_pressed("jump") and is_on_floor():
		jump()
	
	move_and_slide()
	
	update_animation()
	
	if position.y >= 700:
		die()

func get_gravity() -> float:
	return jump_gravity if velocity.y < 0.0 else fall_gravity

func jump():
	velocity.y = jump_velocity
	wall_jump_timer = 0  # Reset wall jump timer on ground jump

func wall_jump(on_left_wall: bool, on_right_wall: bool):
	if can_wall_jump:
		if on_left_wall:
			sprite.scale.x = abs(sprite.scale.x)
			velocity.x = wall_jump_force
			left_raycast.enabled = false
			left_raycast_disabled = true
		elif on_right_wall:
			sprite.scale.x = abs(sprite.scale.x) * -1
			velocity.x = -wall_jump_force
			right_raycast.enabled = false
			right_raycast_disabled = true

		velocity.y = jump_velocity
		wall_jump_timer = wall_jump_cooldown
		wall_jump_cooldown_timer = wall_jump_cooldown  # Start cooldown timer

		# Reset raycast disable duration
		wall_disable_duration = 1  # Duration for raycast disable

		# Re-enable the opposite raycast if it detects a wall
		if on_left_wall and right_raycast.is_colliding():
			right_raycast.enabled = true
			right_raycast_disabled = false
			print("Right raycast re-enabled due to wall detection")

		if on_right_wall and left_raycast.is_colliding():
			left_raycast.enabled = true
			left_raycast_disabled = false
			print("Left raycast re-enabled due to wall detection")



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
			area.get_parent().get_hit(self)
	
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
		velocity.x = 0
		animation.play("Hit")
		await get_tree().create_timer(0.3).timeout
		
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
