extends Control


func _ready():
	$Pacientes.text = "PACIENTES ATENDIDOS: " + str(GameManager.relatorio_do_dia["pacientes"])
	$Acertos.text = "DIAGNÓSTICOS CORRETOS: " + str(GameManager.relatorio_do_dia["acertos"])
	$Erros.text = "ERROS: " + str(GameManager.relatorio_do_dia["erros"])
	$Saldo.text = "SALDO: $" + str(GameManager.caixa_hospital)


func _on_avancar_dia_button_pressed():
	get_tree().change_scene_to_file("res://LojaDeUpgrades.tscn")
