with System;

with Atomic;
with BBqueue;
with BBqueue.Buffers;
with HAL; use HAL;

with RP.Device;

with USB; use USB;
with USB.Device;
with USB.HAL.Device;
with USB.Utils;

package body USB_Serial is

   use type System.Address;
   use type BBqueue.Result_Kind;

   Max_Packet_Size : constant Packet_Size := 64;
   TX_Buffer_Size  : constant BBqueue.Count := 256;
   RX_Buffer_Size  : constant BBqueue.Count := 256;

   type CDC_Line_Coding is record
      Bitrate   : UInt32;
      Stop_Bit  : UInt8;
      Parity    : UInt8;
      Data_Bits : UInt8;
   end record
     with Pack, Size => 56;

   type CDC_Line_Control_State is record
      DTE_Is_Present                : Boolean;
      Half_Duplex_Carrier_Control   : Boolean;
      Reserved                      : UInt14;
   end record
     with Pack, Size => 16;

   type Class_Request_Type is
     (Set_Line_Coding, Get_Line_Coding, Set_Control_Line_State, Send_Break);
   for Class_Request_Type use
     (Set_Line_Coding        => 16#20#,
      Get_Line_Coding        => 16#21#,
      Set_Control_Line_State => 16#22#,
      Send_Break             => 16#23#);

   type Custom_Serial_Class is limited
     new USB.Device.USB_Device_Class with
   record
      Interface_Index : Interface_Id := 0;
      Int_EP          : EP_Id := 0;
      Bulk_EP         : EP_Id := 0;
      Iface_Str       : String_Id := Invalid_String_Id;

      Int_Buf      : System.Address := System.Null_Address;
      Bulk_Out_Buf : System.Address := System.Null_Address;
      Bulk_In_Buf  : System.Address := System.Null_Address;

      TX_Queue : BBqueue.Buffers.Buffer (TX_Buffer_Size);
      RX_Queue : BBqueue.Buffers.Buffer (RX_Buffer_Size);

      TX_In_Progress : aliased Atomic.Flag := Atomic.Init (False);

      Coding : CDC_Line_Coding :=
        (Bitrate   => 115_200,
         Stop_Bit  => 0,
         Parity    => 0,
         Data_Bits => 8);
      State : CDC_Line_Control_State :=
        (DTE_Is_Present              => False,
         Half_Duplex_Carrier_Control => False,
         Reserved                    => 0);
   end record;

   overriding
   function Initialize
     (This                 : in out Custom_Serial_Class;
      Dev                  : in out USB.Device.USB_Device_Stack'Class;
      Base_Interface_Index :        Interface_Id)
      return USB.Device.Init_Result;

   overriding
   procedure Get_Class_Info
     (This                     : in out Custom_Serial_Class;
      Number_Of_Interfaces     :    out Interface_Id;
      Config_Descriptor_Length :    out Natural);

   overriding
   procedure Fill_Config_Descriptor
     (This : in out Custom_Serial_Class;
      Data :    out UInt8_Array);

   overriding
   function Configure
     (This  : in out Custom_Serial_Class;
      UDC   : in out USB.HAL.Device.USB_Device_Controller'Class;
      Index : UInt16)
      return Setup_Request_Answer;

   overriding
   function Setup_Read_Request
     (This  : in out Custom_Serial_Class;
      Req   : Setup_Data;
      Buf   : out System.Address;
      Len   : out Buffer_Len)
      return Setup_Request_Answer;

   overriding
   function Setup_Write_Request
     (This  : in out Custom_Serial_Class;
      Req   : Setup_Data;
      Data  : UInt8_Array)
      return Setup_Request_Answer;

   overriding
   procedure Transfer_Complete
     (This : in out Custom_Serial_Class;
      UDC  : in out USB.HAL.Device.USB_Device_Controller'Class;
      EP   :        EP_Addr;
      CNT  :        Packet_Size);

   procedure Setup_RX
     (This : in out Custom_Serial_Class;
      UDC  : in out USB.HAL.Device.USB_Device_Controller'Class);

   procedure Setup_TX
     (This : in out Custom_Serial_Class;
      UDC  : in out USB.HAL.Device.USB_Device_Controller'Class);

   USB_Stack  : USB.Device.USB_Device_Stack (Max_Classes => 1);
   USB_Class  : aliased Custom_Serial_Class;
   Initialized_Flag : Boolean := False;

   overriding
   function Initialize
     (This                 : in out Custom_Serial_Class;
      Dev                  : in out USB.Device.USB_Device_Stack'Class;
      Base_Interface_Index :        Interface_Id)
      return USB.Device.Init_Result
   is
   begin
      if not Dev.Request_Endpoint (Interrupt, This.Int_EP) then
         return USB.Device.Not_Enough_EPs;
      end if;

         This.Int_Buf :=
            Dev.Request_Buffer ((This.Int_EP, EP_In), Max_Packet_Size);
      if This.Int_Buf = System.Null_Address then
         return USB.Device.Not_Enough_EP_Buffer;
      end if;

      if not Dev.Request_Endpoint (Bulk, This.Bulk_EP) then
         return USB.Device.Not_Enough_EPs;
      end if;

         This.Bulk_Out_Buf :=
            Dev.Request_Buffer ((This.Bulk_EP, EP_Out), Max_Packet_Size);
      if This.Bulk_Out_Buf = System.Null_Address then
         return USB.Device.Not_Enough_EP_Buffer;
      end if;

         This.Bulk_In_Buf :=
            Dev.Request_Buffer ((This.Bulk_EP, EP_In), Max_Packet_Size);
      if This.Bulk_In_Buf = System.Null_Address then
         return USB.Device.Not_Enough_EP_Buffer;
      end if;

      This.Interface_Index := Base_Interface_Index;
         This.Iface_Str :=
            USB.Device.Register_String
               (Dev, USB.To_USB_String ("Custom CDC ACM"));
      return USB.Device.Ok;
   end Initialize;

   overriding
   procedure Get_Class_Info
     (This                     : in out Custom_Serial_Class;
      Number_Of_Interfaces     :    out Interface_Id;
      Config_Descriptor_Length :    out Natural)
   is
      pragma Unreferenced (This);
   begin
      Number_Of_Interfaces := 2;
      Config_Descriptor_Length := 66;
   end Get_Class_Info;

   overriding
   procedure Fill_Config_Descriptor
     (This : in out Custom_Serial_Class;
      Data :    out UInt8_Array)
   is
      F : constant Natural := Data'First;
      USB_CLASS_CDC : constant UInt8 := 2;
      USB_CLASS_CDC_DATA : constant UInt8 := 10;
      CDC_COMM_SUBCLASS_ABSTRACT_CONTROL_MODEL : constant UInt8 := 2;
      CDC_FUNC_DESC_HEADER : constant UInt8 := 0;
      CDC_FUNC_DESC_CALL_MANAGEMENT : constant UInt8 := 1;
      CDC_FUNC_DESC_ABSTRACT_CONTROL_MANAGEMENT : constant UInt8 := 2;
      CDC_FUNC_DESC_UNION : constant UInt8 := 6;
   begin
      Data (F + 0 .. F + 65) :=
        (
         8,
         Dt_Interface_Associate'Enum_Rep,
         UInt8 (This.Interface_Index),
         2,
         USB_CLASS_CDC,
         CDC_COMM_SUBCLASS_ABSTRACT_CONTROL_MODEL,
         0,
         0,

         9,
         Dt_Interface'Enum_Rep,
         UInt8 (This.Interface_Index),
         0,
         1,
         USB_CLASS_CDC,
         CDC_COMM_SUBCLASS_ABSTRACT_CONTROL_MODEL,
         0,
         UInt8 (This.Iface_Str),

         5,
         Dt_Cs_Interface'Enum_Rep,
         CDC_FUNC_DESC_HEADER,
         16#20#,
         16#01#,

         5,
         Dt_Cs_Interface'Enum_Rep,
         CDC_FUNC_DESC_CALL_MANAGEMENT,
         0,
         UInt8 (This.Interface_Index + 1),

         4,
         Dt_Cs_Interface'Enum_Rep,
         CDC_FUNC_DESC_ABSTRACT_CONTROL_MANAGEMENT,
         2,

         5,
         Dt_Cs_Interface'Enum_Rep,
         CDC_FUNC_DESC_UNION,
         UInt8 (This.Interface_Index),
         UInt8 (This.Interface_Index + 1),

         7,
         Dt_Endpoint'Enum_Rep,
         16#80# or UInt8 (This.Int_EP),
         Interrupt'Enum_Rep,
         UInt8 (Max_Packet_Size),
         0,
         16,

         9,
         Dt_Interface'Enum_Rep,
         UInt8 (This.Interface_Index + 1),
         0,
         2,
         USB_CLASS_CDC_DATA,
         0,
         0,
         0,

         7,
         Dt_Endpoint'Enum_Rep,
         UInt8 (This.Bulk_EP),
         Bulk'Enum_Rep,
         UInt8 (Max_Packet_Size),
         0,
         0,

         7,
         Dt_Endpoint'Enum_Rep,
         16#80# or UInt8 (This.Bulk_EP),
         Bulk'Enum_Rep,
         UInt8 (Max_Packet_Size),
         0,
         0);
   end Fill_Config_Descriptor;

   overriding
   function Configure
     (This  : in out Custom_Serial_Class;
      UDC   : in out USB.HAL.Device.USB_Device_Controller'Class;
      Index : UInt16)
      return Setup_Request_Answer
   is
   begin
      if Index /= 1 then
         return Not_Supported;
      end if;

      UDC.EP_Setup ((This.Int_EP, EP_In), Interrupt);
      UDC.EP_Setup ((This.Bulk_EP, EP_In), Bulk);
      UDC.EP_Setup ((This.Bulk_EP, EP_Out), Bulk);
      This.Setup_RX (UDC);
      return Handled;
   end Configure;

   overriding
   function Setup_Read_Request
     (This  : in out Custom_Serial_Class;
      Req   : Setup_Data;
      Buf   : out System.Address;
      Len   : out Buffer_Len)
      return Setup_Request_Answer
   is
   begin
      Buf := System.Null_Address;
      Len := 0;

      if Req.RType.Typ = Class and then Req.RType.Recipient = Iface then
         case Req.Request is
            when Get_Line_Coding'Enum_Rep =>
               Buf := This.Coding'Address;
               Len := Buffer_Len (This.Coding'Size / 8);
               return Handled;
            when others =>
               return Not_Supported;
         end case;
      end if;

      return Next_Callback;
   end Setup_Read_Request;

   overriding
   function Setup_Write_Request
     (This  : in out Custom_Serial_Class;
      Req   : Setup_Data;
      Data  : UInt8_Array)
      return Setup_Request_Answer
   is
   begin
      if Req.RType.Typ = Class and then Req.RType.Recipient = Iface then
         case Req.Request is
            when Set_Line_Coding'Enum_Rep =>
               if Data'Length = (This.Coding'Size / 8) then
                  declare
                     Dst : UInt8_Array (1 .. This.Coding'Size / 8)
                       with Address => This.Coding'Address;
                  begin
                     Dst := Data;
                     return Handled;
                  end;
               else
                  return Not_Supported;
               end if;
            when Set_Control_Line_State'Enum_Rep =>
                      This.State.DTE_Is_Present := (Req.Value and 1) /= 0;
                      This.State.Half_Duplex_Carrier_Control :=
                         (Req.Value and 2) /= 0;
               return Handled;
            when Send_Break'Enum_Rep =>
               return Handled;
            when others =>
               return Not_Supported;
         end case;
      end if;

      return Next_Callback;
   end Setup_Write_Request;

   procedure Setup_RX
     (This : in out Custom_Serial_Class;
      UDC  : in out USB.HAL.Device.USB_Device_Controller'Class)
   is
   begin
      UDC.EP_Ready_For_Data
        (EP => This.Bulk_EP,
         Max_Len => Max_Packet_Size,
         Ready => True);
   end Setup_RX;

   procedure Setup_TX
     (This : in out Custom_Serial_Class;
      UDC  : in out USB.HAL.Device.USB_Device_Controller'Class)
   is
      RG : BBqueue.Buffers.Read_Grant;
      Already_Sending : Boolean;
   begin
      Atomic.Test_And_Set (This.TX_In_Progress, Already_Sending);
      if Already_Sending then
         return;
      end if;

         BBqueue.Buffers.Read
            (This.TX_Queue, RG, BBqueue.Count (Max_Packet_Size));
      if BBqueue.Buffers.State (RG) = BBqueue.Valid then
         USB.Utils.Copy
           (Src   => BBqueue.Buffers.Slice (RG).Addr,
            Dst   => This.Bulk_In_Buf,
            Count => Natural (BBqueue.Buffers.Slice (RG).Length));
             UDC.EP_Send_Packet
                (Ep => This.Bulk_EP,
                  Len => Packet_Size (BBqueue.Buffers.Slice (RG).Length));
         BBqueue.Buffers.Release (This.TX_Queue, RG);
      else
         Atomic.Clear (This.TX_In_Progress);
      end if;
   end Setup_TX;

   overriding
   procedure Transfer_Complete
     (This : in out Custom_Serial_Class;
      UDC  : in out USB.HAL.Device.USB_Device_Controller'Class;
      EP   :        EP_Addr;
      CNT  :        Packet_Size)
   is
   begin
      if EP = (This.Bulk_EP, EP_Out) then
         declare
            WG : BBqueue.Buffers.Write_Grant;
         begin
            BBqueue.Buffers.Grant (This.RX_Queue, WG, BBqueue.Count (CNT));
            if BBqueue.Buffers.State (WG) = BBqueue.Valid then
               USB.Utils.Copy
                 (Src   => This.Bulk_Out_Buf,
                  Dst   => BBqueue.Buffers.Slice (WG).Addr,
                  Count => CNT);
               BBqueue.Buffers.Commit (This.RX_Queue, WG, BBqueue.Count (CNT));
            end if;
         end;
         This.Setup_RX (UDC);
      elsif EP = (This.Bulk_EP, EP_In) then
         Atomic.Clear (This.TX_In_Progress);
         This.Setup_TX (UDC);
      end if;
   end Transfer_Complete;

   procedure Initialize is
      use type USB.Device.Init_Result;
      Status : USB.Device.Init_Result;
   begin
      if Initialized_Flag then
         return;
      end if;

      if not USB_Stack.Register_Class (USB_Class'Unchecked_Access) then
         raise Program_Error with "Failed to register custom USB serial class";
      end if;

      Status := USB_Stack.Initialize
        (Controller      => RP.Device.UDC'Access,
         Manufacturer    => USB.To_USB_String ("Raspberry Pi"),
         Product         => USB.To_USB_String ("Custom Ada Serial"),
         Serial_Number   => USB.To_USB_String ("usb_test2"),
         Max_Packet_Size => Control_Packet_Size (Max_Packet_Size),
         Vendor_Id       => 16#2E8A#,
         Product_Id      => 16#000A#,
         Bcd_Device      => 16#0100#);

      if Status /= USB.Device.Ok then
         raise Program_Error with "USB stack initialization failed";
      end if;

      USB_Stack.Start;
      Initialized_Flag := True;
   end Initialize;

   procedure Poll is
   begin
      if Initialized_Flag then
         USB_Stack.Poll;
      end if;
   end Poll;

   procedure Read (Message : out String; Length : out HAL.UInt32) is
      RG : BBqueue.Buffers.Read_Grant;
   begin
      Length := 0;

         BBqueue.Buffers.Read
            (USB_Class.RX_Queue, RG, BBqueue.Count (Message'Length));
      if BBqueue.Buffers.State (RG) = BBqueue.Valid then
         Length := HAL.UInt32 (BBqueue.Buffers.Slice (RG).Length);
         USB.Utils.Copy
           (Src   => BBqueue.Buffers.Slice (RG).Addr,
            Dst   => Message'Address,
            Count => Length);
         BBqueue.Buffers.Release (USB_Class.RX_Queue, RG);
      end if;
   end Read;

   procedure Write (Data : String) is
      WG : BBqueue.Buffers.Write_Grant;
      Length : HAL.UInt32 := HAL.UInt32 (Data'Length);
   begin
      if not Initialized_Flag or else Data'Length = 0 then
         return;
      end if;

         BBqueue.Buffers.Grant
            (USB_Class.TX_Queue, WG, BBqueue.Count (Length));
      if BBqueue.Buffers.State (WG) = BBqueue.Valid then
             Length :=
                HAL.UInt32'Min
                   (Length, HAL.UInt32 (BBqueue.Buffers.Slice (WG).Length));
         USB.Utils.Copy
           (Src   => Data'Address,
            Dst   => BBqueue.Buffers.Slice (WG).Addr,
            Count => Length);
             BBqueue.Buffers.Commit
                (USB_Class.TX_Queue, WG, BBqueue.Count (Length));
         USB_Class.Setup_TX (RP.Device.UDC);
      end if;
   end Write;

   function Connected return Boolean is
   begin
      return USB_Class.State.DTE_Is_Present;
   end Connected;

end USB_Serial;