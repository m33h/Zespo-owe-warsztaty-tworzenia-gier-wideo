require "Source/Components/Debug"
require "Source/Components/Timer"

local vehicleNode = nil
local CAMERA_DISTANCE = 10.0

Vehicle = ScriptObject()

function Application:new()
    classVariables = { state = 'GAME_MENU' }
    self.__index = self
    return setmetatable(classVariables, self)
end

function Application:SubscribeToEvents()
    SubscribeToEvent("Update", "HandleUpdate")
    SubscribeToEvent("PostUpdate", "HandlePostUpdate")
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

    local zoneNode = scene_:CreateChild("Zone")
    local zone = zoneNode:CreateComponent("Zone")
    zone.ambientColor = Color(0.15, 0.15, 0.15)
    zone.fogColor = Color(0.5, 0.5, 0.7)
    zone.fogStart = 300.0
    zone.fogEnd = 500.0
    zone.boundingBox = BoundingBox(-2000.0, 2000.0)

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
    terrain.spacing = Vector3(1, 0, 1) -- our map is flat
--    terrain.smoothing = true
    terrain.heightMap = cache:GetResource("Image", "Textures/HeightMap.png")
    terrain.material = cache:GetResource("Material", "Materials/Terrain.xml")
    terrain.occluder = true

    local body = terrainNode:CreateComponent("RigidBody")
    body.collisionLayer = 2
    local shape = terrainNode:CreateComponent("CollisionShape")
    shape:SetTerrain()

    scene_:CreateScriptObject("Timer")
end

function Application:PlayGame()
    CreateViewport()
end

function Application:CreateVehicle(vehicleNode)
    vehicleNode = scene_:CreateChild("Vehicle")
    vehicleNode.position = Vector3(0.0, 5.0, 0.0)

    -- Create the vehicle logic script object
    local vehicle = vehicleNode:CreateScriptObject("Vehicle")
    -- Create the rendering and physics components
    vehicle:Init()
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

function Application:CreateVehicle()
    vehicleNode = scene_:CreateChild("Vehicle")
    vehicleNode.position = Vector3(0.0, 3.55, 0.0)

    -- Create the vehicle logic script object
    local vehicle = vehicleNode:CreateScriptObject("Vehicle")
    -- Create the rendering and physics components
    vehicle:Init()

    return vehicleNode
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

    self.hullBody.mass = 10
    self.hullBody.linearDamping = 0.2
    self.hullBody.angularDamping = 0.5
    self.hullBody.collisionLayer = 1
    self.frontLeft = self:InitWheel( "FrontLeft",  Vector3(0.5, 0.55, 0.5))
    self.frontRight = self:InitWheel("FrontRight", Vector3(-0.5, 0.55, 0.5))
    self.rearLeft = self:InitWheel(  "RearLeft",   Vector3(0.5, 0.55, -0.5))
    self.rearRight = self:InitWheel( "RearRight",  Vector3(-0.5, 0.55, -0.5))

    self:PostInit()
end

function Vehicle:InitWheel(name, offset)
    -- Note: do not parent the wheel to the hull scene node. Instead create it on the root level and let the physics
    -- constraint keep it together
    local wheelNode = scene_:CreateChild(name)
    local node = self.node
    wheelNode.position = node:LocalToWorld(offset)

    -- fail
    if offset.x >= 0.0 then
        wheelNode.rotation = node.worldRotation * Quaternion(0.0, 0.0, -9.0)
    else
        wheelNode.rotation = node.worldRotation * Quaternion(0.0, 0.0, 9.0)
    end
    wheelNode.scale = Vector3(1, 0.5, 1)

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

function Vehicle:Start()
    -- Current left/right steering amount (-1 to 1.)
    self.steering = 0.0
    -- Vehicle controls.
    self.controls = Controls()
end