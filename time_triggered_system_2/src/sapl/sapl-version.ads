package SAPL.Version is

   Major : constant Integer := 1;
   Minor : constant Integer := 0;
   Patch : constant Integer := 0;
   Build : constant Integer := 0;

   Firmware_Version : constant String :=
      Integer'Image (Major) & "." &
      Integer'Image (Minor) & "." &
      Integer'Image (Patch) & "." &
      Integer'Image (Build);

end SAPL.Version;