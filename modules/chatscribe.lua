
-- chatscribe v0.1.0
-- By: Ralephis (mibero_)
-- developed using Deadline's babyLua typecheck and autofill module

-- COMPONENT: CHATSCRIBE COMMAND MODULE --

-- proprietary datatype -- 

type chatscribe_message_data = {

	sender : string;
	channel : string;
	message : {string};

}

-- chatscribe object --

local chatscribe = {

	use_whitelist = true; -- whether non-whitelist players are blocked from using commands

	prefix = ".";

	whitelist = {

		userIDs = {3401131717};

		names = {}; -- players who are in this list are automatically whitelisted when they join

	};

	commands = {};

	command_descriptions = {};

	reserved_targets = {};

	data = {}; -- holds command-related data

	reference_lists = { -- on-site documentation via .see command

		teams = {"attacker","defender"};

	}

}

print(`chatscribe v0.1.0`)
print(`By: Ralephis (mibero_)`)
print(`Type "{chatscribe.prefix}commands" in the chat to view chatscribe commands.`)
print(``)

-- registering reserved targets --

chatscribe.reserved_targets["all"] = function(data : chatscribe_message_data) : {player}

	return players.get_all()

end

chatscribe.reserved_targets["attackers"] = function(data : chatscribe_message_data) : {player?}

	local attackers = {}
	for _,player in players.get_all() do

		if player.get_team() ~= "attacker" then
			continue
		end

		table.insert(attackers,player)

	end

	return attackers

end

chatscribe.reserved_targets["defenders"] = function(data : chatscribe_message_data) : {player?}

	local defenders = {}
	for _,player in players.get_all() do

		if player.get_team() ~= "defender" then
			continue
		end

		table.insert(defenders,player)

	end

	return defenders

end

chatscribe.reserved_targets["others"] = function(data : chatscribe_message_data) : {player?}

	local all_players = players.get_all()
	local sender_position = table.find(all_players,players.get(data.sender))

	table.remove(all_players,sender_position)

	return all_players

end

-- populating reference tables --

-- caching available gamemodes
chatscribe.reference_lists["gamemodes"] = {}
for name,executable in gamemode.available_gamemodes do
	table.insert(chatscribe.reference_lists.gamemodes,name)
end

-- caching map configs
chatscribe.reference_lists["maps"] = {}
for _,map in map.get_maps() do
	table.insert(chatscribe.reference_lists.maps,map)
end

-- caching reserved targets
chatscribe.reference_lists["reservedtargets"] = {}
for keyword,_ in chatscribe.reserved_targets do
	table.insert(chatscribe.reference_lists.reservedtargets,keyword)
end

-- chatscribe methods --

function chatscribe:register_command(keyword : string, executable : (data : chatscribe_message_data) -> (), description : string?)

	self.commands[keyword] = executable

	if description then
		self.command_descriptions[keyword] = description
	end

end

function chatscribe:remove_command(keyword : string)

	if not self.commands[keyword] then
		print(`"{keyword}" command not found.`)
		return
	end
	self.commands[keyword] = nil
	print(`Removed the "{keyword}" command.`)

end

function chatscribe:get_reserved_target_result(keyword : string, data : chatscribe_message_data) : {player?}?

	local executable = self.reserved_targets[keyword]
	if not executable then
		return
	end

	return executable(data)

end


function chatscribe:guess_target(target : string) : player?

	-- initialize arrays for holding names and shortened counterparts
	local snippet_names = {}
	local full_names = {}

	-- populate arrays
	for _,player in players.get_all() do
		table.insert(full_names,player.name)

		local snippeted_name = string.sub(player.name,1,#target)
		table.insert(snippet_names,snippeted_name)
	end

	-- find first snippet that matches the target
	local first_position = table.find(snippet_names,target)

	-- if no match found, return
	if not first_position then
		return
	end

	-- if a second match is found, no conclusion can be drawn, return
	if table.find(snippet_names,target,first_position+1) then
		return
	end

	-- return the intended target
	return players.get(full_names[first_position])

end

-- built-in commands --

-- "explode" command includes numerous print() statements for debugging purposes
-- ".explode"; ".explode target"; ".explode reserved_target"
chatscribe:register_command("explode",function(data : chatscribe_message_data)

	-- initialize target variables
	local target_argument = data.message[1]
	local target = nil

	-- if no target argument, assume sender is target
	if not target_argument then
		target = {players.get(data.sender)}
	else -- target argument given, check if reserved
		target = chatscribe:get_reserved_target_result(target_argument,data)
	end

	-- reserved-target check failed, look for player
	if not target then
		target = {chatscribe:guess_target(target_argument)}
	end

	-- no player found, target unknown
	if target == {} then
		print(`No target determined. Command failed.`)
		return
	end

	-- blow up all targeted players
	for _,player in target do

		print(`Blowing up {player.name}.`)
		player.explode()

	end

end, "Blows up the target.")

-- ".whitelist target_name"; ".whitelist target_id"
chatscribe:register_command("whitelist",function(data : chatscribe_message_data)

	local target = data.message[1]

	if tonumber(target) then

		local target_id = tonumber(target)

		if table.find(chatscribe.whitelist.userIDs,target_id) then
			print(`UserID {target_id} is already whitelisted.`)
			return
		end

		table.insert(chatscribe.whitelist.userIDs,target_id)
		print(`{data.sender} whitelisted UserID {target_id}`)
		return

	end

	target = chatscribe:guess_target(target)

	if not target then
		print(`Target not found. Command failed.`)
		return
	end

	if table.find(chatscribe.whitelist.userIDs,target.id) then
		print(`{target.name} is already whitelisted.`)
		return
	end

	table.insert(chatscribe.whitelist.userIDs,target.id)
	print(`{data.sender} whitelisted {target.name}.`)

end, "Authorizes a player/ID to use chatscribe commands.")

-- ".revoke target_name"; ".revoke target_id"
chatscribe:register_command("revoke",function(data : chatscribe_message_data)

	local target = data.message[1]
	local target_name = nil


	if tonumber(target) then

		target = tonumber(target)

	else

		local target_player = players.get(target)
		if not target_player then
			print(`Target not found. Command failed. `)
			return
		end

		target_name = target_player.name
		target = target_player.id

	end

	local id_position = table.find(chatscribe.whitelist.userIDs,target)
	if not id_position then
		print(`{target_name or "UserID " .. target} was not whitelisted.`)
		return
	end
	table.remove(chatscribe.whitelist.userIDs,id_position)

	print(`{data.sender} removed {target_name or "UserID " .. target} from the whitelist.`)

end, "Removes a player/ID's permission to use chatscribe commands.")

-- ".commands"
chatscribe:register_command("commands",function(data : chatscribe_message_data)

	-- uses self.command_descriptions

	print(`commands command called.`)

	print(``)
	print(`Whitelisted players have access to:`)
	for keyword,_ in chatscribe.commands do
		local description = chatscribe.command_descriptions[keyword]

		if description then
			description = " -- " .. description
		else
			description = ""
		end

		print(`	{chatscribe.prefix}{keyword}{description}`)

	end
	print(``)

end, "Displays all available commands.")

-- ".refill"; ".refill target"; ".refill reserved_target"
chatscribe:register_command("refill",function(data : chatscribe_message_data)

	-- targeting code taken from "explode" command

	local target_argument = data.message[1]
	local target = nil

	-- if no target argument, assume sender is target
	if not target_argument then

		target = {players.get(data.sender)}
	else -- target argument given, check if reserved

		target = chatscribe:get_reserved_target_result(target_argument,data)
	end

	-- reserved-target check failed, look for player
	if not target then

		target = {chatscribe:guess_target(target_argument)}
	end

	-- no player found, target unknown
	if target == {} then
		print(`No target determined. Command failed.`)
		return
	end

	for _,player in target do
		player.refill_ammo()
		print(`{data.sender} refilled {player.name}'s ammo.`)
	end

end, "Refills the target's ammunition.")

-- ".health value"; ".health target value"; ".health reserved_target value"
chatscribe:register_command("health",function(data : chatscribe_message_data)

	local target_argument = data.message[1]
	local value_argument = data.message[2]

	local target = nil
	local value = nil

	-- no second argument, i.e. ".health arg1"
	if not value_argument then

		value = tonumber(target_argument)
		target = {players.get(data.sender)}

	else -- second argument exists, ".health arg1 arg2"

		value = tonumber(value_argument)
		target = chatscribe:get_reserved_target_result(target_argument,data)

	end

	-- target argument is not reserved, attempt to guess target
	if not target then

		target = {chatscribe:guess_target(target_argument)}

	end

	-- target not found OR invalid value given
	if target == {} or not value then
		print(`No target determined. Command failed.`)
		return
	end

	for _,player in target do
		player.set_health(value)
		print(`{data.sender} set {player.name}'s health to {value}.`)
	end


end, "Sets the health of the target.")

-- ".init_health value"; ".init_health target value"; ".init_health reserved_target value"
chatscribe:register_command("inithealth",function(data : chatscribe_message_data)

	-- almost identical to ".health" command

	local target_argument = data.message[1]
	local value_argument = data.message[2]

	local target = nil
	local value = nil

	-- no second argument, i.e. ".health arg1"
	if not value_argument then

		value = tonumber(target_argument)
		target = {players.get(data.sender)}

	else -- second argument exists, ".health arg1 arg2"

		value = tonumber(value_argument)
		target = chatscribe:get_reserved_target_result(target_argument,data)

	end

	-- target argument is not reserved, attempt to guess target
	if not target then

		target = {chatscribe:guess_target(target_argument)}

	end

	-- target not found OR invalid value given
	if target == {} or not value then
		print(`No target determined. Command failed.`)
		return
	end

	for _,player in target do
		player.set_initial_health(value)
		print(`{data.sender} set {player.name}'s initial health to {value}.`)
	end

end, "Sets the initial health of the target.")

-- ".kill"; ".kill target"; ".kill reserved_target"
chatscribe:register_command("kill",function(data : chatscribe_message_data)

	-- initialize target variables
	local target_argument = data.message[1]
	local target = nil

	-- if no target argument, assume sender is target
	if not target_argument then
		target = {players.get(data.sender)}
	else -- target argument given, check if reserved
		target = chatscribe:get_reserved_target_result(target_argument,data)
	end

	-- reserved-target check failed, look for player
	if not target then
		target = {chatscribe:guess_target(target_argument)}
	end

	-- no player found, target unknown
	if target == {} then
		print(`No target determined. Command failed.`)
		return
	end

	for _,player in target do
		player.kill()
		print(`{data.sender} commanded for {player.name} to be killed.`)
	end

end, "Kills the target.")

-- ".kick target"; ".kick reserved_target"
chatscribe:register_command("kick",function(data : chatscribe_message_data)

	-- initialize target variables
	local target_argument = data.message[1]
	local target = nil

	-- if no target argument, assume sender is target
	if not target_argument then
		return
	end

	target = chatscribe:get_reserved_target_result(target_argument,data)

	-- reserved-target check failed, look for player
	if not target then
		target = {chatscribe:guess_target(target_argument)}
	end

	-- no player found, target unknown
	if target == {} then
		print(`No target determined. Command failed.`)
		return
	end

	for _,player in target do
		print(`{data.sender} kicked {player.name} from the server.`)
		player.kick()
	end

end, "Kicks the target from the server.")

-- ".ban target_player" WIP
chatscribe:register_command("ban",function(data : chatscribe_message_data)

	print(`Bans via chatscribe have not been implemented yet.`)

end, "Bans the player from the server. NOT FUNCTIONAL.")

-- ".bring target"; ".bring reserved_target" WIP
chatscribe:register_command("bring",function(data : chatscribe_message_data)

	local target_argument = data.message[1]

	if not target_argument then
		print(`Target argument not detected. Command failed.`)
		return
	end

	local sender_player = players.get(data.sender)

	local sender_position = sender_player.get_position()

	if not sender_position then
		print(`Could not get sender's position. Command failed.`)
		return
	end

	local target = chatscribe:get_reserved_target_result(target_argument,data)

	if not target then
		target = {chatscribe:guess_target(target_argument)}
	end

	if target == {} then
		print(`No target determined. Command failed.`)
		return
	end

	for _,player in target do

		if player == sender_player or not player.get_position() then
			continue
		end

		player.set_position(sender_position)
		print(`{data.sender} brought {player.name} to their position.`)

	end

end, "Teleports the target to you.")

-- ".visit target_player"; ".visit target_id"
chatscribe:register_command("visit",function(data : chatscribe_message_data)

	local sender_player = players.get(data.sender)

	if not sender_player.get_position() then
		print(`Sender's position not found. Command failed.`)
		return
	end

	local target_argument = data.message[1]

	if not target_argument then
		print(`Target argument not found. Command failed.`)
		return
	end

	local target = nil

	if tonumber(target_argument) then
		target = players.get_by_userid(tonumber(target_argument))
	else
		target = chatscribe:guess_target(target_argument)
	end

	if not target or target == sender_player then
		print(`Valid target not found. Command failed.`)
		return
	end

	local target_position = target.get_position()

	if not target_position then
		print(`Target player's position not found. Command failed.`)
		return
	end

	sender_player.set_position(target_position)
	print(`{data.sender} went to {target.name}'s position.`)

end, "Teleports you to the player.")

-- ".dmswitch"; ".dmswitch target"; ".dmswitch reserved_target"
chatscribe:register_command("dmswitch",function(data : chatscribe_message_data)

	if not chatscribe.data["dmswitch_data"] then
		chatscribe.data["dmswitch_data"] = {}
	end

	-- initialize target variables
	local target_argument = data.message[1]
	local target = nil

	-- if no target argument, assume sender is target
	if not target_argument then
		target = {players.get(data.sender)}
	else -- target argument given, check if reserved
		target = chatscribe:get_reserved_target_result(target_argument,data)
	end

	-- reserved-target check failed, look for player
	if not target then
		target = {chatscribe:guess_target(target_argument)}
	end

	-- no player found, target unknown
	if target == {} then
		print(`No target determined. Command failed.`)
		return
	end

	for _,player in target do

		if table.find(chatscribe.data.dmswitch_data,player.id) then
			continue
		end

		table.insert(chatscribe.data.dmswitch_data,player.id)
		print(`{data.sender} gave {player.name} a dead-man's switch.`)

	end

	if chatscribe.data["dmswitch_connection"] then
		return
	end

	chatscribe.data["dmswitch_connection"] = on_player_died:Connect(function(name : string, position : Vector3, killer_data : killer_data, stats_counted : boolean)

		local player = players.get(name)
		if not player then return end

		if not table.find(chatscribe.data.dmswitch_data,player.id) then
			return
		end

		table.remove(chatscribe.data.dmswitch_data,table.find(chatscribe.data.dmswitch_data,player.id))

		chat.send_announcement(`{name}'s finger slipped.`)

		time.wait(1.5)

		spawning.explosion(position)
		print(`{name}'s death triggered the explosive charge.`)

	end)

end, "Target explodes on death.")

-- ".sv sharedvar value"; ".sv sharedvar" toggles boolean variables
chatscribe:register_command("sv",function(data : chatscribe_message_data)

	local var_argument = data.message[1]

	if not sharedvars_descriptions[var_argument] then -- doesn't error if nil, unlike sharedvars[var_argument]
		print(`Sharedvar property "{var_argument}" not found. Command failed.`)
		return
	end

	print(`{data.sender} is attempting to manipulate sharedvars.{var_argument}`)

	local value_argument = data.message[2]

	-- if no value argument, toggle boolean of sharedvar if possible
	if not value_argument then

		if type(sharedvars[var_argument]) ~= "boolean" then
			print(`Property is not a boolean, and thus cannot be toggled. Command failed.`)
			return
		end

		sharedvars[var_argument] = not sharedvars[var_argument]

		print(`Property toggled. {var_argument} is {sharedvars[var_argument]}.`)
		return

	end

	print(`Checking if value argument is a boolean.`)

	-- if "true" then set var to true
	if string.lower(value_argument) == "true" then
		sharedvars[var_argument] = true
		print(`Set {var_argument} to true.`)
		return
	end

	-- if "false" then set var to false
	if string.lower(value_argument) == "false" then
		sharedvars[var_argument] = false
		print(`Set {var_argument} to false.`)
		return
	end

	-- if the value is a number and the var is a number, set the var to the value
	if tonumber(value_argument) and type(sharedvars[var_argument]) == "number" then
		sharedvars[var_argument] = tonumber(value_argument)
		print(`Set {var_argument} to {value_argument}.`)
		return
	end

	-- if the var is a string, set it to the value
	if type(sharedvars[var_argument]) == "string" then
		sharedvars[var_argument] = value_argument
		print(`Set {var_argument} to {value_argument}.`)
	end

	-- the value is a string, but the var is not. no action taken

end, "Changes the sharedvars property to the given value.")

-- ".map map_config_name"
chatscribe:register_command("map",function(data : chatscribe_message_data)

	local map_argument = data.message[1]

	if not map_argument or not table.find(chatscribe.reference_lists.maps,map_argument) then
		print(`Map "{map_argument}" not found. Command failed.`)
		return
	end

	map.set_map(map_argument)

	print(`{data.sender} set the map configuration to {map_argument}.`)

end, "Changes the map to the given configuration.")

-- ".gm gamemode" (force sets gamemode)
chatscribe:register_command("gm",function(data : chatscribe_message_data)

	local mode_argument = data.message[1]

	if not chatscribe.reference_lists.gamemodes[mode_argument] then
		print(`Gamemode "{mode_argument}" not found. Command failed.`)
		return
	end

	gamemode.force_set_gamemode(mode_argument)
	print(`{data.sender} force-set the gamemode to {mode_argument}.`)

end, "Force-sets the match to the given gamemode.")

-- ".team team"; ".team target_player team"; ".team reserved_target team"
chatscribe:register_command("team",function(data : chatscribe_message_data)

	local target_argument = data.message[1]
	local value_argument = data.message[2]

	local target = nil
	local value = nil

	-- no second argument, i.e. ".team arg1"
	if not value_argument then

		value = target_argument
		target = {players.get(data.sender)}

	else -- second argument exists, ".team arg1 arg2"

		value = value_argument
		target = chatscribe:get_reserved_target_result(target_argument,data)

	end

	-- target argument is not reserved, attempt to guess target
	if not target then

		target = {chatscribe:guess_target(target_argument)}

	end

	-- target not found OR invalid value given
	if target == {} then
		return
	end

	if not table.find(chatscribe.reference_lists.teams,value) then
		print(`Invalid team given. Command failed.`)
	end

	for _,player in target do
		player.set_team(value)
		print(`{data.sender} put {player.name} on the {value} team.`)
	end

end, "Moves the target to the given team.")

-- ".see target_table" (includes proprietary reserved targets, e.g. commands, gamemodes, map_configs)
chatscribe:register_command("see",function(data : chatscribe_message_data)

	local list_argument = data.message[1]

	if not list_argument or not chatscribe.reference_lists[list_argument] then

		print(`Invalid argument given.`)
		print(`Available reference lists include:`)
		for i,v in chatscribe.reference_lists do
			print(`	* {i}`)
		end
		print(`Type ".see (insert list here)" to view its contents.`)
		return

	end

	print(`{data.sender} requested for {list_argument} data to be displayed.`)
	print(``)
	print(`-- {string.upper(list_argument)} --`)

	for i,v in chatscribe.reference_lists[list_argument] do
		print(`	* {v}`)
	end

	print(`-- END OF {string.upper(list_argument)} --`)
	print(``)

end, "Displays the desired reference list. Useful for seeing available gamemodes, maps, and teams.")

-- ".spawn"; ".spawn target_player"; ".spawn reserved_target"
chatscribe:register_command("spawn",function(data : chatscribe_message_data)

	-- initialize target variables
	local target_argument = data.message[1]
	local target = nil

	-- if no target argument, assume sender is target
	if not target_argument then
		target = {players.get(data.sender)}
	else -- target argument given, check if reserved
		target = chatscribe:get_reserved_target_result(target_argument,data)
	end

	-- reserved-target check failed, look for player
	if not target then
		target = {chatscribe:guess_target(target_argument)}
	end

	-- no player found, target unknown
	if target == {} then
		return
	end

	for _,player in target do
		player.spawn()
		print(`{data.sender} forced {player.name} to spawn.`)
	end

end, "Force-spawns the target.")

-- ".respawn"; ".respawn target_player"; ".respawn reserved_target"
chatscribe:register_command("respawn",function(data : chatscribe_message_data)

	-- initialize target variables
	local target_argument = data.message[1]
	local target = nil

	-- if no target argument, assume sender is target
	if not target_argument then
		target = {players.get(data.sender)}
	else -- target argument given, check if reserved
		target = chatscribe:get_reserved_target_result(target_argument,data)
	end

	-- reserved-target check failed, look for player
	if not target then
		target = {chatscribe:guess_target(target_argument)}
	end

	-- no player found, target unknown
	if target == {} then
		return
	end

	for _,player in target do
		player.respawn()
		print(`{data.sender} forced {player.name} to respawn.`)
	end

end, "Respawns the target.")

-- chat handling --

-- find the requested command if it exists, and pass message data
function chatscribe:command_handler(data : chatscribe_message_data)

	local executable = self.commands[data.message[1]]
	-- verify that command exists
	if not executable then
		print(`Command "{data.message[1]}" not found.`)
		return
	end

	-- remove command-request argument from message
	table.remove(data.message,1)

	executable(data)

end

-- catches chatscribe calls, compresses message into a datatable
chat.player_chatted:Connect(function(name : string, channel : string, message : string)

	-- filter out messages without the prefix
	if string.sub(message,1,#chatscribe.prefix) ~= chatscribe.prefix then
		return
	end
	-- filter out non-whitelisted players if chatscribe.use_whitelist is true
	if not table.find(chatscribe.whitelist.userIDs,players.get(name).id) and chatscribe.use_whitelist then
		return
	end

	-- remove prefix from the message
	message = string.sub(message,#chatscribe.prefix+1,-1)
	-- split message into pieces ("hello world" -> {"hello","world"})
	local segments = string.split(message," ")

	local data : chatscribe_message_data = {

		sender = name;
		channel = channel;
		message = segments;

	}
	chatscribe:command_handler(data)

end)

-- auto-whitelist private-server owner --

if players.get(sharedvars.vip_owner) then
	table.insert(chatscribe.whitelist.userIDs,players.get(sharedvars.vip_owner).id)
	print(`Server owner ("{sharedvars.vip_owner}") was automatically whitelisted.`)
end

-- guestlist connection --

-- automatically whitelists the player if they're listed in chatscribe.whitelist.names
on_player_joined:Connect(function(name : string)

	local userID = players.get(name).id

	if not table.find(chatscribe.whitelist.names,name) or table.find(chatscribe.whitelist.userIDs,userID) then
		return
	end

	table.insert(chatscribe.whitelist.userIDs,userID)

	print(`{name} was automatically whitelisted for chatscribe commands.`)

end)

print(`chatscribe module loaded and online.`)

-- COMPONENT END --