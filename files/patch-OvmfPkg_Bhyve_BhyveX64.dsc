--- OvmfPkg/Bhyve/BhyveX64.dsc.orig	2025-02-21 00:50:36 UTC
+++ OvmfPkg/Bhyve/BhyveX64.dsc
@@ -673,7 +673,7 @@
   PcAtChipsetPkg/PcatRealTimeClockRuntimeDxe/PcatRealTimeClockRuntimeDxe.inf
   MdeModulePkg/Universal/DriverHealthManagerDxe/DriverHealthManagerDxe.inf
   MdeModulePkg/Universal/BdsDxe/BdsDxe.inf
-  MdeModulePkg/Logo/LogoDxe.inf
+  OvmfPkg/Bhyve/LogoDxe/LogoDxe.inf
   MdeModulePkg/Application/UiApp/UiApp.inf {
     <LibraryClasses>
       NULL|MdeModulePkg/Library/DeviceManagerUiLib/DeviceManagerUiLib.inf
