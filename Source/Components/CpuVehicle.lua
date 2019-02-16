require "Source/Components/AppConstants"
require "Source/Components/Timer"

CpuVehicle = ScriptObject()
distanceToCheckpoint = 0

local scene_

function CpuVehicle:Init(scene, cpu_index)
    print("Vehicle:Init")
    --
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

    self.cpu_index = cpu_index
    self.finished = false

    self.hullBody.mass = 5
    self.hullBody.linearDamping = 0.75
    self.hullBody.angularDamping = 0.5
    self.hullBody.collisionLayer = 1
    self.frontLeft = self:InitWheel("FrontLeftCpu_"..self.cpu_index, Vector3(-0.6, -0.4, 0.3))
    self.frontRight = self:InitWheel("FrontRightCpu_"..self.cpu_index, Vector3(0.6, -0.4, 0.3))
    self.rearLeft = self:InitWheel("RearLeftCpu_"..self.cpu_index, Vector3(-0.6, -0.4, -0.3))
    self.rearRight = self:InitWheel("RearRightCpu_"..self.cpu_index, Vector3(0.6, -0.4, -0.3))
    self:PostInit()
end

function CpuVehicle:InitWheel(name, offset)
    print("CpuVehicle:InitWheel")

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

function CpuVehicle:PostInit()
    print("Vehicle:PostInit")

    self.frontLeft = self.scene_:GetChild("FrontLeftCpu_"..self.cpu_index)
    self.frontRight = self.scene_:GetChild("FrontRightCpu_"..self.cpu_index)
    self.rearLeft = self.scene_:GetChild("RearLeftCpu_"..self.cpu_index)
    self.rearRight = self.scene_:GetChild("RearRightCpu_"..self.cpu_index)

    self.frontLeftAxis = self.frontLeft:GetComponent("Constraint")
    self.frontRightAxis = self.frontRight:GetComponent("Constraint")

    self.hullBody = self.node:GetComponent("RigidBody")

    self.frontLeftBody = self.frontLeft:GetComponent("RigidBody")
    self.frontRightBody = self.frontRight:GetComponent("RigidBody")
    self.rearLeftBody = self.rearLeft:GetComponent("RigidBody")
    self.rearRightBody = self.rearRight:GetComponent("RigidBody")
end

function CpuVehicle:Start()
    self.steering = 0.0
    self.controls = Controls()
end

function CpuVehicle:Load(deserializer)
    self.controls.yaw = deserializer:ReadFloat()
    self.controls.pitch = deserializer:ReadFloat()
end

function CpuVehicle:Save(serializer)
    serializer:WriteFloat(self.controls.yaw)
    serializer:WriteFloat(self.controls.pitch)
end

function CpuVehicle:FixedUpdate(timeStep)

    if ((GAME_STATE == "PLAY_GAME" or GAME_STATE == "WIN_STATE") and not self.finished) then

        local nearestCheckpoint = GetNearestCheckpoint(self.node.position, 0).point

--    checks if nearest point is last position
        if(nearestCheckpoint == checkpoints[#checkpoints - 1].point) then
            RegisterTime("CPU_"..self.cpu_index)
            self.finished = true
            return
        end
    
        local nextCheckpoint = GetNearestCheckpoint(self.node.position, 1).point
        checkpointsVector = (nextCheckpoint - nearestCheckpoint):Normalized()
        cos = vectorsCos(checkpointsVector, self.node.direction)
        sin = vectorsSin(checkpointsVector, self.node.direction)


        local newSteering = 0.0

        if sin > 0 and sin < 0.5 then
            newSteering = 0.4
        elseif sin >= 0.5 and sin < 0.8 then
            newSteering = 0.8
        elseif sin >= 0.8 then
            newSteering = 1.0
        elseif sin < 0 and sin > -0.5 then
            newSteering = -0.4
        elseif sin <= -0.5 then
            newSteering = -1.0
        elseif sin < -0.5 and sin > -0.8 then
            newSteering = 0.8
        elseif sin <= 0.8 then
            newSteering = -1.0
        end

        local accelerator = 1.0

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
            local torqueVec = Vector3(ENGINE_POWER * accelerator, 0.0, 0.0)
            local node = self.node
            self.frontLeftBody:ApplyTorque(node.rotation * steeringRot * torqueVec)
            self.frontRightBody:ApplyTorque(node.rotation * steeringRot * torqueVec)
            self.rearLeftBody:ApplyTorque(node.rotation * torqueVec)
            self.rearRightBody:ApplyTorque(node.rotation * torqueVec)
        end

        local localVelocity = self.hullBody.rotation:Inverse() * self.hullBody.linearVelocity
        self.hullBody:ApplyForce(self.hullBody.rotation * Vector3(0.0, -1.0, 0.0) * Abs(localVelocity.z) * DOWN_FORCE)
    end
end
