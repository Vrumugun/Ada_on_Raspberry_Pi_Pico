with HAL;

package USB_Serial is
   procedure Initialize;
   procedure Poll;
   procedure Read (Message : out String; Length : out HAL.UInt32);
   procedure Write (Data : String);
   function Connected return Boolean;
end USB_Serial;