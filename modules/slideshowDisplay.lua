
print(`slideshowDisplay module v0.1.0`)

type SlideImageID = string
type SlideshowData = {
	seconds_per_slide: number;
	slides: {SlideImageID};
}

local function initializeDecal(part: Part): Decal
	local decal: Decal = create_instance("Decal")
	decal.Parent = part
	decal.Name = "decal"
	decal.Face = Enum.NormalId.Front
	return decal
end

local sharedSlideshowDisplay = {}
shared.slideshowDisplay = sharedSlideshowDisplay

local slideshowPatterns = {}
do
	local patterns: {[string]: SlideshowData} = {}
	function slideshowPatterns.getPattern(key: string)
		return patterns[key] or fatalError(`Pattern "{key}" not found.`)
	end
	
	function sharedSlideshowDisplay.registerPattern(key: string, data: SlideshowData)
		patterns[key] = data
	end
	
end

local slideshowDisplay = {}
do

	function slideshowDisplay.new(part: Part, pattern: string)
		local self = {
			part = part;
			pattern = slideshowPatterns.getPattern(pattern);
		}
		setmetatable(self, {__index = slideshowDisplay})

		self.decal = initializeDecal(self.part)
		self:initializeSlideshowThread()

		return self
	end

	function slideshowDisplay:setDecalTexture(id: SlideImageID): ()
		self.decal.Texture = id
	end

	function slideshowDisplay:initializeSlideshowThread(): ()
		local pattern: SlideshowData = self.pattern
		local current_slide_index = 1
		self.slideshow_thread = task.spawn(function()
			while true do
				self:setDecalTexture(pattern.slides[current_slide_index])
				task.wait(pattern.seconds_per_slide)

				if current_slide_index >= #pattern.slides then
					current_slide_index = 1
				else
					current_slide_index += 1
				end
			end

		end)
	end

end
function sharedSlideshowDisplay.initializeSlideshowDisplays(): ()
	for _,part in tags.get_tagged("slideshow_displays_folder")[1].get_children() do
		local pattern = part.get_attribute("slideshow_pattern")
		slideshowDisplay.new(part, pattern)
	end
end

print(`Initialize displays after map is loaded.`)
