function Application:new()
    classVariables = {}
    self.__index = self
    return setmetatable(classVariables, self)
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