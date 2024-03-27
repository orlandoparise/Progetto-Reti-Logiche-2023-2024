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
    type state_type is (RESET, WAITING, SHIFT_WORD, READ_WORD, LOAD_WORD, SHIFT_READ_PREV_WORD, READ_PREV_WORD, LOAD_PREV_WORD, SHIFT_WRITE_PREV_WORD, WRITE_PREV_WORD, SHIFT_READ_PREV_CRED, READ_PREV_CRED, LOAD_PREV_CRED, SHIFT_WRITE_PREV_CRED, WRITE_PREV_CRED, SHIFT_CRED, CRED, DONE);
    signal current_state, next_state : state_type; -- stato attuale (aggiornato sul fronte di salita del clock) e stato prossimo
    signal non_zero, next_non_zero: std_logic; -- diventano 1 appena si riscontra una parola diversa da zero
    signal index, next_index: integer; -- indici di scorrimento nella sequenza
    signal o_mem_addr_tmp : std_logic_vector(15 downto 0); -- segnale interno che rappresenta o_mem_addr allo stato successivo
    signal o_mem_data_tmp : std_logic_vector(7 downto 0); -- segnale interno che rappresenta o_mem_data allo stato successivo
    signal o_done_tmp, o_mem_en_tmp, o_mem_we_tmp : std_logic; -- segnali interni che rappresentano o_done, o_mem_en e o_mem_we allo stato successivo

begin
    
    gestione_clk_rst : process (i_clk, i_rst) -- processo che scandisce l'aggiornamento dei segnali sul fronte di salita del clock e gestisce eventuali situazioni di reset
    begin
        if i_rst = '1' then -- inizializzazione dei segnali di uscita e ritorno allo stato di reset
            current_state <= RESET;
            non_zero <= '0';
            index <= 0;

            o_mem_addr <= (others => '0');
            o_mem_data <= (others => '0');
            o_done <= '0';
            o_mem_en <= '0';
            o_mem_we <= '0';

        elsif rising_edge(i_clk) then -- sincronizzazione dei segnali di uscita e passaggio allo stato prossimo
            current_state <= next_state;
            non_zero <= next_non_zero;
            index <= next_index;

            o_mem_addr <= o_mem_addr_tmp;
            o_mem_data <= o_mem_data_tmp;
            o_done <= o_done_tmp;
            o_mem_we <= o_mem_we_tmp;
            o_mem_en <= o_mem_en_tmp;

        end if;
    end process;

    gestione_stati : process (current_state, i_rst, i_start) -- processo che aggiorna i segnali interni in base ai segnali d'ingresso e allo stato in cui ci si trova
    begin
        next_state <= RESET;
        next_non_zero <= '0';
        next_index <= 0;

        o_mem_addr_tmp <= (others => '0');
        o_mem_data_tmp <= (others => '0');
        o_done_tmp <= '0';
        o_mem_en_tmp <= '0';
        o_mem_we_tmp <= '0';
        
        if current_state = RESET OR current_state = WAITING then
            if i_rst = '0' then
                if i_start = '0' then 
                
                    if current_state = RESET then
                        next_state <= WAITING;
                    else 
                        next_state <= current_state;
                    end if;

                    next_non_zero <= '0';
                    next_index <= 0;

                    o_mem_addr_tmp <= (others => '0');
                    o_mem_data_tmp <= (others => '0');
                    o_done_tmp <= '0';
                    o_mem_en_tmp <= '0';
                    o_mem_we_tmp <= '0';
                else
                    next_state <= SHIFT_WORD; -- inizio della computazione

                    next_non_zero <= '0';
                    next_index <= 0;

                    o_mem_addr_tmp <= i_add; -- si comincia a leggere dal primo indirizzo
                    o_mem_data_tmp <= (others => '0');
                    o_done_tmp <= '0';
                    o_mem_en_tmp <= '1';
                    o_mem_we_tmp <= '0';
                end if;
            end if;

        elsif current_state = SHIFT_WORD OR current_state = READ_WORD then
            
            if current_state = SHIFT_WORD then
                next_state <= READ_WORD;
            else
                next_state <= LOAD_WORD;
            end if;
            
            next_non_zero <= non_zero;
            next_index <= index;

            o_mem_addr_tmp <= std_logic_vector(signed(i_add) + index);
            o_mem_data_tmp <= (others => '0');
            o_done_tmp <= '0';
            o_mem_en_tmp <= '1';
            o_mem_we_tmp <= '0';
        
        elsif current_state = LOAD_WORD then
            if i_mem_data = "00000000" AND non_zero = '0' then -- non sono ancora stati trovati valori diversi da 0 nella sequenza
                next_state <= SHIFT_CRED; -- non modifico il valore e passo allo stato successivo

                next_non_zero <= '0';
                next_index <= index + 1;

                o_mem_addr_tmp <= std_logic_vector(signed(i_add) + index + 1);
                o_mem_data_tmp <= (others => '0');
                o_done_tmp <= '0';
                o_mem_en_tmp <= '1';
                o_mem_we_tmp <= '1';

            else -- è già stata trovata una WORD diversa da 0 nella sequenza
                if i_mem_data = "00000000" then -- il valore del dato nell'index è 0    
                    next_state <= SHIFT_READ_PREV_WORD;

                    next_non_zero <= '1';
                    next_index <= index - 2;

                    o_mem_addr_tmp <= std_logic_vector(signed(i_add) + index - 2);
                    o_mem_data_tmp <= (others => '0');
                    o_done_tmp <= '0';
                    o_mem_en_tmp <= '1';
                    o_mem_we_tmp <= '0';
                else
                    next_state <= SHIFT_CRED;

                    next_non_zero <= '1';
                    next_index <= index + 1;

                    o_mem_addr_tmp <= std_logic_vector(signed(i_add) + index + 1);
                    o_mem_data_tmp <= "00011111";
                    o_done_tmp <= '0';
                    o_mem_en_tmp <= '1';
                    o_mem_we_tmp <= '1';
                end if;
            end if;
        
        elsif current_state = SHIFT_READ_PREV_WORD OR current_state = READ_PREV_WORD then
            if current_state = SHIFT_READ_PREV_WORD then
                next_state <= READ_PREV_WORD;
            else
                next_state <= LOAD_PREV_WORD;
            end if;

            next_non_zero <= '1';
            next_index <= index;

            o_mem_addr_tmp <= std_logic_vector(signed(i_add) + index);
            o_mem_data_tmp <= (others => '0');
            o_done_tmp <= '0';
            o_mem_en_tmp <= '1';
            o_mem_we_tmp <= '0';
        
        elsif current_state = LOAD_PREV_WORD then
            next_state <= SHIFT_WRITE_PREV_WORD;
            
            next_non_zero <= '1';
            next_index <= index + 2;

            o_mem_addr_tmp <= std_logic_vector(signed(i_add) + index + 2);
            o_mem_data_tmp <= i_mem_data;
            o_done_tmp <= '0';
            o_mem_en_tmp <= '1';
            o_mem_we_tmp <= '1';
        
        elsif current_state = SHIFT_WRITE_PREV_WORD then
            next_state <= WRITE_PREV_WORD;
            next_non_zero <= '1';
            next_index <= index;
            
            o_mem_addr_tmp <= std_logic_vector(signed(i_add) + index);
            o_mem_data_tmp <= i_mem_data;
            o_done_tmp <= '0';
            o_mem_en_tmp <= '1';
            o_mem_we_tmp <= '1';
            

        elsif current_state = WRITE_PREV_WORD then
            next_state <= SHIFT_READ_PREV_CRED;

            next_non_zero <= '1';            
            next_index <= index - 1;

            o_mem_addr_tmp <= std_logic_vector(signed(i_add) + index - 1);
            o_mem_data_tmp <= (others => '0');
            o_done_tmp <= '0';
            o_mem_en_tmp <= '1';
            o_mem_we_tmp <= '0';

        elsif current_state = SHIFT_READ_PREV_CRED OR current_state = READ_PREV_CRED then
            if current_state = SHIFT_READ_PREV_CRED then
                next_state <= READ_PREV_CRED;
            else
                next_state <= LOAD_PREV_CRED;
            end if;

            next_non_zero <= '1';
            next_index <= index;

            o_mem_addr_tmp <= std_logic_vector(signed(i_add) + index);
            o_mem_data_tmp <= (others => '0');
            o_done_tmp <= '0';
            o_mem_en_tmp <= '1';
            o_mem_we_tmp <= '0';
        
        elsif current_state = LOAD_PREV_CRED then
            next_state <= SHIFT_WRITE_PREV_CRED;

            next_non_zero <= '1';
            next_index <= index + 2;
            
            o_mem_addr_tmp <= std_logic_vector(signed(i_add) + index + 2);

            o_done_tmp <= '0';
            o_mem_en_tmp <= '1';
            o_mem_we_tmp <= '1';

        elsif current_state = SHIFT_WRITE_PREV_CRED then
            next_state <= WRITE_PREV_CRED;

            next_non_zero <= '1';
            next_index <= index;

            o_mem_addr_tmp <= std_logic_vector(signed(i_add) + index);

            if (signed(i_mem_data) > 0) then
                o_mem_data_tmp <= std_logic_vector(signed(i_mem_data) - 1);
            else
                o_mem_data_tmp <= "00000000";
            end if;
            
            o_done_tmp <= '0';
            o_mem_en_tmp <= '1';
            o_mem_we_tmp <= '1';

        elsif current_state = WRITE_PREV_CRED then
            next_index <= index + 1;

            if ((index + 1) < (signed(i_k) + signed(i_k) - 1)) then
                next_state <= SHIFT_WORD;

                next_non_zero <= '1';

                o_mem_addr_tmp <= std_logic_vector(signed(i_add) + index + 1);
                o_mem_data_tmp <= (others => '0');
                o_done_tmp <= '0';
                o_mem_en_tmp <= '1';
                o_mem_we_tmp <= '0';
            else
                next_state <= DONE;

                next_index <= 0;
                next_non_zero <= '0';

                o_mem_addr_tmp <= (others => '0');
                o_mem_data_tmp <= (others => '0');
                o_done_tmp <= '1';
                o_mem_en_tmp <= '0';
                o_mem_we_tmp <= '0';
            end if;
        
        elsif current_state = SHIFT_CRED then
            next_state <= CRED;
            next_index <= index;
            
            if non_zero = '1' then
                next_non_zero <= '1';

                o_mem_addr_tmp <= std_logic_vector(signed(i_add) + index);
                o_mem_data_tmp <= "00011111";
                o_done_tmp <= '0';
                o_mem_en_tmp <= '1';
                o_mem_we_tmp <= '1';
            else
                next_non_zero <= '0';

                o_mem_addr_tmp <= std_logic_vector(signed(i_add) + index);
                o_mem_data_tmp <= "00000000";
                o_done_tmp <= '0';
                o_mem_en_tmp <= '1';
                o_mem_we_tmp <= '1';
            end if;

        elsif current_state = CRED then
            if non_zero = '0' then -- non sono ancora stati trovati valori diversi da 0 nella sequenza
                
                next_index <= index + 1;

                if ((index + 1) < (signed(i_k) + signed(i_k) - 1)) then
                    next_state <= SHIFT_WORD;

                    next_non_zero <= '0';

                    o_mem_addr_tmp <= std_logic_vector(signed(i_add) + index + 1);
                    o_mem_data_tmp <= (others => '0');
                    o_done_tmp <= '0';
                    o_mem_en_tmp <= '1';
                    o_mem_we_tmp <= '0';
                else
                    next_state <= DONE;

                    next_index <= 0;
                    next_non_zero <= '0';

                    o_mem_addr_tmp <= (others => '0');
                    o_mem_data_tmp <= (others => '0');
                    o_done_tmp <= '1';
                    o_mem_en_tmp <= '0';
                    o_mem_we_tmp <= '0';
                end if;
            else
                next_index <= index + 1;

                if (next_index < (signed(i_k) + signed(i_k) - 1)) then
                    next_state <= SHIFT_WORD;

                    next_non_zero <= '1';

                    o_mem_addr_tmp <= std_logic_vector(signed(i_add) + index + 1);
                    o_mem_data_tmp <= (others => '0');
                    o_done_tmp <= '0';
                    o_mem_en_tmp <= '1';
                    o_mem_we_tmp <= '0';
                else
                    next_state <= DONE;

                    next_non_zero <= '0';
                    next_index <= 0;

                    o_mem_addr_tmp <= (others => '0');
                    o_mem_data_tmp <= (others => '0');
                    o_done_tmp <= '1';
                    o_mem_en_tmp <= '0';
                    o_mem_we_tmp <= '0';
                end if;
            end if;
        
        elsif current_state = DONE then
            next_state <= WAITING;

            next_non_zero <= '0';
            next_index <= 0;

            o_mem_addr_tmp <= (others => '0');
            o_mem_data_tmp <= (others => '0');
            o_done_tmp <= '1';
            o_mem_en_tmp <= '0';
            o_mem_we_tmp <= '0';
        
        else
            next_state <= RESET;
            next_non_zero <= '0';
            next_index <= 0;
        
        end if;
    end process;
end behavioral;