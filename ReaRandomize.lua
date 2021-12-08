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

------------------------------------
-------- Functions -----------------
------------------------------------

local layers

local function btnClick()
  reaper.ShowMessageBox("Success", "ReaRandomize", 0)
end

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

------------------------------------
-------- Window settings -----------
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
-------- Global elements -----------
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
    func = btnClick
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
-------- Tab 1 Elements ------------
------------------------------------


layers[2]:addElements( GUI.createElements(
  {
    name = "selectedTrack",
    type = "Frame",
    x = 96,
    y = 48,
    w = 128,
    h = 24,
    text = "Track 1"
  },
  {
    name = "getTrackButton",
    type = "Button",
    x = 232,
    y = 48,
    w = 72,
    h = 24,
    caption = "Get Track",
    func = btnClick
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
-------- Tab 2 Elements ------------
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
-------- Main functions ------------
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
