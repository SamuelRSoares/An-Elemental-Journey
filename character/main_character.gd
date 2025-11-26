# main_character.gd
extends CharacterBody2D

# --- Constantes e Exportações ---
@export var speed: float = 200.0
@export var max_health: int = 100
@export var attack_damage: int = 20
@export var fire_damage: int = 40 # DANO DO FOGO

# --- Controle de Knockback ---
var knockback_vector: Vector2 = Vector2.ZERO
var knockback_timer: float = 0.0
@export var knockback_duration: float = 0.2
@export var knockback_strength: float = 300.0

# --- Efeito visual de dano ---
var is_taking_damage: bool = false
@export var damage_flash_time: float = 0.1

# --- Sinais ---
signal health_changed(new_health)

# --- Referências de Nós ---
@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_area: Area2D = $PlayerAttackArea 
@onready var attack_collision: CollisionShape2D = $PlayerAttackArea/CollisionShape2D

# --- Variáveis de Estado ---
var current_health: int
var last_move_vector: Vector2 = Vector2(0, 1)
var is_attacking: bool = false
var enemies_hit_this_attack: Array = [] 
var default_sprite_scale: Vector2 

# --- NOVO: Estado do Poder de Fogo ---
var has_fire_power: bool = false
var current_attack_type: String = "normal" # pode ser "normal" ou "fire"

func _ready():
	print("[Player LOG] Player inicializando...")
	current_health = max_health
	default_sprite_scale = anim_sprite.scale
	
	if attack_collision:
		attack_collision.disabled = true
		
	anim_sprite.animation_finished.connect(_on_animation_finished)
	
	if not attack_area.body_entered.is_connected(_on_attack_area_body_entered):
		attack_area.body_entered.connect(_on_attack_area_body_entered)

func _physics_process(_delta: float) -> void:
	if current_health <= 0:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if is_attacking:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if knockback_timer > 0.0:
		velocity = knockback_vector
		move_and_slide()
		knockback_timer -= _delta
		return

	# --- Input de Ataque Normal (K) ---
	if Input.is_action_just_pressed("attack"):
		start_attack("normal")
		return 
	
	# --- NOVO: Input de Ataque de Fogo (Tecla definida, ex: L) ---
	if Input.is_action_just_pressed("fire_attack"):
		if has_fire_power:
			start_attack("fire")
		else:
			print("[Player] Você ainda não tem o poder de fogo!")
		return

	# --- Movimentação ---
	var input_vector = Vector2.ZERO
	if Input.is_action_pressed("ui_right"): input_vector.x += 1
	if Input.is_action_pressed("ui_left"): input_vector.x -= 1
	if Input.is_action_pressed("ui_down"): input_vector.y += 1
	if Input.is_action_pressed("ui_up"): input_vector.y -= 1

	velocity = input_vector.normalized() * speed
	move_and_slide()
	update_animation(input_vector)

# --- FUNÇÃO ATUALIZADA PARA RECEBER O TIPO DE ATAQUE ---
func start_attack(type: String):
	if is_attacking: return
		
	is_attacking = true
	current_attack_type = type # Salva qual ataque é para usar no cálculo de dano
	enemies_hit_this_attack.clear()
	
	# Gambiarra da escala (mantida)
	anim_sprite.scale = default_sprite_scale * 1.8
	
	# Define animação e cor
	if type == "fire":
		anim_sprite.play("attack_fire") # Certifique-se de ter criado essa animação (mesmo que duplicada)
		anim_sprite.modulate = Color(1, 0.2, 0.2) # Fica Vermelho
		print("[Player] LANÇA-CHAMAS ATIVADO!")
	else:
		anim_sprite.play("attack_side")
		anim_sprite.modulate = Color(1, 1, 1) # Cor normal
	
	attack_collision.set_deferred("disabled", false)
	
	await get_tree().physics_frame
	_check_overlapping_bodies()

# --- Lógica de Coletar o Item ---
func collect_fire_power():
	has_fire_power = true
	print("[Player] PODER DE FOGO ADQUIRIDO! Aperte a nova tecla para usar.")
	# Feedback visual rápido (pisca verde)
	anim_sprite.modulate = Color.GREEN
	await get_tree().create_timer(0.5).timeout
	anim_sprite.modulate = Color.WHITE

# --- Lógica de Dano Atualizada ---
func deal_damage_to(body):
	if body.is_in_group("Enemy") and body not in enemies_hit_this_attack:
		
		# Define o dano baseado no golpe atual
		var damage_to_deal = attack_damage
		if current_attack_type == "fire":
			damage_to_deal = fire_damage
			
		print("[PLAYER] Acertou: %s com ataque %s (Dano: %d)" % [body.name, current_attack_type, damage_to_deal])
		
		if body.has_method("take_damage"):
			body.take_damage(damage_to_deal)
			enemies_hit_this_attack.append(body)

# --- Mantenha o resto das funções (overlap, animation_finished, etc) ---

func _check_overlapping_bodies():
	var bodies = attack_area.get_overlapping_bodies()
	for body in bodies:
		deal_damage_to(body)

func _on_attack_area_body_entered(body):
	if is_attacking:
		deal_damage_to(body)

func _on_animation_finished():
	if is_attacking:
		is_attacking = false
		attack_collision.set_deferred("disabled", true)
		enemies_hit_this_attack.clear()
		
		# Restaura escala e cor
		anim_sprite.scale = default_sprite_scale
		anim_sprite.modulate = Color(1, 1, 1) # Importante: tira o vermelho do fogo
		
		update_animation(Vector2.ZERO)

func update_animation(input_vector: Vector2) -> void:
	if is_attacking: return 

	var new_anim: String
	if input_vector != Vector2.ZERO:
		last_move_vector = input_vector
		if input_vector.y < 0: new_anim = "walk_up"
		elif input_vector.y > 0: new_anim = "walk_down"
		else: new_anim = "walk_side"
	else:
		if last_move_vector.y < 0: new_anim = "idle_up"
		elif last_move_vector.y > 0: new_anim = "idle_down"
		else: new_anim = "idle_side"

	if last_move_vector.x != 0:
		anim_sprite.flip_h = last_move_vector.x < 0
		if last_move_vector.x < 0: attack_area.scale.x = -1
		else: attack_area.scale.x = 1

	if anim_sprite.animation != new_anim:
		anim_sprite.play(new_anim)

func take_damage(amount: int, source_position: Vector2 = position):
	if current_health <= 0: return
	var old_health = current_health
	current_health = max(0, current_health - amount)
	knockback_vector = (position - source_position).normalized() * knockback_strength
	knockback_timer = knockback_duration
	is_taking_damage = true
	anim_sprite.modulate = Color(1, 0.4, 0.4)
	get_tree().create_timer(damage_flash_time).timeout.connect(func ():
		# Só volta pro branco se não estiver atacando com fogo (pra não bugar a cor no meio do golpe)
		if not is_attacking or current_attack_type != "fire":
			anim_sprite.modulate = Color(1, 1, 1)
		is_taking_damage = false
	)
	health_changed.emit(current_health)
	if current_health <= 0: handle_death()

func handle_death():
	print("[Player LOG] O jogador morreu!")
