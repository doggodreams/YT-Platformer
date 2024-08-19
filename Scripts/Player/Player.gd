extends CharacterBody2D
class_name Player

@onready var animation = $AnimationPlayer
@onready var sprite = $Sprite2D

@export var speed = 300.0
@export var jump_velocity = -400.0

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@export var attacking = false

var max_health = 2
var health = 0
var can_take_damage = true
@export var hit = false

func _ready():
	GameManager.damage_taken = 0
	health = max_health
	GameManager.player = self

func _process(_delta):
	if Input.is_action_just_pressed("attack") and not hit:
		attack()

func _physics_process(delta):
	if Input.is_action_just_pressed("left"):
		sprite.scale.x = abs(sprite.scale.x) * -1
		$AttackArea.scale.x = abs($AttackArea.scale.x) * -1
	if Input.is_action_just_pressed("right"):
		sprite.scale.x = abs(sprite.scale.x)
		$AttackArea.scale.x = abs($AttackArea.scale.x)
	
	if not is_on_floor():
		velocity.y += gravity * delta
	
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity
	
	if Input.is_action_pressed("down") and is_on_floor():
		position.y += 5
	
	var direction = Input.get_axis("left", "right")
	if direction:
		velocity.x = direction * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
	
	update_animation()
	move_and_slide()
	
	if position.y >= 700:
		die()

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

