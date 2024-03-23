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
    type state_type is (RESET, WAITING, WORD, READ_PREV_WORD, WRITE_PREV_WORD, CRED, READ_PREV_CRED, WRITE_PREV_CRED);
    signal current_state, next_state : state_type;
    signal o_mem_addr_tmp : std_logic_vector(15 downto 0);
    signal o_mem_data_tmp : std_logic_vector(7 downto 0);
    signal o_done_tmp, o_mem_en_tmp, o_mem_we_tmp : std_logic;

begin
    gestione_clk_rst : process (i_clk, i_rst)
    begin
        if i_rst = '1' then -- inizializzazione al reset (asincrono)
            current_state <= WAITING;

            o_mem_addr <= (others => '0');
            o_mem_data <= (others => '0');
            o_done <= '0';
            o_mem_en <= '0';
            o_mem_we <= '0';

        elsif rising_edge(i_clk) then -- sincronizzazione sul fronte di salita
            current_state <= next_state;

            o_mem_addr <= o_mem_addr_tmp;
            o_mem_data <= o_mem_data_tmp;
            o_done <= o_done_tmp;
            o_mem_we <= o_mem_we_tmp;
            o_mem_en <= o_mem_en_tmp;
        end if;
    end process;

    gestione_stati : process (current_state, i_rst, i_start, i_mem_data)
    variable index : integer;
    variable load: std_logic;
    variable non_zero: std_logic;
    begin
        if current_state = RESET then
            if i_rst = '0' then -- se il segnale di reset diventa 0
                if i_start = '0' then
                    next_state <= WAITING; -- stato di WAITING

                    o_mem_addr_tmp <= (others => '0');
                    o_mem_data_tmp <= (others => '0');
                    o_done_tmp <= '0';
                    o_mem_en_tmp <= '0';
                    o_mem_we_tmp <= '0';
                else
                    next_state <= WORD; -- inizio della computazione

                    index := 0;
                    load := '1';
                    non_zero := '0';

                    o_mem_addr_tmp <= i_add;
                    o_mem_data_tmp <= (others => '0');
                    o_done_tmp <= '0';
                    o_mem_en_tmp <= '1';
                    o_mem_we_tmp <= '0';
                end if;
            end if;

        elsif current_state = WAITING then
            if i_rst = '0' then
                if i_start = '0' then
                    next_state <= current_state;

                    o_mem_addr_tmp <= (others => '0');
                    o_mem_data_tmp <= (others => '0');
                    o_done_tmp <= '0';
                    o_mem_en_tmp <= '0';
                    o_mem_we_tmp <= '0';
                else
                    next_state <= WORD;

                    index := 0;
                    load := '1';
                    non_zero := '0';

                    o_mem_addr_tmp <= i_add;
                    o_mem_data_tmp <= (others => '0');
                    o_done_tmp <= '0';
                    o_mem_en_tmp <= '1';
                    o_mem_we_tmp <= '0';
                end if;
            end if;
        
        elsif current_state = WORD then
            if load = '1' then
                next_state <= WORD;
                load := '0';
            else
                if i_mem_data = "00000000" AND non_zero = '0' then -- non sono ancora stati trovati valori diversi da 0 nella sequenza
                    next_state <= CRED; -- non modifico il valore e passo allo stato successivo

                    index := index + 1;
                    load := '1';
                    non_zero := '0';

                    o_mem_addr_tmp <= std_logic_vector(signed(i_add) + index);
                    o_mem_data_tmp <= (others => '0');
                    o_done_tmp <= '0';
                    o_mem_en_tmp <= '1';
                    o_mem_we_tmp <= '1';

                else -- è già stata trovata una WORD diversa da 0 nella sequenza
                    if i_mem_data = "00000000" then -- il valore del dato nell'index è 0    
                        next_state <= READ_PREV_WORD;

                        index := index - 2;
                        load := '1';
                        non_zero := '1';

                        o_mem_addr_tmp <= std_logic_vector(signed(i_add) + index);
                        o_mem_data_tmp <= (others => '0');
                        o_done_tmp <= '0';
                        o_mem_en_tmp <= '1';
                        o_mem_we_tmp <= '0';
                    else
                        next_state <= CRED;

                        index := index + 1;
                        load := '1';
                        non_zero := '1';

                        o_mem_addr_tmp <= std_logic_vector(signed(i_add) + index);
                        o_mem_data_tmp <= "00011111";
                        o_done_tmp <= '0';
                        o_mem_en_tmp <= '1';
                        o_mem_we_tmp <= '1';
                    end if;
                end if;
            end if;

        elsif current_state = READ_PREV_WORD then
            if load = '1' then
                next_state <= READ_PREV_WORD;
                load := '0';
            else 
                next_state <= WRITE_PREV_WORD;

                index := index + 2;
                load := '1';
                non_zero := '1';

                o_mem_addr_tmp <= std_logic_vector(signed(i_add) + index);
                o_mem_data_tmp <= i_mem_data;
                o_done_tmp <= '0';
                o_mem_en_tmp <= '1';
                o_mem_we_tmp <= '1';
            end if;

        elsif current_state = WRITE_PREV_WORD then
            if load = '1' then
                next_state <= WRITE_PREV_WORD;
                load := '0';
            else
                next_state <= READ_PREV_CRED;

                index := index - 1;
                load := '1';
                non_zero := '1';

                o_mem_addr_tmp <= std_logic_vector(signed(i_add) + index);
                o_mem_data_tmp <= (others => '0');
                o_done_tmp <= '0';
                o_mem_en_tmp <= '1';
                o_mem_we_tmp <= '0';
            end if;
            
        elsif current_state = READ_PREV_CRED then
            if load = '1' then
                next_state <= READ_PREV_CRED;
                load := '0';
            else
                next_state <= WRITE_PREV_CRED;

                index := index + 2;
                load := '1';
                non_zero := '1';
                o_mem_addr_tmp <= std_logic_vector(signed(i_add) + index);

                if (signed(i_mem_data) > 0) then
                    o_mem_data_tmp <= std_logic_vector(signed(i_mem_data) - 1);
                else
                    o_mem_data_tmp <= "00000000";
                end if;

                o_done_tmp <= '0';
                o_mem_en_tmp <= '1';
                o_mem_we_tmp <= '1';
            end if;

        elsif current_state = WRITE_PREV_CRED then
            if load = '1' then
                next_state <= WRITE_PREV_CRED;
                load := '0';
            else
                index := index + 1;

                if (index < (signed(i_k) + signed(i_k) - 1)) then
                    next_state <= WORD;

                    load := '1';
                    non_zero := '1';

                    o_mem_addr_tmp <= std_logic_vector(signed(i_add) + index);
                    o_mem_data_tmp <= (others => '0');
                    o_done_tmp <= '0';
                    o_mem_en_tmp <= '1';
                    o_mem_we_tmp <= '0';
                else
                    next_state <= WAITING;

                    index := 0;
                    load := '0';
                    non_zero := '0';

                    o_mem_addr_tmp <= (others => '0');
                    o_mem_data_tmp <= (others => '0');
                    o_done_tmp <= '0';
                    o_mem_en_tmp <= '0';
                    o_mem_we_tmp <= '0';
                end if;
            end if;

        elsif current_state = CRED then
            if load = '1' then
                next_state <= CRED;
                load := '0';
            else
                if non_zero = '0' then -- non sono ancora stati trovati valori diversi da 0 nella sequenza
                
                    index := index + 1;

                    if (index < (signed(i_k) + signed(i_k) - 1)) then
                        next_state <= WORD;

                        load := '1';
                        non_zero := '0';

                        o_mem_addr_tmp <= std_logic_vector(signed(i_add) + index);
                        o_mem_data_tmp <= (others => '0');
                        o_done_tmp <= '0';
                        o_mem_en_tmp <= '1';
                        o_mem_we_tmp <= '0';
                    else
                        next_state <= WAITING;

                        index := 0;
                        load := '0';
                        non_zero := '0';

                        o_mem_addr_tmp <= (others => '0');
                        o_mem_data_tmp <= (others => '0');
                        o_done_tmp <= '1';
                        o_mem_en_tmp <= '0';
                        o_mem_we_tmp <= '0';
                    end if;
                else
                    index := index + 1;

                    if (index < (signed(i_k) + signed(i_k) - 1)) then
                        next_state <= WORD;

                        load := '1';
                        non_zero := '1';

                        o_mem_addr_tmp <= std_logic_vector(signed(i_add) + index);
                        o_mem_data_tmp <= (others => '0');
                        o_done_tmp <= '0';
                        o_mem_en_tmp <= '1';
                        o_mem_we_tmp <= '0';
                    else
                        next_state <= WAITING;

                        index := 0;
                        load := '0';
                        non_zero := '0';

                        o_mem_addr_tmp <= (others => '0');
                        o_mem_data_tmp <= (others => '0');
                        o_done_tmp <= '1';
                        o_mem_en_tmp <= '0';
                        o_mem_we_tmp <= '0';
                    end if;
                end if;
            end if;
        end if;
    end process;
end behavioral;