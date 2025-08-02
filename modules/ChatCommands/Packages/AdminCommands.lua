--!strict
-- This script will run when the mod is loaded.

-- AdminCommands

type dl_Player = any
type CallArgs = {string?}
type CmdFunc = (dl_Player, CallArgs) -> ()

local debuggingEnabled = true

local function debugPrint(...): ()
	if not debuggingEnabled then return end
	print(`AdminCommands: ` .. ...)
end
debugPrint(`AdminCommands script loaded. Debugging mode is enabled.`)



set_require_domain(``)
require(`https://raw.githubusercontent.com/MiberoSIC/dl_modding/refs/heads/main/modules/ChatCommands/ChatCommands.lua`)

local Command = shared.ChatCommandsModule.Command
local ChatCommands = shared.ChatCommandsModule.ChatCommands
local AuthorityList = shared.ChatCommandsModule.AuthorityList



local KeywordTranslator = {}
do
	local keywordAlgorithms: {[string]: (caller: dl_Player) -> {dl_Player?}} = {}
	
	local function getPlayersUsingCheck(check: (plr: dl_Player) -> boolean): {dl_Player?}
		local all_players = players.get_all()
		local valid_players = {}
		for _,plr in all_players do
			if check(plr) then table.insert(valid_players, plr) end
		end
		return valid_players
	end
	
	keywordAlgorithms[`all`] = function(caller)
		return players.get_all()
	end
	keywordAlgorithms[`others`] = function(caller)
		return getPlayersUsingCheck(function(plr)
			return plr.id ~= caller.id
		end)
	end
	keywordAlgorithms[`attackers`] = function(caller)
		return getPlayersUsingCheck(function(plr)
			return plr.get_team() == `attacker`
		end)
	end
	keywordAlgorithms[`defenders`] = function(caller)
		return getPlayersUsingCheck(function(plr)
			return plr.get_team() == `defender`
		end)
	end
	keywordAlgorithms[`bots`] = function(caller)
		return getPlayersUsingCheck(function(plr)
			return plr.is_bot()
		end)
	end
	
	function KeywordTranslator.getPlayersUsingKeyword(caller: dl_Player, keyword: string?): {dl_Player?}?
		local algo = keywordAlgorithms[keyword]
		if not algo then return end
		return algo(caller)
	end
end

local NameGuesser = {}
do
	
	local function getPlayerDict(): {[string]: dl_Player}
		local dict = {}
		for _,player in players.get_all() do
			dict[player.name] = player
		end
		return dict
	end
	local function nameContainsFragment(name: string, frag: string): boolean
		return name:sub(1,#frag) == frag
	end
	local function getGuesses(fragment: string): {dl_Player?}
		local nameDict = getPlayerDict()
		local guesses: {dl_Player} = {}
		for name,player in nameDict do
			if not nameContainsFragment(name, fragment) then continue end
			table.insert(guesses, player)
		end
		return guesses
	end
	function NameGuesser.guessPlayer(fragment: string): dl_Player?
		local guesses = getGuesses(fragment)
		if #guesses ~= 1 then return end
		return guesses[1]
	end
end

local TargetCollector = {}
do
	function TargetCollector.getTargets(params: {
		caller: dl_Player;
		clue: string;
		}): {dl_Player?}
		return KeywordTranslator.getPlayersUsingKeyword(params.caller, params.clue) or {NameGuesser.guessPlayer(params.clue)}
	end
end

local function announce(...): ()
	chat.send_announcement(...)
end

--.authid userID
ChatCommands.add(
	Command.new(`authid`, function(caller: dl_Player, args: CallArgs): ()
	local userID = tonumber(args[1])
	if not userID then announce(`Provide a UserID number.`) return end
	AuthorityList.addID(userID)
end))
--.auth playerName
ChatCommands.add(
	Command.new(`auth`, function(caller: dl_Player, args: CallArgs): ()
	local player = players.get(args[1])
	if not player then announce(`Provide the name of a player.`) end
	AuthorityList.addPlayer(player)
end))

--.revokeid userID
ChatCommands.add(
	Command.new(`revokeid`, function(caller: dl_Player, args: CallArgs): ()
	local userID = tonumber(args[1])
	if not userID then announce(`Provide a UserID number.`) return end
	AuthorityList.removeByID(userID)
end))
--.revoke playerName
ChatCommands.add(
	Command.new(`revoke`, function(caller: dl_Player, args: CallArgs): ()
	local player = players.get(args[1])
	if not player then announce(`Provide the name of a player.`) end
	AuthorityList.removeByID(player.id)
	end)
)

--.kick targetClue
ChatCommands.add(
	Command.new(`kick`, function(caller: dl_Player, args: CallArgs): ()
		local targetingClue = args[1]
		if targetingClue == nil then announce(`Provide a target.`) return end
		local target = TargetCollector.getTargets({caller = caller; clue = targetingClue})
		for _,player in target do
			local name = player.name
			player.kick()
			announce(`{name} was kicked.`)
		end
	end)
)

--.kill targetClue
ChatCommands.add(
	Command.new(`kill`, function(caller: dl_Player, args: CallArgs): ()
		local clue = args[1]
		if clue == nil then return end
		local target = TargetCollector.getTargets({caller = caller; clue = clue})
		for _,plr in target do
			plr.kill()
			print(`Killed {plr.name}.`)
		end
	end)
)
