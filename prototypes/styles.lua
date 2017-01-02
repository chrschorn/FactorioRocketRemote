data:extend(
    {
        {
            type = "font",
            name = "rr-normal",
            from = "default",
            border = false,
            size = 15
        },
        {
            type = "font",
            name = "rr-bold",
            from = "default-bold",
            border = false,
            size = 15
        }
    }
)


local default_gui = data.raw["gui-style"].default

default_gui.rr_frame_style = 
{
	type="frame_style",
	parent="frame_style",
	font="rr-bold",
	top_padding = 10,
	right_padding = 10,
	bottom_padding = 10,
	left_padding = 10,
	resize_row_to_width = true,
	resize_to_row_height = false,
	max_on_row = 1,
}

default_gui.rr_label_style =
{
    type = "label_style",
    font = "rr-normal",
}

default_gui.rr_label_style_bold =
{
    type = "label_style",
    font = "rr-bold",
}

default_gui.rr_button_style = 
{
    type = "button_style",
    parent = "button_style",
    font = "rr-normal"
}

default_gui.rr_checkbox_style =
{
    type = "checkbox_style",
    parent = "checkbox_style",
    font = "rr-normal"
}
