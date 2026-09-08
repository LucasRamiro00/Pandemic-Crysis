extends Node

signal novo_dia_iniciado(dia, semana)
signal semana_alterada(nova_semana)
signal pandemia_iniciada

var dia_atual: int = 1
var semana_atual: int = 1
var dias_totais_jogados: int = 1
var pandemia_ativa: bool = false
const LIMITE_DIAS_TOTAIS: int = 21 # 3 semanas completas de gameplay[cite: 2]

func reiniciar_tempo() -> void:
	dia_atual = 1
	semana_atual = 1
	dias_totais_jogados = 1
	pandemia_ativa = false

func avancar_dia() -> void:
	dia_atual += 1
	dias_totais_jogados += 1
	
	if dias_totais_jogados > LIMITE_DIAS_TOTAIS:
		print("Fim de Jogo: 21 dias concluídos.")
		return

	if dia_atual > 7:
		dia_atual = 1
		semana_atual += 1
		emit_signal("semana_alterada", semana_atual)
		
		if semana_atual == 4 and not pandemia_ativa:
			pandemia_ativa = true
			emit_signal("pandemia_iniciada")
			print("Alerta: A Pandemia Global começou!")

	emit_signal("novo_dia_iniciado", dia_atual, semana_atual)
