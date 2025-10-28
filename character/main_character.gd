extends CharacterBody2D

@export var speed: float = 1000.0
@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D

var last_move_vector: Vector2 = Vector2(0, 1)

func _physics_process(_delta: float) -> void:
	var input_vector = Vector2.ZERO
	
	if Input.is_action_pressed("ui_right"):
		input_vector.x += 1
	if Input.is_action_pressed("ui_left"):
		input_vector.x -= 1
	if Input.is_action_pressed("ui_down"):
		input_vector.y += 1
	if Input.is_action_pressed("ui_up"):
		input_vector.y -= 1

	velocity = input_vector.normalized() * speed
	move_and_slide()

	update_animation(input_vector)

func update_animation(input_vector: Vector2) -> void:
	var new_anim: String

	if input_vector != Vector2.ZERO:
		last_move_vector = input_vector
		
		if input_vector.y < 0:
			new_anim = "walk_up"
		elif input_vector.y > 0:
			new_anim = "walk_down"
		else:
			new_anim = "walk_side"
	else:
		if last_move_vector.y < 0:
			new_anim = "idle_up"
		elif last_move_vector.y > 0:
			new_anim = "idle_down"
		else:
			new_anim = "idle_side"

	if last_move_vector.x != 0:
		anim_sprite.flip_h = last_move_vector.x < 0

	if anim_sprite.animation != new_anim:
		anim_sprite.play(new_anim)
