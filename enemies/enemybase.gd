class_name EnemyBase
extends CharacterBody2D

@export var health: int = 100
@export var speed: float = 80.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

enum State {IDLE, CHASING, ATTACKING, HURT, DEAD}
var current_state: State = State.IDLE

var player = null

func _physics_process(delta: float) -> void:
	if current_state == State.DEAD:
		return

	match current_state:
		State.IDLE:
			_idle_state(delta)
		State.CHASING:
			_chasing_state(delta)
		State.ATTACKING:
			_attacking_state(delta)
		State.HURT:
			_hurt_state(delta)
			
	move_and_slide()


func _idle_state(_delta: float):
	play_animation("idle_side")

func _chasing_state(_delta: float):
	pass

func _attacking_state(_delta: float):
	pass

func _hurt_state(_delta: float):
	pass

func take_damage(amount: int):
	if current_state == State.DEAD or current_state == State.HURT:
		return
		
	health -= amount
	if health <= 0:
		change_state(State.DEAD)
	else:
		change_state(State.HURT)

func change_state(new_state: State):
	current_state = new_state

func play_animation(anim_name: String):
	if animated_sprite.animation != anim_name:
		animated_sprite.play(anim_name)
