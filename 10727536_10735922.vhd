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
    type tipo_stato is (RESET, ASPETTA, PARI, DISPARI); -- PARI: parola, DISPARI: cella vuota
    signal stato_attuale, stato_prossimo: tipo_stato;
    signal indice: std_logic_vector(9 downto 0);
    
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
                        stato_prossimo <= ASPETTA;
                    else
                        stato_prossimo <= PARI;
                    end if;
                else
                    stato_prossimo <= stato_attuale;
                end if;
            elsif stato_attuale = ASPETTA then
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