local _, addon = ...

local AddonName = "BoxHelper"
BoxHelper = LibStub("AceAddon-3.0"):NewAddon("BoxHelper")

local COMM_TARGET_NOT_IN_FRONT = "BoxHelper_TargetNotInFront"
local COMM_GTFO = "BoxHelper_GTFO"

local INDICATOR_STATE_NORMAL = "normal"
local INDICATOR_STATE_NOT_IN_FRONT = "notInFront"
local INDICATOR_STATE_GTFO = "gtfo"

local MAX_NAMES_IN_FRAMES = 5
local TIMER_DURATION = 3

local function bind(object, callback, ...)
    return function(...)
        callback(object, unpack({...})) 
    end
end

function BoxHelper:OnInitialize()
    self.enableDebug=false

    self.triggerMessages = {
        notInFront = "Target needs to be in front of you."
    }

    self.playersTargetNotInFront = {}
    self.playersGTFO = {}

    self.AceTimer = LibStub:GetLibrary("AceTimer-3.0")
    self.AceComm = LibStub:GetLibrary("AceComm-3.0")
    self.AceConsole = LibStub:GetLibrary("AceConsole-3.0")

    self:RegisterChatCommands()
    self:RegisterCommCallbacks()

    self.frames = {}
    self.frames["nameListTargetNotInFront"] = self:CreateNameListFrame("BoxHelperNameListTargetNotInFront", "Not facing target")
    self.frames["nameListGTFO"] = self:CreateNameListFrame("BoxHelperNameListGTFO", "GTFO")

    self.timers = {
        playersTargetNotInFront = {},
        playersGTFO = {}
    }

    -- Color Indicators: Not yet implemented
    --self:CreatePartyIndicatorFrames()

    self:Debug("Initialized")
end

function BoxHelper:RegisterChatCommands()
    self.AceConsole:RegisterChatCommand("boxhelper", bind(self, BoxHelper.OnCommand))
    self.AceConsole:RegisterChatCommand("bh", bind(self, BoxHelper.OnCommand))
end

function BoxHelper:RegisterCommCallbacks()
    self.AceComm:RegisterComm(COMM_TARGET_NOT_IN_FRONT, bind(self, BoxHelper.OnTargetNotInFrontCommReceived))
    self.AceComm:RegisterComm(COMM_GTFO, bind(self, BoxHelper.OnGTFOCommReceived))
end

function BoxHelper:HandleTargetNotInFront ()
    self:Debug("You are not facing your target")

    self:SendNotInFrontComm()
end

function BoxHelper:HandleGTFO ()
    self:Debug("GTFO is triggering")

    self:SendGTFOComm()
end

function BoxHelper:OnCommand(input)

    if (input == "test") then
        self:SendNotInFrontComm()
        self:SendGTFOComm()
        self:Output("Test AceComm message sent")
    end
end

function BoxHelper:SendNotInFrontComm()
    self.AceComm:SendCommMessage(COMM_TARGET_NOT_IN_FRONT, "", "RAID", nil, "ALERT")
end

function BoxHelper:SendGTFOComm()
    self.AceComm:SendCommMessage(COMM_GTFO, "", "RAID", nil, "ALERT")
end

function BoxHelper:OnTargetNotInFrontCommReceived(prefix, message, distribution, sender)
    self:Debug("OnTargetNotInFrontCommReceived from " .. sender)

    self:AddPlayerTargetNotInFront(sender)
end

function BoxHelper:OnGTFOCommReceived(prefix, message, distribution, sender)
    self:Debug("OnGTFOCommReceived from " .. sender)

    self:AddPlayerGTFO(sender)
end

function BoxHelper:CreatePartyIndicatorFrames()
    for i = 1, GetNumPartyMembers() do
        local unitId = "party" .. i
        local unitFrame = _G["PartyMemberFrame" .. i]

        self:CreatePartyIndicatorFrame(unitId, unitFrame)
    end
end

function BoxHelper:CreatePartyIndicatorFrame(unitId, anchorFrame)
    local frame = CreateFrame("Frame", "BoxHelper_PartyIndicator_"..unitId, UIParent)
    frame:SetWidth(10)
    frame:SetHeight(10)
    frame:SetPoint("CENTER")
    frame:SetBackdrop({
     bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    })

    frame:SetBackdropColor(BoxHelper:GetIndicatorColor(INDICATOR_STATE_NORMAL))
    frame:SetPoint("CENTER", anchorFrame, "TOPLEFT", 10, -10)

    return frame
end

function BoxHelper:GetIndicatorColor(state)
    if (state == INDICATOR_STATE_GTFO) then
        return 1, 1, 0, 1
    end

    if (state == INDICATOR_STATE_NOT_IN_FRONT) then
        return 1, 0, 0, 1
    end

    return 1, 1, 1, 1
end

function BoxHelper:CreateNameListFrame(name, headline)
    local frame = CreateFrame("Frame", name, UIParent)
    frame:SetPoint("CENTER")
    frame:SetWidth(200)
    frame:SetHeight(200)
    frame:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    })
    frame:SetMovable(true)
    frame:SetBackdropBorderColor(0.5, 0.5, 0.5)
    frame:SetBackdropColor(0.1, 0.1, 0.1)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:SetResizable(true)

    frame:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            self:StartMoving()
        end
    end)
      
    frame:SetScript("OnMouseUp", function(self, button)
        if button == "LeftButton" then
            self:StopMovingOrSizing()
        end
    end)

    frame.resizeButton = CreateFrame("Button", nil, frame)
    frame.resizeButton:SetWidth(16)
    frame.resizeButton:SetHeight(16)
    frame.resizeButton:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT")
    frame.resizeButton:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    frame.resizeButton:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    frame.resizeButton:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    
    -- Add a script to handle resizing
    frame.resizeButton:SetScript("OnMouseDown", function()
        frame:StartSizing("BOTTOMRIGHT")
    end)
    frame.resizeButton:SetScript("OnMouseUp", function()
        frame:StopMovingOrSizing()
    end)

    local lineHeight = 16;
    
    local fontString = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fontString:SetPoint("TOPLEFT", 5, 0)
    fontString:SetWidth(frame:GetWidth())
    fontString:SetHeight(lineHeight)
    fontString:SetText(headline)
    fontString:SetTextColor(1, 1, 1)
    fontString:SetJustifyH("LEFT")

    frame["nameFontStrings"] = {} 

    -- Prepopulate the frame with empty font string objects, which can then later be used to display names
    -- Necessary since frames and fontStrings cannot be deleted later so we have to declare them and use them as pools
    local yOffset = lineHeight * -1;
    for i = 1, MAX_NAMES_IN_FRAMES do
        local nameString = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        nameString:SetPoint("TOPLEFT", 5, yOffset)
        nameString:SetWidth(200)
        nameString:SetHeight(lineHeight)
        nameString:SetJustifyH("LEFT")
        table.insert(frame["nameFontStrings"], nameString)
        yOffset = yOffset - lineHeight
    end

    return frame
end

function BoxHelper:AddPlayerToList(playerName, playerList, nameListFrame)
    playerList[playerName] = playerName;

    self:UpdateNameListFrame(
        nameListFrame, 
        playerList
    )
end

function BoxHelper:RemovePlayerFromList(playerName, playerList, nameListFrame)
    playerList[playerName] = nil
    
    self:UpdateNameListFrame(
        nameListFrame, 
        playerList
    )
end

function BoxHelper:AddPlayerTargetNotInFront(playerName)
    self:AddPlayerToList(playerName, self.playersTargetNotInFront, self.frames["nameListTargetNotInFront"])

    local timerList = self.timers.playersTargetNotInFront
    if (timerList[playerName]) then
        self.AceTimer:CancelTimer(timerList[playerName], true)
        timerList[playerName] = nil
    end

    timerList[playerName] = self.AceTimer:ScheduleTimer(function()
        BoxHelper:RemovePlayerTargetNotInFront(playerName)
    end, TIMER_DURATION)
end

function BoxHelper:RemovePlayerTargetNotInFront(playerName)
    self:RemovePlayerFromList(playerName, self.playersTargetNotInFront, self.frames["nameListTargetNotInFront"])
end

function BoxHelper:AddPlayerGTFO(playerName)
    self:AddPlayerToList(playerName, self.playersGTFO, self.frames["nameListGTFO"])

    local timerList = self.timers.playersGTFO
    if (timerList[playerName]) then
        self.AceTimer:CancelTimer(timerList[playerName], true)
        timerList[playerName] = nil
    end

    timerList[playerName] = self.AceTimer:ScheduleTimer(function()
        BoxHelper:RemovePlayerGTFO(playerName)
    end, TIMER_DURATION)
end

function BoxHelper:RemovePlayerGTFO(playerName)
    self:RemovePlayerFromList(playerName, self.playersGTFO, self.frames["nameListGTFO"])
end

function BoxHelper:UpdateNameListFrame(frame, nameList)
    local yOffset = -30;
    local height = 20;

    if (frame["nameFontStrings"] == nil) then
        frame["nameFontStrings"] = {} 
    end

    for k, fontString in pairs(frame["nameFontStrings"]) do
        fontString:SetText("")
    end

    local i = 1;
    for nameKey, playerName in pairs(nameList) do
        local _, class = UnitClass(playerName)
        local color = RAID_CLASS_COLORS[class]
        local r, g, b = color.r, color.g, color.b

        if (color == nil or i > MAX_NAMES_IN_FRAMES) then
            break
        end
        
        local nameString = frame["nameFontStrings"][i];
        nameString:SetText(playerName)
        nameString:SetTextColor(r, g, b)

        i = i + 1
    end
end

function BoxHelper:IndexOf (tab, val)
    for index, value in pairs(tab) do
        if value == val then
            return index
        end
    end

    return false
end

function BoxHelper:Output(text)
    DEFAULT_CHAT_FRAME:AddMessage(AddonName .. ": " .. text, 1.0, 1.0, 1.0)
end

function BoxHelper:Debug(text)
    if self.enableDebug then
        self:Output(text)
    end
end

------------------------------------------------------------------------------
--- Error Frame event to detect "Target needs to be in front of you" messages
------------------------------------------------------------------------------
local originalOnEvent = UIErrorsFrame:GetScript("OnEvent")

UIErrorsFrame:SetScript("OnEvent", function(self, event, ...)
    local messageText = ...
    local messageKey = BoxHelper:IndexOf(BoxHelper.triggerMessages, messageText)

    if messageKey == "notInFront" then
        BoxHelper:HandleTargetNotInFront()
    end

    return originalOnEvent(self, event, ...)
end)

------------------------------------------------------------------------------
--- Override "GTFO_PlaySound" to detect any GTFO "events"
------------------------------------------------------------------------------
local originalGTFO_PlaySound = GTFO_PlaySound;

function GTFO_PlaySound(iSound)
    BoxHelper:HandleGTFO()

    originalGTFO_PlaySound(iSound)
end