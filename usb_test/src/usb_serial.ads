with System;

with Atomic;
with BBqueue;
with BBqueue.Buffers;
with HAL;

with USB;
with USB.Device;
with USB.HAL.Device;

package USB_Serial is
   procedure Initialize;
   procedure Poll;
   procedure Read (Message : out String; Length : out HAL.UInt32);
   procedure Write (Data : String);
   function Connected return Boolean;

private

   Max_Packet_Size : constant USB.Packet_Size := 64;
   TX_Buffer_Size  : constant BBqueue.Count := 256;
   RX_Buffer_Size  : constant BBqueue.Count := 256;

   type CDC_Line_Coding is record
      Bitrate   : HAL.UInt32;
      Stop_Bit  : HAL.UInt8;
      Parity    : HAL.UInt8;
      Data_Bits : HAL.UInt8;
   end record
     with Pack, Size => 56;

   type CDC_Line_Control_State is record
      DTE_Is_Present              : Boolean;
      Half_Duplex_Carrier_Control : Boolean;
      Reserved                    : HAL.UInt14;
   end record
     with Pack, Size => 16;

   type Custom_Serial_Class is limited
     new USB.Device.USB_Device_Class with
   record
      Interface_Index : USB.Interface_Id := 0;
      Int_EP          : USB.EP_Id := 0;
      Bulk_EP         : USB.EP_Id := 0;
      Iface_Str       : USB.String_Id := USB.Invalid_String_Id;

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
      Base_Interface_Index :        USB.Interface_Id)
      return USB.Device.Init_Result;

   overriding
   procedure Get_Class_Info
     (This                     : in out Custom_Serial_Class;
      Number_Of_Interfaces     :    out USB.Interface_Id;
      Config_Descriptor_Length :    out Natural);

   overriding
   procedure Fill_Config_Descriptor
     (This : in out Custom_Serial_Class;
      Data :    out HAL.UInt8_Array);

   overriding
   function Configure
     (This  : in out Custom_Serial_Class;
      UDC   : in out USB.HAL.Device.USB_Device_Controller'Class;
      Index : HAL.UInt16)
      return USB.Setup_Request_Answer;

   overriding
   function Setup_Read_Request
     (This  : in out Custom_Serial_Class;
      Req   : USB.Setup_Data;
      Buf   : out System.Address;
      Len   : out USB.Buffer_Len)
      return USB.Setup_Request_Answer;

   overriding
   function Setup_Write_Request
     (This  : in out Custom_Serial_Class;
      Req   : USB.Setup_Data;
      Data  : HAL.UInt8_Array)
      return USB.Setup_Request_Answer;

   overriding
   procedure Transfer_Complete
     (This : in out Custom_Serial_Class;
      UDC  : in out USB.HAL.Device.USB_Device_Controller'Class;
      EP   :        USB.EP_Addr;
      CNT  :        USB.Packet_Size);

   procedure Setup_RX
     (This : in out Custom_Serial_Class;
      UDC  : in out USB.HAL.Device.USB_Device_Controller'Class);

   procedure Setup_TX
     (This : in out Custom_Serial_Class;
      UDC  : in out USB.HAL.Device.USB_Device_Controller'Class);

end USB_Serial;