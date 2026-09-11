require "ISUI/ISPanel"
require "ISUI/ISPanelJoypad"
require "ISUI/ISRichTextPanel"
require "ISUI/ISButton"
require "ISUI/ISTickBox"

ServerMOTD = ServerMOTD or {}

local MODULE = "ServerMOTD"
local OPT_OUT_FILE = "ServerMOTD_ignored.ini"
local PAD = 10
local BUTTON_HGT = getTextManager():getFontHeight(UIFont.Small) + 6

local function readIgnored()
	local names = {}
	local reader = getFileReader(OPT_OUT_FILE, false)
	if not reader then
		return names
	end
	local line = reader:readLine()
	while line ~= nil do
		line = tostring(line):gsub("%s+$", "")
		if line ~= "" then
			table.insert(names, line)
		end
		line = reader:readLine()
	end
	reader:close()
	return names
end

function ServerMOTD.isIgnored(username)
	if not username then
		return false
	end
	for _, name in ipairs(readIgnored()) do
		if name == username then
			return true
		end
	end
	return false
end

function ServerMOTD.setIgnored(username, ignored)
	if not username then
		return
	end
	local names = readIgnored()
	for i = #names, 1, -1 do
		if names[i] == username then
			table.remove(names, i)
		end
	end
	if ignored then
		table.insert(names, username)
	end
	local writer = getFileWriter(OPT_OUT_FILE, true, false)
	for _, name in ipairs(names) do
		writer:write(name .. "\n")
	end
	writer:close()
end

ServerMOTDWindow = ISPanelJoypad:derive("ServerMOTDWindow")

function ServerMOTDWindow:createChildren()
	local titleHgt = getTextManager():getFontHeight(UIFont.Medium)
	local top = titleHgt + PAD * 2
	local bodyHgt = self.height - top - BUTTON_HGT - BUTTON_HGT - PAD * 4
	if bodyHgt < 60 then
		bodyHgt = 60
	end

	self.body = ISRichTextPanel:new(PAD, top, self.width - PAD * 2, bodyHgt)
	self.body:initialise()
	self.body.autosetheight = false
	self.body.clip = true
	self.body.backgroundColor.a = 0
	self.body:setMargins(4, 2, 16, 2)
	self.body.text = self.motdText
	self:addChild(self.body)
	self.body:paginate()

	self.never = ISTickBox:new(PAD, self.body:getBottom() + PAD, self.width - PAD * 2, BUTTON_HGT, "", nil, nil)
	self.never:initialise()
	self.never.background = false
	self.never:addOption("Don't show this again", nil)
	self.never:setSelected(1, false)
	self:addChild(self.never)

	local btnWid = 120
	self.close = ISButton:new((self.width - btnWid) / 2, self.height - PAD - BUTTON_HGT, btnWid, BUTTON_HGT, getText("UI_Ok"), self, ServerMOTDWindow.onClose)
	self.close:initialise()
	self.close:enableAcceptColor()
	self:addChild(self.close)
end

function ServerMOTDWindow:prerender()
	ISPanelJoypad.prerender(self)
	self:drawTextCentre(self.title, self.width / 2, PAD / 2, 1, 1, 1, 1, UIFont.Medium)
	self:drawRect(PAD, getTextManager():getFontHeight(UIFont.Medium) + PAD + 2, self.width - PAD * 2, 1, 0.4, 1, 1, 1)
end

function ServerMOTDWindow:onClose(button)
	if self.never and self.never:isSelected(1) then
		ServerMOTD.setIgnored(self.username, true)
	end
	self:removeSelf()
end

function ServerMOTDWindow:removeSelf()
	if ServerMOTD.window == self then
		ServerMOTD.window = nil
	end
	if ServerMOTD.overlay then
		ServerMOTD.overlay:removeFromUIManager()
		ServerMOTD.overlay = nil
	end
	self:removeFromUIManager()
end

function ServerMOTDWindow:new(x, y, width, height, title, motdText, username)
	local o = ISPanelJoypad:new(x, y, width, height)
	setmetatable(o, self)
	self.__index = self
	o.title = title
	o.motdText = motdText
	o.username = username
	o.backgroundColor = { r = 0, g = 0, b = 0, a = 0.92 }
	o.borderColor = { r = 0.5, g = 0.5, b = 0.5, a = 1 }
	o.moveWithMouse = true
	return o
end

function ServerMOTD.show(title, text, username)
	if ServerMOTD.window then
		ServerMOTD.window:removeSelf()
	end

	local screenW = getCore():getScreenWidth()
	local screenH = getCore():getScreenHeight()
	local width = math.min(720, screenW - 80)
	local height = math.min(560, screenH - 80)
	local x = (screenW - width) / 2
	local y = (screenH - height) / 2

	local overlay = ISPanel:new(0, 0, screenW, screenH)
	overlay:initialise()
	overlay.backgroundColor = { r = 0, g = 0, b = 0, a = 0.6 }
	overlay.borderColor = { r = 0, g = 0, b = 0, a = 0 }
	overlay.wantMouseEvents = true
	overlay:addToUIManager()
	ServerMOTD.overlay = overlay

	ServerMOTD.window = ServerMOTDWindow:new(x, y, width, height, title, text, username)
	ServerMOTD.window:initialise()
	ServerMOTD.window:addToUIManager()
	ServerMOTD.window:setAlwaysOnTop(true)
	ServerMOTD.window:bringToTop()
end

local MOTD_DELAY_TICKS
local SHOW_DELAY_TICKS
local pendingTitle
local pendingText
local pendingUsername

local function pumpShow()
	SHOW_DELAY_TICKS = SHOW_DELAY_TICKS - 1
	if SHOW_DELAY_TICKS > 0 then
		return
	end
	Events.OnPlayerUpdate.Remove(pumpShow)
	ServerMOTD.show(pendingTitle, pendingText, pendingUsername)
end

local function onServerCommand(module, command, args)
	if module ~= MODULE or command ~= "show" then
		return
	end
	if not args then
		return
	end
	local player = getPlayer()
	pendingTitle = args.title or "Server Message"
	pendingText = args.text or ""
	pendingUsername = player and player:getUsername() or nil
	SHOW_DELAY_TICKS = 2
	Events.OnPlayerUpdate.Add(pumpShow)
end

local function sendRequest()
	MOTD_DELAY_TICKS = MOTD_DELAY_TICKS - 1
	if MOTD_DELAY_TICKS > 0 then
		return
	end
	Events.OnPlayerUpdate.Remove(sendRequest)
	local player = getPlayer()
	if not player then
		return
	end
	local username = player:getUsername()
	if ServerMOTD.isIgnored(username) then
		return
	end
	sendClientCommand(MODULE, "request", {})
end

local function requestMotd(playerIndex)
	if not isClient() then
		return
	end
	if ServerMOTD.requested then
		return
	end
	ServerMOTD.requested = true
	MOTD_DELAY_TICKS = 3
	Events.OnPlayerUpdate.Add(sendRequest)
end

Events.OnServerCommand.Add(onServerCommand)
Events.OnCreatePlayer.Add(requestMotd)
