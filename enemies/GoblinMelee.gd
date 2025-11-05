#GoblinMelee.gd
extends EnemyBase

@onready var detection_area: Area2D = $DetectionArea
@onready var attack_area: Area2D = $AttackArea
@onready var hitbox_collision_shape: CollisionShape2D = $Hitbox/CollisionShape2D

var grupoPlayer = "Player" # Nome do grupo do jogador
var damage_dealt_this_attack = false
var player_in_attack_range = false # NOVA VARIÁVEL

func _ready():
	# Conexões de sinais (assumindo que foram feitas pelo editor)
	animated_sprite.animation_finished.connect(_on_animation_finished)

func _idle_state(_delta: float):
	super._idle_state(_delta)
	velocity = Vector2.ZERO
	if player != null:
		change_state(State.CHASING)

func _chasing_state(_delta: float):
	if player == null:
		change_state(State.IDLE)
		return

	# Se o jogador estiver no alcance de ataque, mude para o estado de ataque.
	# Esta verificação agora é muito mais simples e robusta!
	if player_in_attack_range:
		change_state(State.ATTACKING)
		return # Para de executar o resto do código de perseguição

	var direction = (player.global_position - global_position).normalized()
	velocity = direction * speed
	play_animation("walk_side")
	animated_sprite.flip_h = velocity.x < 0
	
func _attacking_state(_delta: float):
	velocity = Vector2.ZERO
	if animated_sprite.animation != "attack_slash_1":
		play_animation("attack_slash_1")
		damage_dealt_this_attack = false
		hitbox_collision_shape.set_deferred("disabled", false)
		print("[Goblin LOG] Ataque iniciado, hitbox ATIVADA.")
		
func _hurt_state(_delta: float):
	velocity = Vector2.ZERO
	play_animation("hurt")

func _on_animation_finished():
	match current_state:
		State.ATTACKING:
			hitbox_collision_shape.set_deferred("disabled", true)
			print("[Goblin LOG] Ataque finalizado, hitbox DESATIVADA.")
			
			# Se o jogador ainda estiver perto, ataca de novo. Se não, persegue.
			if player_in_attack_range:
				change_state(State.ATTACKING)
			else:
				change_state(State.CHASING)
		State.HURT:
			change_state(State.CHASING)
		State.DEAD:
			queue_free()

# --- Funções de Sinais das Áreas ---

func _on_detection_area_body_entered(body):
	if body.is_in_group(grupoPlayer):
		print("Jogador detectado pelo goblin")
		player = body

func _on_detection_area_body_exited(body):
	if body.is_in_group(grupoPlayer):
		player = null
		player_in_attack_range = false # Garante que isso resete se o jogador sair correndo
		change_state(State.IDLE)

# NOVAS FUNÇÕES PARA A ATTACK_AREA
func _on_attack_area_body_entered(body):
	if body.is_in_group(grupoPlayer):
		player_in_attack_range = true

func _on_attack_area_body_exited(body):
	if body.is_in_group(grupoPlayer):
		player_in_attack_range = false

# Função da Hitbox com a variável de grupo consistente
func _on_hitbox_body_entered(body):
	if body.is_in_group(grupoPlayer) and not damage_dealt_this_attack:
		print("[Goblin LOG] Hitbox acertou o jogador!")
		var player_node = body
		player_node.take_damage(10)
		damage_dealt_this_attack = true
