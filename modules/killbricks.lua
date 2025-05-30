
-- killbricks
local _killbricks_version = "0.1.1"
-- Made by Ralephis (@mibero_)

-- Killbricks are made invisible upon enabling.

local function sequentialPrint(strings: {string}): ()
	for _,str in strings do
		print(str)
	end
end
local function fatalError(message: string): ()
	sequentialPrint({
		"killbricks ERROR!";
		message;
	})
	_throwWaterOnServers() -- Undefined on purpose.
end

sequentialPrint({
	`Loading killbricks module... ({_killbricks_version})`;
	"Made by Ralephis (@mibero_)";
	"";
	"Refer to the killbricks folder as an example of how killbricks should look in your map.";
	`Run shared.killbricks.enable() after loading your map to enable killbricks.`;
	"";
})

local killbricks = {}
shared.killbricks = killbricks
do
	
	local killmessage_chance = 0.4
	local seconds_per_killbrick_check = 1
	local killbrick_folder_tag = "killbrick_folder" -- Ensure that the folder has this tag.
	
	
	
	-- "_user" will be replaced with the player's name.
	-- Ex. "_user was killed" -> "awesomeJon61 was killed"
	local killbrick_messages: {string} = {}

	local function getRandomItemFromArray(arr: {any}): any
		local rand_index = math.random(1, #arr)
		return arr[rand_index]
	end

	local function isPlayerInsidePart(player, part: Part): boolean
		local plr_pos: Vector3 = player.get_position()
		local plr_deviation = part.CFrame:PointToObjectSpace(plr_pos):Abs()
		local part_size = part.Size

		return 		plr_deviation.X <= part.Size.X/2
			and		plr_deviation.Y <= part.Size.Y/2
			and		plr_deviation.Z <= part.Size.Z/2
	end

	local function makePartsInvisible(parts: {Part}): ()
		for _,part in parts do
			part.Transparency = 1
		end
	end

	local function getKillbricks(): {Part?}
		local bricks = tags.get_tagged(killbrick_folder_tag)[1].get_children()
		makePartsInvisible(bricks)
		return bricks
	end

	local function sendKillbrickMessage(plr_name: string): ()
		local message = string.gsub(getRandomItemFromArray(killbrick_messages), "_user", plr_name)
		if not message then
			fatalError("Could not get kill-message.")
		end
		chat.send_announcement(message)
	end

	local function testChances(chance_of_success: number): boolean
		return math.random(0,1000) <= chance_of_success*1000
	end

	local function killPlayerViaKillbrick(player): ()
		player.kill()
		if #killbrick_messages > 0 and testChances(killmessage_chance) then
			sendKillbrickMessage(player.name)
		end
	end

	local killbrick_thread: thread = nil
	local function killKillbrickThread(): ()
		if not killbrick_thread then return end
		task.cancel(killbrick_thread)
		killbrick_thread = nil
	end
	local function spawnKillbrickThread(): ()
		local killbricks = getKillbricks()
		if #killbricks < 1 then
			warn("Could not enable killbricks; no killbricks found.")
			return
		end

		killKillbrickThread()
		local new_killbrick_thread = task.spawn(function()


			while task.wait(seconds_per_killbrick_check) do
				for _,player in players.get_alive() do

					for _,brick in killbricks do
						if isPlayerInsidePart(player, brick) then
							killPlayerViaKillbrick(player)
							break
						end
					end

				end
			end

		end)
		killbrick_thread = new_killbrick_thread

	end

	function killbricks.addKillMessages(new_messages: {string}): ()
		for _,str in new_messages do
			table.insert(killbrick_messages, str)
		end
	end

	function killbricks.setKillMessageChance(chance: number): ()
		killmessage_chance = math.clamp(chance,0,1)
		print(`Kill-message chances updated. {killmessage_chance*100}% chance of a killbrick death message.`)
	end

	function killbricks.enable()
		spawnKillbrickThread()
		print("Killbricks enabled.")
	end
	function killbricks.disable()
		killKillbrickThread()
		print("Killbricks disabled.")
	end
end

print("killbricks module loaded.")
