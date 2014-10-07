return {
	modes = {
		normal = {};
		insert = {
			features = {
				typing = true;
			};
		};
		visual = {
			features = {
				displaySelection = true;
				select = '1d';
			};
		};
		visualBlock = {
			features = {
				displaySelection = true;
				select = '2d';
			};
		};
		visualLine = {
			features = {
				displaySelection = true;
				select = 'line';
			};
		};

		default = 'normal';
	};

	actions = {
		['switch-mode'] = function(poke, mode)
			poke.mode = poke.config.modes[mode]
		end;
	};

	input = {
		{
			match = 'i';
			mode = {'normal'};
			action = {'switch-mode', 'insert'};
		};

		{
			match = 'ESC';
			action = {'switch-mode', 'normal'};
		};
	};

	styles = {
		dark = {
			['app'] = {
				fg = colors.white;
				bg = colors.brown;
			};
			['statusbar'] = {
				extends = 'app';
			};

			['code'] = {
				extends = 'app';
			};
			['code:plain'] = {
				extends = 'code';
			};

			['gutter'] = {
				extends = 'app';
			};
			['gutter:noline'] = {
				extends = 'gutter';
				text = '~';
			};
			['gutter:number'] = {
				extends = 'gutter';
			};
		};

		default = 'dark';
	};
}