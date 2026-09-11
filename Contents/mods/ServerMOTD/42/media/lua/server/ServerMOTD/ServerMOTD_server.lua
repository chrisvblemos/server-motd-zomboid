ServerMOTD = ServerMOTD or {}

local MODULE = "ServerMOTD"
local MESSAGE_FILE = "ServerMOTD.txt"
local FALLBACK_TITLE = "Server Message"
local FALLBACK_TEXT = ""

local function sandboxOptions()
	if SandboxVars and type(SandboxVars) == "table" and type(SandboxVars.ServerMOTD) == "table" then
		return SandboxVars.ServerMOTD
	end
	return nil
end

local function readOption(key, fallback)
	local options = sandboxOptions()
	if options then
		local value = options[key]
		if value ~= nil and value ~= "" then
			return value
		end
	end
	return fallback
end

local function loadMessageOverride()
	local reader = getFileReader(MESSAGE_FILE, false)
	if not reader then
		return nil
	end
	local lines = {}
	local line = reader:readLine()
	while line ~= nil do
		table.insert(lines, line)
		line = reader:readLine()
	end
	reader:close()
	if #lines == 0 then
		return nil
	end
	return table.concat(lines, " ")
end

local function isEnabled()
	local config = ServerMOTD.Config or {}
	local options = sandboxOptions()
	if options and options.Enabled ~= nil then
		return options.Enabled
	end
	return config.enabled ~= false
end

local function getMotd()
	local config = ServerMOTD.Config or {}
	local text = loadMessageOverride()
	if not text then
		text = readOption("Message", config.text or FALLBACK_TEXT)
	end
	return {
		title = readOption("Title", config.title or FALLBACK_TITLE),
		text = text,
	}
end

local function onClientCommand(module, command, player, args)
	if module ~= MODULE or command ~= "request" then
		return
	end
	if not isEnabled() then
		return
	end
	local motd = getMotd()
	sendServerCommand(player, MODULE, "show", { title = motd.title, text = motd.text })
end

Events.OnClientCommand.Add(onClientCommand)
