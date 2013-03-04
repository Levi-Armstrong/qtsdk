
// constructor
function Component()
{
}

Component.prototype.createOperations = function()
{
    // Call the base createOperations and afterwards set some registry settings
    // so that the simulator finds its fonts and applications find the simulator
    component.createOperations();

    //return value 3010 means it need a reboot, but in most cases it is not needed for run Qt application
    // return value 5100 means there's a newer version of the runtime already installed
    component.addElevatedOperation("Execute", "{0,3010,1638,5100}", "@TargetDir@\\vcredist\\vcredist_sp1_x86.exe", "/norestart", "/q");
}
