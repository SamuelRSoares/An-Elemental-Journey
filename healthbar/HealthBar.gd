# HealthBar.gd
# Este script controla um componente de UI genérico para exibir a vida.
# Ele não sabe a quem pertence, apenas recebe valores e se atualiza.
class_name HealthBar
extends Control

# Uma referência ao nosso nó TextureProgressBar para fácil acesso.
# O @onready garante que a variável será preenchida quando o nó estiver pronto.
@onready var progress_bar: TextureProgressBar = $ProgressBar

# Esta função será chamada no início para garantir que a barra de vida
# comece com os valores corretos.
func set_initial_health(initial_value: int):
	progress_bar.max_value = initial_value
	progress_bar.value = initial_value

# Esta é a função principal. Qualquer personagem pode chamá-la para
# atualizar o valor exibido na barra.
func update_health(new_value: int):
	# Usamos tween para suavizar a transição da barra de vida,
	# em vez de fazer a mudança ser instantânea. Fica mais polido.
	var tween = create_tween()
	tween.tween_property(progress_bar, "value", new_value, 0.2).set_trans(Tween.TRANS_SINE)
