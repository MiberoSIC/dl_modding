
print(`lightswitch module v0.1.0`)

type LightActor = SpotLight | SurfaceLight | PointLight
local lightActors = {"SpotLight", "SurfaceLight", "PointLight"}

local function sanitizeAssetID(id: number): string
	return `rbxassetid://` .. id
end
local function getRandomItemFromArray(array: {any}): any
	if #array < 1 then fatalError("Array is empty.") return end
	if #array == 1 then return array[1] end

	local rand_index = math.random(1, #array)
	return array[rand_index]
end
local function playSoundOnInstance(parent: Instance, id: string, volume: number?): ()
	task.spawn(function()
		local sound: Sound = create_instance("Sound")
		sound.Parent = parent
		sound.Volume = volume or 1
		sound.SoundId = id
		sound.play()
	end)
end

local lightswitchInteractable = {}
do

	local COOLDOWN_SECONDS = 0.05
	local SWITCH_SFX_VOLUME = 5

	local switch_sfx: {string} = {
		9116284751;
		9116287196;
		9116286075;
		9116284763;
		9116284948;
		9116286215;
	}
	for i,id in switch_sfx do switch_sfx[i] = sanitizeAssetID(id) end

	local function isALightActor(instance: Instance): boolean
		for _,actor_type in lightActors do
			if instance.is_a(actor_type) then return true end
		end
		return false
	end

	function lightswitchInteractable.new(part: Part)
		local self = {
			part = part;
			is_on = true;
			light_actors = nil;
			last_toggle = 0;
		}
		setmetatable(self, {__index = lightswitchInteractable}) 
		self.light_actors = self:getLightActors()
		return self
	end

	function lightswitchInteractable:getLightActors(): {LightActor}
		local light_parts: {Part} = self.part.find_first_child("lights").get_children()
		local actors = {}
		for _,part in light_parts do

			for _,descendant: Instance in part.get_descendants() do
				if isALightActor(descendant) then table.insert(actors, descendant) end
			end

		end
		return actors
	end
	function lightswitchInteractable:setLightActorsEnabledTo(is_enabled: boolean): ()
		for _,actor: LightActor in self.light_actors do
			actor.Enabled = is_enabled
		end
	end

	function lightswitchInteractable:isCooledDown(): boolean
		return tick() >= self.last_toggle+COOLDOWN_SECONDS
	end

	function lightswitchInteractable:on(): ()
		self.is_on = true
		self:setLightActorsEnabledTo(true)
	end
	function lightswitchInteractable:off(): ()
		self.is_on = false
		self:setLightActorsEnabledTo(false)
	end
	function lightswitchInteractable:toggle(): ()
		self.last_toggle = tick()
		if self.is_on then
			self:off()
		else
			self:on()
		end
	end

	function lightswitchInteractable:playSwitchSFX(): ()
		local id = getRandomItemFromArray(switch_sfx)
		playSoundOnInstance(self.part, id, SWITCH_SFX_VOLUME)
	end

	function lightswitchInteractable:interact(player: dl_Player)
		if not self:isCooledDown() then return end
		self:playSwitchSFX()
		self:toggle()
	end
end
register_interactable("light_switch", lightswitchInteractable)

print(`Reload map to initialize lightswitches.`)
