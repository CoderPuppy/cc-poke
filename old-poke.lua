local state = {
	mode = data.modes[data.modes.default];
	tabs = {
		new = function(self)
			local tab = {
				id = #self;
			}
			self[#self + 1] = tab
			return tab
		end;
		switch = function(self, tab)
			self.current = tab
			return self
		end;
	};
}
state.tabs:switch(state.tabs:new())

local ui = {
	style = setmetatable({
		current = {};
		currentName = '<none>';

		get = function(self, id, prop)
			local obj = self.current[id]

			if not obj then
				error(tostring(self.currentName) .. ' doesn\'t have a value for ' .. tostring(id), 2)
			end

			if obj[prop] then
				return obj[prop]
			elseif obj.extends then
				return self:get(obj.extends, prop)
			else
				error(tostring(self.currentName) .. ' doesn\'t have a value for ' .. tostring(prop) .. ' for ' .. tostring(id), 2)
			end
		end;

		use = function(self, name)
			local option = data.styles[name]
			if type(option) ~= 'table' then error('no such style: ' .. tostring(name), 0) end
			self.current = option
			self.currentName = name
			return self, option
		end;
	}, {
		__call = function(self, ...)
			local args = {...}
			if #args == 1 then
				return select(2, self:use(args[1]))
			elseif #args == 2 then
				return self:get(args[1], args[2])
			else
				error('Expected string or string, string, got: ' .. textutils.serialize(args), 2)
			end
		end;
	});

	resize = function(self, width, height)
		self.width, self.height = width, height
	end;
	redraw = function(self)
		term.setBackgroundColor(self.style('code', 'bg'))
		term.clear()

		term.setCursorPos(1, self.height)
		term.setBackgroundColor(self.style('statusbar', 'bg'))
		term.write(string.rep(' ', self.width))
	end;
}

ui.style(data.styles.default)
ui:resize(term.getSize())
ui:redraw()

while true do
	local ev = {os.pullEvent()}
	print(textutils.serialize(ev))
end