require "Source/Components/Debug"

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
    cameraNode:SetPosition(Vector3(0,100,0))
    cameraNode:SetDirection(Vector3(1,0,0))
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

    if input:GetKeyDown(KEY_W) then
        cameraNode:Translate(Vector3(0.0, 0.0, 1.0) * MOVE_SPEED * timeStep)
    end
    if input:GetKeyDown(KEY_S) then
        cameraNode:Translate(Vector3(0.0, 0.0, -1.0) * MOVE_SPEED * timeStep)
    end
    if input:GetKeyDown(KEY_A) then
        cameraNode:Translate(Vector3(-1.0, 0.0, 0.0) * MOVE_SPEED * timeStep)
    end
    if input:GetKeyDown(KEY_D) then
        cameraNode:Translate(Vector3(1.0, 0.0, 0.0) * MOVE_SPEED * timeStep)
    end
end

-- todo: move this to Application class
function HandleUpdate(eventType, eventData)
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