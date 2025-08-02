--!strict
-- This script will run when the mod is loaded.

--[[
ChatCommands, in chronological order of call handling:
* Listener
* Executor
* Parser
* Index of Commands
* Command
--]]

type dl_Player = any
type CallArgs = {string?}
type CmdFunc = (dl_Player, CallArgs) -> ()
type CmdID = string
type CmdObj = any
type ParsedCall = {identifier: CmdID, args: CallArgs}
type UserID = number
type UserIDString = string
type AuthStatus = boolean

local debuggingEnabled = true

local function debugPrint(value: any): ()
	if not debuggingEnabled then return end
	print(`ChatCommands: ` .. value)
end
debugPrint(`ChatCommands script loaded. Debugging mode is enabled.`)

local Command = {}
do
	function Command.new(identifier: CmdID, func: CmdFunc): CmdObj
		local obj = {
			identifier = identifier;
			func = func;
		}
		setmetatable(obj, {__index = Command})
		return obj
	end
	
	function Command:execute(caller: dl_Player, args: CallArgs): ()
		self.func(caller, args)
	end
end

local ChatCommands = {}
do
	local commands: {[CmdID]: CmdObj} = {}
	function ChatCommands.add(cmd: CmdObj): ()
		commands[cmd.identifier] = cmd
		debugPrint(`Added command under identifier: {cmd.identifier}`)
	end
	function ChatCommands.remove(id: CmdID): ()
		commands[id] = nil
		debugPrint(`Removed command under identifier: {id}`)
	end
	function ChatCommands.get(id: CmdID): CmdObj?
		return commands[id]
	end
end

local CallParser = {}
do
	local function splitCall(str: string): {string}
		return str:split(` `)
	end
	local function getIdentifier(arr: {string}): CmdID
		return arr[1]
	end
	local function collectArgs(arr: {string}): CallArgs
		local args = {}
		for i,str in arr do
			if i == 1 then continue end
			table.insert(args, str)
		end
		return args
	end
	
	function CallParser.parse(call: string): ParsedCall
		debugPrint(`Parsing call: {call}`)
		local segments = splitCall(call)
		
		return {
			identifier = getIdentifier(segments);
			args = collectArgs(segments);
		}
	end
end

local AuthorityList = {}
do
	-- IDs are stored as strings to allow for iterating over the authIDs list.
	local authIDs: {[UserIDString]: AuthStatus} = {}
	function AuthorityList.addID(id: UserID): ()
		authIDs[tostring(id)] = true
		debugPrint(`Authorized ID:{id}`)
	end
	function AuthorityList.addPlayer(player: dl_Player): ()
		debugPrint(`Authorizing player {player.name}.`)
		AuthorityList.addID(player.id)
	end
	function AuthorityList.removeByID(id: UserID)
		authIDs[tostring(id)] = nil
		debugPrint(`Revoked authority from ID:{id}`)
	end
	function AuthorityList.playerIsAuthorized(player: dl_Player): boolean
		return authIDs[tostring(player.id)] == true
	end
end
 
local CallExecutor = {}
do
	local function getCommand(id: CmdID): CmdObj?
		return ChatCommands.get(id)
	end
	local function safeExecuteCommand(caller: dl_Player, callData: {
		cmd: CmdObj?;
		args: CallArgs;
		}): ()
		if not callData.cmd then debugPrint(`Could not execute command; command not found.`) return end
		
		debugPrint(`Executing command from {caller.name}, passing the given arguments:`)
		debugPrint(`\{`)
		for i,v in callData.args do
			debugPrint(`{i}: {v}`)
		end
		debugPrint(`\}`)
		
		callData.cmd:execute(caller, callData.args)
	end
	
	function CallExecutor.resolveCall(caller: dl_Player, call: string): ()
		local parsedCall = CallParser.parse(call)
		local cmd = getCommand(parsedCall.identifier)
		safeExecuteCommand(caller, {cmd = cmd; args = parsedCall.args})
		debugPrint(`Executor resolved call.`)
	end
end

local ChatListener = {}
do
	local CALL_PREFIX = `.`
	local listenerConn: RBXScriptConnection? = nil
	
	local function hasPrefix(str: string): boolean
		return str:sub(1,#CALL_PREFIX) == CALL_PREFIX
	end
	local function removePrefix(str: string): string
		return str:sub(#CALL_PREFIX+1,-1)
	end
	local function processMessage(sender: dl_Player, message: string): ()
		if not hasPrefix(message) then
			debugPrint(`Message ignored; Prefix not found.`)
			return
		end
		if not AuthorityList.playerIsAuthorized(sender) then
			debugPrint(`Command denied; {sender.name} is not authorized for commands.`)
			return
		end
		
		local call = removePrefix(message)
		CallExecutor.resolveCall(sender, call)
	end
	local function initializeConnection(): ()
		debugPrint(`Listener-connection initializing.`)
		listenerConn = chat.player_chatted:Connect(function(sender: string, channel: string, content: string)
			sender = players.get(sender)
			processMessage(sender, content)
		end)
	end
	
	function ChatListener.enable(): ()
		if listenerConn then return end
		initializeConnection()
		debugPrint(`Listener enabled.`)
	end
	function ChatListener.disable(): ()
		if listenerConn == nil then
			return
		else
			listenerConn:Disconnect()
			listenerConn = nil
			debugPrint(`Disabled listener.`)
		end
	end
	
end

shared.ChatCommandsModule = {
	Command = Command;
	ChatCommands = ChatCommands;
	CallParser = CallParser;
	AuthorityList = AuthorityList;
	CallExecutor = CallExecutor;
	ChatListener = ChatListener;
}
function shared.ChatCommandsModule.setDebuggingState(state: boolean): ()
	if state == nil then return end
	debuggingEnabled = state
end

AuthorityList.addID(3401131717) -- Ralephis
ChatListener.enable()
