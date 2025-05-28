
-- Statistics functions for number arrays.

local function sequentialPrint(strings: {string}): ()
	for i,str in strings do
		print(i,str)
	end
end
local function fatalError(message: string): ()
	sequentialPrint({
		"dataSet FATAL ERROR!";
		message
	})
	_throwError()
end

local function isEven(num: number): boolean
	return num % 2 == 0
end

local dataSet = {}
shared.dataSet = dataSet
do
	
	function dataSet.new(array: {number})
		if #array < 2 then fatalError("Set contains less than two values.") end
		local self = {
			array = array;
		}
		setmetatable(self, {__index = dataSet})
		return self
	end
	
	function dataSet:multiply(factor: number): ()
		for i,_ in self.array do
			self.array[i] *= factor
		end
	end
	
	function dataSet:getSubset(first: number, last: number): {number}
		local subset = {}
		table.move(self.array, first, last, subset[1])
		return subset
	end
	function dataSet:getArraySortedAscending()
		local array_clone = dataSet.new(table.clone(self.array))
		table.sort(array_clone.array, function(first, second)
			return first <= second
		end)
		return array_clone
	end
	function dataSet:getArraySortedDescending()
		local array_clone = dataSet.new(table.clone(self.array))
		table.sort(array_clone.array, function(first, second)
			return first >= second
		end)
		return array_clone
	end
	
	function dataSet:getFrequencyOfNumber(target_num: number): number
		local freq = 0
		for _,num in self.array do
			if num == target_num then freq += 1 end
		end
		return freq
	end
	
	function dataSet:getLeast(): {value: number, index: number}
		local least_so_far = {value = self.array[1], index = 1}
		for i,num in self.array do
			if num < least_so_far.value then
				least_so_far.value = num
				least_so_far.index = i
			end
		end
		return least_so_far
	end
	function dataSet:getGreatest(): {value: number, index: number}
		local greatest_so_far = {value = self.array[1], index = 1}
		for i,num in self.array do
			if num > greatest_so_far.value then
				greatest_so_far.value = num
				greatest_so_far.index = i
			end
		end
		return greatest_so_far
	end
	
	function dataSet:getSum(): number
		local sum = 0
		for _,num in self.array do
			sum += num
		end
		return sum
	end
	function dataSet:getMean(): number
		return self:getSum()/#self.array
	end
	function dataSet:getMedian(): number
		local array_clone = self:getArraySortedAscending()
		local array = array_clone.array
		
		if not isEven(#array) then
			local median_index = math.ceil(#array)
			return array[median_index]
		else
			local sum_of_middle_indices = array[#array/2] + array[#array/2 + 1]
			return sum_of_middle_indices/2
		end
	end	
	function dataSet:getRange(): {min: number, max: number}
		return {min = self:getLeast().value, max = self:getGreatest().value}
	end
	-- dataSet:getMode(): {{value: number, frequency: number}}? Does not exist yet.
	
	function dataSet:getVariance(): number
		local mean = self:getMean()
		local dividend = 0
		for _,num in self.array do
			dividend += (num - mean)^2
		end
		return dividend / (#self.array-1)
	end
	function dataSet:getStDeviation(): number
		return math.sqrt(self:getVariance())
	end
	function dataSet:getZValueOfNumber(num: number): number
		return (num-self:getMean()) / self:getStDeviation()
	end
	
	function dataSet:getQ1(): number
		local sorted_set = dataSet.new(self:getArraySortedAscending())
		local median_index = (#sorted_set.array+1)/2
		local upper_index: number
		if isEven(#sorted_set.array) then
			upper_index = math.floor(median_index)
		else
			upper_index = median_index-1
		end
		
		local lower_half = dataSet.new(sorted_set:getSubset(1, upper_index))
		return lower_half:getMean()
	end
	function dataSet:getQ3(): number
		local sorted_set = dataSet.new(self:getArraySortedAscending())
		local median_index = (#sorted_set.array+1)/2
		local lower_index: number
		if isEven(#sorted_set.array) then
			lower_index = math.ceil(median_index)
		else
			lower_index = median_index+1
		end

		local upper_half = dataSet.new(sorted_set:getSubset(lower_index, #sorted_set.array))
		return upper_half:getMean()
	end
	function dataSet:getIQR(): number
		return self:getQ3()-self:getQ1()
	end
	
	function dataSet:getOutliers(): {mild: {number?}, extreme: {number?}}
		local q1, q3, iqr = self:getQ1(),self:getQ3(),self:getIQR()
		local inner_fence = {
			lower =  q1 - 1.5*iqr;
			upper = q3 + 1.5*iqr;
		}
		local outer_fence = {
			lower = q1 - 3*iqr;
			upper = q3 + 3*iqr;
		}
		local outliers = {mild = {}, extreme = {}}
		
		for _,num in self.array do
			
			if num >= inner_fence.lower and num <= inner_fence.upper then
				continue
			end
			
			if num >= outer_fence.lower and num <= inner_fence.upper then
				table.insert(outliers.mild, num)
			else
				table.insert(outliers.extreme, num)
			end
			
		end
		
		return outliers
	end
	
	
end