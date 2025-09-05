# ChromaKeys

## Create color schemes within [Micro](https://github.com/zyedidia/micro) using only the keyboard

You can adjust individual scopes:

![Adjust individual scopes](images/adjustIndividualScopes.gif)

Or you can generate entire color schemes using a variety of palettes:

![Generate entire palettes with one keystroke](images/palettes.gif)

## Installation

Clone this repository into `~/.config/micro/plug`.

## Usage

You'll need to bind the following commands to keyboard shortcuts of your choice.

```
"Alt-1":			"command:ckPreviousColorFunction",
"Alt-2":			"command:ckNextColorFunction",
"Alt-3":			"command:ckGenerateColorScheme",
"F8":				"command:ckGenerateColorScheme",
"Alt-g":			"command:ckGenerateColorScheme",

"Alt-6":			"command:ckRandomiseHue",
"Alt-7":			"command:ckRandomiseSaturation",
"Alt-8":			"command:ckRandomiseLightness",

"Alt-B":			"command:ckSettingsToggleUseBaseSL",
"Alt-h":			"command:ckNextGroup",

"Alt-j":			"command:ckFirstColorScheme",
"Alt-k":			"command:ckPreviousColorScheme",
"Alt-l":			"command:ckNextColorScheme",

"AltLeft":			"command:ckScopePrevious",
"AltRight":			"command:ckScopeNext",

"Alt-r":			"command:ckRandomiseColor",
"Alt-R":			"command:ckResetBaseSaturationAndLightness",

"Alt-Y":			"command:ckABSetA",
"Alt-U":			"command:ckABSetB",
"Alt-y":			"command:ckABSelectA",
"Alt-u":			"command:ckABSelectB",

"F1":				"command:ckSaveCurrentTheme",

"F5":				"command:ckHueInc",
"F6":				"command:ckSaturationInc",
"F7":				"command:ckLightnessInc",
"F9":				"command:ckHueIncLarge",
"F10":				"command:ckSaturationIncLarge",
"F11":				"command:ckLightnessIncLarge",

"Shift-F5":			"command:ckHueDec",
"Shift-F6":			"command:ckSaturationDec",
"Shift-F7":			"command:ckLightnessDec",
"Shift-F9":			"command:ckHueDecLarge",
"Shift-F10":		"command:ckSaturationDecLarge",
"Shift-F11":		"command:ckLightnessDecLarge",

"Shift-F12":		"command:ckToggleDebugMode",
"Alt-L":			"command:ckForceLogRules",
```

Additional commands are available that you can also bind to keyboard shortcuts:

### `ckCustomPaletteSetHues`

Set the hues for the custom palette.

Examples:
```
ckCustomPaletteSetHues 35 190
ckCustomPaletteSetHues 35 190 240 250 280 0 330
```

### `ckSettingsSetMaxChannelValue`

Set the upper limit for each individual RGB channel. If this is set to 200, for instance, then no color will have a channel value higher than 200.

Examples:
```
ckSettingsSetMaxChannelValue 220
ckSettingsSetMaxChannelValue 255
```

### `ckSelectColorFunction`

Select a color function by name, instead of cycling through them.

Examples:
```
ckSelectColorFunction randomli
ckSelectColorFunction shades
ckSelectColorFunction shadesofb
ckSelectColorFunction cyclic
```

### Basic Usage

To get an idea of what ChromaKeys can do, hit `F8` (or `Alt-G`, or `Alt-3`) a few times. Use `Alt-1` and `Alt-2` to cycle through the available color generation functions.

### Manual color scheme creation (adjust individual scopes separately)

If you want to adjust each scope separately, select a scope using the `ckScopeNext` (Alt-rightarrow) and `ckScopePrevious` (Alt-leftarrow) commands. Then use the keyboard shortcuts/commands below to change the scope's color:

```
"F5":				"command:ckHueInc",
"Shift-F5":			"command:ckHueDec",
"F6":				"command:ckSaturationInc",
"Shift-F6":			"command:ckSaturationDec",
"F7":				"command:ckLightnessInc",
"Shift-F7":			"command:ckLightnessDec",
"F9":				"command:ckHueIncLarge",
"Shift-F9":			"command:ckHueDecLarge",
"F10":				"command:ckSaturationIncLarge",
"Shift-F10":		"command:ckSaturationDecLarge",
"F11":				"command:ckLightnessIncLarge",
"Shift-F11":		"command:ckLightnessDecLarge",

"Alt-r":			"command:ckRandomiseColor",
"Alt-6":			"command:ckRandomiseHue",
"Alt-7":			"command:ckRandomiseSaturation",
"Alt-8":			"command:ckRandomiseLightness",
```

### Generate entire color schemes in one go using palettes

The `ckPreviousColorFunction` (Alt-1) and `ckNextColorFunction` (Alt-2) commands select the color generator function. `ckGenerateColorScheme` (F8, or Alt-g, or Alt-3) uses the selected function to generate a color scheme. Most of these functions take their base hue and saturation from the base scope. These base settings have a large effect: the same palette function will generate strikingly different-looking color schemes based on the base lightness and saturation settings.

The plugin comes with a range of pre-selected palettes. Or if you prefer to make your own, use the `RandomPalette` function to generate color schemes until you find a palette you like, then switch to the `Custom` function (It's right next to the `RandomPalette` function, so if you're using the default bindings you just need to press `Alt-2`.). You can then generate color schemes using that palette.

If you prefer to set the custom palette hues manually, or if you want more than two base hues, you can use the command `ckCustomPaletteSetHues <hue1> <hue2> ... <hueN>`.

## Concepts

Essentially, you choose a scope (a highlight group), and adjust its color. There are four special scopes:

- `base`: This sets the base color. If you're creating a color scheme manually (as opposed to using the palettes), this is the first scope you need to set.
- `all`: This applies the command to all scopes. Useful if you want to adjust the hue/saturation/lightness of the entire scheme.
- `allExceptFgDefault`: This adjusts everything but the foreground scope color (and the scope colors derived from it - see below).
- `allExceptFgDefaultAsOne`: Same as allExceptFgDefault, but it changes all the affected scopes in lockstep.

### Derived scope colors

The colors for these scopes are derived from other scopes:

```
Default Background (bgDefault)
Symbol (fgSymbol)
Comment background (calcBgComment)
Status line foreground (calcFgStatusLine)
Status line background (calcBgStatusLine)
Line number (calcFgLineNumber)
Current line number (calcFgCurrentLineNumber)
Message (calcFgMessage)
```

You can also change these individually, but if you then use a color generator function, it will overwrite your changes with the new derived colors.

## Saving color schemes

Use `ckSaveCurrentTheme` (F1). This will save the color scheme with a name based on the foreground color in the format `ck<BaseColorName><number>.micro` in your micro user colorschemes folder (~/.config/micro/colorschemes). It will never overwrite any existing files.

## Navigating color schemes

Use `ckNextColorScheme` and `ckPreviousColorScheme`. There is also `ckNextGroup` which takes you to the first scheme in the next color group (ckBlueNN, ckCyan01, ckGray01, ckOrange01 and so on). `ckFirstColorScheme` will take you to the first scheme in the entire folder.

## A-B comparisons

`ckABSetA` (Alt-Shift-Y) and `ckABSetB` (Alt-Shift-U) will set the current color scheme in A-B comparison slots A and B respectively. `ckABSelectA` (Alt-y) and `ckABSelectB` (Alt-u) will let you apply the color scheme in each slot for easy comparison.

## Editing existing color schemes

ChromaKeys can only work with files in your user-specific micro colorschemes folder (`~/.config/micro/colorschemes`). So if you want to edit an existing color scheme, copy the file to that folder, and in Micro, select it using the `ckNextColorScheme` or `ckPreviousColorScheme` commands. If you use `set colorscheme <schemename>`, ChromaKeys will not parse the scheme. You can use the `set ...` command and then quickly use the prev/next scheme shortcuts (Alt-k, Alt-l) so that the scheme is parsed. Once you're happy with the modified scheme, use `ckSaveCurrentTheme` (F1). This will save it using the filename format mentioned above - the existing theme file will not be touched.

## AAQ (Anticipated asked questions)

### Why is there no support for color schemes with light backgrounds?

Well, color schemes with light backgrounds are an abomination, but there's also a practical reason: there's no way I could tolerate staring at a glaring white screen long enough to be able to implement support for them.

### I don't like writing ~1KB to my SSD every time I press a key.

`rsync` your `~/.config/micro/colorschemes` folder to a RAM drive, and symlink to it.
