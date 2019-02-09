require "Source/Components/AppConstants"
local window = nil

function InitializeMenu()
    input.mouseVisible = true
    local style = cache:GetResource("XMLFile", "UI/DefaultStyle.xml")
    ui.root.defaultStyle = style
    InitWindow()
    InitControls()
end

function InitWindow()
    window = Window:new()
    ui.root:AddChild(window)
    window.minWidth = 384
    window:SetLayout(LM_VERTICAL, 6, IntRect(6, 6, 6, 6))
    window:SetAlignment(HA_CENTER, VA_CENTER)
    window:SetName("Window")
    window:SetResizable(true)
end

function InitControls()
    local font = cache:GetResource("Font", "Fonts/Anonymous Pro.ttf")

    local exitButton = ui.root:CreateChild("Button", "ExitButton")
    exitButton:SetStyleAuto()
    exitButton.focusMode = FM_RESETFOCUS
    exitButton:SetSize(400, 50)
    exitButton:SetAlignment(HA_CENTER, VA_CENTER)
    exitButton:SetPosition(0, 0)
    local exitText = exitButton:CreateChild("Text", "ExitText")
    exitText:SetAlignment(HA_CENTER, VA_CENTER)
    exitText:SetFont(font, 24)
    exitText.text = "EXIT"
    SubscribeToEvent(exitButton, "Released", "HandleExitButton")

    local raceButton = ui.root:CreateChild("Button", "RaceButton")
    raceButton:SetStyleAuto()
    raceButton.focusMode = FM_RESETFOCUS
    raceButton:SetSize(400, 50)
    raceButton:SetAlignment(HA_CENTER, VA_CENTER)
    raceButton:SetPosition(0, -50)
    local raceText = raceButton:CreateChild("Text", "RaceText")
    raceText:SetAlignment(HA_CENTER, VA_CENTER)
    raceText:SetFont(font, 24)
    raceText.text = "RACE"
    SubscribeToEvent(raceButton, "Released", "HandleRaceButton")

    local resumeButton = ui.root:CreateChild("Button", "ResumeButton")
    resumeButton:SetStyleAuto()
    resumeButton.focusMode = FM_RESETFOCUS
    resumeButton:SetSize(400, 50)
    resumeButton:SetAlignment(HA_CENTER, VA_CENTER)
    resumeButton:SetPosition(0, -50)
    local resumeText = resumeButton:CreateChild("Text", "ResumeText")
    resumeText:SetAlignment(HA_CENTER, VA_CENTER)
    resumeText:SetFont(font, 24)
    resumeText.text = "Resume"

    resumeButton.visible = false

    SubscribeToEvent(resumeButton, "Released", "HandleResumeButton")
end

function HandleExitButton()
    engine:Exit()
end

function HandleRaceButton()
    input.mouseVisible = false
    ui.root:GetChild("ExitButton", true).visible = false
    ui.root:GetChild("RaceButton", true).visible = false
    ui.root:GetChild("Window", true).visible = false
    ChangeState('START_GAME')
    Application:PlayGame()
end

function HandleResumeButton()
    input.mouseVisible = false
    ui.root:GetChild("ExitButton", true).visible = false
    ui.root:GetChild("ResumeButton", true).visible = false
    ui.root:GetChild("Window", true).visible = false
    ChangeState('PLAY_GAME')
end