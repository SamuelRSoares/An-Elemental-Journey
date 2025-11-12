# main_character.gd
extends CharacterBody2D

# --- Constantes e Exportações ---
@export var speed: float = 200.0
@export var max_health: int = 100

# --- Controle de Knockback ---
var knockback_vector: Vector2 = Vector2.ZERO
var knockback_timer: float = 0.0
@export var knockback_duration: float = 0.2
@export var knockback_strength: float = 300.0

# --- Efeito visual de dano ---
var is_taking_damage: bool = false
@export var damage_flash_time: float = 0.1

# --- Sinais (Comunicação Externa) ---
# Anuncia quando a vida do jogador muda. A cena principal vai ouvir este sinal.
signal health_changed(new_health)

# --- Referências de Nós (@onready) ---
@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D

# REMOVIDO: A referência direta à HealthBar. O jogador não precisa mais conhecê-la.
# @onready var health_bar: HealthBar = $HealthBar 

# --- Variáveis de Estado ---
var current_health: int
var last_move_vector: Vector2 = Vector2(0, 1)

# A função _ready agora é mais simples.
func _ready():
	print("[Player LOG] Player inicializando...")
	current_health = max_health
	print("[Player LOG] Vida definida para: %d / %d" % [current_health, max_health])
	
	# REMOVIDO: Todo o bloco de conexão da barra de vida.
	# Isso agora é responsabilidade da cena principal.

# O resto do seu código (physics_process, update_animation, etc.) permanece exatamente o mesmo.
# =========================================================================================

func _physics_process(_delta: float) -> void:
	if current_health <= 0:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	# --- Aplicar knockback se estiver ativo ---
	if knockback_timer > 0.0:
		velocity = knockback_vector
		move_and_slide()
		knockback_timer -= _delta
		return

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

func take_damage(amount: int, source_position: Vector2 = position):
	if current_health <= 0:
		return

	var old_health = current_health
	current_health = max(0, current_health - amount)
	print("[Player LOG] Recebeu %d de dano. Vida: %d -> %d" % [amount, old_health, current_health])

	# --- Knockback ---
	knockback_vector = (position - source_position).normalized() * knockback_strength
	knockback_timer = knockback_duration

	# --- Flash vermelho ---
	is_taking_damage = true
	anim_sprite.modulate = Color(1, 0.4, 0.4)  # levemente avermelhado
	get_tree().create_timer(damage_flash_time).timeout.connect(func ():
		anim_sprite.modulate = Color(1, 1, 1)
		is_taking_damage = false
	)

	health_changed.emit(current_health)

	if current_health <= 0:
		handle_death()

func handle_death():
	print("[Player LOG] O jogador morreu!")
