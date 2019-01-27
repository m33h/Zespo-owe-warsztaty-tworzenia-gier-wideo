Timer = {}

function Timer:Start()
    timerValue = 0
    timeText = Text:new()
    timeText.text = timerValue.."s"
    timeText:SetFont(cache:GetResource("Font", "Fonts/Anonymous Pro.ttf"), 42)
    timeText.color = Color.RED

    local pos_X = ui.root:GetWidth() / 2 - timeText:GetWidth() / 2
    local pos_Y = 0
    timeText:SetPosition(pos_X, pos_Y)
    ui.root:AddChild(timeText)
end

function Timer:FixedUpdate(timeStep)
    if(application.state == 'PLAY_GAME') then
        timerValue = timerValue + timeStep
        timeText.text = FormatTime(timerValue)
        local pos_X = ui.root:GetWidth() / 2 - timeText:GetWidth() / 2
        local pos_Y = 0
        timeText:SetPosition(pos_X, pos_Y)
    end
    if(application.state == "WIN_STATE") then
        timerValue = timerValue + timeStep
        timeText.text = FormatTime(timerValue)
        timeText.visible = false
    end
end

function Timer:GetValue()
    return timerValue
end

function FormatTime(value)
    local roundedValue = math.floor(value * 100) / 100
    if((roundedValue * 100) % 100 == 0) then
        return roundedValue..".00s"
    end
    if((roundedValue * 100) % 10 == 0) then
        return roundedValue.."0s"
    end
    return roundedValue.."s"
end

--race times of every car are stored in table, there is also counter of elements in tablez
race_timers = {}
num_of_timers = 0

--used to reset all information about timers
function ResetTimers()
    race_timers = {}
    num_of_timers = 0
end

--checks if entry already exist
function CheckIfExist(p_name)
    for i = 1, #race_timers do
        if(race_timers[i].name == p_name) then
            return true
        end
    end
end

--function to register time of vehicle when it crosses end line
function RegisterTime(p_name)
    if (not CheckIfExist(p_name)) then
        table.insert(race_timers, { name = p_name, time = FormatTime(Timer:GetValue())})
    end
    num_of_timers = num_of_timers + 1
end

--displays one entry by index
function PrintEntry(index)
    entryText = Text:new()
    local name = race_timers[index].name
    local time = race_timers[index].time
    entryText.text = index.." "..name.." "..time
    entryText:SetFont(cache:GetResource("Font", "Fonts/Anonymous Pro.ttf"), 42)
    entryText.color = Color.RED

    local pos_X = ui.root:GetWidth() / 2 - entryText:GetWidth() / 2
    local pos_Y = ui.root:GetHeight() / 2 - 150 + entryText:GetHeight() * index
    entryText:SetPosition(pos_X, pos_Y)
    ui.root:AddChild(entryText)
end

--display all results
function DisplayResults()
    if (num_of_timers >= 2) then
        table.sort (race_timers, function (k1, k2) return k1.time < k2.time end )
    end
    for i = 1, #race_timers do
        PrintEntry(i)
    end
end



