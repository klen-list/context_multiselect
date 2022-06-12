-- By Klen_list

local curselect = {}

local cvar_selection_color = CreateConVar("multiselection_color", "43 156 248 255", FCVAR_ARCHIVE, "Sets the color of context menu multi select halo (RGBA)")

local function GetColorFromStr(str)
	local r, g, b, a = string.match(str, "(%d+)% (%d+)% (%d+)% *(%d*)")
	if r and g and b then
		return Color(r, g, b, a)
	end
	return Color(43, 156, 248)
end

local selection_color = GetColorFromStr(cvar_selection_color:GetString())

cvars.AddChangeCallback("multiselection_color", function(_, __, new)
	selection_color = GetColorFromStr(new)
end, "update_color")

hook.Add("PlayerBindPress", "ContextMultiSelect_BlockCtrl", function(_, __, pressed, code)
	if g_ContextMenu:IsVisible() and code == KEY_LCONTROL and pressed then return true end
end)

hook.Remove("CreateMove", "ContextMultiSelect_DisableDuck")

hook.Add("PreDrawHalos", "ContextMultiSelect_DrawCurrent", function()
	halo.Add(curselect, selection_color, 4 + math.sin(RealTime() * 20), 4 + math.sin(RealTime() * 20), 2)
end)

hook.Add("OnContextMenuClose", "ContextMultiSelect_ClearCurrent", function() table.Empty(curselect) end)

local function AddToggleOption(data, menu, ent, ply, tr)
	if not menu.ToggleSpacer then
		menu.ToggleSpacer = menu:AddSpacer()
		menu.ToggleSpacer:SetZPos(500)
	end
	local option = menu:AddOption(data.MenuLabel, function()
		if table.IsEmpty(curselect) then
			data:Action(ent, tr)
		else
			for i, sel_ent in ipairs(curselect) do
				data:Action(sel_ent, tr)
			end
		end
	end)
	local checked = false
	if table.IsEmpty(curselect) then
		checked = data:Checked(ent, ply)
	else
		for i, sel_ent in ipairs(curselect) do
			checked = data:Checked(sel_ent, ply)
			if not checked then break end
		end
	end
	option:SetChecked(checked)
	option:SetZPos(501)
	return option
end

local function AddOption( data, menu, ent, ply, tr )
	if data.Type == "toggle" then return AddToggleOption(data, menu, ent, ply, tr) end
	if data.PrependSpacer then
		menu:AddSpacer()
	end
	local option = menu:AddOption(data.MenuLabel, function()
		if table.IsEmpty(curselect) then
			data:Action(ent, tr)
		else
			for i, sel_ent in ipairs(curselect) do
				data:Action(sel_ent, tr)
			end
		end
	end)
	if data.MenuIcon then
		option:SetImage(data.MenuIcon)
	end
	if data.MenuOpen then
		data.MenuOpen(data, option, ent, tr)
	end
	return option
end

function properties.OpenEntityMenu(ent, tr)
	local menu = DermaMenu()
	for k, v in SortedPairsByMemberValue(properties.List, "Order") do
		if not v.Filter then continue end
		if table.IsEmpty(curselect) then
			if not v:Filter(ent, LocalPlayer()) then continue end
		else
			local skip = false
			for i, sel_ent in ipairs(curselect) do
				if not v:Filter(sel_ent, LocalPlayer()) then skip = true break end
			end
			if skip then continue end
		end
		local option = AddOption(v, menu, ent, LocalPlayer(), tr)
		if v.OnCreate then v:OnCreate(menu, option) end
	end
	menu:Open()
end

g_original_context_hook = g_original_context_hook or hook.GetTable()["GUIMousePressed"]["PropertiesClick"]
hook.Add("GUIMousePressed", "PropertiesClick", function(code, vec)
	if not g_ContextMenu:IsVisible() then return end
	if not input.IsControlDown() then
		for i, e in ipairs(curselect) do
			if not IsValid(e) then
				table.remove(curselect, i)
			end
		end
		return g_original_context_hook(code, vec)
	end
	if code == MOUSE_RIGHT then
		local ent = properties.GetHovered(EyePos(), vec)
		if IsValid(ent) then
			for i, e in ipairs(curselect) do
				if not IsValid(e) then
					table.remove(curselect, i)
				elseif e == ent then
					table.remove(curselect, i)
					return
				end
			end
			table.insert(curselect, ent)
		end
	end
end)