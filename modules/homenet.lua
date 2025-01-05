
-- homenet v0.1.0
-- By: Ralephis (mibero_)

-- COMPONENT: HOMENET INTERNAL SIGNALS MODULE --

-- homenet object
homenet = {}

function homenet.new()
	
	-- signal object to be returned
	local signal = {
		bindings = {};
	}

	-- calls all bound functions, passing the given arguments
	function signal:fire(...)
		for _,exe in self.bindings do
			exe(...)
		end
	end

	-- lists the given function as a binding of the signal, returns a binding object
	function signal:bind(executable : (...any) -> ())

		table.insert(self.bindings,executable)

		-- stores signal and bind indicator
		local binding = {
			is_bound = true;
			signal = self;
		}
		-- destroys the binding, is_bound = false
		function binding:unbind()

			self.is_bound = false
			for i,exe in self.signal.bindings do
				if exe ~= executable then
					continue
				end

				self.signal.bindings[i] = nil
				return

			end

		end

		return binding

	end

	return signal
	
end

print("homenet module loaded and online.")

-- COMPONENT END --

--[[ overview of module functionality

* creates a signal object
local sig = homenet.new()

* binds the given function to the signal, returns a binding object
local sig_conn = sig:bind(function(text)
	print(text)
end)

local sig_check = sig:bind(function()
	print("Fired!")
end)

* when the signal is fired, given arguments are passed to all bound functions
sig:fire("Hello!") -- "Hello!" "Fired!"

* unbinds a binding object
sig_conn:unbind()
print(sig_conn.is_bound) -- "false"

sig:fire() -- "Fired!"

--]]