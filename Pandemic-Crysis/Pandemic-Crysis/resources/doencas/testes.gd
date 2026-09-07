extends Node

func _ready() -> void:
	print("--- INICIANDO SIMULACAO PANDEMIC CRYSIS ---")
	print("Dia Inicial: ", TimeManager.dia_atual, " | Saldo Inicial: ", GameManager.caixa_hospital)
	
	var doenca_teste = GameManager.banco_de_doencas[0]
	
	print("\n--- ATENDIMENTOS ---")
	for i in range(12):
		var acertou = GameManager.processar_diagnostico(doenca_teste, doenca_teste)
	
	print("Atendimentos feitos. Novo saldo: ", GameManager.caixa_hospital)
	
	print("\n--- FECHAMENTO DO DIA ---")
	GameManager.realizar_fechamento_de_caixa()
	print("Saldo após pagar as contas do hospital: ", GameManager.caixa_hospital)
	
	print("\n--- GESTÃO E UPGRADES ---")
	print("Leitos antes: ", GameManager.limite_de_leitos)
	var comprou = GameManager.comprar_upgrade("ampliar_leitos", 300)
	if comprou:
		print("Upgrade comprado! Leitos agora: ", GameManager.limite_de_leitos)
		print("Saldo pós-compra: ", GameManager.caixa_hospital)
		
	print("\n--- AVANÇANDO O TEMPO ---")
	TimeManager.avancar_dia()
	print("Iniciando Dia: ", TimeManager.dia_atual)
