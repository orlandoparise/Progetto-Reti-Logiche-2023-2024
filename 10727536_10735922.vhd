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
    signal modifica : std_logic; -- indica la necessità di modificare la parola e di conseguenza la credibilità (quando si incontra uno zero in uno spazio di parola, eccetto NOTA)
    signal trovato_valore_diverso_da_zero : std_logic; -- indica se è già stato trovato un valore diverso da 0 nella sequenza di parola, rimane 0 fino a quando non se ne trova uno
    signal o_mem_addr_tmp : std_logic_vector(15 downto 0); -- segnale non sincronizzato
    signal o_mem_data_tmp : std_logic_vector(7 downto 0); -- segnale non sincronizzato
    signal o_done_tmp, o_mem_en_tmp, o_mem_we_tmp : std_logic; -- segnali non sincronizzati

begin
    gestione_clk_rst : process (i_clk, i_rst)
    begin
        if i_rst = '1' then -- inizializzazione al reset (asincrono)
            stato_attuale <= RESET;

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
            if i_rst = '0' then -- se il segnale di reset è 0
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
            end if;
        
        elsif stato_attuale = PAROLA then
            if trovato_valore_diverso_da_zero = '0' then -- non sono ancora stati trovati valori diversi da 0 nella sequenza
                stato_prossimo <= CRED; -- non modifico il valore e passo allo stato successivo

                indice <= std_logic_vector(signed(o_mem_addr_tmp) - signed(i_add) + 1);
                modifica <= '0';
                trovato_valore_diverso_da_zero <= '0';
                o_mem_addr_tmp <= std_logic_vector(signed(i_add) + signed(indice));
                o_mem_data_tmp <= (others => '0');
                o_done_tmp <= '0';
                o_mem_en_tmp <= '1';
                o_mem_we_tmp <= '0';

            else -- è già stata trovata una parola diversa da 0 nella sequenza
                if i_mem_data = "00000000" then -- il valore del dato nell'indice è 0    
                    stato_prossimo <= READ_PAROLA_PREC;

                    indice <= std_logic_vector(signed(o_mem_addr_tmp) - signed(i_add) - 2);
                    modifica <= '1';
                    trovato_valore_diverso_da_zero <= '1';
                    o_mem_addr_tmp <= std_logic_vector(signed(i_add) + signed(indice));
                    o_mem_data_tmp <= (others => '0');
                    o_done_tmp <= '0';
                    o_mem_en_tmp <= '1';
                    o_mem_we_tmp <= '0';
                else
                    stato_prossimo <= CRED;

                    indice <= std_logic_vector(signed(o_mem_addr_tmp) - signed(i_add) + 1);
                    modifica <= '0';
                    trovato_valore_diverso_da_zero <= '1';
                    o_mem_addr_tmp <= std_logic_vector(signed(i_add) + signed(indice));
                    o_mem_data_tmp <= "00011111";
                    o_done_tmp <= '0';
                    o_mem_en_tmp <= '1';
                    o_mem_we_tmp <= '1';
                end if;
            end if;

        elsif stato_attuale = READ_PAROLA_PREC then
            stato_prossimo <= WRITE_PAROLA_PREC;

            indice <= std_logic_vector(signed(o_mem_addr_tmp) - signed(i_add) + 2);
            modifica <= '1';
            trovato_valore_diverso_da_zero <= '1';
            o_mem_addr_tmp <= std_logic_vector(signed(i_add) + signed(indice));
            o_mem_data_tmp <= (others => '0');
            o_done_tmp <= '0';
            o_mem_en_tmp <= '1';
            o_mem_we_tmp <= '1';

        elsif stato_attuale = WRITE_PAROLA_PREC then
            stato_prossimo <= READ_CRED_PREC;

            indice <= std_logic_vector(signed(o_mem_addr_tmp) - signed(i_add) - 1);
            modifica <= '1';
            trovato_valore_diverso_da_zero <= '1';
            o_mem_addr_tmp <= std_logic_vector(signed(i_add) + signed(indice));
            o_mem_data_tmp <= (others => '0');
            o_done_tmp <= '0';
            o_mem_en_tmp <= '1';
            o_mem_we_tmp <= '0';

        elsif stato_attuale = CRED then
            if trovato_valore_diverso_da_zero = '0' then -- non sono ancora stati trovati valori diversi da 0 nella sequenza
            
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
            else
                indice <= std_logic_vector(signed(o_mem_addr_tmp) - signed(i_add) + 1);

                if (signed(indice) < (signed(i_k) + signed(i_k) - 1)) then
                    stato_prossimo <= PAROLA;

                    modifica <= '0';
                    trovato_valore_diverso_da_zero <= '1';
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
        
        elsif stato_attuale = READ_CRED_PREC then
            stato_prossimo <= WRITE_CRED_PREC;

            indice <= std_logic_vector(signed(o_mem_addr_tmp) - signed(i_add) + 2);
            modifica <= '1';
            trovato_valore_diverso_da_zero <= '1';
            o_mem_addr_tmp <= std_logic_vector(signed(i_add) + signed(indice));

            if (signed(i_mem_data) > 0) then
                o_mem_data_tmp <= std_logic_vector(signed(i_mem_data) - 1);
            else
                o_mem_data_tmp <= "00000000";
            end if;
            
            o_done_tmp <= '0';
            o_mem_en_tmp <= '1';
            o_mem_we_tmp <= '1';

        elsif stato_attuale = WRITE_CRED_PREC then
            indice <= std_logic_vector(signed(o_mem_addr_tmp) - signed(i_add) + 1);

            if (signed(indice) < (signed(i_k) + signed(i_k) - 1)) then
                stato_prossimo <= PAROLA;

                modifica <= '0';
                trovato_valore_diverso_da_zero <= '1';
                o_mem_addr_tmp <= std_logic_vector(signed(i_add) + signed(indice));
                o_mem_data_tmp <= (others => '0');
                o_done_tmp <= '0';
                o_mem_en_tmp <= '1';
                o_mem_we_tmp <= '0';
            else
                stato_prossimo <= ATTESA;

                indice <= (others => '0');
                modifica <= '0';
                trovato_valore_diverso_da_zero <= '0';
                o_mem_addr_tmp <= (others => '0');
                o_mem_data_tmp <= (others => '0');
                o_done_tmp <= '0';
                o_mem_en_tmp <= '0';
                o_mem_we_tmp <= '0';
            end if;

        else
            stato_prossimo <= stato_attuale;
        end if;
    end process;
end behavioral;