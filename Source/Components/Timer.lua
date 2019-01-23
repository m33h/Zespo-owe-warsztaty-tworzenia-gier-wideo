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

function Timer:FormatTime(value)
    local roundedValue = math.floor(value * 10) / 10
    if((roundedValue * 10) % 10 == 0) then
        return roundedValue..".0s"
    end
    return roundedValue.."s"
end

function Timer:FixedUpdate(timeStep)
    if(application.state == 'PLAY_GAME') then
        timerValue = timerValue + timeStep
        timeText.text = self:FormatTime(timerValue)
        local pos_X = ui.root:GetWidth() / 2 - timeText:GetWidth() / 2
        local pos_Y = 0
        timeText:SetPosition(pos_X, pos_Y)
    end
end

function Timer:GetValue()
    return timerValue
end

--times of every car are stored in table
race_times = {}

--function to register time of vehicle when it crosses end line
function RegisterTime(p_name)
    table.insert(race_times, { name = p_name, time = Timer:GetValue()})
end

--function to display end result
function DisplayResults()
--    table.sort (race_times, function (k1, k2) return k1.time < k2.time end )
    for i = 1, #race_times do
        print(i, race_times[i].name, race_times[i].time)
    end
end


--This is example code
--RegisterTime("Olga", 56)
--RegisterTime("Hej", 6)
--RegisterTime("asd", 17)
--RegisterTime("zxc", 19)
--
--DisplayResults()
