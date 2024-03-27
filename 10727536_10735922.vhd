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
    type state_type is (RESET, WAITING, SHIFT_WORD, READ_WORD, LOAD_WORD, SHIFT_READ_PREV_WORD, READ_PREV_WORD, LOAD_PREV_WORD, SHIFT_WRITE_PREV_WORD, WRITE_PREV_WORD, SHIFT_READ_PREV_CRED, READ_PREV_CRED, LOAD_PREV_CRED, SHIFT_WRITE_PREV_CRED, WRITE_PREV_CRED, SHIFT_CRED, CRED, DONE); -- stati della FSM
    signal current_state, next_state : state_type; -- stato attuale (aggiornato sul fronte di salita del clock) e stato successivo
    signal non_zero, next_non_zero: std_logic; -- riscontro di una parola diversa da zero, allo stato attuale e allo stato successivo
    signal index, next_index: integer; -- indice nella sequenza, allo stato attuale e allo stato successivo
    signal o_mem_addr_tmp : std_logic_vector(15 downto 0); -- o_mem_addr allo stato successivo
    signal o_mem_data_tmp : std_logic_vector(7 downto 0); -- o_mem_data allo stato successivo
    signal o_done_tmp, o_mem_en_tmp, o_mem_we_tmp : std_logic; -- o_done, o_mem_en e o_mem_we allo stato successivo

begin
    manage_clk_rst : process (i_clk, i_rst) -- processo che scandisce i segnali ad ogni clock e gestisce eventi di reset
    begin
        if i_rst = '1' then -- inizializzazione dei segnali in condizione di reset
            current_state <= RESET;
            non_zero <= '0';
            index <= 0;
            o_mem_addr <= (others => '0');
            o_mem_data <= (others => '0');
            o_done <= '0';
            o_mem_en <= '0';
            o_mem_we <= '0';

        elsif rising_edge(i_clk) then -- sincronizzazione dei segnali (interni e di uscita) sul fronte di salita del clock
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

    manage_states : process (current_state, i_rst, i_start) -- processo che aggiorna i segnali interni in base ai segnali d'ingresso e allo stato in cui ci si trova
    begin
        -- segnali di default che prevengono la generazione di latch
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
                if i_start = '0' then -- se il segnale di reset è abbassato e quello di start deve ancora alzarsi ci si trova nello stato di attesa
                    if current_state = RESET then
                        next_state <= WAITING;
                    else 
                        next_state <= current_state;
                    end if;
                else
                    next_state <= SHIFT_WORD; -- inizio della computazione
                    o_mem_addr_tmp <= i_add; -- si comincia a leggere dal primo indirizzo
                    o_mem_en_tmp <= '1';
                end if;
            end if;

        elsif current_state = SHIFT_WORD OR current_state = READ_WORD then
            if current_state = SHIFT_WORD then
                next_state <= READ_WORD;
            else
                next_state <= LOAD_WORD;
            end if;

            next_non_zero <= non_zero;
            next_index <= index; -- si rimane all'indirizzo corrente per accedere a quanto letto
            o_mem_addr_tmp <= std_logic_vector(signed(i_add) + index);
            o_mem_en_tmp <= '1';
        
        elsif current_state = LOAD_WORD then
            if i_mem_data = "00000000" AND non_zero = '0' then -- non sono ancora state trovate parole diverse da zero
                next_state <= SHIFT_CRED;
                next_index <= index + 1;
                o_mem_addr_tmp <= std_logic_vector(signed(i_add) + index + 1);
                o_mem_en_tmp <= '1';
                o_mem_we_tmp <= '1';

            else -- è già stata trovata una parola diversa da zero
                if i_mem_data = "00000000" then
                    next_state <= SHIFT_READ_PREV_WORD;
                    next_non_zero <= '1';
                    next_index <= index - 2; -- si va a leggere la parola precedente
                    o_mem_addr_tmp <= std_logic_vector(signed(i_add) + index - 2);
                    o_mem_en_tmp <= '1';
                else
                    next_state <= SHIFT_CRED;
                    next_non_zero <= '1';
                    next_index <= index + 1; -- la parola è diversa da zero perciò si procede
                    o_mem_addr_tmp <= std_logic_vector(signed(i_add) + index + 1);
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
            next_index <= index; -- si rimane all'indirizzo corrente per accedere a quanto letto
            o_mem_addr_tmp <= std_logic_vector(signed(i_add) + index);
            o_mem_en_tmp <= '1';
        
        elsif current_state = LOAD_PREV_WORD then
            next_state <= SHIFT_WRITE_PREV_WORD;
            next_non_zero <= '1';
            next_index <= index + 2; -- si torna all'indirizzo della parola uguale a zero
            o_mem_addr_tmp <= std_logic_vector(signed(i_add) + index + 2);
            o_mem_data_tmp <= i_mem_data;
            o_mem_en_tmp <= '1';
            o_mem_we_tmp <= '1';
        
        elsif current_state = SHIFT_WRITE_PREV_WORD then
            next_state <= WRITE_PREV_WORD;
            next_non_zero <= '1';
            next_index <= index; -- si rimane all'indirizzo corrente per scrivere la parola precedente
            o_mem_addr_tmp <= std_logic_vector(signed(i_add) + index);
            o_mem_data_tmp <= i_mem_data;
            o_mem_en_tmp <= '1';
            o_mem_we_tmp <= '1';
            
        elsif current_state = WRITE_PREV_WORD then
            next_state <= SHIFT_READ_PREV_CRED;
            next_non_zero <= '1';            
            next_index <= index - 1; -- si va a leggere la credibilità della parola precedente
            o_mem_addr_tmp <= std_logic_vector(signed(i_add) + index - 1);
            o_mem_en_tmp <= '1';

        elsif current_state = SHIFT_READ_PREV_CRED OR current_state = READ_PREV_CRED then
            if current_state = SHIFT_READ_PREV_CRED then
                next_state <= READ_PREV_CRED;
            else
                next_state <= LOAD_PREV_CRED;
            end if;

            next_non_zero <= '1';
            next_index <= index; -- si rimane all'indirizzo corrente per accedere a quanto letto
            o_mem_addr_tmp <= std_logic_vector(signed(i_add) + index);
            o_mem_en_tmp <= '1';
        
        elsif current_state = LOAD_PREV_CRED then
            next_state <= SHIFT_WRITE_PREV_CRED;
            next_non_zero <= '1';
            next_index <= index + 2; -- si va a scrivere la credibilità della parola
            o_mem_addr_tmp <= std_logic_vector(signed(i_add) + index + 2);
            o_mem_en_tmp <= '1';
            o_mem_we_tmp <= '1';

        elsif current_state = SHIFT_WRITE_PREV_CRED then
            next_state <= WRITE_PREV_CRED;
            next_non_zero <= '1';
            next_index <= index; -- si rimane all'indirizzo corrente per scrivere la credibiltà
            o_mem_addr_tmp <= std_logic_vector(signed(i_add) + index);

            if (signed(i_mem_data) > 0) then -- il valore non può essere essere negativo
                o_mem_data_tmp <= std_logic_vector(signed(i_mem_data) - 1); 
            else
                o_mem_data_tmp <= "00000000";
            end if;

            o_mem_en_tmp <= '1';
            o_mem_we_tmp <= '1';

        elsif current_state = WRITE_PREV_CRED then
            next_index <= index + 1;

            if ((index + 1) < (signed(i_k) + signed(i_k) - 1)) then -- si verifica che non sia stata raggiunta la fine della sequenza
                next_state <= SHIFT_WORD;
                next_non_zero <= '1';
                o_mem_addr_tmp <= std_logic_vector(signed(i_add) + index + 1);
                o_mem_en_tmp <= '1';
            else
                next_state <= DONE;
                o_done_tmp <= '1';
            end if;
        
        elsif current_state = SHIFT_CRED then
            next_state <= CRED;
            next_index <= index; -- si rimane all'indirizzo corrente per scrivere la credibiltà
            
            if non_zero = '1' then
                next_non_zero <= '1';
                o_mem_addr_tmp <= std_logic_vector(signed(i_add) + index);
                o_mem_data_tmp <= "00011111";
                o_mem_en_tmp <= '1';
                o_mem_we_tmp <= '1';
            else
                o_mem_addr_tmp <= std_logic_vector(signed(i_add) + index);
                o_mem_en_tmp <= '1';
                o_mem_we_tmp <= '1';
            end if;

        elsif current_state = CRED then
            if non_zero = '0' then -- se non è ancora stata letta una parola diversa da zero
                next_index <= index + 1;

                if ((index + 1) < (signed(i_k) + signed(i_k) - 1)) then -- si verifica che non sia stata raggiunta la fine della sequenza
                    next_state <= SHIFT_WORD;
                    o_mem_addr_tmp <= std_logic_vector(signed(i_add) + index + 1);
                    o_mem_en_tmp <= '1';
                else
                    next_state <= DONE;
                    o_done_tmp <= '1';
                end if;
            else
                next_index <= index + 1;

                if ((index + 1) < (signed(i_k) + signed(i_k) - 1)) then -- si verifica che non sia stata raggiunta la fine della sequenza
                    next_state <= SHIFT_WORD;
                    next_non_zero <= '1';
                    o_mem_addr_tmp <= std_logic_vector(signed(i_add) + index + 1);
                    o_mem_en_tmp <= '1';
                else
                    next_state <= DONE;
                    o_done_tmp <= '1';
                end if;
            end if;
        
        elsif current_state = DONE then
            next_state <= WAITING; -- si torna allo stato di attesa
            o_done_tmp <= '1';
        
        end if;
    end process;
end behavioral;