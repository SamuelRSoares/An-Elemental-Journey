extends EnemyBase

@onready var detection_area: Area2D = $DetectionArea
@onready var attack_area: Area2D = $AttackArea

func _ready():
	detection_area.body_entered.connect(_on_detection_area_body_entered)
	detection_area.body_exited.connect(_on_detection_area_body_exited)
	
	animated_sprite.animation_finished.connect(_on_animation_finished)

func _idle_state(_delta: float):
	super._idle_state(_delta)
	
	velocity = Vector2.ZERO
	
	# Se encontrar um jogador, começa a persegui-lo.
	if player != null:
		change_state(State.CHASING)

func _chasing_state(_delta: float):
	if player == null:
		change_state(State.IDLE)
		return

	# Calcula a direção até o jogador.
	var direction = (player.global_position - global_position).normalized()
	velocity = direction * speed
	
	# Toca a animação de andar.
	play_animation("walk_side")
	
	# Vira o sprite na direção do movimento.
	animated_sprite.flip_h = velocity.x < 0
	
	# Verifica se está perto o suficiente para atacar.
	if global_position.distance_to(player.global_position) <= attack_area.get_node("CollisionShape2D").shape.get_rect().size.x:
		change_state(State.ATTACKING)

func _attacking_state(_delta: float):
	velocity = Vector2.ZERO # Para de se mover para atacar.
	play_animation("attack_slash_1")
	# A lógica de transição para outro estado está em _on_animation_finished.

func _hurt_state(_delta: float):
	velocity = Vector2.ZERO
	play_animation("hurt")
	# Quando a animação "hurt" terminar, voltamos a perseguir.

func _on_animation_finished():
	# Chamado sempre que uma animação termina.
	match current_state:
		State.ATTACKING:
			# Se o ataque terminou, volta a perseguir.
			change_state(State.CHASING)
		State.HURT:
			# Se a animação de dor terminou, volta a perseguir.
			change_state(State.CHASING)
		State.DEAD:
			# Se a animação de morte terminou, o inimigo pode ser removido.
			queue_free()

# --- Funções de Sinais das Áreas ---
func _on_detection_area_body_entered(body):
	# Verifica se o corpo que entrou tem um script de jogador (ou está no grupo "player").
	# Para isso, seu jogador precisa estar no grupo "player".
	if body.is_in_group("player"):
		player = body

func _on_detection_area_body_exited(body):
	if body.is_in_group("player"):
		player = null
		change_state(State.IDLE)
