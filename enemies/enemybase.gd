# EnemyBase.gd
class_name EnemyBase
extends CharacterBody2D

@export var health: int = 60 # Ajustado para o Goblin aguentar 3 hits de 20
@export var speed: float = 80.0
@export var drop_item_scene: PackedScene 

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

enum State {IDLE, CHASING, ATTACKING, HURT, DEAD}
var current_state: State = State.IDLE

var player = null

func _ready():
	# Adicione o Goblin ao grupo "Enemy" para o player detectá-lo
	add_to_group("Enemy")
	# Conectar sinal para saber quando animação de morte ou dano acaba
	animated_sprite.animation_finished.connect(_on_animation_finished)

func _physics_process(delta: float) -> void:
	# Se estiver morto, não faz nada, só espera sumir
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

# Estados Virtuais (sobrescritos pelo filho)
func _idle_state(_delta: float): play_animation("idle_side")
func _chasing_state(_delta: float): pass
func _attacking_state(_delta: float): pass

func _hurt_state(_delta: float):
	# Enquanto está machucado, fica parado
	velocity = Vector2.ZERO
	play_animation("hurt")

func take_damage(amount: int):
	if current_state == State.DEAD:
		return
		
	health -= amount
	print("[Enemy LOG] Inimigo tomou %d de dano. Vida restante: %d" % [amount, health])
	
	if health <= 0:
		change_state(State.DEAD)
	else:
		change_state(State.HURT)

func change_state(new_state: State):
	current_state = new_state
	
	if new_state == State.DEAD:
		
		# Lógica de morte
		velocity = Vector2.ZERO
		# Desabilita colisões para não atrapalhar o player enquanto toca a animação
		$CollisionShape2D.set_deferred("disabled", true) 
		play_animation("dead") # Certifique-se de ter essa animação
		_drop_item()

func play_animation(anim_name: String):
	if animated_sprite.animation != anim_name:
		animated_sprite.play(anim_name)

func _on_animation_finished():
	if current_state == State.DEAD:
		if animated_sprite.animation == "dead":
			print("[Enemy LOG] Inimigo morreu e vai desaparecer.")
			queue_free() # Remove o Goblin do jogo
			
	elif current_state == State.HURT:
		if animated_sprite.animation == "hurt":
			# Se sobreviveu ao dano, volta a perseguir ou idle
			if player:
				change_state(State.CHASING)
			else:
				change_state(State.IDLE)
				
func _drop_item():
	if drop_item_scene:
		# Instancia o item
		var item_instance = drop_item_scene.instantiate()
		
		# Define a posição do item igual à do inimigo
		item_instance.global_position = global_position
		
		# Adiciona o item na cena do jogo (não dentro do inimigo, senão some junto)
		get_tree().current_scene.call_deferred("add_child", item_instance)
		print("[Enemy LOG] Item dropado!")
