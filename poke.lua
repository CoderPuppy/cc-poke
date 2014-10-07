local config
do
	local path = fs.combine(shell.getRunningProgram(), '../config.lua')
	local fn, err = loadfile(path)
	if fn then
		config = fn()
	else
		error(err, 0)
	end

	for name, mode in pairs(config.modes) do
		if name ~= 'default' then
			if type(mode) ~= 'table' then error('invalid mode: ' .. tostring(name) .. ' expected: table, got: ' .. tostring(mode), 0) end
			if type(mode.features) ~= 'table' then mode.features = {} end
			mode.name = name
		end
	end
end

local function child(v, cache)
	cache = type(cache) == 'table' and setmetatable({}, {__index = cache}) or {}
	if type(v) == 'table' then
		local res = setmetatable({}, {__index = v})
		cache[v] = res
		for k, v in pairs(v) do
			if type(v) == 'table' then
				if cache[v] then
					res[k] = cache[v]
				else
					res[k] = child(v, cache)
				end
			end
		end
		return res
	else
		return v
	end
end

local function new(config)
	local poke; poke = {
		style = setmetatable({
			use = function(self, name)
				if not config.styles[name] then error('no style named: ' .. tostring(name), 2) end
				poke.state.style = config.styles[name]
				poke.state.styleName = name
				return self
			end;

			get = function(self, id, prop)
				local obj = poke.state.style[id]

				local styleName = tostring(poke.state.styleName)
				local idStr = tostring(id)
				local propStr = tostring(prop)

				if not obj then
					error(styleName .. ' doesn\'t have a value for ' .. idStr, 2)
				end

				if obj[prop] then
					return obj[prop]
				elseif obj.extends then
					local extends = tostring(obj.extends)
					local ok, res = pcall(self.get, self, obj.extends, prop)
					if ok then
						return res
					elseif res == (styleName .. 'doesn\'t have a value for ' .. propStr .. ' for ' .. extends) then
						error(styleName .. ' doesn\'t have a value for ' .. propStr .. ' for ' .. idStr, 2)
					else
						error(res)
					end
				else
					error(styleName .. ' doesn\'t have a value for ' .. propStr .. ' for ' .. idStr, 2)
				end
			end;
		}, {
			__call = function(self, ...)
				local args = {...}
				if #args == 1 then
					local fg = self:get(args[1], 'fg')
					if fg ~= self.fg then
						term.setTextColor(fg)
						self.fg = fg
					end

					local bg = self:get(args[1], 'bg')
					if bg ~= self.bg then
						term.setBackgroundColor(bg)
						self.bg = bg
					end
				elseif #args == 2 then
					return self:get(args[1], args[2])
				else
					error('what are you trying to do?', 2)
				end
			end;
		});

		old = {};
		state = {};
		redraw = function(self, force)
			if self.state.x ~= self.old.x or self.state.y ~= self.old.y or self.state.width ~= self.old.width or self.state.height ~= self.old.height then
				force = true
			end

			if self.state.style ~= self.old.style then
				force = true
			end

			self.state.tab:bounds(self.state.x, self.state.y, self.state.width, self.state.height - 1)
			self.state.tab:redraw(self.state.tab ~= self.old.tab and true or force)

			self.statusBar:bounds(self.state.x, self.state.y + self.state.height, self.state.width)
			self.statusBar:redraw(force)

			self.old = self.state
			self.state = child(self.old)
		end;
		bounds = function(self, x, y, width, height)
			self.state.x = x
			self.state.y = y
			self.state.width  = width
			self.state.height = height
		end;

		statusBar = {
			old = {};
			state = {};
			redraw = function(self, force)
				if self.state.x ~= self.old.x or self.state.y ~= self.old.y or self.state.width ~= self.old.width then
					force = true
				end

				poke.style('statusbar')
				term.write(string.rep(' ', self.state.width))
				
				self.old = self.state
				self.state = child(self.old)
			end;
			bounds = function(self, x, y, width)
				self.state.x = x
				self.state.y = y
				self.state.width = width
			end;
		};

		panes = {
			new = function(self)
				local pane; pane = {
					id = #self + 1;

					old = {text = {};};
					state = {
						text = {''};
					};
					redraw = function(self, force)
						if self.state.x ~= self.old.x or self.state.y ~= self.old.y or self.state.width ~= self.old.width or self.state.height ~= self.old.height then
							force = true
						end

						for i = 1, self.state.height do
							if force or self.state.text[i] ~= self.old.text[i] then
								term.setCursorPos(self.state.x, self.state.y + i - 1)
								local gutter = ''
								local gutterStyle = 'gutter'
								local code = ''
								local codeStyle = 'code'

								if self.state.text[i] then
									gutter = '  ' .. (i - 1) .. ' '
									gutterStyle = 'gutter:number'
									code = self.state.text[i]
									codeStyle = 'code:plain'
								else
									gutter = poke.style('gutter:noline', 'text')
								end

								poke.style(gutterStyle)
								term.write(gutter)
								poke.style(codeStyle)
								term.write(code)
								term.write(string.rep(' ', self.state.width - #code - #gutter))
							end
						end

						self.old = self.state
						self.state = child(self.old)
					end;
					bounds = function(self, x, y, width, height)
						self.state.x = x
						self.state.y = y
						self.state.width  = width
						self.state.height = height
					end;
				}
				self[pane.id] = pane
				return pane
			end;
		};

		tabs = {
			new = function(self)
				local tab = {
					id = #self + 1;

					old = {};
					state = {
						child = poke.panes:new();
					};
					redraw = function(self, force)
						if self.state.x ~= self.old.x or self.state.y ~= self.old.y or self.state.width ~= self.old.width or self.state.height ~= self.old.height then
							force = true
						end

						self.state.child.state.parent = self
						self.state.child:bounds(self.state.x, self.state.y, self.state.width, self.state.height)
						self.state.child:redraw(self.state.child ~= self.old.child and true or force)

						self.old = self.state
						self.state = child(self.old)
					end;
					bounds = function(self, x, y, width, height)
						self.state.x = x
						self.state.y = y
						self.state.width  = width
						self.state.height = height
					end;
				};
				self[tab.id] = tab
				return tab
			end;
		};
	}
	poke.style:use(config.styles.default)
	poke.state.tab = poke.tabs:new()
	return poke
end

local poke = new(config)

poke:bounds(1, 1, term.getSize())
term.clear()
poke:redraw(true)
sleep(0.5)