library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity genius is
    port (
        CLOCK_50 : in std_logic;
        KEY      : in std_logic_vector(1 downto 0); -- KEY(0): Confirma, KEY(1): Hard Mode
        SW       : in std_logic_vector(9 downto 0); -- SW(0-7) Jogo
        LEDR     : out std_logic_vector(9 downto 0);
        
        -- DISPLAY DE PONTOS (RODADA)
        HEX0     : out std_logic_vector(6 downto 0); -- Unidade da Rodada
        HEX1     : out std_logic_vector(6 downto 0); -- Dezena da Rodada
        
        -- DISPLAY DO TIMER
        HEX4     : out std_logic_vector(6 downto 0); -- Unidade do Timer
        HEX5     : out std_logic_vector(6 downto 0)  -- Dezena do Timer
    );
end entity;

architecture genius of genius is

    type state_type is (
        RESET_STATE,
        GERA_PRIMEIRA_SEQUENCIA,
        MOSTRA_SEQUENCIA,
        ESPERA_INPUT,
        PROXIMA_RODADA,
        GAME_OVER
    );
    signal state : state_type := RESET_STATE;

    -- Array da sequência
    type seq_array_type is array (0 to 63) of integer range 0 to 7;
    signal sequence : seq_array_type := (others => 0);

    -- Alterado para INTEGER para facilitar a conta de dezenas/unidades (0 a 99)
    signal rodada : integer range 0 to 99 := 1;
    
    signal index_show : integer range 0 to 63 := 0;
    signal index_check : integer range 0 to 63 := 0; 
    
    -- === SINCRONIZAÇÃO E DEBOUNCE ===
    signal sw_sync : std_logic_vector(9 downto 0); 
    signal key0_sync : std_logic;                  
    
    signal btn_counter : integer range 0 to 500000 := 0; 
    signal btn_stable  : std_logic := '1'; 
    signal btn_prev    : std_logic := '1'; 
    signal btn_pressed : boolean := false; 
    
    -- Lógica do Jogo
    signal blink_timer : integer range 0 to 125000000 := 0;
    signal random : unsigned(3 downto 0) := "1011"; 
    signal sequence_length : integer range 0 to 63 := 0;
    signal hard_mode : std_logic := '0';
    signal leds_jogo : std_logic_vector(7 downto 0) := (others => '0');
    
    -- Timer de Jogo
    signal tempo_limite_fase : integer range 0 to 99 := 15;
    signal segundos_restantes : integer range 0 to 99 := 15;
    signal contador_1seg : integer range 0 to 50000000 := 0;

    -- Velocidades
    constant VELOCIDADE_NORMAL : integer := 50000000; 
    constant VELOCIDADE_HARD   : integer := 40000000; 
    signal limite_blink : integer := VELOCIDADE_NORMAL;

    function bcd_to_ssd(digit : integer) return std_logic_vector is
    begin
        case digit is
            when 0 => return "1000000";
            when 1 => return "1111001";
            when 2 => return "0100100";
            when 3 => return "0110000";
            when 4 => return "0011001";
            when 5 => return "0010010";
            when 6 => return "0000010";
            when 7 => return "1111000";
            when 8 => return "0000000";
            when 9 => return "0011000";
            when others => return "1111111";
        end case;
    end function;

begin
    -- Visualização dos LEDs
    LEDR(7 downto 0) <= leds_jogo;
    LEDR(8) <= '0';
    LEDR(9) <= hard_mode;

    process(CLOCK_50)
        variable expected_sw : std_logic_vector(7 downto 0);
    begin
        if rising_edge(CLOCK_50) then
            
            -- Sincronização e Debounce 
            sw_sync <= SW;
            key0_sync <= KEY(0);

            if key0_sync /= btn_stable then
                if btn_counter < 500000 then
                    btn_counter <= btn_counter + 1;
                else
                    btn_stable <= key0_sync;
                    btn_counter <= 0;
                end if;
            else
                btn_counter <= 0;
            end if;

            btn_pressed <= false;
            if btn_prev = '1' and btn_stable = '0' then 
                btn_pressed <= true;
            end if;
            btn_prev <= btn_stable; 

            -- Lógica do Jogo
            random <= random(2 downto 0) & (random(3) xor random(2));

            case state is
                when RESET_STATE =>
                    rodada <= 1; -- Começa na rodada 1
                    sequence_length <= 1;
                    index_show <= 0;
                    index_check <= 0;
                    tempo_limite_fase <= 15;
                    segundos_restantes <= 15;
                    leds_jogo <= (others => '0');
                    
                    if KEY(1) = '0' then
                        hard_mode <= '1';
                        limite_blink <= VELOCIDADE_HARD;
                    else
                        hard_mode <= '0';
                        limite_blink <= VELOCIDADE_NORMAL;
                    end if;
                    
                    state <= GERA_PRIMEIRA_SEQUENCIA;

                when GERA_PRIMEIRA_SEQUENCIA =>
                    if hard_mode = '1' then
                        sequence(0) <= to_integer(random(2 downto 0));
                    else
                        sequence(0) <= to_integer(random(1 downto 0));
                    end if;
                    state <= MOSTRA_SEQUENCIA;

                when MOSTRA_SEQUENCIA =>
                    segundos_restantes <= tempo_limite_fase; 
                    contador_1seg <= 0;
                    index_check <= 0; 

                    if blink_timer < (limite_blink / 2) then
                        blink_timer <= blink_timer + 1;
                        leds_jogo <= (others => '0');
                    elsif blink_timer < limite_blink then
                        blink_timer <= blink_timer + 1;
                        case sequence(index_show) is
                            when 0 => leds_jogo <= "00000001";
                            when 1 => leds_jogo <= "00000010";
                            when 2 => leds_jogo <= "00000100";
                            when 3 => leds_jogo <= "00001000";
                            when 4 => leds_jogo <= "00010000";
                            when 5 => leds_jogo <= "00100000";
                            when 6 => leds_jogo <= "01000000";
                            when 7 => leds_jogo <= "10000000";
                            when others => leds_jogo <= "00000000";
                        end case;
                    else
                        blink_timer <= 0;
                        if index_show = sequence_length - 1 then
                            index_show <= 0;
                            state <= ESPERA_INPUT;
                        else
                            index_show <= index_show + 1;
                        end if;
                    end if;

                when ESPERA_INPUT =>
                    leds_jogo <= (others => '0');
                    
                    -- Timer Regressivo
                    if contador_1seg < 50000000 then
                        contador_1seg <= contador_1seg + 1;
                    else
                        contador_1seg <= 0;
                        if segundos_restantes > 0 then
                            segundos_restantes <= segundos_restantes - 1;
                        else
                            state <= GAME_OVER;
                        end if;
                    end if;

                    -- Verifica botão pressionado
                    if btn_pressed then
                        case sequence(index_check) is
                            when 0 => expected_sw := "00000001";
                            when 1 => expected_sw := "00000010";
                            when 2 => expected_sw := "00000100";
                            when 3 => expected_sw := "00001000";
                            when 4 => expected_sw := "00010000";
                            when 5 => expected_sw := "00100000";
                            when 6 => expected_sw := "01000000";
                            when 7 => expected_sw := "10000000";
                            when others => expected_sw := "00000000";
                        end case;

                        if sw_sync(7 downto 0) = expected_sw then
                            if index_check = sequence_length - 1 then
                                state <= PROXIMA_RODADA;
                            else
                                index_check <= index_check + 1;
                            end if;
                        else
                            state <= GAME_OVER;
                        end if;
                    end if;

                when PROXIMA_RODADA =>
                    if hard_mode = '1' then
                        sequence(sequence_length) <= to_integer(random(2 downto 0));
                    else
                        sequence(sequence_length) <= to_integer(random(1 downto 0));
                    end if;

                    sequence_length <= sequence_length + 1;
                    rodada <= rodada + 1; -- Incrementa rodada (suporta > 9)
                    
                    if tempo_limite_fase < 90 then
                        tempo_limite_fase <= tempo_limite_fase + 3;
                    end if;
                    
                    state <= MOSTRA_SEQUENCIA;

                when GAME_OVER =>
                    leds_jogo <= "11111111"; 
                    if btn_pressed then 
                        state <= RESET_STATE;
                    end if;
                    
                when others =>
                    state <= RESET_STATE;
            end case;
        end if;
    end process;

    -- === ATUALIZAÇÃO DOS DISPLAYS ===
    
    -- Pontuação (Rodada) no HEX1 e HEX0
    HEX1 <= bcd_to_ssd(rodada / 10);   -- Dezena da rodada
    HEX0 <= bcd_to_ssd(rodada mod 10); -- Unidade da rodada
    
    -- Timer no HEX5 e HEX4
    HEX5 <= bcd_to_ssd(segundos_restantes / 10);   -- Dezena do timer
    HEX4 <= bcd_to_ssd(segundos_restantes mod 10); -- Unidade do timer

end architecture;