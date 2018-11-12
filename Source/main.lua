require "Source/Components/Menu"

scene_ = nil
cameraNode = nil


function Start()
    application = Application:new()

    Application:InitializeMenu()
end