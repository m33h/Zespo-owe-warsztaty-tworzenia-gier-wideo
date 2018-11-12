require "Source/Components/Menu"

scene_ = nil
cameraNode = nil


function Start()
    application = Application:new()

    Application:CreateScene()
    Application:InitializeMenu()
end