extends CharacterBody2D
class_name Sabertooth

@export var speed = -60.0
var current_speed = 0.0

@export var score = 50

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

var facing_right = false
var dead = false

var max_health = 5
var health

var hit = false
var can_attack = true

@export var knockback_force = 100.0  # Knockback force when hit (horizontal only)
var knockback_velocity = 0.0  # Velocity for knockback

func _ready():
	health = max_health
	$AnimationPlayer.play("Run")

func _physics_process(delta):
	if not is_on_floor():
		velocity.y += gravity * delta

	if !$RayCast2D.is_colliding() and is_on_floor():
		flip()

	if hit:  # Apply knockback effect
		velocity.x = knockback_velocity
		knockback_velocity = lerp(knockback_velocity, 0.0, 5.0 * delta)  # Smoothly reduce knockback
	else:
		velocity.x = speed  # Ensure the enemy keeps moving after knockback

	move_and_slide()

func flip():
	facing_right = !facing_right
	
	scale.x = abs(scale.x) * -1
	if facing_right:
		speed = abs(speed)
	else:
		speed = abs(speed) * -1

func _on_hitbox_area_entered(area):
	if area.get_parent() is Player and !dead and can_attack:
		area.get_parent().take_damage(1)

func take_damage(damage_amount):
	if not dead:
		$AnimationPlayer.play("Hit")
		
		health -= damage_amount
		
		get_node("Healthbar").update_healthbar(health, max_health)

		if health <= 0:
			die()

func get_hit(attacker: Node):
	hit = true  # Set hit to true when hit
	current_speed = speed
	speed = 0
	can_attack = false

	# Determine direction based on the attacker's position
	if attacker.global_position.x > global_position.x:
		knockback_velocity = -knockback_force  # Knockback to the left
	else:
		knockback_velocity = knockback_force  # Knockback to the right

	# Use a timer to control the duration of the knockback effect
	var timer = Timer.new()
	timer.one_shot = true
	timer.wait_time = 0.3  # Duration of knockback
	timer.connect("timeout", _end_knockback)
	add_child(timer)
	timer.start()


func _end_knockback():
	hit = false  # Reset the hit state
	speed = current_speed  # Restore the original speed
	can_attack = true
	$AnimationPlayer.play("Run")  # Resume running animation

func die():
	GameManager.enemies_beaten += 1
	GameManager.score += score
	dead = true
	speed = 0
	$AnimationPlayer.play("Die")
