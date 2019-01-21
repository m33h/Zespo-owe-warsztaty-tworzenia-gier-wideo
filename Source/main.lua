require "Source/Components/Menu"
require "Source/Components/AppConstants"
require "Source/Components/Application"

local vehicleNode

function Start()
    print("Start main")
    application = Application:new()

--[[    Application:CreateScene()
    self.vehicleNode = Application:CreateVehicle(vehicleNode)

    Application:InitializeMenu()
    Application:SubscribeToEvents()]]
end
