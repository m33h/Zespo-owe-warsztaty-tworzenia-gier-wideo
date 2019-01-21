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