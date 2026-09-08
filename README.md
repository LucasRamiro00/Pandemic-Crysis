PANDEMIC CRYSIS - conclusão da campanha + layout da loja
========================================================

ARQUIVOS NOVOS (2)
  Vitoria.tscn
  vitoria.gd

ARQUIVOS ALTERADOS (2)
  LojaDeUpgrades.tscn
  loja_de_upgrades.gd

1. TELA DE CONCLUSÃO DA CAMPANHA
   Antes, passar dos 21 dias não levava a lugar nenhum: o botão "Avançar
   para o Próximo Dia" não fazia nada e o jogador ficava parado na loja.
   Agora o jogo encaminha para a tela de conclusão, com os dias
   sobrevividos, o caixa final como pontuação e uma avaliação:

     até 1.500      Sobrevivência no limite dos recursos
     1.500 a 3.999  Operação mantida com dificuldade
     4.000 a 7.999  Hospital estável e bem administrado
     8.000 ou mais  Excelência em gestão hospitalar

   O save é apagado, como nas derrotas.

   PARA TESTAR SEM JOGAR 21 DIAS: em sistemas/timeManager.gd troque
   const LIMITE_DIAS_TOTAIS: int = 21  por  int = 2, jogue dois dias,
   confirme a tela e devolva o valor para 21.

2. LAYOUT DA LOJA
   Os botões estavam com posição e largura fixas, cada um de um tamanho,
   e a fonte 32 não comportava os textos que a loja agora mostra em tempo
   de execução (ex: "exame hoje: $40"), que ficariam cortados.
   A tela foi remontada com contêineres: título e saldo centralizados,
   os três botões de upgrade com a mesma largura, e o botão de avançar
   centralizado embaixo. Agora a tela se adapta sozinha a qualquer
   resolução e a textos de qualquer tamanho.

   Os nomes dos nós e as conexões de sinal foram preservados - nenhuma
   função do script mudou de nome.
