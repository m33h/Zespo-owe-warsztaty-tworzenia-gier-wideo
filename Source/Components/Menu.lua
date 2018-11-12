local window = nil

Application = {}
function Application:new()
    classVariables = {}
    self.__index = self
    return setmetatable(classVariables, self)
end

function Application:InitializeMenu()
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

    local titleBar = UIElement:new()
    titleBar:SetMinSize(0, 24)
    titleBar.verticalAlignment = VA_TOP
    titleBar.layoutMode = LM_HORIZONTAL

    local windowTitle = Text:new()
    windowTitle.name = "New game"

    titleBar:AddChild(windowTitle)

    window:AddChild(titleBar)

    window:SetStyleAuto()
    windowTitle:SetStyleAuto()
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

    local playButton = ui.root:CreateChild("Button", "PlayButton")
    playButton:SetStyleAuto()
    playButton.focusMode = FM_RESETFOCUS
    playButton:SetSize(400, 50)
    playButton:SetAlignment(HA_CENTER, VA_CENTER)
    playButton:SetPosition(0, -50)
    local playText = playButton:CreateChild("Text", "PlayText")
    playText:SetAlignment(HA_CENTER, VA_CENTER)
    playText:SetFont(font, 24)
    playText.text = "PLAY"
    SubscribeToEvent(playButton, "Released", "HandlePlayButton")
end

function HandleExitButton()
    engine:Exit()
end

function HandlePlayButton()
    input.mouseVisible = false
    engine:Exit()
end