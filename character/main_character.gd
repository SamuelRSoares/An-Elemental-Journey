# main_character.gd
extends CharacterBody2D

# --- Constantes e Exportações ---
@export var speed: float = 200.0
@export var max_health: int = 100
@export var attack_damage: int = 20

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
# Lista para evitar acertar o mesmo inimigo duas vezes no mesmo ataque
var enemies_hit_this_attack: Array = [] 
var default_sprite_scale: Vector2 

func _ready():
	print("[Player LOG] Player inicializando...")
	current_health = max_health
	default_sprite_scale = anim_sprite.scale

	# Desabilita a hitbox de ataque inicialmente
	if attack_collision:
		attack_collision.disabled = true
		
	# Conexões de Sinais
	anim_sprite.animation_finished.connect(_on_animation_finished)
	
	# --- CORREÇÃO IMPORTANTE: CONEXÃO DE SINAL ---
	# Isso garante que se o inimigo entrar na área DURANTE o ataque, ele toma dano
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

	# --- Knockback ---
	if knockback_timer > 0.0:
		velocity = knockback_vector
		move_and_slide()
		knockback_timer -= _delta
		return

	# --- Input de Ataque (Tecla K) ---
	if Input.is_action_just_pressed("attack"):
		start_attack()
		return 

	# --- Movimentação Normal ---
	var input_vector = Vector2.ZERO
	if Input.is_action_pressed("ui_right"): input_vector.x += 1
	if Input.is_action_pressed("ui_left"): input_vector.x -= 1
	if Input.is_action_pressed("ui_down"): input_vector.y += 1
	if Input.is_action_pressed("ui_up"): input_vector.y -= 1

	velocity = input_vector.normalized() * speed
	move_and_slide()
	update_animation(input_vector)

func start_attack():
	if is_attacking:
		return
		
	is_attacking = true
	anim_sprite.scale = default_sprite_scale * 1.8
	enemies_hit_this_attack.clear() # Limpa a lista de quem já tomou dano
	
	var attack_anim = "attack_side"
	# Lógica direcional (opcional)
	# if last_move_vector.y < 0: attack_anim = "attack_up"
	# elif last_move_vector.y > 0: attack_anim = "attack_down"
	
	anim_sprite.play(attack_anim)
	
	# Ativa a hitbox
	attack_collision.set_deferred("disabled", false)
	
	# --- CORREÇÃO CRÍTICA DO BUG ---
	# Espera 1 frame de física para o Godot processar que a hitbox ligou
	await get_tree().physics_frame
	
	# Agora sim verifica quem JÁ ESTAVA dentro da área
	_check_overlapping_bodies()

func _check_overlapping_bodies():
	# Verifica quem já está dentro da área no momento do golpe
	var bodies = attack_area.get_overlapping_bodies()
	print("[PLAYER DEBUG] Corpos detectados após delay: ", bodies.size())
	
	for body in bodies:
		deal_damage_to(body)

func _on_attack_area_body_entered(body):
	# Este método é chamado automaticamente se um inimigo ENTRAR na espada
	# enquanto o ataque está acontecendo
	if is_attacking:
		deal_damage_to(body)

func deal_damage_to(body):
	# Verifica se é inimigo e se já não tomou dano neste mesmo golpe
	if body.is_in_group("Enemy") and body not in enemies_hit_this_attack:
		print("[PLAYER] Acertou: ", body.name)
		if body.has_method("take_damage"):
			body.take_damage(attack_damage)
			enemies_hit_this_attack.append(body) # Marca como atingido

func _on_animation_finished():
	if is_attacking:
		is_attacking = false
		attack_collision.set_deferred("disabled", true)
		enemies_hit_this_attack.clear()
		anim_sprite.scale = default_sprite_scale
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
		if last_move_vector.x < 0:
			attack_area.scale.x = -1
		else:
			attack_area.scale.x = 1

	if anim_sprite.animation != new_anim:
		anim_sprite.play(new_anim)

func take_damage(amount: int, source_position: Vector2 = position):
	if current_health <= 0: return
	var old_health = current_health
	current_health = max(0, current_health - amount)
	print("[Player LOG] Recebeu %d de dano. Vida: %d -> %d" % [amount, old_health, current_health])
	knockback_vector = (position - source_position).normalized() * knockback_strength
	knockback_timer = knockback_duration
	is_taking_damage = true
	anim_sprite.modulate = Color(1, 0.4, 0.4)
	get_tree().create_timer(damage_flash_time).timeout.connect(func ():
		anim_sprite.modulate = Color(1, 1, 1)
		is_taking_damage = false
	)
	health_changed.emit(current_health)
	if current_health <= 0: handle_death()

func handle_death():
	print("[Player LOG] O jogador morreu!")
