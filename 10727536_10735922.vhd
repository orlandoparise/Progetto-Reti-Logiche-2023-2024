library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity project_reti_logiche is
    port (
        i_clk : in std_logic;
        i_rst : in std_logic;
        i_start : in std_logic;
        i_add : in std_logic_vector(15 downto 0);
        i_k : in std_logic_vector(9 downto 0);

        o_done : out std_logic;

        o_mem_addr : out std_logic_vector(15 downto 0);
        i_mem_data : in std_logic_vector(7 downto 0);
        o_mem_data : out std_logic_vector(7 downto 0);
        o_mem_we : out std_logic;
        o_mem_en : out std_logic
    );

end project_reti_logiche;

architecture behavioral of project_reti_logiche is
    type tipo_stato is (RESET, ATTESA, PAROLA, READ_PAROLA_PREC, WRITE_PAROLA_PREC, CRED, READ_CRED_PREC, WRITE_CRED_PREC);
    signal stato_attuale, stato_prossimo : tipo_stato;
    signal indice : std_logic_vector(9 downto 0); -- indice di scorrimento nella sequenza
    signal modifica : std_logic; -- indica la necessità di modificare la parola e di conseguenza la CRED (quando si incontra uno zero in uno spazio di parola, eccetto NOTA)
    signal trovato_valore_diverso_da_zero : std_logic; -- indica se è già stato trovato un valore diverso da 0 nella sequenza di parola, rimane 0 fino a quando non se ne trova uno
    signal o_mem_addr_tmp : std_logic_vector(15 downto 0); -- segnale non sincronizzato
    signal o_mem_data_tmp : std_logic_vector(7 downto 0); -- segnale non sincronizzato
    signal o_done_tmp, o_mem_en_tmp, o_mem_we_tmp : std_logic; -- segnali non sincronizzati

begin
    gestione_clk_rst : process (i_clk, i_rst)
    begin
        if i_rst = '1' then
            stato_attuale <= RESET;

            -- inizializzazione al reset (asincrono)
            indice <= (others => '0');
            modifica <= '0';
            trovato_valore_diverso_da_zero <= '0';
            o_mem_addr <= (others => '0');
            o_mem_data <= (others => '0');
            o_done <= '0';
            o_mem_en <= '0';
            o_mem_we <= '0';

        elsif rising_edge(i_clk) then -- sincronizzazione sul fronte di salita
            stato_attuale <= stato_prossimo;

            o_mem_addr <= o_mem_addr_tmp;
            o_mem_data <= o_mem_data_tmp;
            o_done <= o_done_tmp;
            o_mem_we <= o_mem_we_tmp;
            o_mem_en <= o_mem_en_tmp;

        end if;
    end process;

    gestione_stati : process (stato_attuale)
    begin
        if stato_attuale = RESET then
            if i_rst = '0' then
                if i_start = '0' then
                    stato_prossimo <= ATTESA; -- vado in attesa al clock successivo

                    indice <= (others => '0');
                    modifica <= '0';
                    trovato_valore_diverso_da_zero <= '0';
                    o_mem_addr_tmp <= (others => '0');
                    o_mem_data_tmp <= (others => '0');
                    o_done_tmp <= '0';
                    o_mem_en_tmp <= '0';
                    o_mem_we_tmp <= '0';
                else
                    stato_prossimo <= PAROLA; -- inizio la computazione al clock successivo

                    indice <= (others => '0');
                    modifica <= '0';
                    trovato_valore_diverso_da_zero <= '0';
                    o_mem_addr_tmp <= i_add;
                    o_mem_data_tmp <= (others => '0');
                    o_done_tmp <= '0';
                    o_mem_en_tmp <= '1';
                    o_mem_we_tmp <= '0';
                end if;
            else
            end if;
        elsif stato_attuale = ATTESA then
            if i_rst = '0' then
                if i_start = '0' then
                    stato_prossimo <= stato_attuale;

                    indice <= (others => '0');
                    modifica <= '0';
                    trovato_valore_diverso_da_zero <= '0';
                    o_mem_addr_tmp <= (others => '0');
                    o_mem_data_tmp <= (others => '0');
                    o_done_tmp <= '0';
                    o_mem_en_tmp <= '0';
                    o_mem_we_tmp <= '0';
                else
                    stato_prossimo <= PAROLA;

                    indice <= (others => '0');
                    modifica <= '0';
                    trovato_valore_diverso_da_zero <= '0';
                    o_mem_addr_tmp <= i_add;
                    o_mem_data_tmp <= (others => '0');
                    o_done_tmp <= '0';
                    o_mem_en_tmp <= '1';
                    o_mem_we_tmp <= '0';
                end if;
            else
            end if;
        elsif stato_attuale = PAROLA then
            -- nel caso non siano ancora stati trovati valori diversi da 0 nella sequenza
            if valore_trovato_diverso_da_zero = '0' then
                stato_prossimo <= CRED;

                indice <= std_logic_vector(signed(o_mem_addr_tmp) - signed(i_add) + 1); -- non modifico il valore in quanto già 0 e passo allo stato successivo
                modifica <= '0';
                trovato_valore_diverso_da_zero <= '0';
                o_mem_addr_tmp <= std_logic_vector(signed(i_add) + signed(indice));
                o_mem_data_tmp <= (others => '0');
                o_done_tmp <= '0';
                o_mem_en_tmp <= '1';
                o_mem_we_tmp <= '0';

            else -- nel caso abbiamo già trovato una parola diversa da 0 nella sequenza
                if i_mem_data = "00000000" then -- il valore del dato nell'indice è 0    
                    modifica <= '1';
                    trovato_valore_diverso_da_zero <= '1';
                    o_mem_addr_tmp <= std_logic_vector(signed(i_add) + signed(indice) - 2);
                    o_mem_data_tmp <= (others => '0');
                    o_done_tmp <= '0';
                    o_mem_en_tmp <= '1';
                    o_mem_we_tmp <= '1';
                    indice <= std_logic_vector(signed(o_mem_addr_tmp) - signed(i_add) + 1);
                else
                    modifica <= '0';
                    trovato_valore_diverso_da_zero <= '1';
                    o_mem_addr_tmp <= std_logic_vector(signed(i_add) + signed(indice));
                    o_mem_data_tmp <= (others => '0');
                    o_done_tmp <= '0';
                    o_mem_en_tmp <= '1';
                    o_mem_we_tmp <= '1';
                    indice <= std_logic_vector(signed(o_mem_addr_tmp) - signed(i_add) + 1);
                end if;
            end if;

        elsif stato_attuale = READ_PAROLA_PREC then
            -- aggiornamento segnali

        elsif stato_attuale = WRITE_PAROLA_PREC then
            -- aggiornamento segnali

        elsif stato_attuale = CRED then
            -- nel caso non siano ancora stati trovati valori diversi da 0 nella sequenza
            if valore_trovato_diverso_da_zero = '0' then

                indice <= std_logic_vector(signed(o_mem_addr_tmp) - signed(i_add) + 1);

                if (signed(indice) < (signed(i_k) + signed(i_k) - 1)) then
                    stato_prossimo <= PAROLA;

                    modifica <= '0';
                    trovato_valore_diverso_da_zero <= '0';
                    o_mem_addr_tmp <= std_logic_vector(signed(i_add) + signed(indice));
                    o_mem_data_tmp <= (others => '0');
                    o_done_tmp <= '0';
                    o_mem_en_tmp <= '1';
                    o_mem_we_tmp <= '0';
                else
                    stato_prossimo <= ATTESA;

                    modifica <= '0';
                    trovato_valore_diverso_da_zero <= '0';
                    o_mem_addr_tmp <= (others => '0');
                    o_mem_data_tmp <= (others => '0');
                    o_done_tmp <= '1';
                    o_mem_en_tmp <= '0';
                    o_mem_we_tmp <= '0';
                end if;
            else -- nel caso abbiamo già trovato una parola diversa da 0 nella sequenza
                if i_mem_data = "00000000" then -- il valore del dato nell'indice è 0  
                    o_mem_data <= "00011111"; -- si scrive la CRED a 31
                    indice <= std_logic_vector(signed(o_mem_addr_tmp) - signed(i_add) + 1);

                    if (signed(indice) < (signed(i_k) + signed(i_k) - 1)) then
                        stato_prossimo <= PAROLA;

                        modifica <= '0';
                        trovato_valore_diverso_da_zero <= '0';
                        o_mem_addr_tmp <= std_logic_vector(signed(i_add) + signed(indice));
                        o_mem_data_tmp <= (others => '0');
                        o_done_tmp <= '0';
                        o_mem_en_tmp <= '1';
                        o_mem_we_tmp <= '0';
                    else
                        stato_prossimo <= ATTESA;

                        modifica <= '0';
                        trovato_valore_diverso_da_zero <= '0';
                        o_mem_addr_tmp <= (others => '0');
                        o_mem_data_tmp <= (others => '0');
                        o_done_tmp <= '1';
                        o_mem_en_tmp <= '0';
                        o_mem_we_tmp <= '0';
                    end if;
                end if;
            end if;
        
        elsif stato_attuale = READ_CRED_PREC then
        -- aggiornamento segnali

        elsif stato_attuale = WRITE_CRED_PREC then
        -- aggiornamento segnali
        
        end if;
    end process;
end behavioral;