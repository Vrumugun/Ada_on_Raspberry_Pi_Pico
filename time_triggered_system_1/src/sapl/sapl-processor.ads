package SAPL.Processor is
   procedure Initialize;
   procedure Fail_Safe (Error_Code : Fail_Safe_Error_Codes);
   procedure Disable_Interrupts;
   procedure Enable_Interrupts;
   procedure Wait_For_Interrupt;
end SAPL.Processor;