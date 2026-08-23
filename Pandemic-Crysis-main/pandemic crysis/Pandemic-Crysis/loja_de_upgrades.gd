extends Control


func _ready():
	$Saldo.text = "SALDO: $" + str(GameManager.caixa_hospital)


func _on_ampliar_leitos_button_pressed():
	if GameManager.comprar_upgrade("ampliar_leitos", 500):
		$Saldo.text = "SALDO: $" + str(GameManager.caixa_hospital)


func _on_treinar_funcionarios_button_pressed():
	if GameManager.comprar_upgrade("treinar_funcionarios", 750):
		$Saldo.text = "SALDO: $" + str(GameManager.caixa_hospital)


func _on_modernizar_terminal_button_pressed():
	if GameManager.comprar_upgrade("modernizar_terminal", 1000):
		$Saldo.text = "SALDO: $" + str(GameManager.caixa_hospital)
