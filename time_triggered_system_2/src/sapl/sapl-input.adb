with HAL;
with Pico;
with RP.GPIO;

package body SAPL.Input is

   use type HAL.UInt32;

   Input_State : Boolean := False;
   Input_Counter : HAL.UInt32 := 0;
   Max_Input_Counter : constant HAL.UInt32 := 5;

   procedure Initialize is
   begin
      --  Initialization code for input handling
      Pico.GP4.Configure (RP.GPIO.Output);
      Pico.GP5.Configure (RP.GPIO.Input);
   end Initialize;

   procedure Update is
   begin
      --  Update code for input handling
      Filter_Input;
   end Update;

   procedure Filter_Input is
   begin
      --  Code to filter input signals and update Input_State and Input_Counter
      Pico.GP4.Set;
      if Pico.GP5.Get then
         if not Input_State then
            Input_Counter := Input_Counter + 1;
            if Input_Counter > Max_Input_Counter then
               Input_Counter := 0;
               Input_State := True;
            end if;
         else
            Input_Counter := 0;
         end if;
      else
         if Input_State then
            Input_Counter := Input_Counter + 1;
            if Input_Counter > Max_Input_Counter then
               Input_Counter := 0;
               Input_State := False;
            end if;
         else
            Input_Counter := 0;
         end if;
      end if;
   end Filter_Input;

   function Get_Input_State return Boolean is
   begin
      return Input_State;
   end Get_Input_State;

end SAPL.Input;