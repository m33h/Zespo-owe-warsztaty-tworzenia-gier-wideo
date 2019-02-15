require "Source/Components/Timer"
require "Source/Components/Menu"
require "Source/Components/Vehicle"
require "Source/Components/CpuVehicle"
require "Source/Components/AppConstants"
require "Source/Components/Debug"
require "Source/Components/Guidelines"

local vehicleNode
local cpuVehicleNode
local cpuVehicleNode2
local vehicle
local cpuVehicle
local cpuVehicle2
local collectedPowerupsCount = 0
local nearestCheckpoint
local musicSource
local light_red = 0.1
local light_green = 0.1
local light_blue = 0.1
local light

Application = ScriptObject()

function Start()
    print("Application:Start")

    Application:CreateScene()
    Application:CreateVehicles()
    Application:SubscribeToEvents()
    InitializeMenu()
    CreateSpeedMeter()
    CreateGuidelineBox()
    CreatePowerupsUi()

    musicSource = scene_:CreateComponent("SoundSource")
    musicSource.soundType = SOUND_MUSIC
    local music = cache:GetResource("Sound", "Assets/Music/mushrooms.ogg")
    music.looped = true
    musicSource:Play(music)
end

function Application:SubscribeToEvents()
    SubscribeToEvent("Update", "HandleUpdate")
    SubscribeToEvent("PostUpdate", "HandlePostUpdate")
    SubscribeToEvent(EVENT_POWERUP_COLLECTED, "HandlePowerupCollected")
    SubscribeToEvent(EVENT_MUSHROOM_COLLECTED, "HandleMushroomCollected")
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
    scene_:CreateScriptObject("StartTimer")



    for i = 1, #checkpoints do
        local objectNode = scene_:CreateChild("Mushroom")
        local position = Vector3(checkpoints[i].point.x, 0.0, checkpoints[i].point.z)
        position.y = 0.1
        objectNode.position = position
        objectNode.rotation = Quaternion(Vector3(0.0, 1.0, 0.0), Vector3(0,1,0.0))
        objectNode:SetScale(3.0)
        local object = objectNode:CreateComponent("StaticModel")
        object.model = cache:GetResource("Model", "Models/Mushroom.mdl")
        object.material = cache:GetResource("Material", "Materials/Mushroom.xml")
        object.castShadows = true

        checkpoints[i].flagNode = objectNode
        objectNode:SetEnabled(checkpoints[i].active)
    end


    local lightNode = scene_:CreateChild("DirectionalLight")
    lightNode.direction = Vector3(0.5, -1.0, 0.5)
    light = lightNode:CreateComponent("Light")
    light.lightType = LIGHT_DIRECTIONAL
    light.color = Color(color_red, color_green, color_blue)
    light.specularIntensity = 1.0
end

function Application:PlayGame()
    Application:CreateViewport()
end

function  Application:CreateVehicles(vehiclesrc)
    print("Application:CreateVehicle")

    vehicleNode = scene_:CreateChild("Vehicle")
    vehicleNode.position = Vector3(80, 3.0, 200.0)
    vehicleNode:SetDirection(Vector3(-1,0,0))

    cpuVehicleNode = scene_:CreateChild("CpuVehicle")
    cpuVehicleNode.position = Vector3(80, 3.0, 210.0)
    cpuVehicleNode:SetDirection(Vector3(-1,0,0))
    cpuVehicleNode2 = scene_:CreateChild("CpuVehicle2")
    cpuVehicleNode2.position = Vector3(80, 3.0, 190.0)
    cpuVehicleNode2:SetDirection(Vector3(-1,0,0))

    cpuVehicle = cpuVehicleNode:CreateScriptObject("CpuVehicle")
    cpuVehicle2 = cpuVehicleNode2:CreateScriptObject("CpuVehicle")
    vehicle = vehicleNode:CreateScriptObject("Vehicle")

    cpuVehicle:Init(scene_, "1")
    cpuVehicle2:Init(scene_, "2")
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

function GameInput()
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
    local vehicle = vehicleNode:GetScriptObject()
    if vehicle == nil then
        return
    end

    if(GAME_STATE == 'START_GAME') then
--        ChangeState("PLAY_GAME")
    elseif(GAME_STATE == 'PLAY_GAME') then
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

    if vehicle == nil then
        return
    end

    if((vehicleNode.position - GetActiveCheckpoint(0).point):Length() < 10) then
        vehicle.guildlines_points = vehicle.guildlines_points + 1
        GetActiveCheckpoint(1).flagNode:SetEnabled(true)
        GetActiveCheckpoint(0).flagNode:SetEnabled(false)
        GetActiveCheckpoint(1).active = true
        GetActiveCheckpoint(0).active = false
        SendEvent(EVENT_MUSHROOM_COLLECTED)
    end

    if (DidPlayerFinish(vehicle.guildlines_points)) then
        ChangeState( "WIN_STATE")
        RegisterTime("PLAYER")
    end

    local speed = vehicle.hullBody.linearVelocity:Length()
    UpdateSpeedMeter(speed)

    counter = counter + 1

    local dir = Quaternion(vehicleNode.rotation:YawAngle(), Vector3(0.0, 1.0, 0.0))
    dir = dir * Quaternion(vehicle.controls.yaw, Vector3(0.0, 1.0, 0.0))
    dir = dir * Quaternion(vehicle.controls.pitch, Vector3(1.0, 0.0, 0.0))

    local cameraTargetPos = vehicleNode.position - dir * Vector3(0.0, 0.0, CAMERA_DISTANCE)
    local cameraStartPos = vehicleNode.position


    local cameraRay = Ray(cameraStartPos, (cameraTargetPos - cameraStartPos):Normalized())
    local cameraRayLength = (cameraTargetPos - cameraStartPos):Length()
    local physicsWorld = scene_:GetComponent("PhysicsWorld")
    local result = physicsWorld:RaycastSingle(cameraRay, cameraRayLength, 2)
    if result.body ~= nil then
        cameraTargetPos = cameraStartPos + cameraRay.direction * (result.distance - 0.5)
    end

    cameraNode.position = cameraTargetPos
    cameraNode.rotation = dir

    if(GAME_STATE == 'PLAY_GAME' and (math.random() > 0.7)) then
        light_blue = light_blue + math.random()/20 - math.random()/20
        light_green = light_green + math.random()/20 - math.random()/20
        light_red = light_red + math.random()/20 - math.random()/20
        light:SetColor(Color(light_red, light_green, light_blue))
    end
end

function HandleSceneUpdate(eventType, eventData)
end

function HandlePowerupCollected(eventType, eventData)
    collectedPowerupsCount = collectedPowerupsCount + 1
    UpdatePowerupsUi()
end

function HandleMushroomCollected(eventType, eventData)
    light_blue = light_blue + math.random()/4 - math.random()/5
    light_green = light_green + math.random()/4 - math.random()/5
    light_red = light_red + math.random()/4 - math.random()/5
    light:SetColor(Color(light_red, light_green, light_blue))
end

function CreatePowerupsUi()
    local ammoIconSize = 100
    local ammoIconMarginLeft = 20
    local ammoIconMarginBottom = 20
    local ammoIconPosX = ammoIconMarginLeft
    local ammoIconPosY = ui.root:GetHeight() - ammoIconMarginBottom - ammoIconSize
    local ammoTextPosX = ammoIconPosX + ammoIconSize + ammoIconMarginLeft
    local ammoTextPosY = ammoIconPosY + ammoIconSize/4

    local ammoIconFileName = fileSystem:GetProgramDir() .. "Assets/Textures/ammo.png"
    local ammoTex = cache:GetResource("Texture2D", ammoIconFileName)

    powerupsIcon = Sprite:new()
    powerupsIcon.texture = ammoTex
    powerupsIcon:SetPosition(ammoIconPosX, ammoIconPosY)
    powerupsIcon:SetSize(ammoIconSize, ammoIconSize)

    powerupsCountText = Text:new()
    powerupsCountText.text = "0"
    powerupsCountText:SetFont(cache:GetResource("Font", "Fonts/Anonymous Pro.ttf"), 42)
    powerupsCountText.color = Color.WHITE
    powerupsCountText:SetPosition(ammoTextPosX, ammoTextPosY)

    ui.root:AddChild(powerupsCountText)
    ui.root:AddChild(powerupsIcon)
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

function UpdatePowerupsUi()
    if(collectedPowerupsCount >= 0) then
        powerupsCountText:SetText(collectedPowerupsCount)
    else
        powerupsCountText:SetText("0")
    end
end

function UpdateSpeedMeter(speedValue)
    speedText.text = math.floor(speedValue).."km/h"
    local offset_X = 20
    local offset_Y = 20
    local pos_X = ui.root:GetWidth() - speedText:GetWidth() - offset_X
    local pos_Y = ui.root:GetHeight() - speedText:GetHeight() - offset_Y
    speedText:SetPosition(pos_X, pos_Y)
end
