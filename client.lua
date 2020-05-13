-- All Data
local Menus = {}
local Components = {}

-- Current Data
local OpenedMenu = nil
local HoveredIndex = 1

function AddMenu(name)
  local index = Utils.GenerateUUID()

  Menus[index] = {
    name = name,
    type = "base",
    components = {},
  }

  return index
end

function AddSubMenu(name, menu)
  local index = Utils.GenerateUUID()

  Menus[index] = {
    name = name,
    type = "submenu",
    components = {},
    parent = menu
  }

  table.insert(Menus[menu].components, {
    index = index,
    name = name,
    parent = menu,
    type = "submenu"
  })

  return index
end

function AddButton(name, menu, callback)
  local index = Utils.GenerateUUID()

  Components[index] = {
    name = name,
    type = "button",
    action = callback
  }

  table.insert(Menus[menu].components, {
    index = index,
    name = name,
    type = "button"
  })
end

function AddCheckbox(name, menu, callback)
  local index = Utils.GenerateUUID()

  Components[index] = {
    name = name,
    type = "checkbox",
    action = callback,
    state = false
  }

  table.insert(Menus[menu].components, {
    index = index,
    name = name,
    type = "checkbox",
    state = false
  })
end

function OpenMenu(menu)
  local menuToOpen = Menus[menu]
  if menuToOpen then
    SendNUIMessage({
      type = "open_menu",
      data = {
        name = menuToOpen.name,
        components = menuToOpen.components,
        option = 1
      }
    })
    OpenedMenu = menuToOpen
    HoveredIndex = 1
  end
end

function CloseMenu()
  if OpenedMenu then
    SendNUIMessage({ type = "close_menu" })
    OpenedMenu = nil
    HoveredIndex = 1
  end
end

function IsAnyMenuOpen()
  if OpenedMenu then
    return true
  end
  return false
end

function IsMenuOpened(menu)
  if OpenedMenu.index == menu then
    return true
  end
  return false
end

function GetOpenedMenu()
  if OpenedMenu then
    return OpenedMenu.index
  end
  return nil
end

-- EXPORTS
exports("AddMenu", AddMenu)
exports("AddSubMenu", AddSubMenu)
exports("AddButton", AddButton)
exports("OpenMenu", OpenMenu)
exports("AddCheckbox", AddCheckbox)
exports("CloseMenu", CloseMenu)
exports("IsAnyMenuOpen", IsAnyMenuOpen)
exports("IsMenuOpen", IsMenuOpened)
exports("GetOpenedMenu", GetOpenedMenu)

-- CONTROLS
function GoUp()
  local prev = HoveredIndex - 1

  if prev < 1 then
    prev = #OpenedMenu.components
  end

  HoveredIndex = prev
  SendNUIMessage({
    type = "set_menu_option",
    data = {
      option = HoveredIndex
    }
  })
end

function GoDown()
  local next = HoveredIndex + 1

  if next > #OpenedMenu.components then
    next = 1
  end

  HoveredIndex = next
  SendNUIMessage({
    type = "set_menu_option",
    data = {
      option = HoveredIndex
    }
  })
end

function Enter()
  local selected = OpenedMenu.components[HoveredIndex]
  if selected then
    if selected.type == "submenu" then
      OpenMenu(selected.index)
    else
      local component = Components[selected.index]
      if selected.type == "checkbox" then
        local newState = not component.state
        component.state = newState
        selected.state = newState
        component.action(newState)
        SendNUIMessage({
          type = "set_checkbox_state",
          data = {
            id = selected.index,
            state = newState
          }
        })
      elseif selected.type == "button" then
        Components[selected.index].action()
      end
    end
  end
end

function Backspace()
  if OpenedMenu then
    if not OpenedMenu.parent then
      CloseMenu()
    else
      OpenMenu(OpenedMenu.parent)
    end
  end
end

Citizen.CreateThread(function()
  while true do
    Citizen.Wait(0)
    if OpenedMenu then

      if IsControlJustPressed(0, 172) then
        GoUp()
      elseif IsControlJustPressed(0, 173) then
        GoDown()
      elseif IsControlJustPressed(0, 176) then
        Enter()
      elseif IsControlJustPressed(0, 177) then
        Backspace()
      end

    end
  end
end)