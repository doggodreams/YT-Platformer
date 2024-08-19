extends CharacterBody2D
class_name Player

@onready var animation = $AnimationPlayer
@onready var sprite = $Sprite2D


@export var move_speed = 200.0  # New movement speed for horizontal movement

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

func _ready():
	GameManager.damage_taken = 0
	health = max_health
	GameManager.player = self

func _process(_delta):
	if Input.is_action_just_pressed("attack") and not hit:
		attack()

func _physics_process(delta):
	velocity.y += get_gravity() * delta
	velocity.x = get_input_velocity() * move_speed
	
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
