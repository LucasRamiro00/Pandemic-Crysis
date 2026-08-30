extends Node

signal relatorio_diario_emitido(saldo, acertos, erros, cumpriu_meta)
signal game_over_acionado(motivo)

var caixa_hospital: int = 1000
var custo_manutencao_diaria: int = 150
var limite_de_leitos: int = 5
var bonus_velocidade_exame: float = 1.0
var terminal_modernizado: bool = false

var pacientes_atendidos_hoje: int = 0
var diagnosticos_corretos_hoje: int = 0
var erros_cometidos_hoje: int = 0
var relatorio_do_dia: Dictionary = {}
var meta_pacientes_dia: int = 10 
var dias_consecutivos_falhando_quota: int = 0

var banco_de_doencas: Array[Doenca] = []

func _ready() -> void:
	carregar_banco_de_doencas()

func carregar_banco_de_doencas() -> void:
	var caminho_pasta: String = "res://resources/doencas/"
	var diretorio = DirAccess.open(caminho_pasta)
	if diretorio:
		diretorio.list_dir_begin()
		var nome_arquivo = diretorio.get_next()
		while nome_arquivo != "":
			if not diretorio.current_is_dir() and nome_arquivo.ends_with(".tres"):
				var doenca_carregada = load(caminho_pasta + nome_arquivo) as Doenca
				if doenca_carregada:
					banco_de_doencas.append(doenca_carregada)
			nome_arquivo = diretorio.get_next()
		print("Banco carregado. Doenças cadastradas: ", banco_de_doencas.size())
	else:
		print("Erro: Não foi possível acessar a pasta de doenças.")

func processar_diagnostico(doenca_selecionada: Doenca, doenca_real: Doenca) -> bool:
	pacientes_atendidos_hoje += 1
	if doenca_selecionada.nome == doenca_real.nome:
		diagnosticos_corretos_hoje += 1
		caixa_hospital += doenca_real.recompensa_financeira
		return true
	else:
		erros_cometidos_hoje += 1
		return false

func comprar_upgrade(tipo_upgrade: String, custo: int) -> bool:
	if caixa_hospital >= custo:
		caixa_hospital -= custo
		match tipo_upgrade:
			"ampliar_leitos":
				limite_de_leitos += 3
			"treinar_funcionarios":
				bonus_velocidade_exame -= 0.1 
			"modernizar_terminal":
				terminal_modernizado = true
		return true
	return false

func realizar_fechamento_de_caixa() -> void:
	caixa_hospital -= custo_manutencao_diaria
	
	if caixa_hospital < 0:
		emit_signal("game_over_acionado", "falencia")
		print("Game Over: O hospital faliu.")
		return
		
	var cumpriu_quota: bool = pacientes_atendidos_hoje >= meta_pacientes_dia
	if not cumpriu_quota:
		dias_consecutivos_falhando_quota += 1
		if dias_consecutivos_falhando_quota >= 3: 
			emit_signal("game_over_acionado", "quota")
			print("Game Over: Interdição operacional.")
			return
	else:
		dias_consecutivos_falhando_quota = 0
	
	
	
	relatorio_do_dia = {
		"saldo": caixa_hospital,
		"pacientes": pacientes_atendidos_hoje,
		"acertos": diagnosticos_corretos_hoje,
		"erros": erros_cometidos_hoje,
		"cumpriu_meta": cumpriu_quota
	}
	
	emit_signal("relatorio_diario_emitido", caixa_hospital, diagnosticos_corretos_hoje, erros_cometidos_hoje, cumpriu_quota)
	pacientes_atendidos_hoje = 0
	diagnosticos_corretos_hoje = 0	
	erros_cometidos_hoje = 0
