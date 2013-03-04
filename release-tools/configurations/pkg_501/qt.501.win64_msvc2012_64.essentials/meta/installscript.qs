/* This file is part of the Qt SDK

*/

// constructor
function Component()
{
}

Component.prototype.isDefault = function()
{
    if (installer.environmentVariable("VS110COMNTOOLS")) {
        return true;
    }
    return false;
}

createShortcuts = function()
{
    var qtStringVersion = "%QT_VERSION%";
    // Create a batch file with the development environment
    var component_root_path = installer.value("TargetDir") + "%TARGET_INSTALL_DIR%";
    component_root_path = component_root_path.replace(/\//g, "\\");

    var batchFileName = component_root_path + "\\" + "bin" + "\\" + "qtenv2.bat";
    var contentString = "echo off\r\n";
    contentString += "echo Setting up environment for Qt usage...\r\n";
    contentString += "set PATH="  + component_root_path + "\\bin;%PATH%\r\n";
    contentString += "cd /D " + component_root_path + "\r\n";

    // Dump batch file
    component.addOperation("AppendFile", batchFileName, contentString);

    var windir = installer.environmentVariable("WINDIR");
    if (windir == "") {
        QMessageBox["warning"]( "Error" , "Error", "Could not find windows installation directory");
        return;
    }

    var cmdLocation = windir + "\\system32\\cmd.exe";
    component.addOperation( "CreateShortcut",
                            cmdLocation,
                            "@StartMenuDir@/%QT_VERSION%/MSVC 2012 (64-bit)/Qt " + qtStringVersion + " 64-bit for Desktop (MSVC 2012).lnk",
                            "/A /Q /K " + batchFileName);
    // Assistant
    component.addOperation( "CreateShortcut",
                            component_root_path + "/bin/assistant.exe",
                            "@StartMenuDir@/%QT_VERSION%/MSVC 2012 (64-bit)/Assistant.lnk");

    // Designer
    component.addOperation( "CreateShortcut",
                            component_root_path + "/bin/designer.exe",
                            "@StartMenuDir@/%QT_VERSION%/MSVC 2012 (64-bit)/Designer.lnk");

    // Linguist
    component.addOperation( "CreateShortcut",
                            component_root_path + "/bin/linguist.exe",
                            "@StartMenuDir@/%QT_VERSION%/MSVC 2012 (64-bit)/Linguist.lnk");
}

Component.prototype.beginInstallation = function()
{
    installer.setValue(component.name + "_qtpath", "@TargetDir@" + "%TARGET_INSTALL_DIR%");
}

Component.prototype.createOperations = function()
{
    component.createOperations();

    if (installer.value("os") == "win") {
        try {
            // Create a batch file and shortcuts with the development environment
            createShortcuts();

            if (installer.value("SDKToolBinary") == "")
                return;
            var qmakeBinary = "@TargetDir@/%TARGET_INSTALL_DIR%/bin/qmake.exe";

            component.addOperation("Execute",
                new Array("{1}", "@SDKToolBinary@", "addQt", "--id", component.name, "--name", "Qt %QT_VERSION% MSVC2012 64bit", "--type", "Qt4ProjectManager.QtVersion.Desktop", "--qmake", qmakeBinary));

            component.addOperation("Execute",
                new Array("{1}", "@SDKToolBinary@", "addKit", "--id", component.name + "_kit", "--name", "Desktop Qt %QT_VERSION% MSVC2012 64bit", "--toolchain", "x86-windows-msvc2012-pe-64bit", "--qt", component.name, "--debuggerengine", "4", "--devicetype", "Desktop"));

        } catch( e ) {
            print( e );
        }
    }
}
