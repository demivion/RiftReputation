-- variables

riftreputation = {
	needsbroadcast = true,
	lastbroadcast = 0,
	needsuiupdate = true,
	lastuiupdate = 0,
	eraseconfirm = false,
	ui = {},
	version = 001,
	updateindex = 0,
	incombat = false,
}
local rr = riftreputation

RiftReputation_playerdata = ""
RiftReputation_voterdata = ""
RiftReputation_votesdata = ""

local defaults = {
	active = true,
	ui_x = 650,
	ui_y = 810,
	ui_x2 = 1070,
	ui_y2 = 810,
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
		--rr.variablestest()
		rr.unconvert()
		rr.ui.create()
		rr.ui.createsearch()
		
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

function rr.variablestest(player)
	if not rrplayerdata then rrplayerdata = {} end
	if not rrvoterdata then rrvoterdata = {} end
	if not rrplayeraverage then rrplayeraverage = {} end
	if not rrsettings then rrsettings = {} end
	if not rrvotes then rrvotes = {} end
	
	if rrplayerdata[player] == nil 
	then
		rrplayerdata[player] = {	
			upscore = 1,
			downscore = 1,
			neutralscore = 1,
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
			upgiven = 1,
			downgiven = 1,
			neutralgiven = 1,
			upscoreweight = 0,
			nuscoreweight = 0,
			downscoreweight = 0,
		}
	end
end

function rr.onupdate()
	local now = Inspect.Time.Frame()
	
	if now - rr.lastbroadcast < 15 
	then
		rr.needsbroadcast = false
	elseif now - rr.lastbroadcast >= 15 
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
		rr.ui.update()
	
	end

end

function rr.entercombat()
	rr.incombat = true
	Command.Message.Reject("yell", "rrep")
end

function rr.leavecombat()
	rr.incombat = false
	Command.Message.Accept("yell", "rrep")
end

function rr.ratestore(player, voter, scoretype)
	
	local upgiven = 1
	local neutralgiven = 1
	local downgiven = 1
	local uprecieved = 0
	local downrecieved = 0
	local neutralrecieved = 0
	local total = 0
	
	rr.variablestest(player)
	rr.variablestest(voter)
		
	
	if rrvotes == nil 
	then
		rrvotes = {}
	end
	if rrvotes[player] == nil 
	then
		rrvotes[player] = {}
	end
	
	rrvotes[player][voter] = scoretype
	
	
	for player, voter in pairs(rrvotes) do
		
		uprecieved = 1
		neutralrecieved = 1
		downrecieved = 1
		
		for voter, value in pairs(rrvotes[player]) do
			if value == "1" then
				upgiven = upgiven + 1
				uprecieved = uprecieved +1
			elseif value == "2" then
				neutralgiven = neutralgiven + 1
				neutralrecieved = neutralrecieved + 1
			elseif value == "3" then
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
			
			rrvoterdata[voter].upscoreweight = (((.3*rrvoterdata[voter].neutralgiven + .3*rrvoterdata[voter].downgiven)/rrvoterdata[voter].upgiven^.85)*(rrplayerdata[voter].upscore/rrplayerdata[voter].downscore)^(1/6))^(1/2.2)
			rrvoterdata[voter].neutralscoreweight = 1
			rrvoterdata[voter].downscoreweight = (((.3*rrvoterdata[voter].upgiven + .3*rrvoterdata[voter].neutralgiven)/rrvoterdata[voter].downgiven^1.25)*(rrplayerdata[voter].upscore/rrplayerdata[voter].downscore)^(1/6))^(1/2.2)
			
			if rrvoterdata[voter].upscoreweight > 3 then rrvoterdata[voter].upscoreweight = 3 end
			if rrvoterdata[voter].downscoreweight > 3 then rrvoterdata[voter].upscoreweight = 3 end
			
			if rrvotes[player][voter] == "1" then
				rrplayerdata[player].upscore = rrplayerdata[player].upscore + rrvoterdata[voter].upscoreweight
			elseif rrvotes[player][voter] == "2" then
				rrplayerdata[player].neutralscore = rrplayerdata[player].neutralscore + rrvoterdata[voter].neutralscoreweight
			elseif rrvotes[player][voter] == "3" then
				rrplayerdata[player].downscore = rrplayerdata[player].downscore + rrvoterdata[voter].downscoreweight
			end
		end	
			
			total = (rrplayerdata[player].upscore + rrplayerdata[player].neutralscore + rrplayerdata[player].downscore)
			rrplayerdata[player].uppercent = (rrplayerdata[player].upscore / total)
			rrplayerdata[player].neutralpercent = (rrplayerdata[player].neutralscore / total)
			rrplayerdata[player].downpercent = (rrplayerdata[player].downscore / total)
			
	end


end

function rr.rateshow()

print(table.show(rrplayerdata))
print(table.show(rrvoterdata))
end

function rr.playershow(player)
	local total  = (rrplayerdata[player].numuprecieved + rrplayerdata[player].numneutralrecieved + rrplayerdata[player].numdownrecieved -3)
	if total < 0 then total = 0 end
	if rrplayerdata[player] then
		print(player .. "'s Reputation: " .. total .. "Votes")
		print(string.format("%.2f%%%s", rrplayerdata[player].uppercent*100, " Positive"))
		print(string.format("%.2f%%%s", rrplayerdata[player].neutralpercent*100, " Neutral"))
		print(string.format("%.2f%%%s", rrplayerdata[player].downpercent*100, " Negative"))
		
	else
		print("Player not found")
	end

end

function rr.broadcast()
	if rr.incombat == false then
		local selfvotes = {}
		local votesinline
		local votesdata
		local testinline
		local testdata
		local votes = rrvotes
		local size
		
		--selfvotes.id = rrsettings.player
		for player, voter in pairs(votes) do
			
			if votes[player][rrsettings.player] ~= nil then
				
				if selfvotes[rrsettings.player] == nil then
					selfvotes[rrsettings.player] = {}
				end
				
				selfvotes[rrsettings.player][player] = votes[player][rrsettings.player]
					
				testinline = Utility.Serialize.Inline(selfvotes)
				testdata = zlib.deflate(9)(testinline, "finish")
				size = Utility.Message.Size(nil, "rrep", testdata)
				
				if size >= 1000 then
					Command.Message.Broadcast("yell", nil, "rrep", testdata)
					selfvotes[rrsettings.player] = {}
					--print("sent split of size " .. size)
				end		
			
			end
		
		end
		--print("sent:")
		--print(table.show(selfvotes))
		votesinline = Utility.Serialize.Inline(selfvotes)
		votesdata = zlib.deflate(9)(votesinline, "finish")
		--print(Utility.Message.Size(nil, "rrep", votesdata))
		Command.Message.Broadcast("yell", nil, "rrep", votesdata)
	end
	
end

function rr.recieve(from, type, channel, identifier, data)

local datainflated
local dataload
local voter

	--print("message recieved from: " .. from)


	if rrsettings.active == true --and from ~= self
	then
		datainflated = zlib.inflate()(data, "finish")
		dataload = loadstring("return " .. datainflated)() 
		--print("recieved:")
		--print(table.show(dataload))
		--sender = dataload.id
		--print("sender = " .. sender)
		--dataload.id = nil
		if dataload ~= nil and dataload[from] ~= nil then
			for players, value  in pairs(dataload[from]) do
				--for voters, value in pairs(dataload[players]) do
				if value == 1 or value == 2 or value == 3 then
					rr.ratestore(players, from, value)
					--print("player = " .. players)
					--print("voter = " .. from)
					--print("score = " .. value)
				end
			end
		end
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
	
		
	if args[0] == "on" and argnumber == 1
	then
		rr.on()
	elseif args[0] == "off" and argnumber == 1
	then
		rr.off()
	elseif args[0] == "erase" and argnumber == 1
	then
		rr.erase()
	elseif args[0] == "list" and argnumber == 1
	then
		rr.rateshow()
	elseif args[0] == "vote" and argnumber == 2 and Inspect.Unit.Detail("player.target").player == true
	then
	
		local voter = Inspect.Unit.Detail("player").name
		local player = Inspect.Unit.Detail("player.target").name
		local scoretype = string.lower(args[1])
		--print(scoretype)
		if player == voter 
		then 
			print("Sorry! No self-votes allowed :P")
		elseif Inspect.Unit.Detail("player.target").level ~= 50
		then
			print("You can only vote for level 50 players")
		elseif Inspect.Unit.Detail("player").level ~= 50
		then
			print("You can only vote if you are level 50")
		elseif string.find(player, "@") ~= nil then
			print("You can only vote for players on your own shard")
		elseif Inspect.Unit.Detail("player.target").faction ~= Inspect.Unit.Detail("player").faction then
			print("You can only vote for players of your faction")
		else
			if scoretype == "up" then 
				rr.ratestore(player, voter, "1")
				print("You gave " .. player .. " a Positive vote!")
			elseif scoretype == "neutral" then
				rr.ratestore(player, voter, "2")
				print("You gave " .. player .. " a Neutral vote!")
			elseif scoretype == "down" then
				rr.ratestore(player, voter, "3")
				print("You gave " .. player .. " a Negative vote!")
			else
				print("Vote up neutral or down only")
			end
		end
	elseif args[0] == "lock" and argnumber == 1
	then
		rrsettings.locked = true
		print("UI locked")
	elseif args[0] == "unlock" and argnumber == 1
	then
		rrsettings.locked = false
		print("UI unlocked")
	elseif args[0] == "show" and argnumber == 2
	then
		rr.playershow(args[1]:gsub("^%l", string.upper))
	elseif args[0] == "test"
	then
		test()
	else
		rr.help()
	end
end

function rr.help()

	print("RiftReputation: A player reputation system.")
	print("Right click and drag to move UI frames.")
	print("[/rr on]")
	print("[/rr off]")
	print("[/rr list] to list all data")
	print("[/rr erase] use this twice to erase all of your saved data and restore to defaults. (note: this does not erase your voting history from other players)")
	print("[/rr show player] to view a specific player's reputation")
	print("[/rr vote up/neutral/down]   to give your target a positive/neutral/negative vote.")
	print("[/rr lock/unlock] to either lock or unlock the UI frames")


end

function rr.on()
	rrsettings.active = true
	Command.Message.Accept("yell", "rrep")
	print("RiftReputation on")
		rr.ui.backgroundframe:SetVisible(true)
		rr.ui.targetratingframe:SetVisible(true)
		rr.ui.targetvotesframe:SetVisible(true)
		rr.ui.barbackground:SetVisible(true)
		rr.ui.respected:SetVisible(true)
		rr.ui.notorious:SetVisible(true)
	    rr.ui.barindicator:SetVisible(true)
		
		rr.ui.backgroundframe2:SetVisible(true)
		rr.ui.targetratingframe2:SetVisible(true)
		rr.ui.targetvotesframe2:SetVisible(true)
		rr.ui.barbackground2:SetVisible(true)
		rr.ui.respected2:SetVisible(true)
		rr.ui.notorious2:SetVisible(true)
	    rr.ui.barindicator2:SetVisible(true)
	
	Event.System.Update.Begin[rr.updateindex][1] = rr.onupdate

end

function rr.off()
	rrsettings.active = false
	Command.Message.Reject("yell", "rrep")
	print("RiftReputation off")
		rr.ui.backgroundframe:SetVisible(false)
		rr.ui.targetratingframe:SetVisible(false)
		rr.ui.targetvotesframe:SetVisible(false)
		rr.ui.barbackground:SetVisible(false)
		rr.ui.respected:SetVisible(false)
		rr.ui.notorious:SetVisible(false)
	    rr.ui.barindicator:SetVisible(false)
		
		rr.ui.backgroundframe2:SetVisible(false)
		rr.ui.targetratingframe2:SetVisible(false)
		rr.ui.targetvotesframe2:SetVisible(false)
		rr.ui.barbackground2:SetVisible(false)
		rr.ui.respected2:SetVisible(false)
		rr.ui.notorious2:SetVisible(false)
	    rr.ui.barindicator2:SetVisible(false)
	
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

function rr.ui.createsearch()

	rr.ui.RightDown = false
    rr.ui.originalXDiff2 = 0
    rr.ui.originalYDiff2 = 0

	if not rrsettings.ui_x2 then rrsettings.ui_x2 = defaults.ui_x2 end
	if not rrsettings.ui_y2 then rrsettings.ui_y2 = defaults.ui_y2 end
	
	-- Background Frame
	
	rr.ui.backgroundframe2 = UI.CreateFrame("Text", "Background2", rr.ui.context)
    
	rr.ui.backgroundframe2:SetFontSize(16)
    rr.ui.backgroundframe2:SetFontColor(1, 1, 1, 0)
	rr.ui.backgroundframe2:SetWidth(200)
	rr.ui.backgroundframe2:SetHeight(75)
    rr.ui.backgroundframe2:SetBackgroundColor(0, 0, 0, .35)    
    rr.ui.backgroundframe2:SetLayer(50)
	rr.ui.backgroundframe2:SetPoint("TOPLEFT", UIParent, "TOPLEFT", rrsettings.ui_x2, rrsettings.ui_y2)
    rr.ui.backgroundframe2:SetVisible(true)
	rr.ui.backgroundframe2:SetMouseMasking("limited")

	function rr.ui.backgroundframe2.Event:RightDown()
		if rrsettings.locked == false 
		then
			rr.ui.RightDown = true
			local mouse = Inspect.Mouse()
			rr.ui.originalXDiff2 = mouse.x - rr.ui.backgroundframe2:GetLeft()
			rr.ui.originalYDiff2 = mouse.y - rr.ui.backgroundframe2:GetTop()
		end
	end
	
	function rr.ui.backgroundframe2.Event:RightUp()
		if rrsettings.locked == false 
		then	
			rr.ui.RightDown = false
		end
	end
	
	function rr.ui.backgroundframe2.Event:RightUpoutside()
		if rrsettings.locked == false 
		then	
			rr.ui.RightDown = false
		end
	end
	
	function rr.ui.backgroundframe2.Event:MouseMove(x, y)
		if rrsettings.locked == false 
		then	
			if not rr.ui.RightDown then
				return
			end
			rr.ui.backgroundframe2:SetPoint("TOPLEFT", UIParent, "TOPLEFT", x - rr.ui.originalXDiff2, y - rr.ui.originalYDiff2)
			rrsettings.ui_x2 = x - rr.ui.originalXDiff2
			rrsettings.ui_y2 = y - rr.ui.originalYDiff2
		end		
	end

	
	-- search Frame
	
	rr.ui.targetratingframe2 = UI.CreateFrame("RiftTextfield", "SearchRating", rr.ui.context)
    
	rr.ui.targetratingframe2:SetText("Search...")
	--rr.ui.targetratingframe2:SetFontSize(15)
    --rr.ui.targetratingframe2:SetFontColor(1, 1, 1, 1)
	rr.ui.targetratingframe2:SetWidth(200)
	rr.ui.targetratingframe2:SetHeight(22)
    rr.ui.targetratingframe2:SetBackgroundColor(0, 0, 0, .35)    
    rr.ui.targetratingframe2:SetLayer(51)
	rr.ui.targetratingframe2:SetPoint("TOPLEFT", rr.ui.backgroundframe2, "TOPLEFT", 0, 0)
    rr.ui.targetratingframe2:SetVisible(true)
	
	function rr.ui.targetratingframe2.Event:TextfieldChange()
		rr.ui.searchtext = rr.ui.targetratingframe2:GetText()
		rr.ui.update()
	end
	

	-- search votes text Frame
	
	rr.ui.targetvotesframe2 = UI.CreateFrame("Text", "TargetVotes2", rr.ui.context)
    
	rr.ui.targetvotesframe2:SetFontSize(15)
    rr.ui.targetvotesframe2:SetFontColor(1, 1, 1, 1)
	rr.ui.targetvotesframe2:SetWidth(200)
	rr.ui.targetvotesframe2:SetHeight(22)
    rr.ui.targetvotesframe2:SetBackgroundColor(0, 0, 0, .35)    
    rr.ui.targetvotesframe2:SetLayer(51)
	rr.ui.targetvotesframe2:SetPoint("BOTTOMLEFT", rr.ui.backgroundframe2, "BOTTOMLEFT", 0, 0)
    rr.ui.targetvotesframe2:SetVisible(true)
	
	-- search bar background Frame
	
	rr.ui.barbackground2 = UI.CreateFrame("Texture", "Barbackground2", rr.ui.context)
    
	rr.ui.barbackground2:SetTexture("RiftReputation", "media/barbackground.png")
	rr.ui.barbackground2:SetWidth(100)
	rr.ui.barbackground2:SetHeight(32)
    rr.ui.barbackground2:SetLayer(51)
	rr.ui.barbackground2:SetPoint("CENTER", rr.ui.backgroundframe2, "CENTER", 0, 0)
    rr.ui.barbackground2:SetVisible(true)
	
	-- search respected Frame
	
	rr.ui.respected2 = UI.CreateFrame("Texture", "Respected2", rr.ui.context)
    
	rr.ui.respected2:SetTexture("RiftReputation", "media/respected.png")
	rr.ui.respected2:SetWidth(50)
	rr.ui.respected2:SetHeight(35)
    rr.ui.respected2:SetLayer(52)
	rr.ui.respected2:SetPoint("CENTERRIGHT", rr.ui.backgroundframe2, "CENTERRIGHT", 0, 0)
    rr.ui.respected2:SetVisible(true)

	-- search notorious Frame
	
	rr.ui.notorious2 = UI.CreateFrame("Texture", "Notorious2", rr.ui.context)
    
	rr.ui.notorious2:SetTexture("RiftReputation", "media/notorious.png")
	rr.ui.notorious2:SetWidth(50)
	rr.ui.notorious2:SetHeight(35)
    rr.ui.notorious2:SetLayer(52)
	rr.ui.notorious2:SetPoint("CENTERLEFT", rr.ui.backgroundframe2, "CENTERLEFT", 0, 0)
    rr.ui.notorious2:SetVisible(true)
	
	-- search bar indicator Frame
	
	rr.ui.barindicator2 = UI.CreateFrame("Texture", "barindicator2", rr.ui.context)
    
	rr.ui.barindicator2:SetTexture("RiftReputation", "media/indicator.png")
	rr.ui.barindicator2:SetWidth(7)
	rr.ui.barindicator2:SetHeight(35)
    rr.ui.barindicator2:SetLayer(53)
	rr.ui.barindicator2:SetPoint("CENTER", rr.ui.barbackground2, "CENTER", 0, 0)
    rr.ui.barindicator2:SetVisible(true)
end

function rr.ui.create()

	rr.ui.context = UI.CreateContext("RiftReputationContext")
	rr.ui.RightDown = false
    rr.ui.originalXDiff = 0
    rr.ui.originalYDiff = 0

	if not rrsettings.ui_x then rrsettings.ui_x = defaults.ui_x end
	if not rrsettings.ui_y then rrsettings.ui_y = defaults.ui_y end
	--if not rrsettings.ui_xt then rrsettings.ui_xt = defaults.ui_xt end
	--if not rrsettings.ui_yt then rrsettings.ui_yt = defaults.ui_yt end
	if not rrsettings.locked then rrsettings.locked = defaults.locked end
	
	-- Background Frame
	
	rr.ui.backgroundframe = UI.CreateFrame("Text", "Background", rr.ui.context)
    
	rr.ui.backgroundframe:SetFontSize(16)
    rr.ui.backgroundframe:SetFontColor(1, 1, 1, 0)
	rr.ui.backgroundframe:SetWidth(225)
	rr.ui.backgroundframe:SetHeight(75)
    rr.ui.backgroundframe:SetBackgroundColor(0, 0, 0, .35)    
    rr.ui.backgroundframe:SetLayer(50)
	rr.ui.backgroundframe:SetPoint("TOPLEFT", UIParent, "TOPLEFT", rrsettings.ui_x, rrsettings.ui_y)
    rr.ui.backgroundframe:SetVisible(true)
	rr.ui.backgroundframe:SetMouseMasking("limited")

	function rr.ui.backgroundframe.Event:RightDown()
		if rrsettings.locked == false 
		then
			rr.ui.RightDown = true
			local mouse = Inspect.Mouse()
			rr.ui.originalXDiff = mouse.x - rr.ui.backgroundframe:GetLeft()
			rr.ui.originalYDiff = mouse.y - rr.ui.backgroundframe:GetTop()
		end
	end
	
	function rr.ui.backgroundframe.Event:RightUp()
		if rrsettings.locked == false 
		then	
			rr.ui.RightDown = false
		end
	end
	
	function rr.ui.backgroundframe.Event:RightUpoutside()
		if rrsettings.locked == false 
		then	
			rr.ui.RightDown = false
		end
	end
	
	function rr.ui.backgroundframe.Event:MouseMove(x, y)
		if rrsettings.locked == false 
		then	
			if not rr.ui.RightDown then
				return
			end
			rr.ui.backgroundframe:SetPoint("TOPLEFT", UIParent, "TOPLEFT", x - rr.ui.originalXDiff, y - rr.ui.originalYDiff)
			rrsettings.ui_x = x - rr.ui.originalXDiff
			rrsettings.ui_y = y - rr.ui.originalYDiff
		end		
	end

	
	-- Target's name text Frame
	
	rr.ui.targetratingframe = UI.CreateFrame("Text", "TargetRating", rr.ui.context)
    
	rr.ui.targetratingframe:SetFontSize(15)
    rr.ui.targetratingframe:SetFontColor(1, 1, 1, 1)
	rr.ui.targetratingframe:SetWidth(200)
	rr.ui.targetratingframe:SetHeight(22)
    rr.ui.targetratingframe:SetBackgroundColor(0, 0, 0, .35)    
    rr.ui.targetratingframe:SetLayer(51)
	rr.ui.targetratingframe:SetPoint("TOPLEFT", rr.ui.backgroundframe, "TOPLEFT", 0, 0)
    rr.ui.targetratingframe:SetVisible(false)

	-- Target's votes text Frame
	
	rr.ui.targetvotesframe = UI.CreateFrame("Text", "TargetVotes", rr.ui.context)
    
	rr.ui.targetvotesframe:SetFontSize(15)
    rr.ui.targetvotesframe:SetFontColor(1, 1, 1, 1)
	rr.ui.targetvotesframe:SetWidth(200)
	rr.ui.targetvotesframe:SetHeight(22)
    rr.ui.targetvotesframe:SetBackgroundColor(0, 0, 0, .35)    
    rr.ui.targetvotesframe:SetLayer(51)
	rr.ui.targetvotesframe:SetPoint("BOTTOMLEFT", rr.ui.backgroundframe, "BOTTOMLEFT", 0, 0)
    rr.ui.targetvotesframe:SetVisible(false)
	
	-- bar background Frame
	
	rr.ui.barbackground = UI.CreateFrame("Texture", "Barbackground", rr.ui.context)
    
	rr.ui.barbackground:SetTexture("RiftReputation", "media/barbackground.png")
	rr.ui.barbackground:SetWidth(100)
	rr.ui.barbackground:SetHeight(32)
    rr.ui.barbackground:SetLayer(51)
	rr.ui.barbackground:SetPoint("TOPLEFT", rr.ui.backgroundframe, "TOPLEFT", 50, 22)
    rr.ui.barbackground:SetVisible(false)
	
	-- respected Frame
	
	rr.ui.respected = UI.CreateFrame("Texture", "Respected", rr.ui.context)
    
	rr.ui.respected:SetTexture("RiftReputation", "media/respected.png")
	rr.ui.respected:SetWidth(50)
	rr.ui.respected:SetHeight(35)
    rr.ui.respected:SetLayer(52)
	rr.ui.respected:SetPoint("TOPLEFT", rr.ui.barbackground, "TOPRIGHT", 0, -2)
    rr.ui.respected:SetVisible(false)

	-- notorious Frame
	
	rr.ui.notorious = UI.CreateFrame("Texture", "Notorious", rr.ui.context)
    
	rr.ui.notorious:SetTexture("RiftReputation", "media/notorious.png")
	rr.ui.notorious:SetWidth(50)
	rr.ui.notorious:SetHeight(35)
    rr.ui.notorious:SetLayer(52)
	rr.ui.notorious:SetPoint("TOPLEFT", rr.ui.backgroundframe, "TOPLEFT", 0, 20)
    rr.ui.notorious:SetVisible(false)
	
	-- down vote button
	rr.ui.downbutton = UI.CreateFrame("Texture", "DownButton", rr.ui.context)
    
	rr.ui.downbutton:SetTexture("RiftReputation", "media/thumbsdown.png")
	rr.ui.downbutton:SetWidth(25)
	rr.ui.downbutton:SetHeight(25)
    rr.ui.downbutton:SetLayer(52)
	rr.ui.downbutton:SetPoint("BOTTOMRIGHT", rr.ui.backgroundframe, "BOTTOMRIGHT", 0, 0)
    rr.ui.downbutton:SetVisible(false)
	
	function rr.ui.downbutton.Event:LeftDown()
		rr.ui.downbutton:SetTexture("RiftReputation", "media/thumbsdownpressed.png")	
	end
	
	function rr.ui.downbutton.Event:LeftUp()
		local voter = Inspect.Unit.Detail("player").name
		local player = Inspect.Unit.Detail("player.target").name


		if player == voter 
		then 
			print("Sorry! No self-votes allowed :P")
		elseif Inspect.Unit.Detail("player.target").level ~= 50
		then
			print("You can only vote for level 50 players")
		elseif Inspect.Unit.Detail("player").level ~= 50
		then
			print("You can only vote if you are level 50")
		elseif string.find(player, "@") ~= nil then
			print("You can only vote for players on your own shard")
		elseif Inspect.Unit.Detail("player.target").faction ~= Inspect.Unit.Detail("player").faction then
			print("You can only vote for players of your faction")
		else
			rr.ratestore(player, voter, "3")
			print("You gave " .. player .. " a Negative vote!")
		end
		
		if rrvotes ~= nil and rrvotes[player] ~= nil and rrvotes[player][voter] == "3" then
			rr.ui.downbutton:SetTexture("RiftReputation", "media/thumbsdownchecked.png")
		else
			rr.ui.downbutton:SetTexture("RiftReputation", "media/thumbsdown.png")
		end
		
	end
	
	-- up vote button
	rr.ui.upbutton = UI.CreateFrame("Texture", "UpButton", rr.ui.context)
    
	rr.ui.upbutton:SetTexture("RiftReputation", "media/thumbsup.png")
	rr.ui.upbutton:SetWidth(25)
	rr.ui.upbutton:SetHeight(25)
    rr.ui.upbutton:SetLayer(52)
	rr.ui.upbutton:SetPoint("TOPRIGHT", rr.ui.backgroundframe, "TOPRIGHT", 0, 0)
    rr.ui.upbutton:SetVisible(false)
	
	function rr.ui.upbutton.Event:LeftDown()
		rr.ui.upbutton:SetTexture("RiftReputation", "media/thumbsuppressed.png")	
	end
	
	function rr.ui.upbutton.Event:LeftUp()
		local voter = Inspect.Unit.Detail("player").name
		local player = Inspect.Unit.Detail("player.target").name


		if player == voter 
		then 
			print("Sorry! No self-votes allowed :P")
		elseif Inspect.Unit.Detail("player.target").level ~= 50
		then
			print("You can only vote for level 50 players")
		elseif Inspect.Unit.Detail("player").level ~= 50
		then
			print("You can only vote if you are level 50")
		elseif string.find(player, "@") ~= nil then
			print("You can only vote for players on your own shard")
		elseif Inspect.Unit.Detail("player.target").faction ~= Inspect.Unit.Detail("player").faction then
			print("You can only vote for players of your faction")
		else
			rr.ratestore(player, voter, "1")
			print("You gave " .. player .. " a Positive vote!")
		end
		
		if rrvotes ~= nil and rrvotes[player] ~= nil and rrvotes[player][voter] == "1" then
			rr.ui.upbutton:SetTexture("RiftReputation", "media/thumbsupchecked.png")
		else
			rr.ui.upbutton:SetTexture("RiftReputation", "media/thumbsup.png")
		end
		
	end
	
	-- neutral vote button
	rr.ui.neutralbutton = UI.CreateFrame("Texture", "NeutralButton", rr.ui.context)
    
	rr.ui.neutralbutton:SetTexture("RiftReputation", "media/neutral.png")
	rr.ui.neutralbutton:SetWidth(25)
	rr.ui.neutralbutton:SetHeight(25)
    rr.ui.neutralbutton:SetLayer(52)
	rr.ui.neutralbutton:SetPoint("CENTERRIGHT", rr.ui.backgroundframe, "CENTERRIGHT", 0, 0)
    rr.ui.neutralbutton:SetVisible(false)

	function rr.ui.neutralbutton.Event:LeftDown()
		rr.ui.neutralbutton:SetTexture("RiftReputation", "media/neutralpressed.png")	
	end
	
	function rr.ui.neutralbutton.Event:LeftUp()
		local voter = Inspect.Unit.Detail("player").name
		local player = Inspect.Unit.Detail("player.target").name


		if player == voter 
		then 
			print("Sorry! No self-votes allowed :P")
		elseif Inspect.Unit.Detail("player.target").level ~= 50
		then
			print("You can only vote for level 50 players")
		elseif Inspect.Unit.Detail("player").level ~= 50
		then
			print("You can only vote if you are level 50")
		elseif string.find(player, "@") ~= nil then
			print("You can only vote for players on your own shard")
		elseif Inspect.Unit.Detail("player.target").faction ~= Inspect.Unit.Detail("player").faction then
			print("You can only vote for players of your faction")
		else
			rr.ratestore(player, voter, "2")
			print("You gave " .. player .. " a Neutral vote!")
		end
		
		if rrvotes ~= nil and rrvotes[player] ~= nil and rrvotes[player][voter] == "2" then
			rr.ui.neutralbutton:SetTexture("RiftReputation", "media/neutralchecked.png")
		else
			rr.ui.neutralbutton:SetTexture("RiftReputation", "media/neutral.png")
		end
	end
	
	-- bar indicator Frame
	
	rr.ui.barindicator = UI.CreateFrame("Texture", "barindicator", rr.ui.context)
    
	rr.ui.barindicator:SetTexture("RiftReputation", "media/indicator.png")
	rr.ui.barindicator:SetWidth(7)
	rr.ui.barindicator:SetHeight(35)
    rr.ui.barindicator:SetLayer(53)
	rr.ui.barindicator:SetPoint("CENTER", rr.ui.barbackground, "CENTER", 0, 0)
    rr.ui.barindicator:SetVisible(false)
end

function rr.ui.update()
	
	local barxoffset = 50
	local total = 0
	local votes = 0
	
	local barxoffset2 = 50
	local total2 = 0
	local votes2 = 0

	if Inspect.Unit.Detail('player.target') and Inspect.Unit.Detail('player.target').player == true
	then
		local player = Inspect.Unit.Detail('player').name
		local target = Inspect.Unit.Detail('player.target').name
		rr.ui.backgroundframe:SetVisible(true)
		rr.ui.targetratingframe:SetText(target .. "'s Repute:")
		rr.ui.targetratingframe:SetVisible(true)
		
		rr.ui.targetvotesframe:SetVisible(true)
		rr.ui.barbackground:SetVisible(true)
		rr.ui.respected:SetVisible(true)
		rr.ui.notorious:SetVisible(true)
		rr.ui.barindicator:SetVisible(true)
		rr.ui.neutralbutton:SetVisible(true)
		rr.ui.upbutton:SetVisible(true)
		rr.ui.downbutton:SetVisible(true)
		if rrplayerdata[target] ~= nil then
			total = (rrplayerdata[target].upscore + rrplayerdata[target].neutralscore + rrplayerdata[target].downscore)
			rrplayerdata[target].uppercent = (rrplayerdata[target].upscore / total)
			rrplayerdata[target].neutralpercent = (rrplayerdata[target].neutralscore / total)
			barxoffset = 100 * ((.5 * rrplayerdata[target].neutralpercent) + rrplayerdata[target].uppercent)
			votes = (rrplayerdata[target].numuprecieved + rrplayerdata[target].numdownrecieved + rrplayerdata[target].numneutralrecieved - 3)
			if votes < 0 then votes = 0 end
		end	
			rr.ui.targetvotesframe:SetText("Total Votes: " .. votes)
			rr.ui.barindicator:SetPoint("CENTER", rr.ui.barbackground, "CENTERLEFT", barxoffset, 0)
		if rrvotes ~= nil and rrvotes[target] ~= nil and rrvotes[target][player] ~= nil then
			if rrvotes[target][player] == "3" then
				rr.ui.downbutton:SetTexture("RiftReputation", "media/thumbsdownchecked.png")
			else
				rr.ui.downbutton:SetTexture("RiftReputation", "media/thumbsdown.png")
			end
			
			if rrvotes[target][player] == "2" then
				rr.ui.neutralbutton:SetTexture("RiftReputation", "media/neutralchecked.png")
			else
				rr.ui.neutralbutton:SetTexture("RiftReputation", "media/neutral.png")
			end
			
			if rrvotes[target][player] == "1" then
				rr.ui.upbutton:SetTexture("RiftReputation", "media/thumbsupchecked.png")
			else
				rr.ui.upbutton:SetTexture("RiftReputation", "media/thumbsup.png")
			end
		else
			rr.ui.upbutton:SetTexture("RiftReputation", "media/thumbsup.png")
			rr.ui.neutralbutton:SetTexture("RiftReputation", "media/neutral.png")
			rr.ui.downbutton:SetTexture("RiftReputation", "media/thumbsdown.png")
		end

	else
		rr.ui.backgroundframe:SetVisible(false)
		rr.ui.targetratingframe:SetVisible(false)
		rr.ui.targetvotesframe:SetVisible(false)
		rr.ui.barbackground:SetVisible(false)
		rr.ui.respected:SetVisible(false)
		rr.ui.notorious:SetVisible(false)
	    rr.ui.barindicator:SetVisible(false)
		rr.ui.neutralbutton:SetVisible(false)
		rr.ui.upbutton:SetVisible(false)
		rr.ui.downbutton:SetVisible(false)
	end
	
	if rr.ui.searchtext ~= nil and rrplayerdata[rr.ui.searchtext:gsub("^%l", string.upper)] ~= nil then
		total2 = (rrplayerdata[rr.ui.searchtext].upscore + rrplayerdata[rr.ui.searchtext].neutralscore + rrplayerdata[rr.ui.searchtext].downscore)
		rrplayerdata[rr.ui.searchtext].uppercent = (rrplayerdata[rr.ui.searchtext].upscore / total2)
		rrplayerdata[rr.ui.searchtext].neutralpercent = (rrplayerdata[rr.ui.searchtext].neutralscore / total2)
		barxoffset2 = 100 * ((.5 * rrplayerdata[rr.ui.searchtext].neutralpercent) + rrplayerdata[rr.ui.searchtext].uppercent)
		votes2 = (rrplayerdata[rr.ui.searchtext].numuprecieved + rrplayerdata[rr.ui.searchtext].numdownrecieved + rrplayerdata[rr.ui.searchtext].numneutralrecieved - 3)
		if votes2 < 0 then votes2 = 0 end

		rr.ui.targetvotesframe2:SetText("Total Votes: " .. votes2)
		rr.ui.barindicator2:SetPoint("CENTER", rr.ui.barbackground2, "CENTERLEFT", barxoffset2, 0)
	else
		rr.ui.targetvotesframe2:SetText("Total Votes: 0")
		rr.ui.barindicator2:SetPoint("CENTER", rr.ui.barbackground2, "CENTERLEFT", 50, 0)
	end


end

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
		--print("player data:")
		--print(table.show(rrplayerdata))
	end
	
	if RiftReputation_voterdata and rrvoterdata ~= nil
	then
		rrvoterdatauncompress  = zlib.inflate()(RiftReputation_voterdata, "finish")
		rrvoterdata = loadstring("return rrvoterdata")()
		--print("voter data:")
		--print(table.show(rrvoterdata))
	end
	
	if RiftReputation_votes and rrvotes ~= nil
	then
		rrvotesuncompress  = zlib.inflate()(RiftReputation_votes, "finish")
		rrvotes = loadstring("return rrvotes")()
		--print("vote histories:")
		--print(table.show(rrvotes))
	end
	
end

function test()

end


table.insert(Event.System.Secure.Enter, 			{rr.entercombat, 		"RiftReputation", "Enter Combat"})
table.insert(Event.System.Secure.Leave, 			{rr.leavecombat,		"RiftReputation", "Leave Combat"})
table.insert(Event.Addon.SavedVariables.Save.Begin, {rr.convert, 			"RiftReputation", "Convert b4 save"})
table.insert(Event.Addon.SavedVariables.Load.End, 	{rr.addonloaded,		"RiftReputation", "Load variables"})
table.insert(Event.Message.Receive, 				{rr.recieve, 			"RiftReputation", "Received Message"})
table.insert(Command.Slash.Register("rr"), 			{rr.slash, 				"RiftReputation", "Slash Cmd"})
table.insert(Command.Slash.Register("RiftReputation"), 	{rr.help, 			"RiftReputation", "Slash Cmd"})
