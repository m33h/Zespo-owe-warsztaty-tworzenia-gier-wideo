checkpoints = {
    { active = true, point = Vector3(40,1.4,200) },
    { active = false, point = Vector3(20,1.4,200) },
    { active = false, point = Vector3(0,1.4,200) },
    { active = false, point = Vector3(-20,1.4,200) },
    { active = false, point = Vector3(-40,1.4,200) },
    { active = false, point = Vector3(-60,1.4,200) },
    { active = false, point = Vector3(-85,1.4,195) },
    { active = false, point = Vector3(-90,1.4,190) },
    { active = false, point = Vector3(-95,1.4,185) },
    { active = false, point = Vector3(-100,1.4,160) },
    { active = false, point = Vector3(-100,1.4,140) },
    { active = false, point = Vector3(-100,1.4,120) },
    { active = false, point = Vector3(-100,1.4,100) },
    { active = false, point = Vector3(-100,1.4,80) },
    { active = false, point = Vector3(-100,1.4,60) },
    { active = false, point = Vector3(-100,1.4,40) },
    { active = false, point = Vector3(-100,1.4,20) },
    { active = false, point = Vector3(-100,1.4,0) },
    { active = false, point = Vector3(-100,1.4,-20) },
    { active = false, point = Vector3(-100,1.4,-40) },
    { active = false, point = Vector3(-100,1.4,-60) },
    { active = false, point = Vector3(-100,1.4,-80) },
    { active = false, point = Vector3(-100,1.4,-100) },
    { active = false, point = Vector3(-100,1.4,-120) },
    { active = false, point = Vector3(-100,1.4,-140) },
    { active = false, point = Vector3(-100,1.4,-160) },
    { active = false, point = Vector3(-95,1.4,-185) },
    { active = false, point = Vector3(-90,1.4,-190) },
    { active = false, point = Vector3(-85,1.4,-195) },
    { active = false, point = Vector3(-60,1.4,-200) },
    { active = false, point = Vector3(-40,1.4,-200) },
    { active = false, point = Vector3(-20,1.4,-200) },
    { active = false, point = Vector3(0,1.4,-200) },
    { active = false, point = Vector3(20,1.4,-200) },
    { active = false, point = Vector3(40,1.4,-200) },
    { active = false, point = Vector3(60,1.4,-200) },
    { active = false, point = Vector3(85,1.4,-195) },
    { active = false, point = Vector3(90,1.4,-190) },
    { active = false, point = Vector3(95,1.4,-185) },
    { active = false, point = Vector3(100,1.4,-160) },
    { active = false, point = Vector3(100,1.4,-140) },
    { active = false, point = Vector3(100,1.4,-120) },
    { active = false, point = Vector3(100,1.4,-100) },
    { active = false, point = Vector3(100,1.4,-80) },
    { active = false, point = Vector3(100,1.4,-60) },
    { active = false, point = Vector3(100,1.4,-40) },
    { active = false, point = Vector3(100,1.4,-20) },
    { active = false, point = Vector3(100,1.4,0) },
    { active = false, point = Vector3(100,1.4,20) },
    { active = false, point = Vector3(100,1.4,40) },
    { active = false, point = Vector3(100,1.4,60) },
}


function DidPlayerFinish(counter)
    if (counter == #checkpoints - 1) then
        return true
    else
        return false
    end
end

function GetActiveCheckpoint(order)
    for k = 1, #checkpoints do
        if(checkpoints[k].active == true) then
            return checkpoints[k+order]
        end
    end
end

function MarkNextCheckpointActive()
    currentCheckpoint = GetActiveCheckpoint(0)
    nextCheckpoint = GetActiveCheckpoint(1)
end

function GetNearestCheckpoint(vector, order)
    local minIndex = 1
    local minDistance = 1000000
    for k = 1, #checkpoints do
        dist = (checkpoints[k].point - vector):Length()
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

    return (vec1.x * vec2.z - vec1.z * vec2.x) / (d_vec1:Length() * d_vec2:Length())
end
