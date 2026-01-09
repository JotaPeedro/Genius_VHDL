# Jogo Genius em VHDL para FPGA
Este repositório contém a implementação em VHDL do clássico jogo de memória 'Genius' (também conhecido como 'Simon'). O projeto foi desenvolvido para rodar em uma FPGA Intel MAX 10, visando especificamente uma placa como a Altera DE10-Lite. O jogo desafia os jogadores a memorizar e repetir uma sequência crescente de luzes.

## Funcionalidades

-   **Jogabilidade Clássica "Simon":** Observe a sequência e repita-a. A sequência aumenta a cada rodada bem-sucedida.
-   **Dois Modos de Dificuldade:**
    -   **Modo Normal:** Utiliza uma sequência de 4 LEDs.
    -   **Modo Difícil:** Utiliza uma sequência de 8 LEDs e uma velocidade de exibição mais rápida.
-   **Contador de Rodadas:** O número da rodada atual é exibido em dois displays de 7 segmentos (`HEX1` e `HEX0`).
-   **Temporizador (Countdown):** Os jogadores têm um tempo limitado para inserir sua sequência, exibido em dois displays de 7 segmentos separados (`HEX5` e `HEX4`). O tempo limite aumenta ligeiramente a cada rodada.
-   **Feedback Visual e Sonoro:** A sequência do jogo é mostrada nos LEDs da placa.
-   **Indicação de Game Over:** Todos os LEDs do jogo acendem para indicar uma entrada incorreta ou se o tempo acabar.

## Como Jogar

1.  **Selecionar Dificuldade:** Antes de começar, escolha o nível de dificuldade.
    -   **Modo Normal:** Não pressione nenhuma tecla ao iniciar.
    -   **Modo Difícil:** Pressione e segure `KEY[1]` ao ligar ou reiniciar o jogo. O indicador `LEDR[9]` acenderá se o Modo Difícil estiver ativo.
2.  **Iniciar o Jogo:** Pressione `KEY[0]` para começar um novo jogo.
3.  **Observar a Sequência:** O jogo piscará uma sequência de luzes em `LEDR[7:0]`.
4.  **Repetir a Sequência:** Use as chaves `SW[7:0]` para replicar o padrão, uma luz de cada vez. Cada chave corresponde a um LED específico (ex: ligue `SW[0]` para `LEDR[0]`, `SW[1]` para `LEDR[1]`, etc.). Apenas uma chave deve estar ligada ('on') por vez para sua seleção.
5.  **Confirmar Cada Passo:** Após ajustar a chave correta para uma luz na sequência, pressione `KEY[0]` para confirmar sua escolha.
6.  **Progressão:** Se você repetir corretamente toda a sequência dentro do limite de tempo, o jogo avança para a próxima rodada, adicionando mais um passo à sequência.
7.  **Game Over:** Se você cometer um erro ou o tempo expirar, todos os oito LEDs do jogo (`LEDR[7:0]`) acenderão. Pressione `KEY[0]` para reiniciar o jogo do início.

## Hardware e Implementação

O projeto está configurado para uma FPGA **Intel MAX 10 10M50DCF484C7G**, comumente encontrada na placa Altera DE10-Lite.

### Mapeamento de Hardware

| Componente            | Porta VHDL / Pino    | Função                                        |
| ------------------- | -------------------- | --------------------------------------------- |
| Clock               | `CLOCK_50`           | Clock do sistema (50 MHz)                     |
| Botão (Push Button) | `KEY[0]`             | Confirmar entrada / Reiniciar após Game Over  |
| Botão (Push Button) | `KEY[1]`             | Selecionar Modo Difícil na inicialização      |
| Chaves (Switches)   | `SW[7:0]`            | Entrada do jogador para corresponder à sequência |
| LEDs                | `LEDR[7:0]`          | Exibem a sequência do jogo e estado de Game Over |
| LED                 | `LEDR[9]`            | Indicador de Modo Difícil (Ligado = Difícil)  |
| Displays 7-Seg      | `HEX1`, `HEX0`       | Exibem o número da rodada atual (01-99)       |
| Displays 7-Seg      | `HEX5`, `HEX4`       | Exibem o temporizador para entrada do jogador |

### Máquina de Estados

A lógica do jogo é controlada por uma máquina de estados finitos (FSM) que circula pelos seguintes estados:

-   `RESET_STATE`: Inicializa ou reinicia as variáveis do jogo.
-   `GERA_PRIMEIRA_SEQUENCIA`: Gera o primeiro elemento da sequência para um novo jogo.
-   `MOSTRA_SEQUENCIA`: Exibe a sequência de luzes atual para o jogador.
-   `ESPERA_INPUT`: Aguarda o jogador repetir a sequência usando as chaves e o botão de confirmação.
-   `PROXIMA_RODADA`: Se o jogador for bem-sucedido, este estado incrementa a rodada e adiciona um novo elemento à sequência.
-   `GAME_OVER`: Entra neste estado após uma entrada incorreta ou tempo esgotado.

## Configuração e Compilação

1.  **Software:** Você precisará do **Intel Quartus Prime** (o projeto foi criado com a versão 20.1.0 Lite Edition).
2.  **Clonar:** Clone este repositório para sua máquina local.
3.  **Abrir Projeto:** Inicie o Quartus Prime e abra o arquivo de projeto `projeto3.qpf`.
4.  **Compilar:** Compile o design clicando em "Start Compilation".
5.  **Programar FPGA:** Use o Quartus Programmer para carregar o arquivo `.sof` gerado (localizado no diretório `output_files/`) para sua DE10-Lite ou placa FPGA compatível.
