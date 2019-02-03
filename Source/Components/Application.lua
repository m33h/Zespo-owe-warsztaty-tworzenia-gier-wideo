require "Source/Components/Timer"
require "Source/Components/Menu"
require "Source/Components/Vehicle"
require "Source/Components/AppConstants"
require "Source/Components/Debug"
require "Source/Components/Guidelines"

local vehicleNode

Application = ScriptObject()

function Start()
    print("Application:Start")

    Application:CreateScene()
    Application:CreateVehicle()
    Application:SubscribeToEvents()
    InitializeMenu()
    CreateSpeedMeter()
    CreateGuidelineBox()
end

function Application:SubscribeToEvents()
    SubscribeToEvent("Update", "HandleUpdate")
    SubscribeToEvent("PostUpdate", "HandlePostUpdate")
end

function Application:CreateScene()
    scene_ = Scene()
    local sceneFileName = fileSystem:GetProgramDir() .. "Assets/scenes/mainScene2.xml"
    scene_:LoadXML(sceneFileName)

    cameraNode = Node()
    cameraNode:SetPosition(Vector3(50,50,0))
    cameraNode:SetDirection(Vector3(1,1,0))
    local camera = cameraNode:CreateComponent("Camera")
    camera.farClip = 500.0

    renderer:SetViewport(0, Viewport:new(scene_, camera))
    scene_:CreateScriptObject("Timer")
end

function Application:PlayGame()
    Application:CreateViewport()
end

function  Application:CreateVehicle(vehiclesrc)
    print("Application:CreateVehicle")

    vehicleNode = scene_:CreateChild("Vehicle")
    vehicleNode.position = Vector3(100, 3.0, 200.0)
    vehicleNode:SetDirection(Vector3(-1,0,0))

    local vehicle = vehicleNode:CreateScriptObject("Vehicle")
    vehicle:Init(scene_)
end

function  Application:CreateViewport()
end

function  Application:MoveCamera(timeStep)
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

function GameInput(vehicle)
    if ui.focusElement == nil then
        SetKeyboardControls(vehicle)
        SetMouseControls(vehicle)
    else
        vehicle.controls:Set(CTRL_FORWARD + CTRL_BACK + CTRL_LEFT + CTRL_RIGHT, false)
    end
    if input:GetKeyDown(KEY_ESCAPE) then
        ChangeState('GAME_MENU')
    end
end

function SetKeyboardControls(vehicle)
    vehicle.controls:Set(CTRL_FORWARD, input:GetKeyDown(KEY_W))
    vehicle.controls:Set(CTRL_BACK, input:GetKeyDown(KEY_S))
    vehicle.controls:Set(CTRL_LEFT, input:GetKeyDown(KEY_A))
    vehicle.controls:Set(CTRL_RIGHT, input:GetKeyDown(KEY_D))
end

function SetMouseControls(vehicle)
    vehicle.controls.yaw = vehicle.controls.yaw + input.mouseMoveX * YAW_SENSITIVITY
    vehicle.controls.pitch = vehicle.controls.pitch + input.mouseMoveY * YAW_SENSITIVITY
    vehicle.controls.pitch = Clamp(vehicle.controls.pitch, 0.0, 80.0) -- Limit pitch
end

function HandleUpdate(eventType, eventData)
    if vehicleNode == nil then
        return
    end

    local vehicle = vehicleNode:GetScriptObject()
    if vehicle == nil then
        return
    end

    if(GAME_STATE == 'PLAY_GAME') then
        GameInput(vehicle)
        TimerDemo()  --used to show timer functionality, it needs to be changed
    elseif(GAME_STATE == 'GAME_MENU') then
        Menu()
    elseif(GAME_STATE == 'WIN_STATE') then
        TimerDemo() --used to show timer functionality, it needs to be changed
    end
end

function Menu()
    input.mouseVisible = true
    ui.root:GetChild("ExitButton", true).visible = true
    ui.root:GetChild("ResumeButton", true).visible = true
    ui.root:GetChild("Window", true).visible = true
end

function HandlePostUpdate(eventType, eventData)
    if vehicleNode == nil then
        return
    end

    local vehicle = vehicleNode:GetScriptObject()
    if vehicle == nil then
        return
    end

    local speed = vehicle.hullBody.linearVelocity:Length()
    UpdateSpeedMeter(speed)
    UpdateGuidelineBox()

    counter = counter + 1

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
end

function CreateSpeedMeter()
    speedText = Text:new()

    speedText.text = "0km/h"
    speedText:SetFont(cache:GetResource("Font", "Fonts/Anonymous Pro.ttf"), 42)
    speedText.color = Color.BLUE

    local offset_X = 20
    local offset_Y = 20
    local pos_X = ui.root:GetWidth() - speedText:GetWidth() - offset_X
    local pos_Y = ui.root:GetHeight() - speedText:GetHeight() - offset_Y
    speedText:SetPosition(pos_X, pos_Y)

    ui.root:AddChild(speedText)
end

function CreateGuidelineBox()
    guideline = Text:new()

    guideline.text = "100, 200 -> 100, 200"
    guideline:SetFont(cache:GetResource("Font", "Fonts/Anonymous Pro.ttf"), 42)
    guideline.color = Color.RED

    local offset_X = 20
    local offset_Y = 100
    local pos_X = ui.root:GetWidth() - guideline:GetWidth() - offset_X
    local pos_Y = ui.root:GetHeight() - guideline:GetHeight() - offset_Y
    guideline:SetPosition(pos_X, pos_Y)

    ui.root:AddChild(guideline)
end

function UpdateSpeedMeter(speedValue)
    speedText.text = math.floor(speedValue).."km/h"
    local offset_X = 20
    local offset_Y = 20
    local pos_X = ui.root:GetWidth() - speedText:GetWidth() - offset_X
    local pos_Y = ui.root:GetHeight() - speedText:GetHeight() - offset_Y
    speedText:SetPosition(pos_X, pos_Y)
end

function UpdateGuidelineBox()
    local checkpoint = GetNearestPoint(vehicleNode.position, 0)
    local nearestCheckpoint = GetNearestPoint(vehicleNode.position, 0)
    local nextCheckpoint = GetNearestPoint(vehicleNode.position, 1)
    checkpointsVector = (nextCheckpoint - nearestCheckpoint):Normalized()
    vehicleToCheckpointVector = vehicleNode.direction
    cos = vectorsCos(checkpointsVector, vehicleNode.direction)

    if cos < -0.3 then
        turnInfo = 'TURN RIGHT'
    elseif cos > 0.3 then
        turnInfo = 'TURN LEFT'
    else
        turnInfo = ''
    end


    guideline.text = vehicleNode.position.x..', '..vehicleNode.position.z..' -> '..checkpoint.x..', '..checkpoint.z..' '..turnInfo
    local offset_X = 20
    local offset_Y = 100
    local pos_X = ui.root:GetWidth() - guideline:GetWidth() - offset_X
    local pos_Y = ui.root:GetHeight() - guideline:GetHeight() - offset_Y
    guideline:SetPosition(pos_X, pos_Y)
end
