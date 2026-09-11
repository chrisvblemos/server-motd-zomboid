ServerMOTD = ServerMOTD or {}

ServerMOTD.Config = {
	enabled = true,
	debug = true,
	title = "Welcome to the Server",
	text = "<CENTRE> <SIZE:medium> Welcome to our server! <LINE> <LINE> <LEFT> <SIZE:small> Please take a moment to read the rules: <LINE> <LINE> 1. Be respectful to other survivors. <LINE> 2. No cheating, exploiting or duping. <LINE> 3. No griefing or destroying other players' builds. <LINE> 4. Roleplay where possible and keep chat friendly. <LINE> 5. Have fun! <LINE> <LINE> <RGB:1,0.35,0.35> Breaking the rules may result in a ban.",
}

function ServerMOTD.log(message)
	message = "[ServerMOTD] " .. tostring(message)
	print(message)
	if ServerMOTD.Config and ServerMOTD.Config.debug then
		local writer = getFileWriter("ServerMOTD_debug.log", true, true)
		if writer then
			writer:write(message .. "\n")
			writer:close()
		end
	end
end
