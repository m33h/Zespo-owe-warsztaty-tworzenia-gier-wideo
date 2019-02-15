require "Source/Components/AppConstants"

Vehicle = ScriptObject()

local scene_

function Vehicle:Init(scene)
    print("Vehicle:Init")

    -- This function is called only from the main program when initially creating the vehicle, not on scene load
    self.scene_ = scene
    local node = self.node
    local hullObject = node:CreateComponent("StaticModel")
    self.hullBody = node:CreateComponent("RigidBody")
    local hullShape = node:CreateComponent("CollisionShape")

    node.scale = Vector3(1.5, 1, 3)
    hullObject.model = cache:GetResource("Model", "Models/Box.mdl")
    hullObject.material = cache:GetResource("Material", "Materials/Stone.xml")

    hullObject.castShadows = true
    hullShape:SetBox(Vector3(1.0, 1.0, 1.0))

    self.hullBody.mass = 5
    self.hullBody.linearDamping = 0.75
    self.hullBody.angularDamping = 0.5
    self.hullBody.collisionLayer = 1
    self.frontLeft = self:InitWheel("FrontLeft", Vector3(-0.6, -0.4, 0.3))
    self.frontRight = self:InitWheel("FrontRight", Vector3(0.6, -0.4, 0.3))
    self.rearLeft = self:InitWheel("RearLeft", Vector3(-0.6, -0.4, -0.3))
    self.rearRight = self:InitWheel("RearRight", Vector3(0.6, -0.4, -0.3))

    self:SubscribeToEvents()
    self:PostInit()

    self.guildlines_points = 0
end

function Vehicle:SubscribeToEvents()
    print("Vehicle:SubscribeToEvents")
    SubscribeToEvent(self.node, "NodeCollision", "HandleCollision")
end

function HandleCollision(eventType, eventData)
    print("Vehicle:HandleCollision")
    local otherNode = eventData["OtherNode"]:GetPtr("Node")

    if nil ~= otherNode then
        if otherNode:HasTag(TAG_POWERUP) then
            print("Collected powerup!")
            otherNode:SetEnabled(false)
            SendEvent(EVENT_POWERUP_COLLECTED)
        elseif otherNode:HasTag(TAG_WEAPON) then
            print("Collected weapon!")
            otherNode:SetEnabled(false)
        end
    end
end

function Vehicle:InitWheel(name, offset)
    print("Vehicle:InitWheel")

    -- Note: do not parent the wheel to the hull scene node. Instead create it on the root level and let the physics
    -- constraint keep it together
    local wheelNode = self.scene_:CreateChild(name)
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
    wheelShape:SetSphere(1)
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
    print("Vehicle:PostInit")

    self.frontLeft = self.scene_:GetChild("FrontLeft")
    self.frontRight = self.scene_:GetChild("FrontRight")
    self.rearLeft = self.scene_:GetChild("RearLeft")
    self.rearRight = self.scene_:GetChild("RearRight")

    self.frontLeftAxis = self.frontLeft:GetComponent("Constraint")
    self.frontRightAxis = self.frontRight:GetComponent("Constraint")

    self.hullBody = self.node:GetComponent("RigidBody")

    self.frontLeftBody = self.frontLeft:GetComponent("RigidBody")
    self.frontRightBody = self.frontRight:GetComponent("RigidBody")
    self.rearLeftBody = self.rearLeft:GetComponent("RigidBody")
    self.rearRightBody = self.rearRight:GetComponent("RigidBody")
end

function Vehicle:Start()
    print("Vehicle:Start")

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
        self.steering = self.steering * 0.9 + newSteering * 0.05
    else
        self.steering = self.steering * 0.7 + newSteering * 0.2
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
