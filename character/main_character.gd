extends CharacterBody2D

# --- Constantes e Exportações ---
@export var speed: float = 200.0
@export var max_health: int = 100

# --- Sinais (Comunicação Externa) ---
# Anuncia quando a vida do jogador muda. A UI (HealthBar) ouve este sinal.
signal health_changed(new_health)

# --- Referências de Nós (@onready) ---
@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D
# Referência à HealthBar que deve ser um nó filho do Player na cena.
@onready var health_bar: HealthBar = $HealthBar

# --- Variáveis de Estado ---
var current_health: int
# Guarda a última direção de movimento para a animação de "idle".
var last_move_vector: Vector2 = Vector2(0, 1) # Começa olhando para baixo

# Chamada uma vez quando o nó entra na árvore da cena. Ideal para inicialização.
func _ready():
	print("[Player LOG] Player inicializando...")
	# Inicializa a vida atual com o valor máximo.
	current_health = max_health
	print("[Player LOG] Vida definida para: %d / %d" % [current_health, max_health])
	
	# --- Conexão da Barra de Vida ---
	# Conecta o sinal 'health_changed' deste script à função 'update_health' do script da HealthBar.
	if health_bar:
		health_changed.connect(health_bar.update_health)
		# Informa à barra de vida qual é a vida inicial para configurar seu valor máximo.
		health_bar.set_initial_health(current_health)
		print("[Player LOG] Barra de vida conectada e inicializada com sucesso.")
	else:
		# Este log é crucial para saber se você esqueceu de adicionar a HealthBar na cena.
		print("[Player ERRO] Nó HealthBar não foi encontrado! A UI de vida não funcionará.")


# Chamada a cada frame de física. Ideal para movimento e colisões.
func _physics_process(_delta: float) -> void:
	# Se o jogador estiver morto, interrompemos a lógica de movimento.
	if current_health <= 0:
		velocity = Vector2.ZERO # Garante que o jogador pare de se mover ao morrer.
		move_and_slide()
		return # Interrompe a execução da função aqui.

	# --- Captura de Input ---
	var input_vector = Vector2.ZERO
	if Input.is_action_pressed("ui_right"):
		input_vector.x += 1
	if Input.is_action_pressed("ui_left"):
		input_vector.x -= 1
	if Input.is_action_pressed("ui_down"):
		input_vector.y += 1
	if Input.is_action_pressed("ui_up"):
		input_vector.y -= 1

	# --- Movimento ---
	velocity = input_vector.normalized() * speed
	move_and_slide()

	# --- Animação ---
	update_animation(input_vector)

# Atualiza a animação com base na direção do movimento.
func update_animation(input_vector: Vector2) -> void:
	var new_anim: String

	# Lógica para determinar a animação de andar ou parado
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

	# Vira o sprite horizontalmente
	if last_move_vector.x != 0:
		anim_sprite.flip_h = last_move_vector.x < 0

	# Troca a animação apenas se for diferente da atual, para evitar reiniciá-la a cada frame.
	if anim_sprite.animation != new_anim:
		anim_sprite.play(new_anim)
		# Descomente a linha abaixo para ver no console toda vez que a animação mudar.
		# print("[Player LOG] Animação alterada para: ", new_anim)

# --- Funções de Lógica de Vida ---

# Função pública para que outros nós (inimigos, projéteis) possam causar dano ao jogador.
func take_damage(amount: int):
	# Se já estiver morto, não faz mais nada.
	if current_health <= 0:
		return

	var old_health = current_health
	current_health -= amount
	# Garante que a vida não fique negativa (útil para a UI).
	current_health = max(0, current_health)
	
	print("[Player LOG] Recebeu %d de dano. Vida: %d -> %d" % [amount, old_health, current_health])

	# Emite o sinal para que a barra de vida se atualize.
	health_changed.emit(current_health)

	# Lógica de morte
	if current_health <= 0:
		handle_death()

# Centraliza a lógica que acontece quando o jogador morre.
func handle_death():
	print("[Player LOG] O jogador morreu!")
	
	# A partir daqui, você pode adicionar a lógica de morte:
	# Exemplo 1: Tocar uma animação de morte e desabilitar colisões.
	# anim_sprite.play("death")
	# $CollisionShape2D.set_deferred("disabled", true) # Desabilita a colisão para não bloquear inimigos
	
	# Exemplo 2: Recarregar a cena após um tempo.
	# await get_tree().create_timer(1.5).timeout # Espera 1.5 segundos
	# get_tree().reload_current_scene()
