do
	local styles = {
		{
			type = "frame_style",
			name = "robotarmy_command_palette",
			minimal_width = 192,
			maximal_width = 192,
			top_padding = 8,
			bottom_padding = 8,
			left_padding = 8,
			right_padding = 8,
		},
		{
			type = "horizontal_flow_style",
			name = "robotarmy_command_information",
			horizontal_spacing = 8,
			vertical_spacing = 2,
			max_on_row = 2,
			resize_row_to_width = true,
			resize_to_row_height = true,
			top_padding = 0,
			bottom_padding = 0,
			left_padding = 0,
			right_padding = 0,
			maximal_width = 192,
		},
		{
			type = "horizontal_flow_style",
			name = "robotarmy_command_palette_buttons",
			horizontal_spacing = 8,
			vertical_spacing = 8,
			max_on_row = 4,
			resize_to_row_height = true,
			top_padding = 0,
			bottom_padding = 0,
			left_padding = 0,
			right_padding = 0,
			maximal_width = 192,
		},
		{
			type = "button_style",
			name = "robotarmy_command_button",
			scalable = false,
			top_padding = 0,
			bottom_padding = 0,
			left_padding = 0,
			right_padding = 0,
			width = 32+3+3,
			height = 32+3+3,
			default_graphical_set = {
				type = "composition",
				filename = "__core__/graphics/gui.png",
				priority = "extra-high-no-scale",
				corner_size = {3, 3},
				position = {8, 0}
			}
		},
		{
			type = "label_style",
			name = "robotarmy_command_label",
			font = "default-bold",
			width = (192 / 2) - 16,
			single_line = true,
		},
		{
			type = "label_style",
			name = "robotarmy_command_data",
			font = "default",
			width = (192 / 2) - 16,
			align = "right",
			single_line = true,
		},
	}
	for _, s in next, styles do
		local n = s.name
		s.name = nil
		_G.data.raw["gui-style"].default[n] = s
	end
end
