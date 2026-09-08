extends Control

@onready var btn_continuar: Button = $ColorRect/Continuar

func _ready() -> void:
	btn_continuar.visible = GameManager.existe_save()

func _on_button_pressed() -> void:
	GameManager.apagar_save()
	GameManager.reiniciar_jogo()
	TimeManager.reiniciar_tempo()
	get_tree().change_scene_to_file("res://Triagem.tscn")

func _on_continuar_pressed() -> void:
	if GameManager.carregar_partida():
		get_tree().change_scene_to_file("res://Triagem.tscn")
	else:
		btn_continuar.visible = false

func _on_sair_pressed() -> void:
	get_tree().quit()
