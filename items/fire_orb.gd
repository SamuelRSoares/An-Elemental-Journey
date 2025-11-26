# FireOrb.gd
extends Area2D

func _ready():
	# Conecta o sinal para detectar quando algo encosta na orbe
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	# Verifica se quem encostou é o Player
	if body.name == "MainCharacter" or body.is_in_group("Player"):
		print("[ITEM] Player pegou a Orbe de Fogo!")
		
		# Vamos criar essa função no Player jajá
		if body.has_method("collect_fire_power"):
			body.collect_fire_power()
			
		# O item desaparece
		queue_free()
