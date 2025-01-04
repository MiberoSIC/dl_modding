
-- works

print("I run immediately.")

local chatscribe = {}

chatscribe.property = "I'm a property."

function chatscribe:print_property()

	print("I'm a method printing a property.")
	print(self.property)

end

chatscribe:print_property()

function shared.test_print()
	print("I was initialized in chatscribe.")
end