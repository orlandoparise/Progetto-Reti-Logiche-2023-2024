LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

entity project_reti_logiche is
    port (
        i_clk   : in std_logic;
        i_rst   : in std_logic;
        i_start : in std_logic;
        i_add   : in std_logic_vector(15 downto 0);
        i_k     : in std_logic_vector(9 downto 0);
        
        o_done  : out std_logic;
        
        o_mem_addr  : out std_logic_vector(15 downto 0);
        i_mem_data  : in std_logic_vector(7 downto 0);
        o_mem_data  : out std_logic_vector(7 downto 0);
        o_mem_we    : out std_logic;
        o_mem_en    : out std_logic
    );

end project_reti_logiche;

architecture behavioral of project_reti_logiche is
    type tipo_stato is (RESET, ATTESA, PARI, DISPARI);  -- PARI: parola, DISPARI: cella vuota
    signal stato_attuale, stato_prossimo: tipo_stato;
    signal indice: std_logic_vector(9 downto 0);    -- indice di scorrimento nella sequenza
    signal modifica: std_logic;     -- indica la necessità di modificare la parola e di conseguenza la credibilità (quando si incontra uno zero in uno spazio di parola, eccetto NOTA)
    signal trovato_valore_diverso_da_zero: std_logic;   -- indica se è già stato trovato un valore diverso da 0 nella sequenza di parola, rimane 0 fino a quando non se ne trova uno
    signal o_mem_addr_tmp: std_logic_vector(15 downto 0);   -- segnale non sincronizzato
    signal o_mem_data_tmp: std_logic_vector(7 downto 0);    -- segnale non sincronizzato
    signal done_tmp,  o_mem_en_tmp,  o_mem_we: std_logic; -- segnali non sincronizzati
    
    begin
        gestione_stato: process(i_clk, i_rst)
        begin   
            if i_rst = '1' then 
                stato_attuale <= RESET;
            elsif rising_edge(i_clk) then
                stato_attuale <= stato_prossimo;
            end if;
        end process;
        
        gestione_transizione: process(stato_attuale)
        begin
            if stato_attuale = RESET then
                if i_rst = '0' then
                    if i_start = '0' then
                        stato_prossimo <= ATTESA;
                    else
                        stato_prossimo <= PARI;
                    end if;
                else
                    stato_prossimo <= stato_attuale;
                end if;
            elsif stato_attuale = ATTESA then
                if i_rst = '0' then
                    if i_start = '0' then
                        stato_prossimo <= stato_attuale;
                    else
                        stato_prossimo <= PARI;
                    end if;
                else
                    stato_prossimo <= RESET;
                end if;
            elsif stato_attuale = PARI then
                -- cambio segnali
            elsif stato_attuale = DISPARI then
                -- cambio segnali
            end if;
        end process;
          
end behavioral;