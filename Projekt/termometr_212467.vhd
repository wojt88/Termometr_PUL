
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_unsigned.all;

entity termometr is
    Port (  
	 
		clk : in std_logic ; 									--zegar
		reset : in std_logic; 									--reset
		onewire : inout std_logic;   							--linia onewire							


		a_to_g : out STD_LOGIC_VECTOR (6 downto 0);		-- poszczególne segmenty wyœwietlacza, segmenty a,b,c,d,e,f,g
		anody : out STD_LOGIC_VECTOR (3 downto 0);		-- sekcje wyœwietlacza, wspólne anody
      dot : out  STD_LOGIC										-- kropka
		
	);
end termometr;

architecture Behavioral of termometr is

	signal cnt_1us : std_logic_vector(4 downto 0); 
	signal int_1us : std_logic; 
	signal is_conv : std_logic :='0'; 
	signal cnt_ow : std_logic_vector(19 downto 0):="00000000000000000000";
	signal cnt_bit : std_logic_vector(14 downto 0):="000000000000000";	
	signal ow_data : std_logic_vector(15 downto 0);	
	signal ow_out  :  std_logic;  --! ow_out to port
	signal ow_in   :  std_logic;  --! ow_in from port
	signal ow_dir  :  std_logic;        --! '0' = in, '1' = out
	signal next_state : std_logic :='0';
	
	signal x : STD_LOGIC_VECTOR (19 downto 0);			-- dane odczytane z onewire			
	signal digit : STD_LOGIC_VECTOR (3 downto 0);
	signal clk_div : STD_LOGIC_VECTOR (23 downto 0) := X"000000";
	signal s : STD_LOGIC_VECTOR (1 downto 0):="00";
	
	type STATES is (reset_ow,wait_presence,skip_rom, convent_t,wait_750ms, read_skratchpad,
	read_data,save_data, wait_4_resp);
	signal state : STATES := reset_ow; 						--maszyna stanów onewire
	
	type BIT_STATES is (b0,b1,b2,b3,b4,b5,b6,b7,b8,b9,b10,b11,b12,b13,b14,b15);
	signal bit_state : BIT_STATES := b0; 					--maszyna nadawania/ odbioru bitów
	
	function to_bcd ( bin : std_logic_vector(7 downto 0) ) return std_logic_vector is
	
	variable i : integer:=0;
	
		variable bcd : std_logic_vector(11 downto 0) := (others => '0');
		variable bint : std_logic_vector(7 downto 0) := bin;

		begin
		for i in 0 to 7 loop  
			bcd(11 downto 1) := bcd(10 downto 0);  
			bcd(0) := bint(7);
			bint(7 downto 1) := bint(6 downto 0);
			bint(0) :='0';


			if(i < 7 and bcd(3 downto 0) > "0100") then 
				bcd(3 downto 0) := bcd(3 downto 0) + "0011";
			end if;

			if(i < 7 and bcd(7 downto 4) > "0100") then 
				bcd(7 downto 4) := bcd(7 downto 4) + "0011";
			end if;

			if(i < 7 and bcd(11 downto 8) > "0100") then  
				bcd(11 downto 8) := bcd(11 downto 8) + "0011";
			end if;

		end loop;
		return bcd;
end to_bcd;
	
begin

	ow: process (reset, int_1us)
		begin
			if (reset = '0') then
				state <= reset_ow;			elsif (rising_edge(int_1us)) then
				case (state) is
				
					when reset_ow => --impuls reset
						cnt_ow <= cnt_ow + 1; 
						ow_dir <= '1';
						ow_out<='0';
						if (cnt_ow="00000000000111100100") then
							cnt_ow <="00000000000000000001";
							state <= wait_presence;
							ow_dir <= '0';
							ow_out<='Z';
						end if;
						
						
					when wait_presence => --oczekiwanie na impuls presence
						cnt_ow <= cnt_ow + 1; 
						if ow_in ='0' then next_state <='1';
						end if;
						if (cnt_ow="100111000100000") then
							cnt_ow <="00000000000000000001"; 
							
							if next_state ='1' then state <= skip_rom;
							else state <= reset_ow;
							end if;
						end if;
						
					when skip_rom => -- wys³anie komendy 0xCC
												
						case (bit_state) is 
								
							when b0 => -- ok0
							cnt_bit <= cnt_bit + 1;
								if cnt_bit="000000000000000" then
									ow_dir <= '1';
									ow_out<='0';
								end if;	
								if cnt_bit="000000000111100" then
									ow_dir <= '0';
									ow_out<='Z';
								end if;	
								if cnt_bit="000000001000101" then
								
								cnt_bit<="000000000000000";
								bit_state <= b1;
								end if;	
								
							when b1 => 
							
								cnt_bit <= cnt_bit + 1;
								if cnt_bit="000000000000000" then
									ow_dir <= '1';
									ow_out<='0';
								end if;	
								if cnt_bit="000000000111100" then
									ow_dir <= '0';
									ow_out<='Z';
								end if;	
								if cnt_bit="000000001000101" then
								
								cnt_bit<="000000000000000";
								bit_state <= b2;
								end if;	
								
							when b2 => --ok 1
							 
								cnt_bit <= cnt_bit + 1;
								if cnt_bit="000000000000000" then
									ow_dir <= '1';
									ow_out<='0';
								end if;	
								if cnt_bit="000000000000110" then
									ow_dir <= '0';
									ow_out<='Z';
								end if;	
								if cnt_bit="000000001000101" then
								
									cnt_bit<="000000000000000";
									bit_state <= b3;
								end if;	
																						
							when b3 =>
							
								cnt_bit <= cnt_bit + 1;
								if cnt_bit="000000000000000" then
									ow_dir <= '1';
									ow_out<='0';
								end if;	
								if cnt_bit="000000000000110" then
									ow_dir <= '0';
									ow_out<='Z';
								end if;	
								if cnt_bit="000000001000101" then
								
									cnt_bit<="000000000000000";
									bit_state <= b4;
								end if;	
															
							when b4 =>
							
								cnt_bit <= cnt_bit + 1;
								if cnt_bit="000000000000000" then
									ow_dir <= '1';
									ow_out<='0';
								end if;	
								if cnt_bit="000000000111100" then
									ow_dir <= '0';
									ow_out<='Z';
								end if;	
								if cnt_bit="000000001000101" then
								
								cnt_bit<="000000000000000";
								bit_state <= b5;
								end if;	
														
							when b5 =>
							
								cnt_bit <= cnt_bit + 1;
								if cnt_bit="000000000000000" then
									ow_dir <= '1';
									ow_out<='0';
								end if;	
								if cnt_bit="000000000111100" then
									ow_dir <= '0';
									ow_out<='Z';
								end if;	
								if cnt_bit="000000001000101" then
								
								cnt_bit<="000000000000000";
								bit_state <= b6;
								end if;	
																						
							when b6 =>
							
								cnt_bit <= cnt_bit + 1;
								if cnt_bit="000000000000000" then
									ow_dir <= '1';
									ow_out<='0';
								end if;	
								if cnt_bit="000000000000110" then
									ow_dir <= '0';
									ow_out<='Z';
								end if;	
								if cnt_bit="000000001000101" then
								
									cnt_bit<="000000000000000";
									bit_state <= b7;
								end if;	
														
							when b7 =>
								
								cnt_bit <= cnt_bit + 1;
								if cnt_bit="000000000000000" then
									ow_dir <= '1';
									ow_out<='0';
								end if;	
								if cnt_bit="000000000000110" then
									ow_dir <= '0';
									ow_out<='Z';
								end if;	
								if cnt_bit="100111000100000" then
								
									cnt_bit<="000000000000000";
									bit_state <= b0;
									if is_conv ='0' then
										state <= convent_t;
									elsif is_conv ='1' then
										state <= read_skratchpad;
									end if;	
								end if;	

								when others =>
							
						end case;	
											
					when convent_t => -- wys³anie komendy 0xBE
						
						case (bit_state) is 
								
							when b0 => -- ok0
							
							cnt_bit <= cnt_bit + 1;
								if cnt_bit="000000000000000" then
									ow_dir <= '1';
									ow_out<='0';
								end if;	
								if cnt_bit="000000000111100" then
									ow_dir <= '0';
									ow_out<='Z';
								end if;	
								if cnt_bit="000000001000101" then
								
								cnt_bit<="000000000000000";
								bit_state <= b1;
								end if;	
								
							when b1 => 
							
							cnt_bit <= cnt_bit + 1;
								if cnt_bit="000000000000000" then
									ow_dir <= '1';
									ow_out<='0';
								end if;	
								if cnt_bit="000000000111100" then
									ow_dir <= '0';
									ow_out<='Z';
								end if;	
								if cnt_bit="000000001000101" then
								
								cnt_bit<="000000000000000";
								bit_state <= b2;
								end if;	
								
								
							when b2 => --ok 1
							 
								cnt_bit <= cnt_bit + 1;
								if cnt_bit="000000000000000" then
									ow_dir <= '1';
									ow_out<='0';
								end if;	
								if cnt_bit="000000000000110" then
									ow_dir <= '0';
									ow_out<='Z';
								end if;	
								if cnt_bit="000000001000101" then
								
									cnt_bit<="000000000000000";
									bit_state <= b3;
								end if;	
																						
							when b3 =>
							
								cnt_bit <= cnt_bit + 1;
								if cnt_bit="000000000000000" then
									ow_dir <= '1';
									ow_out<='0';
								end if;	
								if cnt_bit="000000000111100" then
									ow_dir <= '0';
									ow_out<='Z';
								end if;	
								if cnt_bit="000000001000101" then
								
								cnt_bit<="000000000000000";
								bit_state <= b4;
								end if;	
								
							
			
							when b4 =>
							
								cnt_bit <= cnt_bit + 1;
								if cnt_bit="000000000000000" then
									ow_dir <= '1';
									ow_out<='0';
								end if;	
								if cnt_bit="000000000111100" then
									ow_dir <= '0';
									ow_out<='Z';
								end if;	
								if cnt_bit="000000001000101" then
								
								cnt_bit<="000000000000000";
								bit_state <= b5;
								end if;	
																
								
							when b5 =>
							
								cnt_bit <= cnt_bit + 1;
								if cnt_bit="000000000000000" then
									ow_dir <= '1';
									ow_out<='0';
								end if;	
								if cnt_bit="000000000111100" then
									ow_dir <= '0';
									ow_out<='Z';
								end if;	
								if cnt_bit="000000001000101" then
								
								cnt_bit<="000000000000000";
								bit_state <= b6;
								end if;	
								
							
							when b6 =>
							
								cnt_bit <= cnt_bit + 1;
								if cnt_bit="000000000000000" then
									ow_dir <= '1';
									ow_out<='0';
								end if;	
								if cnt_bit="000000000000110" then
									ow_dir <= '0';
									ow_out<='Z';
								end if;	
								if cnt_bit="000000001000101" then
								
									cnt_bit<="000000000000000";
									bit_state <= b7;
								end if;	
														
							when b7 =>
								
								cnt_bit <= cnt_bit + 1;
								if cnt_bit="000000000000000" then
									ow_dir <= '1';
									ow_out<='0';
								end if;	
								if cnt_bit="000000000111100" then
									ow_dir <= '0';
									ow_out<='Z';
								end if;	
								if cnt_bit="100111000100000" then
								
										cnt_bit<="000000000000000";
										bit_state <= b0;
										state <= wait_750ms;
					
								end if;	
																
								when others =>
								
						end case;	
											
					when wait_750ms => -- oczekiwanie na konwersjê temperatury
						if(is_conv='0') then
							cnt_ow <= cnt_ow + 1; 
							
							if (cnt_ow="11110111000110110000") then
								cnt_ow <="00000000000000000001"; 
								
								is_conv<='1';
								state <= reset_ow;
							end if;
						elsif is_conv='1' then
								state <= read_skratchpad;
						end if;					
					
					when read_skratchpad => -- wys³anie komendy 0x44

						case (bit_state) is 
								
							when b0 => -- ok0
							
							cnt_bit <= cnt_bit + 1;
								if cnt_bit="000000000000000" then
									ow_dir <= '1';
									ow_out<='0';
								end if;	
								if cnt_bit="000000000111100" then
									ow_dir <= '0';
									ow_out<='Z';
								end if;	
								if cnt_bit="000000001000101" then
								
								cnt_bit<="000000000000000";
								bit_state <= b1;
								end if;	
								
							when b1 => 
							
								cnt_bit <= cnt_bit + 1;
								if cnt_bit="000000000000000" then
									ow_dir <= '1';
									ow_out<='0';
								end if;	
								if cnt_bit="000000000000110" then
									ow_dir <= '0';
									ow_out<='Z';
								end if;	
								if cnt_bit="000000001000101" then
								
									cnt_bit<="000000000000000";
									bit_state <= b2;
								end if;		
								
							when b2 => --ok 1
							 
								cnt_bit <= cnt_bit + 1;
								if cnt_bit="000000000000000" then
									ow_dir <= '1';
									ow_out<='0';
								end if;	
								if cnt_bit="000000000000110" then
									ow_dir <= '0';
									ow_out<='Z';
								end if;	
								if cnt_bit="000000001000101" then
								
									cnt_bit<="000000000000000";
									bit_state <= b3;
								end if;	
																						
							when b3 =>
							
								cnt_bit <= cnt_bit + 1;
								if cnt_bit="000000000000000" then
									ow_dir <= '1';
									ow_out<='0';
								end if;	
								if cnt_bit="000000000000110" then
									ow_dir <= '0';
									ow_out<='Z';
								end if;	
								if cnt_bit="000000001000101" then
								
									cnt_bit<="000000000000000";
									bit_state <= b4;
								end if;	
															
							when b4 =>
							
								cnt_bit <= cnt_bit + 1;
								if cnt_bit="000000000000000" then
									ow_dir <= '1';
									ow_out<='0';
								end if;	
								if cnt_bit="000000000000110" then
									ow_dir <= '0';
									ow_out<='Z';
								end if;	
								if cnt_bit="000000001000101" then
								
									cnt_bit<="000000000000000";
									bit_state <= b5;
								end if;		
								
							when b5 =>
							
								cnt_bit <= cnt_bit + 1;
								if cnt_bit="000000000000000" then
									ow_dir <= '1';
									ow_out<='0';
								end if;	
								if cnt_bit="000000000000110" then
									ow_dir <= '0';
									ow_out<='Z';
								end if;	
								if cnt_bit="000000001000101" then
								
									cnt_bit<="000000000000000";
									bit_state <= b6;
								end if;		
																						
							when b6 =>
							
								cnt_bit <= cnt_bit + 1;
								if cnt_bit="000000000000000" then
									ow_dir <= '1';
									ow_out<='0';
								end if;	
								if cnt_bit="000000000111100" then
									ow_dir <= '0';
									ow_out<='Z';
								end if;	
								if cnt_bit="000000001000101" then
								
								cnt_bit<="000000000000000";
								bit_state <= b7;
								end if;	

														
							when b7 =>
								
								cnt_bit <= cnt_bit + 1;
								if cnt_bit="000000000000000" then
									ow_dir <= '1';
									ow_out<='0';
								end if;	
								if cnt_bit="000000000000110" then
									ow_dir <= '0';
									ow_out<='Z';
								end if;	
								if cnt_bit="100111000100000" then
								
									cnt_bit<="000000000000000";
									bit_state <= b0;
									state <= wait_4_resp;
								end if;		
					
								when others =>								
								
						end case;	
							
					when wait_4_resp => 	--oczekiwanie na odpowiedŸ
							ow_dir <= '0';
							ow_out<='Z';					
							if ow_in='0' then state <= read_data;
							end if;
							
					when read_data => 
							
						ow_dir <= '0';
						ow_out<='Z';	
						case (bit_state) is 
								
							when b0 => 
							
							cnt_bit <= cnt_bit + 1;
								
								if cnt_bit="000000000001110" then
									ow_data(0)<= ow_in;
									
								end if;	
	
								if cnt_bit="000000001000101" then				
								cnt_bit<="000000000000000";
								bit_state <= b1;
								end if;	
								
							when b1 => 
					
								cnt_bit <= cnt_bit + 1;
								
								if cnt_bit="000000000001110" then
									ow_data(1)<= ow_in;
									
								end if;	
	
								if cnt_bit="000000001000101" then				
								cnt_bit<="000000000000000";
								bit_state <= b2;
								end if;						
								
							when b2 => 
			
								cnt_bit <= cnt_bit + 1;
								
								if cnt_bit="000000000001110" then
									ow_data(2)<= ow_in;
									
								end if;	
	
								if cnt_bit="000000001000101" then				
								cnt_bit<="000000000000000";
								bit_state <= b3;
								end if;				
																						
							when b3 =>

								cnt_bit <= cnt_bit + 1;
								
								if cnt_bit="000000000001110" then
									ow_data(3)<= ow_in;
									
								end if;	
	
								if cnt_bit="000000001000101" then				
								cnt_bit<="000000000000000";
								bit_state <= b4;
								end if;	

							when b4 =>
							
								cnt_bit <= cnt_bit + 1;
								
								if cnt_bit="000000000001110" then
									ow_data(4)<= ow_in;
									
								end if;	
	
								if cnt_bit="000000001000101" then				
								cnt_bit<="000000000000000";
								bit_state <= b5;
								end if;	

							when b5 =>
		
								cnt_bit <= cnt_bit + 1;
								
								if cnt_bit="000000000001110" then
									ow_data(5)<= ow_in;
									
								end if;	
	
								if cnt_bit="000000001000101" then				
								cnt_bit<="000000000000000";
								bit_state <= b6;
								end if;	
		
							when b6 =>
	
							cnt_bit <= cnt_bit + 1;
								
								if cnt_bit="000000000001110" then
									ow_data(6)<= ow_in;
									
								end if;	
	
								if cnt_bit="000000001000101" then				
								cnt_bit<="000000000000000";
								bit_state <= b7;
								end if;	
													
							when b7 =>
								
								cnt_bit <= cnt_bit + 1;
								
								if cnt_bit="000000000001110" then
									ow_data(7)<= ow_in;
									
								end if;	
	
								if cnt_bit="000000001000101" then				
								cnt_bit<="000000000000000";
								bit_state <= b8;
								end if;				
			
							when b8 =>
			
								cnt_bit <= cnt_bit + 1;
								
								if cnt_bit="000000000001110" then
									ow_data(8)<= ow_in;
									
								end if;	
	
								if cnt_bit="000000001000101" then				
								cnt_bit<="000000000000000";
								bit_state <= b9;
								end if;	
							when b9 =>
			
								cnt_bit <= cnt_bit + 1;
								
								if cnt_bit="000000000001110" then
									ow_data(9)<= ow_in;	
								end if;	
	
								if cnt_bit="000000001000101" then				
								cnt_bit<="000000000000000";
								bit_state <= b10;
				
								end if;	
			
							when b10 =>
			
								cnt_bit <= cnt_bit + 1;
								
								if cnt_bit="000000000001110" then
									ow_data(10)<= ow_in;	
								end if;	
	
								if cnt_bit="000000001000101" then				
								cnt_bit<="000000000000000";
								bit_state <= b11;
			
								end if;	
			
							when b11 =>
			
								cnt_bit <= cnt_bit + 1;
								
								if cnt_bit="000000000001110" then
									ow_data(11)<= ow_in;	
								end if;	
	
								if cnt_bit="000000001000101" then				
								cnt_bit<="000000000000000"; 
								bit_state <= b12;
				
								end if;	
			
							when b12 =>
			
								cnt_bit <= cnt_bit + 1;
								
								if cnt_bit="000000000001110" then
									ow_data(12)<= ow_in;
								end if;	
	
								if cnt_bit="000000001000101" then				
								cnt_bit<="000000000000000";
								bit_state <= b13;
								end if;	
			
							when b13 =>
			
								cnt_bit <= cnt_bit + 1;							
								if cnt_bit="000000000001110" then
									ow_data(13)<= ow_in;
									
								end if;	
	
								if cnt_bit="000000001000101" then				
								cnt_bit<="000000000000000";
								bit_state <= b14;
								end if;	
			
							when b14 =>
			
								cnt_bit <= cnt_bit + 1;
								
								if cnt_bit="000000000001110" then
									ow_data(14)<= ow_in;			
								end if;	
	
								if cnt_bit="000000001000101" then				
								cnt_bit<="000000000000000";
								bit_state <= b15;
						
								end if;	
			
							when b15 =>
			
								cnt_bit <= cnt_bit + 1;
								
								if cnt_bit="000000000001110" then
									ow_data(15)<= ow_in;		
								end if;	
	
								if cnt_bit="000000001000101" then				
								cnt_bit<="000000000000000";
								bit_state <= b0;
								state <= save_data;
								end if;	
				
						end case;	
							
					when save_data => --zapisywanie danych
					
							x(19 downto 8) <= to_bcd(ow_data(11 downto 4));
						
							case ow_data(3 downto 2) is 
								when "00" => 
									x(7 downto 0)<= "00000000";
								when "01" =>
									x(7 downto 0)<= "00100101";
								when "10" =>
									x(7 downto 0)<= "01010000";
								when "11" =>
									x(7 downto 0)<= "01110101";
								when others =>
								
								end case;
							
							
							dot <= '1';
					
						is_conv<='0';
						state <= reset_ow; 
											
				end case;
			end if; 
	end process ow;

	clock_1us: process (clk, reset) -- generacja zegara 1us
		begin 
			if (reset = '0') then
				cnt_1us <= (others => '0');			elsif (clk'event and clk='1') then
				cnt_1us <= cnt_1us + 1; 
				if (cnt_1us="11000") then
					cnt_1us<="00000";
					if (int_1us = '0') then
						int_1us <= '1';			
					else			
						int_1us <= '0';
					end if;
				end if;
			end if;
			
	end process clock_1us;

	process (clk, s, x) is --proces steruj¹cy anodami wyœwietlacza
	begin
		if (clk'event and clk ='1') then
			case s is 
				when "00" => digit <= x(3 downto 0);
					if s ="00" then anody <= "0001"; else null; end if; 
				when "01" => digit <= x(7 downto 4);
					if s ="01" then anody <= "0010"; else null; end if; 
				when "10" => digit <= x(11 downto 8);
					if s ="10" then anody <= "0100"; else null; end if; 
				when others => digit <= x(15 downto 12);
					if s ="11" then anody <= "1000"; else null; end if; 
			end case;
			end if; 
	end process;		
	
	
	process (clk, digit) is --proces steruj¹cy segmentami
	begin 
		if (clk'event and clk ='1') then
			case digit is
				when X"0" => a_to_g <= "1111110";			--definicja cyfry 0
				when X"1" => a_to_g <= "0110000";			--definicja cyfry 1
				when X"2" => a_to_g <= "1101101";			--definicja cyfry 2
				when X"3" => a_to_g <= "1111001";			--definicja cyfry 3
				when X"4" => a_to_g <= "0110011";			--definicja cyfry 4
				when X"5" => a_to_g <= "1011011";			--definicja cyfry 5
				when X"6" => a_to_g <= "1011111";			--definicja cyfry 6
				when X"7" => a_to_g <= "1110010";			--definicja cyfry 7
				when X"8" => a_to_g <= "1111111";			--definicja cyfry 8
				when X"9" => a_to_g <= "1111011";			--definicja cyfry 9
				when others => a_to_g <= "1001111";			--definicja litery E
			end case;
		end if; 
	end process;
			
	process (clk) --prescaler wyœwietlacza
		 begin
			  if (clk'event and clk = '1') then
					clk_div <= clk_div + '1';
			  end if;
	end process;
		
    process (clk_div(17))
    begin
        if (clk_div(17)'Event and clk_div(17) = '1') then

                s <= s + '1';   
        end if;
    end process;


  onewire <= ow_out when ow_dir = '1' else 'Z'; -- obs³uga bufora 3 stanowego
  ow_in <= onewire when ow_dir = '0' else ow_out;
   

end Behavioral;

