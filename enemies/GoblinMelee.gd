# GoblinMelee.gd
extends EnemyBase

@onready var detection_area: Area2D = $DetectionArea
@onready var attack_area: Area2D = $AttackArea
@onready var hitbox_collision_shape: CollisionShape2D = $Hitbox/CollisionShape2D

var grupoPlayer = "Player"
var damage_dealt_this_attack = false
var player_in_attack_range = false

# Controle de tempo de ataque
var attack_timer: float = 0.0
@export var attack_duration: float = 2.1
@export var attack_impact_time: float = 0.98
@export var attack_hitbox_duration: float = 0.1

var attack_started := false
var attack_phase_done := false

func _ready():
	super._ready() # Importante chamar o _ready da base para adicionar ao grupo Enemy!

# --- ESTADOS ---

func _idle_state(_delta: float):
	super._idle_state(_delta)
	velocity = Vector2.ZERO
	if player:
		change_state(State.CHASING)

func _chasing_state(_delta: float):
	if not player:
		change_state(State.IDLE)
		return
	
	# Se chegar perto, ataca
	if player_in_attack_range:
		change_state(State.ATTACKING)
		return

	var direction = (player.global_position - global_position).normalized()
	velocity = direction * speed
	play_animation("walk_side")
	animated_sprite.flip_h = velocity.x < 0

func _attacking_state(delta: float):
	velocity = Vector2.ZERO

	if not attack_started:
		play_animation("attack_slash_1")
		damage_dealt_this_attack = false
		hitbox_collision_shape.disabled = true
		attack_phase_done = false
		attack_timer = 0.0
		attack_started = true
		print("[Goblin LOG] Iniciando ataque...")

	attack_timer += delta

	# Lógica da Hitbox do Goblin (igual ao seu código original)
	if not attack_phase_done and attack_timer >= attack_impact_time:
		hitbox_collision_shape.set_deferred("disabled", false)
		attack_phase_done = true

	if attack_phase_done and attack_timer >= attack_impact_time + attack_hitbox_duration:
		hitbox_collision_shape.set_deferred("disabled", true)

	if attack_timer >= attack_duration:
		hitbox_collision_shape.set_deferred("disabled", true)
		attack_started = false
		attack_timer = 0.0

		if player_in_attack_range:
			change_state(State.ATTACKING)
		else:
			change_state(State.CHASING)

# O _hurt_state na base já trata a animação, mas se quiser algo específico aqui, pode manter vazio
# pois a base chama play_animation("hurt")
func _hurt_state(_delta: float):
	super._hurt_state(_delta)

# --- ÁREAS (Detection e Attack Area) ---
# Mantenha seus métodos _on_detection_area_body_entered, etc. exatamente como estão.
# Apenas certifique-se que as conexões de sinal na aba "Node" do Godot estão feitas.

func _on_detection_area_body_entered(body):
	if body.is_in_group(grupoPlayer):
		player = body

func _on_detection_area_body_exited(body):
	if body.is_in_group(grupoPlayer):
		player = null
		player_in_attack_range = false
		change_state(State.IDLE)

func _on_attack_area_body_entered(body):
	if body.is_in_group(grupoPlayer):
		player_in_attack_range = true

func _on_attack_area_body_exited(body):
	if body.is_in_group(grupoPlayer):
		player_in_attack_range = false

func _on_hitbox_body_entered(body):
	if body.is_in_group(grupoPlayer) and not damage_dealt_this_attack:
		print("[Goblin LOG] Golpe acertou o jogador!")
		body.take_damage(10, global_position)
		damage_dealt_this_attack = true
