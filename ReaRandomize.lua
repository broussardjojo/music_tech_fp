-- The core library must be loaded prior to anything else
local libPath = reaper.GetExtState("Scythe v3", "libPath")
if not libPath or libPath == "" then
    reaper.MB("Couldn't load the Scythe library. Please install 'Scythe library v3' from ReaPack, then run 'Script: Scythe_Set v3 library path.lua' in your Action List.", "Whoops!", 0)
    return
end

-- This line needs to use loadfile; anything afterward can be required
loadfile(libPath .. "scythe.lua")()
local GUI = require("gui.core")
local Table = require("public.table")
local layers

------------------------------------
-------- Plugin Parameters ---------
------------------------------------

-- The annoying part:
-- Because we're doing custom implementation for different effects,
-- And limiting what parameters users can play with, we need to find
-- The index of the settings for every fucking guy.
local pitch_param_to_index = {
  ["Shift"] = 5,
  ["Formant Shift"] = 9,
  ["Wet"] = 0,
  ["Dry"] = 1
}

local eq_param_to_index = {
  ["LPF Frequency"] = 0,
  ["LPF Bandwidth"] = 2,
  ["HPF Frequency"] = 9,
  ["HPF Bandwidth"] = 11
}

local reverb_param_to_index = {
  ["Room Size"] = 2,
  ["Reverb LPF"] = 6,
  ["Reverb HPF"] = 7,
  ["Wet"] = 0,
  ["Dry"] = 1
}

local gate_param_to_index = {
  ["Threshold"] = 0,
  ["Attack"] = 1,
  ["Hold"] = 4,
  ["Release"] = 2,
  ["Invert"] = 18, -- Don't know if this works bc it's a checkbox
  ["Wet"] = 10,
  ["Dry"] = 9
}

local delay_param_to_index = {
  ["Length"] = 4, -- I believe this is musical length; use 3 for time length
  ["Feedback Gain"] = 5,
  ["Feedback LPF"] = 6,
  ["Feedback HPF"] = 7,
  ["Wet"] = 0,
  ["Dry"] = 1
}

-- A little dictionary between the names of plugins (from the checkbox on main tab)
-- To the name of the advanced settings guy.
local plugin_to_settings_name = {
  ["ReaPitch"] = {"pitchParams", pitch_param_to_index},
  ["ReaGate"] = {"gateParams", gate_param_to_index},
  ["ReaEQ"] = {"eqParams", eq_param_to_index},
  ["ReaDelay"] = {"delayParams", delay_param_to_index},
  ["ReaVerbate"] = {"reverbParams", reverb_param_to_index}
}

------------------------------------
---------- GUI Methods -------------
------------------------------------

--Checks if # of plugins textbox contains a single digit number
local function validateNumPlugins()
  local numPluginsTextbox = GUI.findElementByName("numPluginsTextbox")
  local tbcont = numPluginsTextbox.retval
  return string.len(tbcont) <= 1 and tonumber(tbcont) ~= nil
end

--Toggles hidden options depending on the selected mode
local function toggleHiddenOptions()
  local modeDropdown = GUI.findElementByName("modeDropdown")
  local selectedMode = modeDropdown.retval
  local tabs = GUI.findElementByName("tabs")
  local selectedTab = tabs.retval
  local numPluginTextbox = GUI.findElementByName("numPluginsTextbox")
  if selectedMode == 2 and selectedTab == 1 then
    layers[3]:show()
  else
    layers[3]:hide()
  end
end

local function getTrack()
  selectedTrack = reaper.GetSelectedTrack(0, 0)
    if selectedTrack then
      local _, trackName = reaper.GetSetMediaTrackInfo_String(selectedTrack, "P_NAME", "", false)
      if trackName == "" then
        local trackNumber = reaper.GetMediaTrackInfo_Value(selectedTrack, "IP_TRACKNUMBER")
        GUI.Val("selectedTrackName", "Track " .. math.tointeger(trackNumber))
      else
        GUI.Val("selectedTrackName", trackName)
      end
    else
      -- if there is no selected track, then we complain to the user
      reaper.ShowMessageBox("Please select a track!", "Error", 0)
    end
end

------------------------------------
------- Generate FX Methods --------
------------------------------------

function getDelta()
  local randomnessKnob = GUI.findElementByName("randomnessKnob")
  return randomnessKnob.retval / 100
end

-- Generate a random float between two values
function randomFloat(lower, greater)
    return lower + math.random()  * (greater - lower);
end

-- Writes a message to the Reaper Console.
function Msg(param)
  reaper.ShowConsoleMsg(tostring(param).."\n")
end

-- Returns a table of the selected values for the provided checkbox.
local function getSelectedFromCheckbox(checkbox_name)
  checkbox_list = GUI.findElementByName(checkbox_name)
  selected_hash = checkbox_list.selectedOptions
  
  selected_list = {}
  for k,v in pairs(selected_hash) do
    if v then table.insert(selected_list, checkbox_list.options[k]) end
  end
  return selected_list
end

-- Removes all effects from provided track.
function RemoveAllFX(track)
  effect_count = reaper.TrackFX_GetCount(track)
  for i=0, effect_count, 1
  do
    reaper.TrackFX_Delete(track, 0)
  end
end

-- Given the name of an effect, add that effect to the selected track;
-- set all parameter values in it randomly between their min and max settings.
-- Maybe add error handling if we get an invalid effect name
function AddTrueRandomEffect(effect_name, track, delta)
  -- Delta argument is basically a "randomness coefficient" - we use it to modify the min/max
  -- Should be in range from 0 - 1; 1 is full range, 0 is all defaults
  effect_position = reaper.TrackFX_AddByName(track, effect_name, false, -1)
  param_count = reaper.TrackFX_GetNumParams(track, effect_position)
  
  -- This next part might be wrong:
  -- For some reason, even when delta is low, things are getting shifted far apart from their original values :?
  for i = 0, param_count - 1, 1
  do
    -- Get the extremes of the parameter settings. We'll choose a random value in the range between the two.
    -- Right now, I don't think we're changing categorical parameters (e.g. from low shelf -> high shelf, etc)
    -- But it works for numerical parameters.
    default_val = reaper.TrackFX_GetParamNormalized(track, effect_position, i)
    ret, minv, maxv = reaper.TrackFX_GetParamEx(track, effect_position, i) 
    -- These are the extremes that the parameters can be modified down or up to, when considering the delta.
    deltamin = default_val - (delta * (default_val - minv))
    deltamax = default_val + (delta * (maxv - default_val))
    param_val = randomFloat(deltamin, deltamax)
    discard, param_name = reaper.TrackFX_GetParamName(track, effect_position, i)
    Msg(effect_name..": Changed "..tostring(param_name).." (parameter ".. tostring(i) .. ") from "..tostring(default_val).." to "..tostring(param_val))
    reaper.TrackFX_SetParam(track, effect_position, i, param_val)
  end
end

-- Only randomizes the parameters in the provided table.
function RandomizeSelectedParameters(effect_name, track, delta)
  selected_settings_table_name = plugin_to_settings_name[effect_name][1]
  effect_position = reaper.TrackFX_AddByName(track, effect_name, false, -1)
  
  -- ARDUOUS TASK OF GETTING STUFF FROM ADVANCED BOXES
  param_index_table_name = plugin_to_settings_name[effect_name][1]
  param_index_table = plugin_to_settings_name[effect_name][2]
  advanced_checkbox_selections = getSelectedFromCheckbox(param_index_table_name)
  to_edit = {}
  for k, v in pairs(advanced_checkbox_selections) do
    table.insert(to_edit, param_index_table[v])
  end
  
  -- MODIFYING SELECTED PARAMETERS
  for k, v in pairs(to_edit) do
    default_val = reaper.TrackFX_GetParamNormalized(track, effect_position, v)
    ret, minv, maxv = reaper.TrackFX_GetParamEx(track, effect_position, v)
    deltamin = default_val - (delta * (default_val - minv))
    deltamax = default_val + (delta * (maxv - default_val))
    param_val = randomFloat(deltamin, deltamax)
    discard, param_name = reaper.TrackFX_GetParamName(track, effect_position, v)
    Msg(effect_name..": Changed "..tostring(param_name).. " from "..tostring(default_val).." to "..tostring(param_val))
    reaper.TrackFX_SetParam(track, effect_position, v, param_val)
  end
end

-- This is the one that triggers when you press the "OK" button.
-- Doesn't randomize order, currently
local function generateEffects()

  if selectedTrack == nil then
    reaper.ShowMessageBox("Please select a track first!", "Error", 0)
    return
  end
  
  delta = getDelta()
  
  -- A table of the names of the selected plugins.
  selected_plugins = getSelectedFromCheckbox("pluginList")
  if selected_plugins[1] == nil then
    reaper.ShowMessageBox("Please select at least 1 effect!", "Error", 0)
    return
  end
  
  -- Optional; Maybe make a checkbox for this one?
  RemoveAllFX(selectedTrack)
  
  -- 1 for Exact, 2 for Random Plugins, 3 for the last one
  mode = GUI.findElementByName("modeDropdown").retval
  
  -- This is for "exact"
  if mode == 1 then
    for k, v in pairs(selected_plugins) do
      Msg("Plugin selected: " .. tostring(v))
      RandomizeSelectedParameters(tostring(v), selectedTrack, delta)
    end
  elseif mode == 2 then
    Msg("I haven't implemented this one yet")
  elseif mode == 3 then
    for k, v in pairs(selected_plugins) do
      Msg("Plugin seleceted: " .. tostring(v))
      AddTrueRandomEffect(v, selectedTrack, delta)
    end
  end
  
  -- Enabling all effects now
  effect_count = reaper.TrackFX_GetCount(selectedTrack)
  for i = 0, effect_count - 1, 1
  do
    reaper.TrackFX_SetEnabled(selectedTrack, i, 1)
  end
end

------------------------------------
-------- Window Settings -----------
------------------------------------


local window = GUI.createWindow({
  name = "ReaRandomize",
  x = 0,
  y = 0,
  w = 432,
  h = 540,
  anchor = "mouse",
  corner = "C",
})

layers = table.pack( GUI.createLayers(
  {name = "Layer1", z = 1},
  {name = "Layer2", z = 2},
  {name = "Layer3", z = 3},
  {name = "Layer4", z = 4}
))

window:addLayers(table.unpack(layers))


------------------------------------
-------- Global Elements -----------
------------------------------------


layers[1]:addElements( GUI.createElements(
  {
    name = "tabs",
    type = "Tabs",
    x = -10,
    y = 0,
    w = 64,
    h = 20,
    tabs = {
      {
        label = "Basic",
        layers = {layers[2], layers[3]}
      },
      {
        label = "Advanced",
        layers = {layers[4]}
      }
    },
    pad = 16,
    tabW = 96
  },
  {
    name = "okButton",
    type = "Button",
    x = 168,
    y = 510,
    w = 96,
    h = 20,
    caption = "Ok",
    func = generateEffects
  },
  {
    name = "frameDivider",
    type = "Frame",
    x = 0,
    y = 500,
    w = window.w,
    h = 1,
  }
))


------------------------------------
------- Basic Tab Elements ---------
------------------------------------


layers[2]:addElements( GUI.createElements(
  {
    name = "selectedTrackName",
    type = "Frame",
    x = 96,
    y = 48,
    w = 128,
    h = 24,
  },
  {
    name = "getTrackButton",
    type = "Button",
    x = 232,
    y = 48,
    w = 72,
    h = 24,
    caption = "Get Track",
    func = getTrack
  },
  {
    name = "pluginList",
    type = "Checklist",
    x = 44,
    y = 126,
    w = 144,
    h = 144,
    caption = "Plugins",
    options = {"ReaPitch","ReaGate","ReaEQ","ReaDelay","ReaVerbate"}
  },
  {
    name = "randomnessKnob",
    type = "Knob",
    x = 256,
    y = 150,
    w = 96,
    caption = "Randomness",
    captionY = -36,
    min = 1,
    max = 100,
    inc = 1,
    default = 49,
    showValues = false,
  },
  {
    name = "modeDropdown",
    type = "Menubox",
    x = 172,
    y = 330,
    w = 124,
    h = 24,
    caption = "Mode:",
    options = {"Exact", "Random Plugins", "Random All"}
  }
))

layers[3]:addElements( GUI.createElements(
  {
    name = "repeatedPlugins",
    type = "Checklist",
    x = 134,
    y = 380,
    w = 166,
    h = 32,
    frame = false,
    caption = "",
    options = {"Allow Repeated Plugins"},
    selectedOptions = {true}
  },
  {
    name = "numPluginsTextbox",
    type = "Textbox",
    x = 244,
    y = 420,
    w = 24,
    h = 24,
    caption = "# of Plugins:",
    pad = 8,
    validator = validateNumPlugins,
    validateOnType = true
  }
))

-- We have too many values to be legible if we draw them all; we'll disable them
-- and have the knob's caption update itself to show the value instead.
local randomnessKnob = GUI.findElementByName("randomnessKnob")
function randomnessKnob:redraw()
  -- This grabs the knob's prototype - the Knob class - so we can use the original
  -- redraw method.
  getmetatable(self).redraw(self)
  self.caption = "Randomness: " .. self.retval .. "%"
end

-- Make sure it shows the value right away
randomnessKnob:redraw()


------------------------------------
------ Advanced Tab Elements -------
------------------------------------


layers[4]:addElements( GUI.createElements(
  {
    name = "pitchParams",
    type = "Checklist",
    x = 44,
    y = 56,
    w = 144,
    h = 120,
    caption = "ReaPitch",
    options = {"Shift","Formant Shift","Wet","Dry"},
    selectedOptions = {true, true, false, false}
  },
  {
    name = "gateParams",
    type = "Checklist",
    x = 244,
    y = 56,
    w = 144,
    h = 192,
    caption = "ReaGate",
    options = {"Threshold","Attack","Hold","Release","Invert","Wet","Dry"},
    selectedOptions = {true, true, false, true, false, false, false}
  },
  {
    name = "eqParams",
    type = "Checklist",
    x = 44,
    y = 196,
    w = 144,
    h = 120,
    caption = "ReaEQ",
    options = {"LPF Frequency","LPF Bandwidth","HPF Frequency","HPF Bandwidth"},
    selectedOptions = {true, true, true, true}
  },
  {
    name = "delayParams",
    type = "Checklist",
    x = 244,
    y = 266,
    w = 144,
    h = 168,
    caption = "ReaDelay",
    options = {"Length","Feedback Gain","Feedback LPF","Feedback HPF","Wet","Dry"},
    selectedOptions = {true, true, false, false, false, true}
  },
  {
    name = "reverbParams",
    type = "Checklist",
    x = 44,
    y = 336,
    w = 144,
    h = 144,
    caption = "ReaVerbate",
    options = {"Room Size","Reverb LPF","Reverb HPF","Wet","Dry"},
    selectedOptions = {true, false, false, false, true}
  }
))


------------------------------------
-------- Main Functions ------------
------------------------------------


-- This will be run on every update loop of the GUI script
local function Main()

  -- Prevent the user from resizing the window
  if window.state.resized then
    -- If the window's size has been changed, reopen it
    -- at the current position with the size we specified
    window:reopen({w = window.w, h = window.h})
  end
  
  toggleHiddenOptions()

end

-- Open the script window and initialize a few things
window:open()

-- Tell the GUI library to run Main on each update loop
-- Individual elements are updated first, then GUI.func is run, then the GUI is redrawn
GUI.func = Main

-- How often (in seconds) to run GUI.func. 0 = every loop.
GUI.funcTime = 0

-- Start the main loop
GUI.Main()