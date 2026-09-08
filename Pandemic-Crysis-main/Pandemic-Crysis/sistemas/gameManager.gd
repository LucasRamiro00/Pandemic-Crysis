extends Node

signal relatorio_diario_emitido(saldo, acertos, erros, cumpriu_meta)
signal game_over_acionado(motivo)

# Arquivo de save. "user://" é a pasta de dados do jogo no sistema do
# jogador, então funciona igual no editor e no jogo exportado.
const CAMINHO_SAVE: String = "user://partida.save"

# Valores iniciais em constantes: a declaração e o reiniciar_jogo() leem daqui,
# então não tem risco de um mudar e o outro ficar para trás.
const CAIXA_INICIAL: int = 1000
const CUSTO_MANUTENCAO_INICIAL: int = 150
const LEITOS_INICIAIS: int = 5
const BONUS_VELOCIDADE_INICIAL: float = 1.0

# --- Dificuldade por semana ----------------------------------------------
# A meta fica constante no começo (para não virar repetição) e só aperta na
# reta final. A manutenção é que sobe a cada semana: é ela que cria a decisão
# "invisto num upgrade agora ou guardo para bancar os custos do mês?".
# Índice 0 = semana 1, índice 1 = semana 2, índice 2 = semana 3.
const METAS_POR_SEMANA: Array[int] = [5, 6, 9]
const MANUTENCAO_POR_SEMANA: Array[int] = [150, 350, 600]

# --- Balanceamento -------------------------------------------------------
# Quanto o hospital perde por diagnóstico errado. Sem isto, errar só deixava
# de render, então chutar as respostas dava lucro e ler os sintomas era
# opcional. Ajuste este número junto com as recompensas dos .tres.
const PENALIDADE_POR_ERRO: int = 120

var caixa_hospital: int = CAIXA_INICIAL
var custo_manutencao_diaria: int = CUSTO_MANUTENCAO_INICIAL
var limite_de_leitos: int = LEITOS_INICIAIS
var bonus_velocidade_exame: float = BONUS_VELOCIDADE_INICIAL
var terminal_modernizado: bool = false

var pacientes_atendidos_hoje: int = 0
var diagnosticos_corretos_hoje: int = 0
var erros_cometidos_hoje: int = 0
var relatorio_do_dia: Dictionary = {}
# Meta reduzida de 10 para 5: com 21 dias de campanha, 10 por dia davam 210
# atendimentos, o que cansava antes do fim. A Triagem permite atender alguns
# a mais que a meta, por escolha do jogador.
var meta_pacientes_dia: int = 5 
var dias_consecutivos_falhando_quota: int = 0

var banco_de_doencas: Array[Doenca] = []

func _ready() -> void:
	carregar_banco_de_doencas()

# Chamada pelo botão "Jogar" do menu principal.
# O GameManager é autoload: ele NÃO é destruído ao trocar de cena, então sem
# isto uma partida nova herda o caixa, os upgrades e os contadores da anterior.
# ATENÇÃO: não chame carregar_banco_de_doencas() aqui. Ela usa append e
# duplicaria todas as doenças a cada partida nova.
func reiniciar_jogo() -> void:
	caixa_hospital = CAIXA_INICIAL
	custo_manutencao_diaria = CUSTO_MANUTENCAO_INICIAL
	limite_de_leitos = LEITOS_INICIAIS
	bonus_velocidade_exame = BONUS_VELOCIDADE_INICIAL
	terminal_modernizado = false

	pacientes_atendidos_hoje = 0
	diagnosticos_corretos_hoje = 0
	erros_cometidos_hoje = 0
	dias_consecutivos_falhando_quota = 0
	relatorio_do_dia = {}
	atualizar_dificuldade_da_semana(1)


# Chamada pela Triagem no início de cada dia. Ajusta meta e manutenção
# conforme a semana corrente do TimeManager.
func atualizar_dificuldade_da_semana(semana: int) -> void:
	var indice: int = clamp(semana - 1, 0, METAS_POR_SEMANA.size() - 1)
	meta_pacientes_dia = METAS_POR_SEMANA[indice]
	custo_manutencao_diaria = MANUTENCAO_POR_SEMANA[indice]

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
		caixa_hospital -= PENALIDADE_POR_ERRO
		# A penalidade pode zerar o caixa no meio do turno. Sem esta checagem
		# o jogo seguia com saldo negativo até o fechamento do dia.
		verificar_falencia()
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

# Dispara o game over assim que o caixa fica negativo, seja no meio do turno
# (penalidade por erro) ou no fechamento do dia (manutenção).
func verificar_falencia() -> bool:
	if caixa_hospital < 0:
		emit_signal("game_over_acionado", "falencia")
		apagar_save()
		print("Game Over: O hospital faliu.")
		return true
	return false

func realizar_fechamento_de_caixa() -> void:
	caixa_hospital -= custo_manutencao_diaria
	
	if verificar_falencia():
		return
		
	var cumpriu_quota: bool = pacientes_atendidos_hoje >= meta_pacientes_dia
	if not cumpriu_quota:
		dias_consecutivos_falhando_quota += 1
		if dias_consecutivos_falhando_quota >= 3: 
			emit_signal("game_over_acionado", "quota")
			apagar_save()
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


# --- Sistema de save ------------------------------------------------------
# O jogo salva um checkpoint no início de cada dia e quando o jogador sai
# pela Triagem. Como todo o estado da partida vive nestes dois autoloads,
# basta serializar as variáveis deles num JSON.

func salvar_partida() -> void:
	var dados: Dictionary = {
		"caixa_hospital": caixa_hospital,
		"custo_manutencao_diaria": custo_manutencao_diaria,
		"limite_de_leitos": limite_de_leitos,
		"bonus_velocidade_exame": bonus_velocidade_exame,
		"terminal_modernizado": terminal_modernizado,
		"pacientes_atendidos_hoje": pacientes_atendidos_hoje,
		"diagnosticos_corretos_hoje": diagnosticos_corretos_hoje,
		"erros_cometidos_hoje": erros_cometidos_hoje,
		"dias_consecutivos_falhando_quota": dias_consecutivos_falhando_quota,
		"dia_atual": TimeManager.dia_atual,
		"semana_atual": TimeManager.semana_atual,
		"dias_totais_jogados": TimeManager.dias_totais_jogados,
		"pandemia_ativa": TimeManager.pandemia_ativa,
	}

	var arquivo := FileAccess.open(CAMINHO_SAVE, FileAccess.WRITE)
	if arquivo == null:
		push_warning("Não foi possível gravar o save.")
		return
	arquivo.store_string(JSON.stringify(dados))
	arquivo.close()


func existe_save() -> bool:
	return FileAccess.file_exists(CAMINHO_SAVE)


func carregar_partida() -> bool:
	if not existe_save():
		return false

	var arquivo := FileAccess.open(CAMINHO_SAVE, FileAccess.READ)
	if arquivo == null:
		return false
	var conteudo: String = arquivo.get_as_text()
	arquivo.close()

	var dados = JSON.parse_string(conteudo)
	if typeof(dados) != TYPE_DICTIONARY:
		push_warning("Save corrompido: começando partida nova.")
		apagar_save()
		return false

	caixa_hospital = int(dados.get("caixa_hospital", CAIXA_INICIAL))
	custo_manutencao_diaria = int(dados.get("custo_manutencao_diaria", CUSTO_MANUTENCAO_INICIAL))
	limite_de_leitos = int(dados.get("limite_de_leitos", LEITOS_INICIAIS))
	bonus_velocidade_exame = float(dados.get("bonus_velocidade_exame", BONUS_VELOCIDADE_INICIAL))
	terminal_modernizado = bool(dados.get("terminal_modernizado", false))
	pacientes_atendidos_hoje = int(dados.get("pacientes_atendidos_hoje", 0))
	diagnosticos_corretos_hoje = int(dados.get("diagnosticos_corretos_hoje", 0))
	erros_cometidos_hoje = int(dados.get("erros_cometidos_hoje", 0))
	dias_consecutivos_falhando_quota = int(dados.get("dias_consecutivos_falhando_quota", 0))
	relatorio_do_dia = {}

	TimeManager.dia_atual = int(dados.get("dia_atual", 1))
	TimeManager.semana_atual = int(dados.get("semana_atual", 1))
	TimeManager.dias_totais_jogados = int(dados.get("dias_totais_jogados", 1))
	TimeManager.pandemia_ativa = bool(dados.get("pandemia_ativa", false))

	return true


func apagar_save() -> void:
	if existe_save():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(CAMINHO_SAVE))
