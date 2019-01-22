require "Source/Components/AppConstants"
require "Source/Components/Vehicle"
require "Source/Components/Menu"

local vehicleNode

Application = ScriptObject()

function Start()
    print("Application:Start")
    Application:CreateScene()
    Application:CreateVehicle()
    Application:SubscribeToEvents()
end

function  Application:new()
    print("Application:new")
    classVariables = { state = 'GAME_MENU' }
    self.__index = self
    return setmetatable(classVariables, self)
end

function  Application:SubscribeToEvents()
    SubscribeToEvent("Update", "HandleUpdate")
    SubscribeToEvent("PostUpdate", "HandlePostUpdate")
end

function  Application:CreateScene()
    scene_ = Scene()
    local sceneFileName = fileSystem:GetProgramDir() .. "Assets/scenes/mainScene2.xml"
    scene_:LoadXML(sceneFileName)

    cameraNode = Node()
    cameraNode:SetPosition(Vector3(50,50,0))
    cameraNode:SetDirection(Vector3(-1,-1,0))
    local camera = cameraNode:CreateComponent("Camera")
    camera.farClip = 500.0

    renderer:SetViewport(0, Viewport:new(scene_, camera))
end

function Application:PlayGame()
    CreateViewport()
end

function  Application:CreateVehicle(vehiclesrc)
    print("Application:CreateVehicle")

    vehicleNode = scene_:CreateChild("Vehicle")
    vehicleNode.position = Vector3(15, 3.0, -15.0)

    local vehicle = vehicleNode:CreateScriptObject("Vehicle")
    vehicle:Init(scene_)
end

function  Application:CreateViewport()
end

function  Application:MoveCamera(timeStep)
    print("Move Camera")
    local MOVE_SPEED = 20.0
    local MOUSE_SENSITIVITY = 0.1
    local mouseMove = input.mouseMove

    yaw = yaw + MOUSE_SENSITIVITY * mouseMove.x
    pitch = pitch + MOUSE_SENSITIVITY * mouseMove.y
    pitch = Clamp(pitch, -90.0, 90.0)

    cameraNode.rotation = Quaternion(pitch, yaw, 0.0)

    if input:GetKeyDown(KEY_T) then
        cameraNode:Translate(Vector3(0.0, 0.0, 1.0) * MOVE_SPEED * timeStep)
    end
    if input:GetKeyDown(KEY_G) then
        cameraNode:Translate(Vector3(0.0, 0.0, -1.0) * MOVE_SPEED * timeStep)
    end
    if input:GetKeyDown(KEY_F) then
        cameraNode:Translate(Vector3(-1.0, 0.0, 0.0) * MOVE_SPEED * timeStep)
    end
    if input:GetKeyDown(KEY_H) then
        cameraNode:Translate(Vector3(1.0, 0.0, 0.0) * MOVE_SPEED * timeStep)
    end
end


function HandleUpdate(eventType, eventData)
    if vehicleNode == nil then
        return
    end

    local vehicle = vehicleNode:GetScriptObject()
    if vehicle == nil then
        return
    end

    --[[if(application.state == 'PLAY_GAME') then]]
        -- Get movement controls and assign them to the vehicle component. If UI has a focused element, clear controls
        if ui.focusElement == nil then
            vehicle.controls:Set(CTRL_FORWARD, input:GetKeyDown(KEY_W))
            vehicle.controls:Set(CTRL_BACK, input:GetKeyDown(KEY_S))
            vehicle.controls:Set(CTRL_LEFT, input:GetKeyDown(KEY_A))
            vehicle.controls:Set(CTRL_RIGHT, input:GetKeyDown(KEY_D))

            -- Add yaw & pitch from the mouse motion or touch input. Used only for the camera, does not affect motion
            if touchEnabled then
                for i=0, input.numTouches - 1 do
                    local state = input:GetTouch(i)
                    if not state.touchedElement then -- Touch on empty space
                        local camera = cameraNode:GetComponent("Camera")
                        if not camera then return end

                        vehicle.controls.yaw = vehicle.controls.yaw + TOUCH_SENSITIVITY * camera.fov / graphics.height * state.delta.x
                        vehicle.controls.pitch = vehicle.controls.pitch + TOUCH_SENSITIVITY * camera.fov / graphics.height * state.delta.y
                    end
                end
            else
                vehicle.controls.yaw = vehicle.controls.yaw + input.mouseMoveX * YAW_SENSITIVITY
                vehicle.controls.pitch = vehicle.controls.pitch + input.mouseMoveY * YAW_SENSITIVITY
            end
            -- Limit pitch
            vehicle.controls.pitch = Clamp(vehicle.controls.pitch, 0.0, 80.0)


        else
            vehicle.controls:Set(CTRL_FORWARD + CTRL_BACK + CTRL_LEFT + CTRL_RIGHT, false)
        end
        if input:GetKeyDown(KEY_ESCAPE) then
            input.mouseVisible = true
            ui.root:GetChild("ExitButton", true).visible = true
            ui.root:GetChild("ResumeButton", true).visible = true
            ui.root:GetChild("Window", true).visible = true
            application['state'] = 'GAME_MENU'
        end
end


function HandlePostUpdate(eventType, eventData)
    if vehicleNode == nil then
        return
    end

    local vehicle = vehicleNode:GetScriptObject()
    if vehicle == nil then
        return
    end

    local dir = Quaternion(vehicleNode.rotation:YawAngle(), Vector3(0.0, 1.0, 0.0))
    dir = dir * Quaternion(vehicle.controls.yaw, Vector3(0.0, 1.0, 0.0))
    dir = dir * Quaternion(vehicle.controls.pitch, Vector3(1.0, 0.0, 0.0))

    local cameraTargetPos = vehicleNode.position - dir * Vector3(0.0, 0.0, CAMERA_DISTANCE)
    local cameraStartPos = vehicleNode.position

    -- Raycast camera against static objects (physics collision mask 2)
    -- and move it closer to the vehicle if something in between
    local cameraRay = Ray(cameraStartPos, (cameraTargetPos - cameraStartPos):Normalized())
    local cameraRayLength = (cameraTargetPos - cameraStartPos):Length()
    local physicsWorld = scene_:GetComponent("PhysicsWorld")
    local result = physicsWorld:RaycastSingle(cameraRay, cameraRayLength, 2)
    if result.body ~= nil then
        cameraTargetPos = cameraStartPos + cameraRay.direction * (result.distance - 0.5)
    end
    cameraNode.position = cameraTargetPos
    cameraNode.rotation = dir
end

function HandleSceneUpdate(eventType, eventData)
    -- Move the camera by touch, if the camera node is initialized by descendant sample class
    if touchEnabled and cameraNode then
        for i=0, input:GetNumTouches()-1 do
            local state = input:GetTouch(i)
            if not state.touchedElement then -- Touch on empty space
                if state.delta.x or state.delta.y then
                    local camera = cameraNode:GetComponent("Camera")
                    if not camera then return end

                    yaw = yaw + TOUCH_SENSITIVITY * camera.fov / graphics.height * state.delta.x
                    pitch = pitch + TOUCH_SENSITIVITY * camera.fov / graphics.height * state.delta.y

                    -- Construct new orientation for the camera scene node from yaw and pitch; roll is fixed to zero
                    cameraNode:SetRotation(Quaternion(pitch, yaw, 0))
                else
                    -- Move the cursor to the touch position
                    local cursor = ui:GetCursor()
                    if cursor and cursor:IsVisible() then cursor:SetPosition(state.position) end
                end
            end
        end
    end
end