checkpoints = { Vector3(100,1.4,200), Vector3(-10,1.4,200), Vector3(-80,1.4,140), Vector3(-10,1.4,-210), Vector3(80,1.4,-210), Vector3(100,1.4,-130), Vector3(100,1.4,180), Vector3(100,1.4,200) }

function GetNearestPoint(vector, order)
    local minIndex = 1
    local minDistance = 1000000
    for k = 1, 8 do
        dist = (checkpoints[k] - vector):Length()
        if(dist < minDistance) then
            minDistance = dist
            minIndex = k
        end
    end

    return checkpoints[minIndex+order]
end

function vectorsCos(vec1, vec2)
    local d_vec1 = Vector2(vec1.x, vec1.z)
    local d_vec2 = Vector2(vec2.x, vec2.z)

    return (d_vec1.x * d_vec2.x + d_vec1.y * d_vec2.y) / (d_vec1:Length() * d_vec2:Length())
end

function vectorsSin(vec1, vec2)
    local d_vec1 = Vector2(vec1.x, vec1.z)
    local d_vec2 = Vector2(vec2.x, vec2.z)

    return (d_vec1 * d_vec2):Length() / (d_vec1:Length() * d_vec2:Length())
end
