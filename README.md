# music_tech_fp

## Overview
This is a script made for Reaper created using Reaper's LUA integration, allowing the easy randomized application of several effects
(currently Reapitch, ReaGate, ReaEq, ReaDelay, and ReaVerbate) and modification of their parameters. The GUI was created using the Scythe
library.

## UI and settings
The UI is composed of two tabs - the "Basic" tab and the "Advanced" tab.
- Basics Tab
  - Track selector
    - Enables user to select the track that FX will be added to.
    - Displays selected track.
    - Track is required to be selected in this manner before FX can be added.
  - Plugins checkbox
    - Enables user selection of what effect(s) will be added to selected track
    - At least one must be selected in this manner before FX can be added.
  - Randomness knob
    - Enables user selection of how far away from default values parameters can be changed to.
    - Low and high points of parameters are given by the following:
      - ``low: default_parameter_value - ((randomness / 100) * (default_parameter_value - minimum_parameter_value))``
      - ``high: default_parameter_value + ((randomness / 100) * (default_parameter_value - maximum_parameter_value))``
  - Mode dropdown
    - Provides options for generation of random effects.
    - **All options will delete all previously added FX on the track, and enable all newly added FX.**
      - Use this on a bus track!
    - Options
      - Exact
        - Adds one copy of each effect selected in the plugins checkbox to the selected track
        - Only modifies parameters selected in the Advanced tab
        - FX added in top-down order
      - Random Plugins
        - Randomly chooses plugins out of the plugins checkbox to add, with or without repetition of effects.
        - Allows user assignment of how many effects to add.
      - Random All
        - Adds one copy of each effect selected in the plugins checkbox to the selected track
        - Modifies all parameters, disregarding advanced tab selections
          - This includes parameters not displayed on the advanced tab 
        - FX added in top-down order
- Advanced Tab
  - Composed of 5 seperate checkboxes, one for each plugin
  - Allows selection of which parameters will be randomized during the generation of FX.
  - Does not display all parameters
  
## Points of improvement
- Ability to enforce more restrictions on parameters incl. step size (for ex., limit musical delay to increments of 1/8 notes)
- Abstract randomization functions + UI to enable user to add additional plugins
  - Right now we do have the ability to add any installed effect given solely its name and randomize parameters
- More randomness options besides simply a linear scale of difference from default
- Also it's not impossible there's some unexpected behavior in modifying parameters in the linear manner that we have
- Support categorical parameter assignment; e.g. changing type of filter in ReaEQ
- Prevent repeated positive gain resulting in a track getting automatically muted
