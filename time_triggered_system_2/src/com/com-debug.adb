with USB_Serial;
with RP2040_SVD.TIMER; use RP2040_SVD.TIMER;
with RP.Device;

package body COM.Debug is

   Rx_Buffer : Circular_Buffer_Character;
   Tx_Buffer : Circular_Buffer_Character;

   Start_Us : HAL.UInt32;
   End_Us   : HAL.UInt32;
   Update_Us  : HAL.UInt32;
   Max_Update_Us : HAL.UInt32 := 0;

   procedure Initialize is
   begin
      USB_Serial.Initialize;
      --  During connect the USB stack needs up to 50 ms.
      --  This will exceed our scheduler tick time.
      --  Wait here until the connection is established.
      while not USB_Serial.Connected loop
         USB_Serial.Poll;
         RP.Device.Timer.Delay_Milliseconds (1);
      end loop;
   end Initialize;

   procedure Update is
      use HAL;
   begin
      Start_Us := TIMER_Periph.TIMELR;
      USB_Serial.Poll;
      if USB_Serial.Connected then
         Receive_Character;
         Transmit_Character;
      end if;
      End_Us := TIMER_Periph.TIMELR;
      Update_Us := End_Us - Start_Us;
      if Update_Us > Max_Update_Us then
         Max_Update_Us := Update_Us;
      end if;
   end Update;

   function Get_Update_Time_Us return HAL.UInt32 is
   begin
      return Max_Update_Us;
   end Get_Update_Time_Us;

   procedure Receive_Character is
      Received_Char : Character;
      Message : String (1 .. 64);
      Length : HAL.UInt32;
   begin
      USB_Serial.Read (Message, Length);
      for I in 1 .. Natural (Length) loop
         Received_Char := Message (I);
         if not Rx_Buffer.Is_Buffer_Full then
            Rx_Buffer.Put_Character (Received_Char);
         end if;
      end loop;
   end Receive_Character;

   procedure Transmit_Character is
      Next_Char : Character;
   begin
      if not Tx_Buffer.Is_Buffer_Empty then
         Next_Char := Tx_Buffer.Get_Character;
         USB_Serial.Write ("" & Next_Char);
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

end COM.Debug;