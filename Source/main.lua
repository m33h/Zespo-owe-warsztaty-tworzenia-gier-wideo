require "Source/Components/Debug"
require "Source/Components/Menu"

local CTRL_FORWARD = 1
local CTRL_BACK = 2
local CTRL_LEFT = 4
local CTRL_RIGHT = 8

local CAMERA_DISTANCE = 10.0
local YAW_SENSITIVITY = 0.1
local ENGINE_POWER = 10.0
local DOWN_FORCE = 10.0
local MAX_WHEEL_ANGLE = 22.5

local vehicleNode = nil

function Start()
    application = Application:new()

    Application:CreateScene()
    vehicleNode = Application:CreateVehicle(vehicleNode)

    Application:InitializeMenu()
    Application:SubscribeToEvents()
    CreateSpeedMeter()
end

function CreateVehicle()
    vehicleNode = scene_:CreateChild("Vehicle")
    vehicleNode.position = Vector3(0.0, 5.0, 0.0)

    local vehicle = vehicleNode:CreateScriptObject("Vehicle")
    vehicle:Init()
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

function UpdateSpeedMeter(speedValue)
    speedText.text = math.floor(speedValue).."km/h"
    local offset_X = 20
    local offset_Y = 20
    local pos_X = ui.root:GetWidth() - speedText:GetWidth() - offset_X
    local pos_Y = ui.root:GetHeight() - speedText:GetHeight() - offset_Y
    speedText:SetPosition(pos_X, pos_Y)
end

function HandleUpdate(eventType, eventData)
    if vehicleNode == nil then
        return
    end

    local vehicle = vehicleNode:GetScriptObject()
    if vehicle == nil then
        return
    end

    if(application.state == 'PLAY_GAME') then
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

            -- Check for loading / saving the scene
            if input:GetKeyPress(KEY_F5) then
                scene_:SaveXML(fileSystem:GetProgramDir() .. "Data/Scenes/VehicleDemo.xml")
            end
            if input:GetKeyPress(KEY_F7) then
                scene_:LoadXML(fileSystem:GetProgramDir() .. "Data/Scenes/VehicleDemo.xml")
                -- After loading we have to reacquire the vehicle scene node, as it has been recreated
                -- Simply find by name as there's only one of them
                vehicleNode = scene_:GetChild("Vehicle", true)
                vehicleNode:GetScriptObject():PostInit()
            end
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

    -- Physics update has completed. Position camera behind vehicle
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

function Vehicle:Start()
    -- Current left/right steering amount (-1 to 1.)
    self.steering = 0.0
    -- Vehicle controls.
    self.controls = Controls()
end

function Vehicle:Load(deserializer)
    self.controls.yaw = deserializer:ReadFloat()
    self.controls.pitch = deserializer:ReadFloat()
end

function Vehicle:Save(serializer)
    serializer:WriteFloat(self.controls.yaw)
    serializer:WriteFloat(self.controls.pitch)
end

function Vehicle:Init()
    -- This function is called only from the main program when initially creating the vehicle, not on scene load
    local node = self.node
    local hullObject = node:CreateComponent("StaticModel")
    self.hullBody = node:CreateComponent("RigidBody")
    local hullShape = node:CreateComponent("CollisionShape")

    node.scale = Vector3(1.5, 1.0, 3.0)
    hullObject.model = cache:GetResource("Model", "Models/Box.mdl")
    hullObject.material = cache:GetResource("Material", "Materials/Stone.xml")
    hullObject.castShadows = true
    hullShape:SetBox(Vector3(1.0, 1.0, 1.0))

    self.hullBody.mass = 1.0
    self.hullBody.linearDamping = 0.2 -- Some air resistance
    self.hullBody.angularDamping = 0.5
    self.hullBody.collisionLayer = 1
    self.frontLeft = self:InitWheel("FrontLeft", Vector3(-0.6, -0.4, 0.3))
    self.frontRight = self:InitWheel("FrontRight", Vector3(0.6, -0.4, 0.3))
    self.rearLeft = self:InitWheel("RearLeft", Vector3(-0.6, -0.4, -0.3))
    self.rearRight = self:InitWheel("RearRight", Vector3(0.6, -0.4, -0.3))

    self:PostInit()
end

function Vehicle:PostInit()
    self.frontLeft = scene_:GetChild("FrontLeft")
    self.frontRight = scene_:GetChild("FrontRight")
    self.rearLeft = scene_:GetChild("RearLeft")
    self.rearRight = scene_:GetChild("RearRight")

    self.frontLeftAxis = self.frontLeft:GetComponent("Constraint")
    self.frontRightAxis = self.frontRight:GetComponent("Constraint")

    self.hullBody = self.node:GetComponent("RigidBody")

    self.frontLeftBody = self.frontLeft:GetComponent("RigidBody")
    self.frontRightBody = self.frontRight:GetComponent("RigidBody")
    self.rearLeftBody = self.rearLeft:GetComponent("RigidBody")
    self.rearRightBody = self.rearRight:GetComponent("RigidBody")
end

function Vehicle:InitWheel(name, offset)
    local wheelNode = scene_:CreateChild(name)
    local node = self.node
    wheelNode.position = node:LocalToWorld(offset)
    if offset.x >= 0.0 then
        wheelNode.rotation = node.worldRotation * Quaternion(0.0, 0.0, -90.0)
    else
        wheelNode.rotation = node.worldRotation * Quaternion(0.0, 0.0, 90.0)
    end
    wheelNode.scale = Vector3(0.8, 0.5, 0.8)

    local wheelObject = wheelNode:CreateComponent("StaticModel")
    local wheelBody = wheelNode:CreateComponent("RigidBody")
    local wheelShape = wheelNode:CreateComponent("CollisionShape")
    local wheelConstraint = wheelNode:CreateComponent("Constraint")

    wheelObject.model = cache:GetResource("Model", "Models/Cylinder.mdl")
    wheelObject.material = cache:GetResource("Material", "Materials/Stone.xml")
    wheelObject.castShadows = true
    wheelShape:SetSphere(1.0)
    wheelBody.friction = 1
    wheelBody.mass = 1
    wheelBody.linearDamping = 0.2 -- Some air resistance
    wheelBody.angularDamping = 0.75 -- Could also use rolling friction
    wheelBody.collisionLayer = 1
    wheelConstraint.constraintType = CONSTRAINT_HINGE
    wheelConstraint.otherBody = node:GetComponent("RigidBody")
    wheelConstraint.worldPosition = wheelNode.worldPosition -- Set constraint's both ends at wheel's location
    wheelConstraint.axis = Vector3(0.0, 1.0, 0.0) -- Wheel rotates around its local Y-axis

    if offset.x >= 0.0 then -- Wheel's hull axis points either left or right
        wheelConstraint.otherAxis = Vector3(1.0, 0.0, 0.0)
    else
        wheelConstraint.otherAxis = Vector3(-1.0, 0.0, 0.0)
    end

    wheelConstraint.lowLimit = Vector2(-180.0, 0.0) -- Let the wheel rotate freely around the axis
    wheelConstraint.highLimit = Vector2(180.0, 0.0)
    wheelConstraint.disableCollision = true -- Let the wheel intersect the vehicle hull

    return wheelNode
end

function Vehicle:FixedUpdate(timeStep)
    local newSteering = 0.0
    local accelerator = 0.0

    if self.controls:IsDown(CTRL_LEFT) then
        newSteering = -1.0
    end
    if self.controls:IsDown(CTRL_RIGHT) then
        newSteering = 1.0
    end
    if self.controls:IsDown(CTRL_FORWARD) then
        accelerator = 1.0
    end
    if self.controls:IsDown(CTRL_BACK) then
        accelerator = -0.5
    end

    -- When steering, wake up the wheel rigidbodies so that their orientation is updated
    if newSteering ~= 0.0 then
        self.frontLeftBody:Activate()
        self.frontRightBody:Activate()
        self.steering = self.steering * 0.95 + newSteering * 0.05
    else
        self.steering = self.steering * 0.8 + newSteering * 0.2
    end

    local steeringRot = Quaternion(0.0, self.steering * MAX_WHEEL_ANGLE, 0.0)
    self.frontLeftAxis.otherAxis = steeringRot * Vector3(-1.0, 0.0, 0.0)
    self.frontRightAxis.otherAxis = steeringRot * Vector3(1.0, 0.0, 0.0)

    if accelerator ~= 0.0 then
        -- Torques are applied in world space, so need to take the vehicle & wheel rotation into account
        local torqueVec = Vector3(ENGINE_POWER * accelerator, 0.0, 0.0)
        local node = self.node
        self.frontLeftBody:ApplyTorque(node.rotation * steeringRot * torqueVec)
        self.frontRightBody:ApplyTorque(node.rotation * steeringRot * torqueVec)
        self.rearLeftBody:ApplyTorque(node.rotation * torqueVec)
        self.rearRightBody:ApplyTorque(node.rotation * torqueVec)
    end

    -- Apply downforce proportional to velocity
    local localVelocity = self.hullBody.rotation:Inverse() * self.hullBody.linearVelocity
    self.hullBody:ApplyForce(self.hullBody.rotation * Vector3(0.0, -1.0, 0.0) * Abs(localVelocity.z) * DOWN_FORCE)
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