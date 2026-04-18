with HAL.UART; use HAL.UART;
with RP.Device;
with RP.GPIO;
with RP.UART;
with Pico;
with SAPL.Processor; use SAPL.Processor;

package body COM.Cross is

   use type RP.UART.UART_FIFO_Status;

   Rx_Buffer : Circular_Buffer_Character;
   Tx_Buffer : Circular_Buffer_Character;

   Test_Error : exception;
   UART    : RP.UART.UART_Port renames RP.Device.UART_0;
   UART_TX_TOP : RP.GPIO.GPIO_Point renames Pico.GP16;
   UART_RX_TOP : RP.GPIO.GPIO_Point renames Pico.GP17;
   UART_TX_BOTTOM : RP.GPIO.GPIO_Point renames Pico.GP0;
   UART_RX_BOTTOM : RP.GPIO.GPIO_Point renames Pico.GP1;
   Buffer  : UART_Data_8b (1 .. 1);
   Status  : UART_Status;

   procedure Initialize is
   begin
      -- Initialize communication interfaces, if any
      --  I don't know if the pull up is needed, but it doesn't hurt?
      if SAPL.Processor.Get_Cpu_Id = SAPL.Processor.Cpu_Top then
         UART_TX_TOP.Configure (RP.GPIO.Output, RP.GPIO.Pull_Up, RP.GPIO.UART);
         UART_RX_TOP.Configure (RP.GPIO.Input, RP.GPIO.Floating, RP.GPIO.UART);
      elsif SAPL.Processor.Get_Cpu_Id = SAPL.Processor.Cpu_Bottom then
         UART_TX_BOTTOM.Configure (RP.GPIO.Output, RP.GPIO.Pull_Up, RP.GPIO.UART);
         UART_RX_BOTTOM.Configure (RP.GPIO.Input, RP.GPIO.Floating, RP.GPIO.UART);
      else
         SAPL.Processor.Fail_Safe (SAPL.Unknown_Cpu);
      end if;

      UART.Configure
         (Config =>
            (Baud      => 115_200,
            Word_Size => 8,
            Parity    => False,
            Stop_Bits => 1,
            others    => <>));
   end Initialize;

   procedure Update_Tx is
   begin
      Transmit_Character;
   end Update_Tx;

   procedure Update_Rx is
   begin
      Receive_Character;
   end Update_Rx;

   procedure Receive_Character is
      C: Character;
   begin
      if UART.Receive_Status /= RP.UART.Empty then
         UART.Receive (Buffer, Status, Timeout => 0);
         case Status is
            when Err_Error =>
               raise Test_Error with "Echo receive failed with status " & Status'Image;
            when Err_Timeout =>
               raise Test_Error with "Unexpected Err_Timeout with timeout disabled!";
            when Busy =>
               --  Busy indicates a Break condition- RX held low for a full
               --  word time. This may be detected unintentionally if a
               --  transmitter is not connected. Break is used by some
               --  protocols (eg. LIN bus) to indicate the end of a frame.
               --
               --  For this example, we just ignore it.
               null;
            when Ok =>
               if not Rx_Buffer.Is_Buffer_Full then
                  C := Character'Val (Buffer (1));
                  Rx_Buffer.Put_Character (C);
               end if;
         end case;
      end if;
   end Receive_Character;

   procedure Transmit_Character is
      Next_Char : Character;
      C : UART_Data_8b (1 .. 1);
   begin
      if not Tx_Buffer.Is_Buffer_Empty then
         Next_Char := Tx_Buffer.Get_Character;
         C (1) := Character'Pos (Next_Char);
         UART.Transmit (C, Status);
         if Status /= Ok then
            raise Test_Error with "Send_Hello transmit failed with status " & Status'Image;
         end if;
         UART.Send_Break (RP.Device.Timer'Access, UART.Frame_Time * 2);
      end if;
   end Transmit_Character;

   procedure Put_Tx_Character (C : Character) is
   begin
      if not Tx_Buffer.Is_Buffer_Full then
         Tx_Buffer.Put_Character (C);
      end if;
   end Put_Tx_Character;

   procedure Put_Tx_String (S : String) is
   begin
      for C of S loop
         Put_Tx_Character (C);
      end loop;
   end Put_Tx_String;

   function Is_Rx_Character_Available return Boolean is
   begin
      return not Rx_Buffer.Is_Buffer_Empty;
   end Is_Rx_Character_Available;

   function Get_Next_Rx_Character return Character is
      Next_Character : Character;
   begin
      if Is_Rx_Character_Available then
         Next_Character := Rx_Buffer.Get_Character;
         return Next_Character;
      else
         raise Constraint_Error;
      end if;
   end Get_Next_Rx_Character;

   procedure Put_Character (Self : in out Circular_Buffer_Character;
      C : Character) is
   begin
      Self.Data (Self.Head) := C;
      Self.Head := Self.Head + 1;
      if Self.Head = Buffer_Size then
         Self.Head := 0;
      end if;
   end Put_Character;

   function Get_Character (Self : in out Circular_Buffer_Character)
      return Character is
      Next_Character : Character;
   begin
      if not Is_Buffer_Empty (Self) then
         Self.Tail := Self.Tail + 1;
         if Self.Tail = Buffer_Size then
            Self.Tail := Self.Tail - Buffer_Size;
         end if;

         Next_Character := Self.Data (Self.Tail);
         return Next_Character;
      else
         raise Constraint_Error;
      end if;
   end Get_Character;

   function Is_Buffer_Empty (Self : in out Circular_Buffer_Character)
      return Boolean is
      Temp : Natural;
   begin
      Temp := Self.Tail + 1;
      if Temp = Buffer_Size then
         Temp := Temp - Buffer_Size;
      end if;
      return Temp = Self.Head;
   end Is_Buffer_Empty;

   function Is_Buffer_Full (Self : in out Circular_Buffer_Character)
      return Boolean is
      Temp : Natural;
   begin
      Temp := Self.Head + 1;
      if Temp = Buffer_Size then
         Temp := Temp - Buffer_Size;
      end if;
      return Temp = Self.Tail;
   end Is_Buffer_Full;

end COM.Cross;