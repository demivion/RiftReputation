-- variables

riftreputation = {
	needsbroadcast = true,
	lastbroadcast = 0,
	needsuiupdate = true,
	lastuiupdate = 0,
	encrypt = 2106,
	eraseconfirm = false,
	ui = {},
	version = 001,
	updateindex = 0,
}
local rr = riftreputation

RiftReputation_playerdata = ""
RiftReputation_voterdata = ""
RiftReputation_votesdata = ""

local defaults = {
	active = true,
	ui_x = 650,
	ui_y = 810,
	ui_xt = 1070,
	ui_yt = 810,
	locked = false,
	player = Inspect.Unit.Detail("player").name,
}

if not rrsettings then
	rrsettings = defaults
end

if not rrplayerdata then
	rrplayerdata = {}
end

if not rrvoterdata then
	rrplayerdata = {}
end

if not rrplayeraverage then
	rrplayeraverage = {}
end

if not rrvotes then
	rrvotes = {}
	
end

-- main

function rr.addonloaded(addon) 
	if (addon == "RiftReputation") then

		rr.printversion()
		rr.variablestest()
		rr.unconvert()
		--rr.ui.create()
		
		table.insert(Event.System.Update.Begin, 		{rr.onupdate, 		"RiftReputation", "OnUpdate" })
		rr.updateindex = #Event.System.Update.Begin		
		
		if rrsettings.active == nil then rrsettings.active = defaults.active end
		
		if rrsettings.active == true
		then
			rr.on()
		elseif rrsettings.active == false
		then
			rr.off()
		end
		
		if not rrsettings.player
		then
			rrsettings.player = Inspect.Unit.Detail("player").name
		end


	end
end

function rr.printversion()
	print("RiftReputation v" .. rr.version .. " loaded /rr for options.")
end

function rr.variablestest()
	if not rrplayerdata then rrplayerdata = {} end
	if not rrvoterdata then rrvoterdata = {} end
	if not rrplayeraverage then rrplayeraverage = {} end
	if not rrsettings then rrsettings = {} end
	if not rrvotes then rrvotes = {} end
end

function rr.onupdate()
	local now = Inspect.Time.Frame()
	
	if now - rr.lastbroadcast < 5 
	then
		rr.needsbroadcast = false
	elseif now - rr.lastbroadcast >= 5 
	then
		rr.needsbroadcast = true		
	end
	
	if rr.needsbroadcast == true 
	then
	
		rr.lastbroadcast = now
		rr.broadcast()
	
	end
	
	if now - rr.lastuiupdate < 1 
	then
		rr.needsuiupdate = false
	elseif now - rr.lastuiupdate >= 1 
	then
		rr.needsuiupdate = true		
	end
	
	if rr.needsuiupdate == true 
	then
	
		rr.lastuiupdate = now
		--rr.ui.update()
	
	end

end

function rr.ratestore(player, voter, scoretype)
	rr.variablestest()
	if rrplayerdata[player] == nil 
	then
		rrplayerdata[player] = {	
			upscore = 0,
			downscore = 0,
			neutralscore = 0,
			numuprecieved = 0,
			numdownrecieved = 0,
			numneutralrecieved = 0,
			uppercent = 0,
			downpercent = 0,
			neutralpercent = 0,
		}
	end
	if rrvoterdata[player] == nil 
	then
		rrvoterdata[player] = {		
			upgiven = 0,
			downgiven = 0,
			neutralgiven = 0,
			upscoreweight = 0,
			nuscoreweight = 0,
			downscoreweight = 0,
		}
	end
	if rrplayerdata[voter] == nil 
	then
		rrplayerdata[voter] = {	
			upscore = 0,
			downscore = 0,
			neutralscore = 0,
			numuprecieved = 0,
			numdownrecieved = 0,
			numneutralrecieved = 0,
			uppercent = 0,
			downpercent = 0,
			neutralpercent = 0,
		}
	end
	if rrvoterdata[voter] == nil 
	then
		rrvoterdata[voter] = {		
			upgiven = 0,
			downgiven = 0,
			neutralgiven = 0,
			upscoreweight = 0,
			nuscoreweight = 0,
			downscoreweight = 0,
		}
	end
	
	if rrvotes == nil 
	then
		rrvotes = {}
	end
	if rrvotes[player] == nil 
	then
		rrvotes[player] = {}
	end
	if rrvotes[player][voter] == nil 
	then
		rrvotes[player][voter] = ""
	end
	
	local upgiven = 0
	local neutralgiven = 0
	local downgiven = 0
	local uprecieved = 0
	local downrecieved = 0
	local neutralrecieved = 0
	local total = 0
	
	rrvotes[player][voter] = scoretype

	for player, voter in pairs(rrvotes) do
		
		uprecieved = 0
		neutralrecieved = 0
		downrecieved = 0
		
		for voter, value in pairs(rrvotes[player]) do
			if value == "up" then
				upgiven = upgiven + 1
				uprecieved = uprecieved +1
			elseif value == "neutral" then
				neutralgiven = neutralgiven + 1
				neutralrecieved = neutralrecieved + 1
			elseif value == "down" then
				downgiven = downgiven + 1
				downrecieved = downrecieved + 1
			end
		end
		
		rrplayerdata[player].numuprecieved = uprecieved
		rrplayerdata[player].numneutralrecieved = neutralrecieved
		rrplayerdata[player].numdownrecieved = downrecieved
		
	end

	rrvoterdata[voter].upgiven = upgiven
	rrvoterdata[voter].neutralgiven = neutralgiven
	rrvoterdata[voter].downgiven = downgiven 


	for player, voter in pairs(rrvotes) do
		
		rrplayerdata[player].upscore = 0
		rrplayerdata[player].neutralscore = 0
		rrplayerdata[player].downscore = 0

		
		for voter, value in pairs(rrvotes[player]) do
			
			if rrvoterdata[voter].upgiven == 0 
			then
			rrvoterdata[voter].upgiven = 1
			end
			
			if rrvoterdata[voter].neutralgiven == 0 
			then
			rrvoterdata[voter].neutralgiven = 1
			end
			
			if rrvoterdata[voter].downgiven == 0 
			then
			rrvoterdata[voter].downgiven = 1
			end
			
			if rrplayerdata[voter].upscore == 0 
			then
			rrplayerdata[voter].upscore = 1
			end
			
			if rrplayerdata[voter].downscore == 0 
			then
			rrplayerdata[voter].downscore = 1
			end			
			--print(rrplayerdata[voter].downscore .. "downscore")
			--print(rrplayerdata[voter].upscore .. "upscore")
			--print(rrvoterdata[voter].downgiven .. "downgiven")
			--print(rrvoterdata[voter].upgiven .. "upgiven")
			--print(rrvoterdata[voter].neutralgiven .. "neutralgiven")			
			rrvoterdata[voter].upscoreweight = (((.3*rrvoterdata[voter].neutralgiven + .3*rrvoterdata[voter].downgiven)/rrvoterdata[voter].upgiven^.85)*(rrplayerdata[voter].upscore/rrplayerdata[voter].downscore)^(1/6))^(1/2.2)
			--rrvoterdata[voter].neutralscoreweight = ((rrvoterdata[voter].upgiven + rrvoterdata[voter].downgiven)/rrvoterdata[voter].neutralgiven)*(rrplayerdata[voter].upscore/rrplayerdata[voter].downscore)
			rrvoterdata[voter].neutralscoreweight = 1
			rrvoterdata[voter].downscoreweight = (((.3*rrvoterdata[voter].upgiven + .3*rrvoterdata[voter].neutralgiven)/rrvoterdata[voter].downgiven^1.25)*(rrplayerdata[voter].upscore/rrplayerdata[voter].downscore)^(1/6))^(1/2.2)
			--print(rrvoterdata[voter].upscoreweight .. "up score weight")
			--print(rrvoterdata[voter].downscoreweight .. "down score weight")
			--print(rrvoterdata[voter].neutralscoreweight .. "neutral score weight")
			
			if rrvotes[player][voter] == "up" then
				--print(rrplayerdata[player].upscore .. player .. " up increased by " .. rrvoterdata[voter].upscoreweight .. voter)
				rrplayerdata[player].upscore = rrplayerdata[player].upscore + rrvoterdata[voter].upscoreweight
				--print(player .. "'s score = " .. rrplayerdata[player].upscore)
			elseif rrvotes[player][voter] == "neutral" then
				--print(rrplayerdata[player].neutralscore .. player .. " neutralincreased by " .. rrvoterdata[voter].neutralscoreweight .. voter)
				rrplayerdata[player].neutralscore = rrplayerdata[player].neutralscore + rrvoterdata[voter].neutralscoreweight
				--print(player .. "'s score = " .. rrplayerdata[player].neutralscore)			
			elseif rrvotes[player][voter] == "down" then
				--print(rrplayerdata[player].downscore .. player .. " down increased by " .. rrvoterdata[voter].downscoreweight .. voter)
				rrplayerdata[player].downscore = rrplayerdata[player].downscore + rrvoterdata[voter].downscoreweight
				--print(player .. "'s score = " .. rrplayerdata[player].downscore)
			end
		end	
			
			total = (rrplayerdata[player].upscore + rrplayerdata[player].neutralscore + rrplayerdata[player].downscore)
			rrplayerdata[player].uppercent = (rrplayerdata[player].upscore / total)
			rrplayerdata[player].neutralpercent = (rrplayerdata[player].neutralscore / total)
			rrplayerdata[player].downpercent = (rrplayerdata[player].downscore / total)
		
	end


end

function rr.average(data)
	local sum = 0
	local count = 0
	--local tempaverage = data.averagerating
	--data.averagerating = nil
	for k,v in pairs(data) do
		if type(v) == 'number' then
			sum = sum + v
			count = count + 1
		end
	end
	--data.averagerating = tempaverage
	return (sum / count)
end

function rr.rateshow()

print(table.show(rrplayerdata))

end

function rr.playershow(player)
	
	if rrplayerdata[player] then
		print(player .. "'s Reputation: " ..(rrplayerdata[player].numuprecieved + rrplayerdata[player].numneutralrecieved + rrplayerdata[player].numdownrecieved) .. "Votes")
		print(string.format("%.2f%%%s", rrplayerdata[player].uppercent*100, " Positive"))
		print(string.format("%.2f%%%s", rrplayerdata[player].neutralpercent*100, " Neutral"))
		print(string.format("%.2f%%%s", rrplayerdata[player].downpercent*100, " Negative"))
		
	else
		print("Player not found")
	end

end

function rr.broadcast()
	--[[
	local data
	local t = rrvotes

	local fromlength = 0
	local fromll = 0
	
	
	if rrsettings.active == true 
	then
		for k,v in pairs(t) do

			fth = string.len(rrsettings.player)
			fll = string.len(fth)
			kth = string.len(k)
			kll = string.len(kth)

			if rrvotes[k][Inspect.Unit.Detail("player").name] ~= nil 
			then
				data = zlib.deflate()(tostring(string.sub(rrvotes[k][Inspect.Unit.Detail("player").name], 1, 1) .. fll .. fth .. rrsettings.player .. kll .. kth .. k), "finish")
				Command.Message.Broadcast("yell", nil, "riftreputation", data)
				--print("broadcasted: " .. data)
			end
		end
	end
	]]--
	local selfvotes = {}
	local votesinline
	local votesdata
	local votes = rrvotes
	selfvotes.id = rrsettings.player
	--test
	for player, voter in pairs(votes) do
		if votes[player][rrsettings.player] ~= nil then
			selfvotes[player] = {}
			selfvotes[player][rrsettings.player] = votes[player][rrsettings.player]
		end
	end
	--print("sent:")
	--print(table.show(selfvotes))
	votesinline = Utility.Serialize.Inline(selfvotes)
	votesdata = zlib.deflate(9)(votesinline, "finish")
	print(Utility.Message.Size(nil, "rrep", votesdata))
	Command.Message.Broadcast("yell", nil, "rrep", votesdata)
	
	
end

function rr.recieve(from, type, channel, identifier, data)
--[[
	local player = ""
	local voter = ""
	local self = Inspect.Unit.Detail("player").name
	local scoretype = ""
	local test = 0
	local fromll = 0
	local fromlength = 0
	local sendname = ""
]]--

local datainflated
local dataload
local voter

	--print("message recieved from: " .. from)


	if rrsettings.active == true --and from ~= self
	then
--[[		
		--print("bandwidth: " .. table.show(Utility.Message.Limits()))
		datainflated = zlib.inflate()(data, "finish")
		--print("type: " .. type)
		--if channel then print("channel: " .. channel) end
		--print("identifier: " .. identifier)
		--print("data: " .. data)
		--print("test: " .. test)
			
		scoretype = string.sub(data, 1,1)
		fromll = tonumber(string.sub(data, 2, 2))
		fromlength = tonumber(string.sub(data, 3, (3 + fromll - 1)))		
		sendname = string.sub(data, (3 + fromll), (3 + fromll + fromlength -1))
		toll = string.sub(data, (3 + fromll + fromlength), (3 + fromll + fromlength))
		toth = string.sub(data, (3 + fromll + fromlength + 1), (3 + fromll + fromlength + toll))
		toname = string.sub(data, (3 + fromll + fromlength + toll +1), (3 + fromll + fromlength + toll + toth))
		
		if scoretype == "u"
		then
			scoretype = "up"
		elseif scoretype == "d"
		then
			scoretype = "down"
		elseif scoretype == "n"
		then
			scoretype = "neutral"
		end
		player = toname
		voter = sendname
]]--
		datainflated = zlib.inflate()(data, "finish")
		dataload = loadstring("return " .. datainflated)() 
		--print("recieved:")
		--print(table.show(dataload))
		voter = dataload.id
		dataload.id = nil
		
		for players, voters in pairs(dataload) do
			--for voters, value in pairs(dataload[players]) do
				rr.ratestore(players, voters, dataload[players][voter])
				print("player = " .. players)
				print("voter = " .. voter)
				print("score = " .. dataload[players][voter])
			--end
		end
		
		
--[[
		print("fromlength" .. fromlength)
		print("toth" .. toth)
		print("message: " .. data)
		print("player = " .. player)
		print("voter = " .. sendname)
		print("score = " .. scoretype)
		print("message accepted")
]]--
		
	end

end

-- slash cmds

function rr.slash(params)
	local args = {}
	local argnumber = 0
	for argument in string.gmatch(params, "[^%s]+") do
		args[argnumber] = argument
		argnumber = argnumber + 1
	end
	
	if argnumber > 0 
	then
		
		if args[0] == "on" 
		then
			rr.on()
		end
		
		if args[0] == "off"
		then
			rr.off()
		end
		
		if args[0] == "erase"
		then
			rr.erase()
		end
		
		if args[0] == "list" 
		then
			rr.rateshow()
		end
		
		if args[0] == "vote" and argnumber == 2 and Inspect.Unit.Detail("player.target").player == true
		then
		
			local voter = Inspect.Unit.Detail("player").name
			local player = Inspect.Unit.Detail("player.target").name
			local scoretype = string.lower(args[1])
			print(scoretype)
			if player == voter 
			then 
				print("Sorry! No self-votes allowed :P")
			elseif Inspect.Unit.Detail("player.target").level ~= 50
			then
				Print("Can only vote for level 50 players")
			elseif Inspect.Unit.Detail("player").level ~= 50
			then
				Print("Can only vote if you are level 50")
			else
				if scoretype == "up" then 
					rr.ratestore(player, voter, "up")
					print("You gave " .. player .. " a Positive vote!")
				elseif scoretype == "neutral" then
					rr.ratestore(player, voter, "neutral")
					print("You gave " .. player .. " a Neutral vote!")
				elseif scoretype == "down" then
					rr.ratestore(player, voter, down)
					print("You gave " .. player .. " a Negative vote!")
				else
					print("Vote up neutral or down only")
				end
			end
				
		elseif args[0] == "vote" and argnumber == 3 
		then
			
			local voter = Inspect.Unit.Detail("player").name
			local player = args[1]:gsub("^%l", string.upper)
			local scoretype = string.lower(args[2])
			print(scoretype)
			
			if player == voter 
			then 
				print("Sorry! No self-votes allowed :P")
			--elseif not Inspect.Unit.Detail(player)
			--then
			--	Print("Must be a legitimate player")
			--elseif Inspect.Unit.Detail(player).level ~= 50
			--then
			--	Print("Can only vote for level 50 players")
			elseif Inspect.Unit.Detail("player").level ~= 50
			then
				Print("Can only vote if you are level 50")
			else
				if scoretype == "up" then 
					rr.ratestore(player, voter, "up")
					print("You gave " .. player .. " a Positive vote!")
				elseif scoretype == "neutral" then
					rr.ratestore(player, voter, "neutral")
					print("You gave " .. player .. " a Neutral vote!")
				elseif scoretype == "down" then
					rr.ratestore(player, voter, "down")
					print("You gave " .. player .. " a Negative vote!")
				else
					print("Vote up neutral or down only")
				end
			end
		
		end
	
		if args[0] == "lock"
		then
			rrsettings.locked = true
			print("UI locked")
		end
		
		if args[0] == "unlock"
		then
			rrsettings.locked = false
			print("UI unlocked")
		end
	
		if args[0] == "show" and argnumber == 2
		then
			rr.playershow(args[1]:gsub("^%l", string.upper))
		end
		
		if args[0] == "test"
		then
			test()
		end
		
	else
		rr.help()
	end
end

function rr.help()

	print("RiftReputation: A player reputation system.")
	print("[/rr on]")
	print("[/rr off]")
	print("[/rr list] to list all reputations")
	print("[/rr show player] to view a specific player's reputation")
	print("[/rr vote player up/neutral/down] to give a player a positive/neutral/negative vote.")
	print("[/rr vote up/neutral/dow]n   to give your target a positive/neutral/negative vote.")
	print("[/rr lock/unlock] to either lock or unlock the UI frames")


end

function rr.on()
	rrsettings.active = true
	Command.Message.Accept("yell", "rrep")
	print("RiftReputation on")
	--rr.ui.playerratingframe:SetVisible(true)
	--rr.ui.targetratingframe:SetVisible(true)
	
	Event.System.Update.Begin[rr.updateindex][1] = rr.onupdate

end

function rr.off()
	rrsettings.active = false
	Command.Message.Reject("yell", "rrep")
	print("RiftReputation off")
	--rr.ui.playerratingframe:SetVisible(false)
	--rr.ui.targetratingframe:SetVisible(false)
	
	Event.System.Update.Begin[rr.updateindex][1] = function() end
		
end

function rr.erase()




	if rr.eraseconfirm == true then
	
		rrplayeraverage = {}
		rrplayerdata = {}		
		rrvotes = {}
		rrvoterdata = {}
		rrsettings = {}
		
		RiftReputation_playerdata = ""
		RiftReputation_voterdata = ""
		RiftReputation_votes = ""
		print("All Data Erased")
		rr.eraseconfirm = false
	else
	print("Warning! This will erase all your data!")
	print("type /rr erase again to confirm.")
	rr.eraseconfirm = true
	end
end

--UI
--[[
function rr.ui.create()

	rr.ui.context = UI.CreateContext("RiftReputationContext")
	rr.ui.RightDown = false
    rr.ui.originalXDiff = 0
    rr.ui.originalYDiff = 0

	if not rrsettings.ui_x then rrsettings.ui_x = defaults.ui_x end
	if not rrsettings.ui_y then rrsettings.ui_y = defaults.ui_y end
	if not rrsettings.ui_xt then rrsettings.ui_xt = defaults.ui_xt end
	if not rrsettings.ui_yt then rrsettings.ui_yt = defaults.ui_yt end
	if not rrsettings.locked then rrsettings.locked = defaults.locked end
	
	-- Player's Frame
	
	rr.ui.playerratingframe = UI.CreateFrame("Text", "PlayerRating", rr.ui.context)
    
	rr.ui.playerratingframe:SetFontSize(16)
    rr.ui.playerratingframe:SetFontColor(1, 1, 1, 1)
	rr.ui.playerratingframe:SetWidth(195)
	rr.ui.playerratingframe:SetHeight(26)
    rr.ui.playerratingframe:SetBackgroundColor(0, 0, 0, .7)    
    rr.ui.playerratingframe:SetLayer(50)
	rr.ui.playerratingframe:SetPoint("TOPLEFT", UIParent, "TOPLEFT", rrsettings.ui_x, rrsettings.ui_y)
    rr.ui.playerratingframe:SetVisible(true)
	rr.ui.playerratingframe:SetMouseMasking("limited")

	function rr.ui.playerratingframe.Event:RightDown()
		if rrsettings.locked == false 
		then
			rr.ui.RightDown = true
			local mouse = Inspect.Mouse()
			rr.ui.originalXDiff = mouse.x - rr.ui.playerratingframe:GetLeft()
			rr.ui.originalYDiff = mouse.y - rr.ui.playerratingframe:GetTop()
		end
	end
	
	function rr.ui.playerratingframe.Event:RightUp()
		if rrsettings.locked == false 
		then	
			rr.ui.RightDown = false
		end
	end
	
	function rr.ui.playerratingframe.Event:RightUpoutside()
		if rrsettings.locked == false 
		then	
			rr.ui.RightDown = false
		end
	end
	
	function rr.ui.playerratingframe.Event:MouseMove(x, y)
		if rrsettings.locked == false 
		then	
			if not rr.ui.RightDown then
				return
			end
			rr.ui.playerratingframe:SetPoint("TOPLEFT", UIParent, "TOPLEFT", x - rr.ui.originalXDiff, y - rr.ui.originalYDiff)
			rrsettings.ui_x = x - rr.ui.originalXDiff
			rrsettings.ui_y = y - rr.ui.originalYDiff
		end		
	end

	
	-- Target's Frame
	
	rr.ui.targetratingframe = UI.CreateFrame("Text", "TargetRating", rr.ui.context)
    
	rr.ui.targetratingframe:SetFontSize(16)
    rr.ui.targetratingframe:SetFontColor(1, 1, 1, 1)
	rr.ui.targetratingframe:SetWidth(215)
	rr.ui.targetratingframe:SetHeight(26)
    rr.ui.targetratingframe:SetBackgroundColor(0, 0, 0, .7)    
    rr.ui.targetratingframe:SetLayer(50)
	rr.ui.targetratingframe:SetPoint("TOPLEFT", UIParent, "TOPLEFT", rrsettings.ui_xt, rrsettings.ui_yt)
    rr.ui.targetratingframe:SetVisible(false)
	rr.ui.targetratingframe:SetMouseMasking("limited")


	function rr.ui.targetratingframe.Event:RightDown()
		if rrsettings.locked == false 
		then
			rr.ui.RightDown = true
			local mouse = Inspect.Mouse()
			rr.ui.originalXDiff = mouse.x - rr.ui.targetratingframe:GetLeft()
			rr.ui.originalYDiff = mouse.y - rr.ui.targetratingframe:GetTop()
		end
	end
	
	function rr.ui.targetratingframe.Event:RightUp()
		if rrsettings.locked == false 
		then	
			rr.ui.RightDown = false
		end
	end
	
	function rr.ui.targetratingframe.Event:RightUpoutside()
		if rrsettings.locked == false 
		then
			rr.ui.RightDown = false
		end
	end
	
	function rr.ui.targetratingframe.Event:MouseMove(x, y)
		if rrsettings.locked == false 
		then
			if not rr.ui.RightDown then
				return
			end
			rr.ui.targetratingframe:SetPoint("TOPLEFT", UIParent, "TOPLEFT", x - rr.ui.originalXDiff, y - rr.ui.originalYDiff)
			rrsettings.ui_xt = x - rr.ui.originalXDiff
			rrsettings.ui_yt = y - rr.ui.originalYDiff
			rr.ui.update()
		end
	end



end

function rr.ui.update()
	local playerpositiverating = 0
	local playerneutralrating = 0
	local playernegativerating = 0
	local playerpositivenum = 0
	local playerneutralnum = 0
	local playernegativenum = 0
	local targetpositiverating = 0
	local targetneutralrating = 0
	local targetnegativerating = 0
	local targetpositivenum = 0
	local targetneutralnum = 0
	local targetnegativenum = 0
	local player = Inspect.Unit.Detail('player').name
	
		if rrplayeraverage[player] 
		then 
			local playerpositiverating = rrplayeraverage[player].uprating or 0
			local playerneutralrating = 0
			local playernegativerating = 0
			local playerpositivenum = rrplayeraverage[player].upnum or 0
			local playerneutralnum = 0
			local playernegativenum = 0
		end
        
	rr.ui.playerratingframe:SetText(string.format("%s%.2f%%%s%i%s", "Your Reputation: ", playerpositiverating*100, " (", playerpositivenum, ") Positive"))
	
	if Inspect.Unit.Detail('player.target')
	then
		if Inspect.Unit.Detail('player.target').player == true 
		then
			local target = Inspect.Unit.Detail('player.target').name
		
				if not rrplayeraverage[target] 
				then 
					targetrating1rating = "--"
				else
					targetrating1rating = round(rrplayeraverage[target],1)
				end
			
			rr.ui.targetratingframe:SetText("Target's Reputation" .. ": [ " .. targetrating1rating .. " Overall ]")
			rr.ui.targetratingframe:SetVisible(true)
		else
			rr.ui.targetratingframe:SetVisible(false)
		end
	else
		rr.ui.targetratingframe:SetVisible(false)
	end
	
	if rrsettings.locked == false 
	then

	else
	
	end

end
]]--
-- utilities

function table.show(t, name, indent)
   local cart     -- a container
   local autoref  -- for self references
   local function isemptytable(t) return next(t) == nil end
   local function basicSerialize (o)
      local so = tostring(o)
      if type(o) == "function" then
         local info = debug.getinfo(o, "S")
         -- info.name is nil because o is not a calling level
         if info.what == "C" then
            return string.format("%q", so .. ", C function")
         else 
            -- the information is defined through lines
            return string.format("%q", so .. ", defined in (" ..
                info.linedefined .. "-" .. info.lastlinedefined ..
                ")" .. info.source)
         end
      elseif type(o) == "number" or type(o) == "boolean" then
         return so
      else
         return string.format("%q", so)
      end
   end
	local function addtocart (value, name, indent, saved, field)
      indent = indent or ""
      saved = saved or {}
      field = field or name

      cart = cart .. indent .. field

      if type(value) ~= "table" then
         cart = cart .. " = " .. basicSerialize(value) .. ";\n"
      else
         if saved[value] then
            cart = cart .. " = {}; -- " .. saved[value] 
                        .. " (self reference)\n"
            autoref = autoref ..  name .. " = " .. saved[value] .. ";\n"
         else
            saved[value] = name
            --if tablecount(value) == 0 then
            if isemptytable(value) then
               cart = cart .. " = {};\n"
            else
               cart = cart .. " = {\n"
               for k, v in pairs(value) do
                  k = basicSerialize(k)
                  local fname = string.format("%s[%s]", name, k)
                  field = string.format("[%s]", k)
                  -- three spaces between levels
                  addtocart(v, fname, indent .. "   ", saved, field)
               end
               cart = cart .. indent .. "};\n"
            end
         end
      end
   end

   name = name or "__unnamed__"
   if type(t) ~= "table" then
      return name .. " = " .. basicSerialize(t)
   end
   cart, autoref = "", ""
   addtocart(t, name, indent)
   return cart .. autoref
end

function round(num, idp)
  return tonumber(string.format("%." .. (idp or 0) .. "f", num))
end


function rr.convert()

	local rrplayerdatadataserialized
	local rrvoterdataserialized
	local rrvotesserialized

	rrplayerdataserialized = Utility.Serialize.Inline(rrplayerdata)
	RiftReputation_playerdata = zlib.deflate()(rrplayerdataserialized, "finish")

	rrvoterdataserialized = Utility.Serialize.Inline(rrvoterdata)
	RiftReputation_voterdata = zlib.deflate()(rrvoterdataserialized, "finish")
	
	rrvotesserialized = Utility.Serialize.Inline(rrvotes)
	RiftReputation_votes = zlib.deflate()(rrvotesserialized, "finish")

end

function rr.unconvert()

	local rrplayerdatauncompress
	local rrplayerdataload
	local rrvoterdatauncompress
	local rrvoterdataload
	local rrvotesuncompress
	local rrvotesload
	
	if RiftReputation_playerdata and rrplayerdata ~= nil
	then
		rrplayerdatauncompress  = zlib.inflate()(RiftReputation_playerdata, "finish")
		rrplayerdata = loadstring("return rrplayerdata")()
		print("player data:")
		print(table.show(rrplayerdata))
	end
	
	if RiftReputation_voterdata and rrvoterdata ~= nil
	then
		rrvoterdatauncompress  = zlib.inflate()(RiftReputation_voterdata, "finish")
		rrvoterdata = loadstring("return rrvoterdata")()
		print("voter data:")
		print(table.show(rrvoterdata))
	end
	
	if RiftReputation_votes and rrvotes ~= nil
	then
		rrvotesuncompress  = zlib.inflate()(RiftReputation_votes, "finish")
		rrvotes = loadstring("return rrvotes")()
		print("vote histories:")
		print(table.show(rrvotes))
	end
	--test

end

function test()
print(table.show(Library.LibAccounts.here))
end


table.insert(Event.Addon.SavedVariables.Save.Begin, {rr.convert, 			"RiftReputation", "Convert b4 save"})
table.insert(Event.Addon.SavedVariables.Load.End, 	{rr.addonloaded,		"RiftReputation", "Load variables"})
table.insert(Event.Message.Receive, 				{rr.recieve, 			"RiftReputation", "Received Message"})
table.insert(Command.Slash.Register("rr"), 			{rr.slash, 				"RiftReputation", "Slash Cmd"})
