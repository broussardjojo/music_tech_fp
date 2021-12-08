function Msg(param)
  reaper.ShowConsoleMsg(tostring(param).."\n")
end

-- A function to convert a log measurement of volume into DB
function LogToDB(vol)
  return 20 * math.log(vol,10)
end

-- A function to convert a DB measurement of volume into log
function DBToLog(vol)
  return math.exp(vol*0.115129254)
end

-- Generate a random float between two values
function randomFloat(lower, greater)
    return lower + math.random()  * (greater - lower);
end


-- Given the name of an effect, add that effect to the selected track;
-- set all parameter values in it randomly between their min and max settings.
-- Maybe add error handling if we get an invalid effect name
function AddTrueRandomEffect(effect_name, track)
  effect_position = reaper.TrackFX_AddByName(track, effect_name, false, -1)
  param_count = reaper.TrackFX_GetNumParams(track, effect_position)
  
  for i = 0, param_count - 1, 1
  do
    -- Get the extremes of the parameter settings. We'll choose a random value in the range between the two.
    ret, minv, maxv = reaper.TrackFX_GetParamEx(track, effect_position, i)
    param_val = randomFloat(minv, maxv)
    discard, param_name = reaper.TrackFX_GetParamName(track, effect_position, i)
    Msg(effect_name..": Set "..tostring(param_name).." to value "..tostring(param_val))
    reaper.TrackFX_SetParam(track, effect_position, i, param_val)
  end
  
end

-- Add a random delay (with "ReaDelay" effect) to the selected track in the active project
function AddRandomDelay()
  track = reaper.GetSelectedTrack(0,0)
  effect_position = reaper.TrackFX_AddByName(track, "ReaDelay", false, -1)
  param_count = reaper.TrackFX_GetNumParams(track, effect_position)
  
  for i = 0, param_count - 1, 1
  do
    -- Get the extremes of the parameter settings. We'll choose a random value in the range between the two.
    ret, minv, maxv = reaper.TrackFX_GetParamEx(track, effect_position, i)
    param_val = randomFloat(minv, maxv)
    reaper.TrackFX_SetParam(track, effect_position, i, param_val)
  end
  
end

-- Removes all effects from provided track.
function RemoveAllFX(track)
  effect_count = reaper.TrackFX_GetCount(track)
  for i=0, effect_count, 1
  do
    reaper.TrackFX_Delete(track, 0)
  end
end


-- Main Function
function Main()
  -- Functionality to consider adding:
    -- Randomize order of effects
    -- More user specificity in choosing / modifying parameters to edit
    -- Control randomness

  -- Initializing stuff; resetting console, setting random seed, removing all effects on track
  track_to_modify = reaper.GetSelectedTrack(0,0)
  
  math.randomseed(os.time())
  reaper.ShowConsoleMsg("")
  RemoveAllFX(track_to_modify)
  
  -- Adding chosen effects; maybe do some stuff for GUI integration?
  AddTrueRandomEffect("ReaDelay", track_to_modify)
  AddTrueRandomEffect("ReaVerb", track_to_modify)
  AddTrueRandomEffect("ReaEQ", track_to_modify)
  -- This method also works for non-native effects, so long as they're installed!
  --AddTrueRandomEffect("TyrellN6", track_to_modify)
  
  -- Enable all effects
  effect_count = reaper.TrackFX_GetCount(track_to_modify)
  for i = 0, effect_count - 1, 1
  do
    reaper.TrackFX_SetEnabled(track_to_modify, i, 1)
  end
  
  reaper.UpdateArrange()
end

Main()
