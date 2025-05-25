
print(`artPiece module v0.1.0`)

local function sanitizeAssetID(id: number): string
	return `rbxassetid://` .. id
end
local function getRandomItemFromArray(array: {any}): any
	if #array < 1 then fatalError("Array is empty.") return end
	if #array == 1 then return array[1] end

	local rand_index = math.random(1, #array)
	return array[rand_index]
end
local function initializeDecal(part: Part): Decal
	local decal: Decal = create_instance("Decal")
	decal.Parent = part
	decal.Name = "decal"
	decal.Face = Enum.NormalId.Front
	return decal
end

local sharedArtPiece = {}
shared.artPiece = sharedArtPiece

type ArtImageID = string
local artImageIDs = {}
do
	local image_IDs: {ArtImageID} = {
		11818627057;
		11176073563;
		811793373;
		8373881910;
		122089686877068;
	}
	for i,num_id in image_IDs do
		image_IDs[i] = sanitizeAssetID(num_id)
	end

	function artImageIDs.isIDCached(id: string): boolean
		if table.find(image_IDs, id) then return true else return false end
	end

	function artImageIDs.removeID(id: string): ()
		local index = table.find(image_IDs, id)
		table.remove(image_IDs, index)
	end

	function artImageIDs.addID(id: string): ()
		table.insert(image_IDs, id)
	end

	function artImageIDs.getRandomID(): ArtImageID
		return getRandomItemFromArray(image_IDs)
	end

end

local artPiece = {}
do

	function artPiece.new(data: {
		part: Part;
		image_ID: ArtImageID?;
		})
		print(`Initializing art piece.`)
		local self = {
			part = data.part;
			decal = initializeDecal(data.part);
		}
		setmetatable(self, {__index = artPiece})

		self:setImage(data.image_ID or artImageIDs.getRandomID())

		return self
	end

	function artPiece:setImage(image_ID: ArtImageID): ()
		self.decal.Texture = image_ID
		print(`Set decal textureID to {self.decal.Texture}`)
	end

end
function sharedArtPiece.initializeArtPieces(): ()
	local tagged_parts: {Part?} = tags.get_tagged("art_piece")
	if #tagged_parts > 0 then print(`Tagged instances detected.`) end
	for _,part in tagged_parts do
		artPiece.new({
			part = part;
			image_ID = part.get_attribute("image_ID");
		})
	end
end

print(`Initialize art pieces after map is loaded.`)
