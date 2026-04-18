package SAPL.Processor is

   type Cpu_Id is (Cpu_Unknown, Cpu_Top, Cpu_Bottom);

   procedure Initialize;
   procedure Fail_Safe (Error_Code : Fail_Safe_Error_Codes);
   procedure Disable_Interrupts;
   procedure Enable_Interrupts;
   procedure Wait_For_Interrupt;
   function Get_Cpu_Id return Cpu_Id;

private
   procedure Read_Cpu_Id;
end SAPL.Processor;