extends Control

@onready var btn_continuar: Button = $ColorRect/Continuar


func _ready() -> void:
	# O botão "Continuar" só aparece se existir uma partida salva.
	btn_continuar.visible = GameManager.existe_save()


# Botão "Jogar" = partida nova. Descarta o save e zera os autoloads.
func _on_button_pressed() -> void:
	GameManager.apagar_save()
	GameManager.reiniciar_jogo()
	TimeManager.reiniciar_tempo()
	get_tree().change_scene_to_file("res://Triagem.tscn")


# Botão "Continuar" = retoma o dia em que a partida parou.
func _on_continuar_pressed() -> void:
	if GameManager.carregar_partida():
		get_tree().change_scene_to_file("res://Triagem.tscn")
	else:
		# Save inexistente ou corrompido: some com o botão e segue no menu.
		btn_continuar.visible = false


func _on_sair_pressed() -> void:
	get_tree().quit()
