class_name EnemyBase
extends CharacterBody2D

@export var health: int = 60 # Ajustado para o Goblin aguentar 3 hits de 20
@export var speed: float = 80.0
@export var drop_item_scene: PackedScene 

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var health_bar: ProgressBar = $HealthBar

enum State {IDLE, CHASING, ATTACKING, HURT, DEAD}
var current_state: State = State.IDLE

var player = null

func _ready():
	# Adiciona ao grupo Enemy para ser detectado pelo player
	add_to_group("Enemy")
	
	# Conecta animações
	animated_sprite.animation_finished.connect(_on_animation_finished)
	
	# Atualiza a barra ao iniciar
	_initialize_healthbar()

func _initialize_healthbar():
	if health_bar:
		health_bar.max_value = health
		health_bar.value = health
		health_bar.visible = false  # barra some até levar dano (fica mais bonito)

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

# ------------------------
#     ESTADOS "BASE"
# ------------------------
func _idle_state(_delta: float):
	play_animation("idle_side")

func _chasing_state(_delta: float):
	pass

func _attacking_state(_delta: float):
	pass

func _hurt_state(_delta: float):
	velocity = Vector2.ZERO
	play_animation("hurt")

# -------------------------------------
#      SISTEMA DE DANO + HEALTHBAR
# -------------------------------------
func take_damage(amount: int):
	if current_state == State.DEAD:
		return
		
	health -= amount
	print("[Enemy LOG] Inimigo tomou %d de dano. Vida restante: %d" % [amount, health])
	
	_update_healthbar()

	if health <= 0:
		change_state(State.DEAD)
	else:
		change_state(State.HURT)

func _update_healthbar():
	if not health_bar:
		return
	
	# Atualiza vida visual
	health_bar.value = max(health, 0)

	# Mostra a barra quando tomar dano
	if health < health_bar.max_value:
		health_bar.visible = true

	# Se quiser que desapareça quando estiver cheio novamente:
	if health >= health_bar.max_value:
		health_bar.visible = false

# -------------------------------------
#            TROCA DE ESTADOS
# -------------------------------------
func change_state(new_state: State):
	current_state = new_state
	
	if new_state == State.DEAD:
		velocity = Vector2.ZERO
		$CollisionShape2D.set_deferred("disabled", true)
		play_animation("dead")
		_drop_item()

func play_animation(anim_name: String):
	if animated_sprite.animation != anim_name:
		animated_sprite.play(anim_name)

func _on_animation_finished():
	if current_state == State.DEAD:
		if animated_sprite.animation == "dead":
			print("[Enemy LOG] Inimigo morreu e vai desaparecer.")
			queue_free()
			
	elif current_state == State.HURT:
		if animated_sprite.animation == "hurt":
			if player:
				change_state(State.CHASING)
			else:
				change_state(State.IDLE)

# -------------------------------------
#              DROP DE ITEM
# -------------------------------------
func _drop_item():
	if drop_item_scene:
		var item_instance = drop_item_scene.instantiate()
		item_instance.global_position = global_position
		get_tree().current_scene.call_deferred("add_child", item_instance)
		print("[Enemy LOG] Item dropado!")
