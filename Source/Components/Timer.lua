StartTimer = {}

function StartTimer:Start()
    startTimerValue = 6
    startTimeText = Text:new()
    startTimeText.text = startTimerValue.."s"
    startTimeText:SetFont(cache:GetResource("Font", "Fonts/Anonymous Pro.ttf"), 72)
    startTimeText.color = Color.YELLOW
    startTimeText:SetVisible(false)

    local pos_X = ui.root:GetWidth() / 2 - startTimeText:GetWidth() / 2
    local pos_Y = ui.root:GetHeight() / 2
    startTimeText:SetPosition(pos_X, pos_Y)
    ui.root:AddChild(startTimeText)
end

function StartTimer:FixedUpdate(timeStep)
    if(GAME_STATE == 'START_GAME') then
        startTimeText:SetVisible(true)
        startTimerValue = startTimerValue - timeStep
        startTimeText.text = math.floor(startTimerValue)
        local pos_X = ui.root:GetWidth() / 2 - startTimeText:GetWidth() / 2
        local pos_Y = ui.root:GetHeight() / 2
        startTimeText:SetPosition(pos_X, pos_Y)
    end
    if (math.floor(startTimerValue) == 0) then
        ChangeState("PLAY_GAME")
        startTimerValue = startTimerValue - timeStep
        startTimeText.text = "GO!"
        local pos_X = ui.root:GetWidth() / 2 - startTimeText:GetWidth() / 2
        local pos_Y = ui.root:GetHeight() / 2
        startTimeText:SetPosition(pos_X, pos_Y)
    end
    if (startTimerValue <= 0) then
        startTimeText:SetVisible(false)
    end
end

Timer = {}

function Timer:Start()
    timerValue = 0
    timeText = Text:new()
    timeText.text = timerValue..".00s"
    timeText:SetFont(cache:GetResource("Font", "Fonts/Anonymous Pro.ttf"), 42)
    timeText.color = Color.RED

    local pos_X = ui.root:GetWidth() / 2 - timeText:GetWidth() / 2
    local pos_Y = 0
    timeText:SetPosition(pos_X, pos_Y)
    ui.root:AddChild(timeText)
end

function Timer:FixedUpdate(timeStep)
    if(GAME_STATE == 'PLAY_GAME') then
        timerValue = timerValue + timeStep
        timeText.text = FormatTime(timerValue)
        local pos_X = ui.root:GetWidth() / 2 - timeText:GetWidth() / 2
        local pos_Y = 0
        timeText:SetPosition(pos_X, pos_Y)
    end
    if(GAME_STATE== "WIN_STATE") then
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

--This demo was written to show timer functionality
function TimerDemo()
    if input:GetKeyDown(KEY_1) then
        RegisterTime("Ala")
    end
    if input:GetKeyDown(KEY_2) then
        RegisterTime("Bartek")
    end
    if input:GetKeyDown(KEY_3) then
        RegisterTime("Cezary")
    end
    if input:GetKeyDown(KEY_4) then
        RegisterTime("Dawid")
    end
    if input:GetKeyDown(KEY_5) then
        ChangeState("WIN_STATE")
    end
    if (GAME_STATE == "WIN_STATE") then
        DisplayResults()
    end
end


