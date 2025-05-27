
-- Utility functions for number arrays.

local function sequentialPrint(strings: {string}): ()
	for i,str in strings do
		print(i,str)
	end
end
local function fatalError(message: string): ()
	sequentialPrint({
		"numArray FATAL ERROR!";
		message
	})
	_throwError()
end

local numArray = {}
shared.numArray = numArray
do
	
	function numArray.new(array: {number})
		local self = {
			array = array;
		}
		setmetatable(self, {__index = numArray})
		return self
	end
	
	function numArray:multiply(factor: number): ()
		for i,_ in self.array do
			self.array[i] *= factor
		end
	end
	
	function numArray:getArraySortedAscending()
		local array_clone = numArray.new(table.clone(self.array))
		table.sort(array_clone.array, function(first, second)
			return first <= second
		end)
		return array_clone
	end
	function numArray:getArraySortedDescending()
		local array_clone = numArray.new(table.clone(self.array))
		table.sort(array_clone.array, function(first, second)
			return first >= second
		end)
		return array_clone
	end
	
	function numArray:getFrequencyOfNumber(target_num: number): number
		local freq = 0
		for _,num in self.array do
			if num == target_num then freq += 1 end
		end
		return freq
	end
	
	function numArray:getLeast(): {value: number, index: number}
		local least_so_far = {value = self.array[1], index = 1}
		for i,num in self.array do
			if num < least_so_far.value then
				least_so_far.value = num
				least_so_far.index = i
			end
		end
		return least_so_far
	end
	function numArray:getGreatest(): {value: number, index: number}
		local greatest_so_far = {value = self.array[1], index = 1}
		for i,num in self.array do
			if num > greatest_so_far.value then
				greatest_so_far.value = num
				greatest_so_far.index = i
			end
		end
		return greatest_so_far
	end
	
	function numArray:getSum(): number
		local sum = 0
		for _,num in self.array do
			sum += num
		end
		return sum
	end
	function numArray:getMean(): number
		return self:getSum()/#self.array
	end
	function numArray:getMedian(): number
		local array_clone = self:getArraySortedAscending()
		local array = array_clone.array
		
		if #array % 2 ~= 0 then -- if #array is odd:
			local median_index = math.ceil(#array)
			return array[median_index]
		else -- #array is even:
			local sum_of_middle_indices = array[#array/2] + array[#array/2 + 1]
			return sum_of_middle_indices/2
		end
	end	
	function numArray:getRange(): {min: number, max: number}
		return {min = self:getLeast().value, max = self:getGreatest().value}
	end
	-- numArray:getMode(): {{value: number, frequency: number}}? Does not exist yet.
	
end
