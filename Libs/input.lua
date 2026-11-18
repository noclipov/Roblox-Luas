--[[ ════════════════════════════════════════════════════════════
  Noclipov · input · v2.0
  Эмуляция мыши/клавиатуры через VirtualInputManager.
  API: MouseClick(x, y, hold?, button?) · MoveMouse(x, y) · PressKey(key, hold?)
       CenterMouseClick(hold?) · ClickGui(guiObject, hold?) · Viewport()
════════════════════════════════════════════════════════════ ]]

-- [1] SERVICES
local VIM       = game:GetService("VirtualInputManager")
local Workspace = game:GetService("Workspace")

-- [2] MODULE
local Input = { Version = "2.0" }

-- [3] HELPERS
local function wait(t)
	if t and t > 0 then task.wait(t) end
end

-- [4] PUBLIC API
function Input.Viewport(): Vector2
	local cam = Workspace.CurrentCamera -- камера может смениться, не кэшируем
	return cam and cam.ViewportSize or Vector2.zero
end

-- button: 0 = ЛКМ, 1 = ПКМ, 2 = СКМ
function Input.MouseClick(x: number, y: number, hold: number?, button: number?)
	button = button or 0
	VIM:SendMouseButtonEvent(x, y, button, true, nil, 0)
	wait(hold)
	VIM:SendMouseButtonEvent(x, y, button, false, nil, 0)
end

function Input.MoveMouse(x: number, y: number)
	VIM:SendMouseMoveEvent(x, y, nil)
end

function Input.PressKey(key: Enum.KeyCode, hold: number?)
	VIM:SendKeyEvent(true, key, false, nil)
	wait(hold)
	VIM:SendKeyEvent(false, key, false, nil)
end

function Input.CenterMouseClick(hold: number?)
	local v = Input.Viewport()
	Input.MouseClick(v.X / 2, v.Y / 2, hold)
end

-- Клик по центру GuiObject (учитывает GuiInset)
function Input.ClickGui(gui: GuiObject, hold: number?)
	local inset = game:GetService("GuiService"):GetGuiInset()
	local c = gui.AbsolutePosition + gui.AbsoluteSize / 2 + inset
	Input.MouseClick(c.X, c.Y, hold)
end

return Input
