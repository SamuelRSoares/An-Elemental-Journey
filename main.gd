# main.gd
extends Node2D

# Referências para os nós que este script precisa "gerenciar".
# IMPORTANTE: Os nomes "Player" e "UI" devem corresponder EXATAMENTE
# aos nomes dos nós instanciados na sua árvore de cena.
@onready var player = $Player 
@onready var ui = $UI

func _ready():
	print("[Main LOG] Cena principal inicializando. Conectando jogador e UI...")

	# Encontra a HealthBar dentro da cena da UI.
	var health_bar = ui.get_node("HealthBar")

	# Conecta o sinal do jogador à função da barra de vida.
	player.health_changed.connect(health_bar.update_health)
	
	# No início do jogo, dizemos à barra de vida para se configurar
	# com a vida máxima do jogador.
	health_bar.set_initial_health(player.max_health)
	
	print("[Main LOG] Conexão entre Player e HealthBar realizada com sucesso!")
