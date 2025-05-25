
print(`jukebox module v0.1.0`)

---- HELPER FUNCTIONS

local function getRandomItemFromArray(array: {any}): any
	if #array < 1 then fatalError("Array is empty.") return end
	if #array == 1 then return array[1] end

	local rand_index = math.random(1, #array)
	return array[rand_index]
end
local function sanitizeAssetID(id: number): string
	return `rbxassetid://` .. id
end

local function getSongLength(id: MusicID): number
	local sound: Sound = sound.create()
	sound.SoundId = id
	local length = sound.TimeLength
	sound.destroy()
	return length
end

local function initializeSpeakerSound(speaker: Part): Sound
	local sound: Sound = create_instance("Sound")
	sound.Parent = speaker
	sound.Looped = true
	return sound
end
local function initializeSpeakers(jukebox_part: Part, sound_id: MusicID): {Sound}
	local sounds = {}
	for _,speaker in jukebox_part.find_first_child("speakers").get_children() do
		local sound = initializeSpeakerSound(speaker)
		sound.SoundId = sound_id
		table.insert(sounds, sound)
	end
	return sounds
end

----

-- Exposed methods for the autorun script and other modules.
local sharedJukebox = {}
shared.jukebox = sharedJukebox

type MusicID = string
local musicIDs = {}
do
	local music_IDs: {number} = {}
	function musicIDs.getRandomID(): string
		return getRandomItemFromArray(music_IDs)
	end

	function sharedJukebox.addMusicIDs(IDs: {string | number})
		for _,id in IDs do
			if type(id) == "number" then id = sanitizeAssetID(id) end
			table.insert(music_IDs, id)
		end
	end
end

local jukeboxInteractable = {}
do
	
	function jukeboxInteractable.new(part: Part)
		local self = {
			part = part;
			sound_id = musicIDs.getRandomID();
			is_playing = false;
		}
		self.sounds = initializeSpeakers(self.part, self.sound_id)

		setmetatable(self, {__index = jukeboxInteractable})

		return self
	end

	function jukeboxInteractable:setVolume(new_vol: number): ()
		for _,sound: Sound in self.sounds do
			sound.Volume = new_vol
		end
	end

	function jukeboxInteractable:randomizeSoundID(): ()
		self.sound_id = musicIDs.getRandomID()
	end

	function jukeboxInteractable:spawnSongQueueThread(): ()
		self.queue_thread = task.spawn(function()
			print(`Spawning a new song-queue thread.`)
			task.wait(getSongLength(self.sound_id))
			self:randomizeSoundID()
			self:play()
		end)
	end
	function jukeboxInteractable:killSongQueueThread(): ()
		if not self.queue_thread then
			print(`Attempted to kill song-queue thread, but no thread found.`)
			return
		end

		print(`Killing song-queue thread.`)
		task.cancel(self.queue_thread)
		self.queue_thread = nil
	end

	function jukeboxInteractable:play(): ()
		print(`Playing music from the jukebox.`)
		self.is_playing = true
		self:spawnSongQueueThread()
		for _,sound in self.sounds do
			sound.SoundId = self.sound_id
			sound.play()
		end
	end
	function jukeboxInteractable:stop(): ()
		print(`Stopping the jukebox.`)
		self.is_playing = false
		self:killSongQueueThread()
		for _,sound in self.sounds do
			sound.stop()
		end
	end

	function jukeboxInteractable:interact(player: dl_Player): ()
		if self.is_playing then
			self:stop()
		else
			self:play()
		end
	end

end
register_interactable("jukebox", jukeboxInteractable)

print(`Reload map to initialize jukeboxes.`)
