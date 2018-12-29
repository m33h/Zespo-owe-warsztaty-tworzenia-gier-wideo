require "Source/Components/Debug"
require "Source/Components/Menu"

scene_ = nil
cameraNode = nil
yaw = 0
pitch = 0
vehicleNode = nil

function Start()
    application = Application:new()

    Application:CreateScene()
    Application:InitializeMenu()
    Application:CreateVehicle()
end