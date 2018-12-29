require "Source/Components/Debug"

local vehicleNode = nil
local CTRL_FORWARD = 1
local CTRL_BACK = 2
local CTRL_LEFT = 4
local CTRL_RIGHT = 8

local CAMERA_DISTANCE = 10.0
local YAW_SENSITIVITY = 0.1
local ENGINE_POWER = 10.0
local DOWN_FORCE = 10.0
local MAX_WHEEL_ANGLE = 22.5

Vehicle = ScriptObject()

function Application:new()
    classVariables = { state = 'GAME_MENU' }
    self.__index = self
    self.subscribeToEvents()
    return setmetatable(classVariables, self)
end

function Application:subscribeToEvents()
    SubscribeToEvent("Update", "HandleUpdate")
end

function Application:CreateScene()
    scene_ = Scene()
    scene_:CreateComponent("Octree")
    scene_:CreateComponent("PhysicsWorld")

    cameraNode = Node()
    cameraNode:SetPosition(Vector3(5,5,0))
    cameraNode:SetDirection(Vector3(-1,-1,0))
    local camera = cameraNode:CreateComponent("Camera")
    camera.farClip = 500.0

    renderer:SetViewport(0, Viewport:new(scene_, camera))

    local lightNode = scene_:CreateChild("DirectionalLight")
    lightNode.direction = Vector3(0.3, -0.5, 0.425)
    local light = lightNode:CreateComponent("Light")
    light.lightType = LIGHT_DIRECTIONAL
    light.castShadows = true
    light.shadowBias = BiasParameters(0.00025, 0.5)
    light.shadowCascade = CascadeParameters(10.0, 50.0, 200.0, 0.0, 0.8)
    light.specularIntensity = 0.5

    local terrainNode = scene_:CreateChild("Terrain")
    terrainNode.position = Vector3(0.0, 0.0, 0.0)
    local terrain = terrainNode:CreateComponent("Terrain")
    terrain.patchSize = 64
    terrain.spacing = Vector3(0, 0, 0) -- our map is flat
    terrain.smoothing = true
    terrain.heightMap = cache:GetResource("Image", "Textures/HeightMap.png")
    terrain.material = cache:GetResource("Material", "Materials/Terrain.xml")
    terrain.occluder = true

    local shape = terrainNode:CreateComponent("CollisionShape")
    shape:SetTerrain()
end

function Application:PlayGame()
    CreateViewport()
end

function CreateViewport()
    scene_:CreateComponent("Octree")
    local planeNode = scene_:CreateChild("Plane")
    planeNode.scale = Vector3(100.0, 1.0, 100.0)
    local planeObject = planeNode:CreateComponent("StaticModel")
    planeObject.model = cache:GetResource("Model", "Models/Plane.mdl")
    planeObject.material = cache:GetResource("Material", "Materials/StoneTiled.xml")
    local lightNode = scene_:CreateChild("DirectionalLight")
    lightNode.direction = Vector3(0.6, -1.0, 0.8) -- The direction vector does not need to be normalized
    local light = lightNode:CreateComponent("Light")
    light.lightType = LIGHT_DIRECTIONAL
end

function MoveCamera(timeStep)
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

-- todo: move this to Application class
function HandleUpdate(eventType, eventData)
    if vehicleNode == nil then
        return
    end

    local vehicle = vehicleNode:GetScriptObject()

    if vehicle == nil then
        return
    end

--     Get movement controls and assign them to the vehicle component. If UI has a focused element, clear controls
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
--        dbg()
        vehicle.controls:Set(CTRL_FORWARD + CTRL_BACK + CTRL_LEFT + CTRL_RIGHT, false)
    end

    local timeStep = eventData["TimeStep"]:GetFloat()
    if(application.state == 'PLAY_GAME') then
        MoveCamera(timeStep)
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

function Application:CreateVehicle()
    vehicleNode = scene_:CreateChild("Vehicle")
    vehicleNode.position = Vector3(0.0, 3, 0.0)

    -- Create the vehicle logic script object
    local vehicle = vehicleNode:CreateScriptObject("Vehicle")
    -- Create the rendering and physics components
    vehicle:Init()
end

function Vehicle:Init()
    -- This function is called only from the main program when initially creating the vehicle, not on scene load
    local node = self.node
    local hullObject = node:CreateComponent("StaticModel")
    self.hullBody = node:CreateComponent("RigidBody")
    local hullShape = node:CreateComponent("CollisionShape")

    node.scale = Vector3(1.5, 1, 3)
    hullObject.model = cache:GetResource("Model", "Models/Box.mdl")
    hullObject.material = cache:GetResource("Material", "Materials/Stone.xml")

    hullObject.castShadows = true
    hullShape:SetBox(Vector3(1.0, 1.0, 1.0))

    self.hullBody.mass = -1
    self.hullBody.linearDamping = 0.2 -- Some air resistance
    self.hullBody.angularDamping = 0.5
    self.hullBody.collisionLayer = 1
    self.frontLeft = self:InitWheel("FrontLeft", Vector3(0.5, -0.5, 0.5))
    self.frontRight = self:InitWheel("FrontRight", Vector3(-0.5, -0.5, 0.5))
    self.rearLeft = self:InitWheel("RearLeft", Vector3(0.5, -0.5, -0.5))
    self.rearRight = self:InitWheel("RearRight", Vector3(-0.5, -0.5, -0.5))

    self:PostInit()
end

function Vehicle:InitWheel(name, offset)
    -- Note: do not parent the wheel to the hull scene node. Instead create it on the root level and let the physics
    -- constraint keep it together
    local wheelNode = scene_:CreateChild(name)
    local node = self.node
    wheelNode.position = node:LocalToWorld(offset)
    if offset.x >= 0.0 then
        wheelNode.rotation = node.worldRotation * Quaternion(0.0, 0.0, -9.0)
    else
        wheelNode.rotation = node.worldRotation * Quaternion(0.0, 0.0, 9.0)
    end
    wheelNode.scale = Vector3(0.8, 0.5, 0.8)

    local wheelObject = wheelNode:CreateComponent("StaticModel")
    local wheelBody = wheelNode:CreateComponent("RigidBody")
    local wheelShape = wheelNode:CreateComponent("CollisionShape")
    local wheelConstraint = wheelNode:CreateComponent("Constraint")

    wheelObject.model = cache:GetResource("Model", "Models/Cylinder.mdl")
    wheelObject.material = cache:GetResource("Material", "Materials/Stone.xml")
    wheelObject.castShadows = true
    wheelShape:SetSphere(0.01)
    wheelBody.friction = 1
    wheelBody.mass = 1
    wheelBody.linearDamping = 0.2 -- Some air resistance
    wheelBody.angularDamping = 0.075 -- Could also use rolling friction
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
        -- refactor
        local torqueVec = Vector3(ENGINE_POWER * accelerator * 0.00001, 0.0, 0.0)
        local node = self.node
        self.frontLeftBody:ApplyTorque(node.rotation * steeringRot * torqueVec)
        self.frontRightBody:ApplyTorque(node.rotation * steeringRot * torqueVec)
        self.rearLeftBody:ApplyTorque(node.rotation * torqueVec)
        self.rearRightBody:ApplyTorque(node.rotation * torqueVec)
    end

    -- Apply downforce proportional to velocity
--    local localVelocity = self.hullBody.rotation:Inverse() * self.hullBody.linearVelocity
--    self.hullBody:ApplyForce(self.hullBody.rotation * Vector3(0.0, -1.0, 0.0) * Abs(localVelocity.z) * DOWN_FORCE)
end

function Vehicle:Start()
    -- Current left/right steering amount (-1 to 1.)
    self.steering = 0.0
    -- Vehicle controls.
    self.controls = Controls()
end