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

    -- Create heightmap terrain with collision
    local terrainNode = scene_:CreateChild("Terrain")
    terrainNode.position = Vector3(0.0, 0.0, 0.0)
    local terrain = terrainNode:CreateComponent("Terrain")
    terrain.patchSize = 64
    terrain.spacing = Vector3(2.0, 0.1, 2.0) -- Spacing between vertices and vertical resolution of the height map
    terrain.smoothing = true
    terrain.heightMap = cache:GetResource("Image", "Textures/HeightMap.png")
    terrain.material = cache:GetResource("Material", "Materials/Terrain.xml")
    -- The terrain consists of large triangles, which fits well for occlusion rendering, as a hill can occlude all
    -- terrain patches and other objects behind it
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

    local NUM_OBJECTS = 200
    for i = 1, NUM_OBJECTS do
        local mushroomNode = scene_:CreateChild("Mushroom")
        mushroomNode.position = Vector3(Random(90.0) - 45.0, 0.0, Random(90.0) - 45.0)
        mushroomNode.rotation = Quaternion(0.0, Random(360.0), 0.0)
        mushroomNode:SetScale(0.5 + Random(2.0))
        local mushroomObject = mushroomNode:CreateComponent("StaticModel")
        mushroomObject.model = cache:GetResource("Model", "Models/Mushroom.mdl")
        mushroomObject.material = cache:GetResource("Material", "Materials/Mushroom.xml")
        cameraNode.position = Vector3(0.0, 5.0, 0.0)
    end
end

function MoveCamera(timeStep)
    local MOVE_SPEED = 20.0

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
    MoveCamera(timeStep)
end