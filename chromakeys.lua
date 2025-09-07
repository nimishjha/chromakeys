VERSION = "0.0.2"

local micro = import("micro")
local config = import("micro/config")
local buffer = import("micro/buffer")
local os = import("os")
local ioutil = import("ioutil")
local fmt = import("fmt")
local time = import("time")

local settings = {
	colorSchemes = {},
	colorSchemeGroups = {},
	fgVars = {},
	bgVars = {},
	calcVars = {},
	fgColors = {},
	useBaseSL = false,
	base = {
		h = 220,
		s = 50,
		l = 50
	},
	allExceptFgDefaultAsOne = {
		h = 330,
		s = 50,
		l = 50
	},
	scopes = {},
	colorFunctions = {},
	uniformBrightness = 60,
	minFgLightness = 35,
	maxFgLightness = 75,
	maxBgLightness = 15,
	backgroundLightness = 6,
	backgroundSaturation = 100,
	commentBgLightness = 15,
	paletteMinSaturation = 30,
	paletteMaxSaturation = 70,
	shouldForceUniformBrightness = false,
	shouldEnsureSeparation = true,
	shouldLimitChannelValues = true,
	shouldLockFgDefaultToBaseColor = false,
	shouldRecalculateDerivedColors = true,
	shouldAdjustPerceptualBrightness = true,
	shouldForceOneColorToWhite = false,
	maxChannelValue = 200,
	rulesMap = {},
	currentScope = "fgDefault",
	colorSchemeFolderPath = "",
	currentColorScheme = "zzChromaKeys1",
	colorSchemePrefix = "ck",
	colorSchemeA = "ckGray33",
	colorSchemeB = "ckOrange44",
	logString = "",
	colorSchemeText = "",
	hueStep = 1,
	saturationStep = 1,
	lightnessStep = 0.25,
	hueCycleStep = 10,
	CUSTOM_PALETTE_NAME = "CustomPalette",
	palettes = {
		CustomPalette         = { 75, 140 },
		Blue                  = { 210, 240 },
		BlueCyan              = { 220, 190 },
		BlueCyanOrange        = { 240, 210, 190, 180, 30, 40 },
		BlueGreen             = { 210, 220, 230, 240, 130, 140 },
		BlueOrange            = { 220, 40 },
		BlueRed               = { 220, 230, 240, 350, 0 },
		BlueRedOrange         = { 230, 240, 250, 350, 0, 40 },
		BlueYellow            = { 220, 240, 60 },
		Cyan                  = { 170, 180, 190 },
		Cyan2                 = { 160, 170 },
		CyanBlueOrange        = { 180, 190, 220, 230, 240, 40 },
		CyanOrange            = { 180, 190, 40 },
		CyanYellow            = { 190, 60 },
		Green                 = { 80, 90, 110, 120, 130, 140, 150, 160 },
		Green2                = { 75, 155 },
		GreenCyan             = { 110, 130, 150, 170, 180, 190 },
		GreenYellow           = { 120, 130, 140, 160, 45, 55 },
		MoreBlueLessOrange    = { 210, 220, 230, 240, 30, 40 },
		Orange                = { 20, 30 },
		OrangeBlue            = { 25, 240 },
		OrangeCyan            = { 25, 190 },
		OrangeCyan2           = { 40, 180 },
		OrangeCyan3           = { 50, 190 },
		OrangeCyan4           = { 20, 190 },
		OrangeCyan5           = { 20, 175 },
		OrangeViolet          = { 25, 250 },
		Pink                  = { 315, 320, 325, 330, 335 },
		Red                   = { 350, 0, 10 },
		RedBlue               = { 350, 0, 220, 230, 240 },
		RedPink               = { 0, 330 },
		Violet                = { 250, 255, 260, 265, 270, 280 },
		VioletBlue            = { 250, 260, 220 },
		VioletGreenCyan       = { 250, 90, 190 },
		VioletCyan            = { 250, 260, 190 },
		VioletCyanRedOrange   = { 250, 190, 0, 20 },
		VioletGreen           = { 250, 260, 160 },
		VioletOrange          = { 250, 260, 30 },
		VioletPink            = { 250, 260, 330 },
		VioletRed             = { 250, 260, 0 },
		VioletYellow          = { 250, 260, 60 },
		Yellow                = { 55, 65 },
	},
	isDebugMode = false,
	showStatusOnLoad = false,
	generationCount = 0,
}

local ACTIONS = {
	HUE_INCREASE              = 1,
	HUE_DECREASE              = 2,
	SATURATION_INCREASE       = 3,
	SATURATION_DECREASE       = 4,
	LIGHTNESS_INCREASE        = 5,
	LIGHTNESS_DECREASE        = 6,
	HUE_INCREASE_LARGE        = 7,
	HUE_DECREASE_LARGE        = 8,
	SATURATION_INCREASE_LARGE = 9,
	SATURATION_DECREASE_LARGE = 10,
	LIGHTNESS_INCREASE_LARGE  = 11,
	LIGHTNESS_DECREASE_LARGE  = 12,
	RANDOMISE                 = 15,
	RANDOMISE_HUE             = 16,
	RANDOMISE_SATURATION      = 17,
	RANDOMISE_LIGHTNESS       = 18,
}

local SPECIAL_SCOPES = {
	ALL_EXCEPT_FGDEFAULT_AS_ONE = "allExceptFgDefaultAsOne",
	ALL_EXCEPT_FGDEFAULT = "allExceptFgDefault",
	ALL = "all",
	BASE = "base",
}





local Cyclable = {}
Cyclable.__index = Cyclable

function Cyclable.new(variableNames)
	local self = setmetatable({}, Cyclable)
	self.variables = {}
	self.currentVariable = nil
	self.currentIndex = 0

	if type(variableNames) == "table" then
		for _, name in ipairs(variableNames) do
			if type(name) == "string" and name ~= "" then
				table.insert(self.variables, name)
			end
		end
		if #self.variables > 0 then
			self.currentIndex = 1
			self.currentVariable = self.variables[1]
		end
	end

	return self
end

function Cyclable:current()
	return self.currentVariable
end

function Cyclable:next()
	if #self.variables == 0 then
		self.currentIndex = 0
		self.currentVariable = nil
		return nil
	end

	self.currentIndex = self.currentIndex + 1
	if self.currentIndex > #self.variables then
		self.currentIndex = 1
	end
	self.currentVariable = self.variables[self.currentIndex]
	return self.currentVariable
end

function Cyclable:previous()
	if #self.variables == 0 then
		self.currentIndex = 0
		self.currentVariable = nil
		return nil
	end

	self.currentIndex = self.currentIndex - 1
	if self.currentIndex < 1 then
		self.currentIndex = #self.variables
	end
	self.currentVariable = self.variables[self.currentIndex]
	return self.currentVariable
end

function Cyclable:getVariables()
	return self.variables
end

function Cyclable:add(value)
	table.insert(self.variables, value)
	if self.currentIndex == nil or self.currentIndex == 0 then
		self.currentIndex = #self.variables
		self.currentVariable = value
	end
end

function Cyclable:addAndSelect(value)
	table.insert(self.variables, value)
	self.currentIndex = #self.variables
	self.currentVariable = value
end

function Cyclable:select(key)
	for index, value in ipairs(self.variables) do
		if value[1] == key then
			self.currentIndex = index
			self.currentVariable = self.variables[self.currentIndex]
		end
	end
end

function Cyclable:debug()
	for _, value in pairs(self.variables) do
		forceLog(value[1])
	end
	forceLog("currentIndex: " .. tostring(self.currentIndex) .. ", current: " .. tostring(self:current()))
end




local colorSchemeTemplate = [[
color-link default "{{fgDefault}},{{bgDefault}}"
color-link statement "{{fgStatement}}"
color-link identifier "{{fgIdentifier}},{{bgDefault}}"
color-link constant "{{fgConstant}},{{bgDefault}}"
color-link constant.string "{{fgConstantString}},{{bgDefault}}"
color-link constant.regex "{{fgConstantRegex}},{{calcBgStatusLine}}"
color-link comment "{{fgComment}},{{calcBgComment}}"
color-link symbol "{{fgSymbol}}"
color-link type "{{fgType}}"
color-link preproc "{{fgPreproc}}"
color-link special "{{fgSpecial}}"

color-link tabbar "{{fgDefault}},{{calcBgStatusLine}}"
color-link tabbar.active "{{fgDefault}},{{bgDefault}}"

color-link diff-added "#006600"
color-link diff-deleted "#880000"
color-link diff-modified "#003355"
color-link error "#CC0000,#440000"
color-link error-message "#CC0000,#440000"
color-link gutter-error "#CC0000,#440000"
color-link gutter-warning "#CC6600,#442200"
color-link todo "#CC5500"

color-link color-column "{{bgDefault}}"
color-link cursor-line "{{bgDefault}}"
color-link scrollbar "{{calcFgStatusLine}},{{calcBgStatusLine}}"

color-link message "{{calcFgMessage}}"
color-link statusline "{{calcFgStatusLine}},{{calcBgStatusLine}}"
color-link divider "{{calcBgStatusLine}},{{calcBgStatusLine}}"
color-link line-number "{{calcFgLineNumber}},{{calcBgStatusLine}}"
color-link current-line-number "{{calcFgCurrentLineNumber}},{{calcBgStatusLine}}"

color-link hlsearch "#DDDD00,#442200"
color-link tab-error "{{bgDefault}}"
color-link trailingws "{{bgDefault}}"
color-link underlined "{{fgStatement}}"
color-link ignore "#CC00CC"

color-link selection "#AABBCC,#000080"
color-link indent-char "#202020"
color-link match-brace "#EEEE00"
]]





function setMaxChannelValue(bp, args)
	if args[1] ~= nil then
		local max = tonumber(args[1])
		if type(max) == "number" then
			settings.maxChannelValue = max
			showMessage("settings.maxChannelValue is now " .. settings.maxChannelValue)
		end
	end
end

function getMatchingStrings(array, str)
	local matches = {}
	for _, stringFromArray in ipairs(array) do
		if string.lower(stringFromArray) == str then
			return { stringFromArray }
		elseif string.match(string.lower(stringFromArray), str) then
			table.insert(matches, stringFromArray)
		end
	end
	return matches
end

function logTable(tableInstance, indentLevel)
	assert(type(tableInstance) == "table", "Expected table, received " .. type(tableInstance))
	if not indentLevel then indentLevel = 0 end
	for key, value in pairs(tableInstance) do
		indentString = string.rep("\t", indentLevel) .. key .. " = "
	  	if type(value) == "table" then
			forceLog(indentString .. "(table)")
			logTable(value, indentLevel+1)
	  	elseif type(value) == nil then
			forceLog(indentString .. " nil")
		else
			forceLog(indentString .. tostring(value))
		end
	end
end

function getColorFunctionNames()
	local functionsByName = settings.colorFunctions:getVariables()
	local functionNames = {}
	for _, tbl in pairs(functionsByName) do
		table.insert(functionNames, tbl[1])
	end
	forceLog(table.concat(functionNames, " | "))
	return functionNames
end

function selectColorFunction(bp, args)
	if args[1] ~= nil then
		local colorFunctionNames = getColorFunctionNames()
		local matches = getMatchingStrings(colorFunctionNames, string.lower(args[1]))
		if #matches == 1 then
			settings.colorFunctions:select(matches[1])
			showStatus()
		else
			local s = ""
			for _, scope in ipairs(matches) do
				s = s .. scope .. " "
			end
			showMessage("matching functions: " .. s)
		end
	else
		return
	end
end

function toggleDebugMode()
	settings.isDebugMode = not settings.isDebugMode
	showMessage(settings.isDebugMode and "Debug mode ON" or "Debug mode OFF")
end

function toggleConstraints()
	settings.shouldRecalculateDerivedColors = not settings.shouldRecalculateDerivedColors
	local message = settings.shouldRecalculateDerivedColors and "Derived colors ON" or "Derived colors OFF"
	showMessage(message)
end

function toggleBooleanOption(optionName)
	return function()
		settings[optionName] = not settings[optionName]
		showMessage(string.format("%s: %s", optionName, settings[optionName]))
	end
end

function showMessage(s)
	micro.InfoBar():Message(s)
end

function showError(s)
	micro.InfoBar():Error(s)
end

function log(arg)
	if not settings.isDebugMode then return end
	if type(arg) ~= "string" then arg = tostring(arg) end
	buffer.Log(arg .. "\n")
end

function forceLog(arg)
	if type(arg) ~= "string" then arg = tostring(arg) end
	buffer.Log(arg .. "\n")
end

function logSeparator()
	if settings.isDebugMode then
		log(string.rep("–", 80))
	end
end

function currentScopeInfoToString()
	local currentScope = settings.scopes:current()
	local scopeInfo = padToWidth("scope: " .. currentScope, 32)
	if currentScope == SPECIAL_SCOPES.BASE then
		return scopeInfo .. debugHslColorShort(settings.base)
	elseif currentScope == SPECIAL_SCOPES.ALL or currentScope == SPECIAL_SCOPES.ALL_EXCEPT_FGDEFAULT then
		return padToWidth(scopeInfo, 54)
	elseif currentScope == SPECIAL_SCOPES.ALL_EXCEPT_FGDEFAULT_AS_ONE then
		return scopeInfo .. debugHslColorShort(makeHsl(settings.allExceptFgDefaultAsOne.h, settings.allExceptFgDefaultAsOne.s, settings.allExceptFgDefaultAsOne.l))
	end
	local color = settings.rulesMap[currentScope]
	if color ~= nil then
		return scopeInfo .. debugHslColorShort(makeHsl(color.h, color.s, color.l))
	else
		return scopeInfo .. padToWidth(" (no color set)", 28)
	end
end

function getMaxChannelValue(rules)
	local highestChannelValue = 0
	for scope, hslColor in pairs(rules) do
		local hex = hslToHex(hslColor)
		local r, g, b = hexToRgb(hex)
		local max = math.max(r, g, b)
		if max > highestChannelValue then
			highestChannelValue = max
		end
	end
	return highestChannelValue
end

function debugHslColor(hslValue)
	assert(isValidHsl(hslValue), debugInvalidHsl(hslValue))
	local h, s, l = splitHsl(hslValue)
	local hex = hslToHex({ h = h, s = s, l = l })
	local r, g, b = hexToRgb(hex)
	h = math.floor(h)
	s = math.floor(s)
	l = math.floor(l)
	return string.format("%4s%4s%4s%10s%8s%4s%4s%6s%8s", h, s, l, hex, r, g, b, calcBrightnessHex(hex), getBrightestChannel(hex))
end

function debugHslColorShort(hslValue)
	assert(isValidHsl(hslValue), debugInvalidHsl(hslValue))
	local h, s, l = splitHsl(hslValue)
	h = math.floor(h)
	s = math.floor(s)
	local hex = hslToHex(hslValue)
	local lFormatted = string.format("%.2f", l)
	return string.format("%4s%4s%7s%10s", h, s, lFormatted, hex)
end

function debugInvalidHsl(hsl)
	if type(hsl) ~= "table" then
		return string.format("Invalid HSL - type of hsl is %s", type(hsl))
	end
	return string.format("Invalid HSL - h: %s, s: %s, l: %s", hsl.h, hsl.s, hsl.l)
end

function logRules(isForced)
	if not settings.isDebugMode and isForced == nil then return end
	local logString = string.format("\n%s%29s%15s%11s%23s%s", "Scope", "HSL", "Hex", "RGB", "Brightness\n", string.rep("–", 82) .. "\n")
	for scope, color in pairs(settings.rulesMap) do
		logString = logString .. padToWidth(scope, 30) .. debugHslColor(color) .. "\n"
	end
	forceLog(logString)
end

function forceLogRules()
	logRules(true)
end

function makeString(...)
	local str = ""
	for _, value in ipairs({ ... }) do
		str = str .. string.format("%s", value) .. " "
	end
	return str
end

function addLog(str)
	settings.logString = settings.logString .. str .. " ◼ "
end

function showStatus()
	local colorFunction = settings.colorFunctions:current()[1]
	if colorFunction == settings.CUSTOM_PALETTE_NAME then
		colorFunction = colorFunction .. " " .. table.concat(settings.palettes[settings.CUSTOM_PALETTE_NAME], " ")
	elseif colorFunction == "RandomPalette" then
		colorFunction = colorFunction .. " " .. table.concat(settings.palettes[settings.CUSTOM_PALETTE_NAME], " ")
	end
	local statusInfo = padToWidth(colorFunction, 24) .. " ◼ " .. currentScopeInfoToString()
	showMessage(statusInfo .. " ◼ " .. settings.logString)
	settings.logString = ""
end

function addHue(hue, num)
	hue = hue + num
	if hue > 359 then
		hue = 0
	elseif hue < 1 then
		hue = 359
	end
	return hue
end

function calcBrightness(r, g, b)
	local brightness = math.floor((r + g + b) * 0.1307)
	return clamp(brightness, 0, 100)
end

function calcBrightnessHex(hexColor)
	local r, g, b = hexToRgb(hexColor)
	return calcBrightness(r, g, b)
end

function getBrightestChannel(hex)
	local r, g, b = hexToRgb(hex)
	local maxValue = math.max(r, g, b)
	if maxValue > settings.maxChannelValue then maxValue = "! " .. maxValue end
	return maxValue
end

function normTo255(norm)
	return clamp(math.floor(norm * 255), 0, 255)
end

function clamp(n, min, max)
	if n < min then return min end
	if n > max then return max end
	return n
end

function padToWidth(str, width)
	local len = string.len(str)
	if len > width then return str end
	return str .. string.rep(" ", width - len)
end

function shuffle(array)
	local n = #array
	for i = n, 2, -1 do
		local j = math.random(1, i)
		array[i], array[j] = array[j], array[i]
	end
	return array
end

function shuffleExcludingFirstItem(array)
	local n = #array
	local firstItem = array[1]
	for i = n, 2, -1 do
		local j = math.random(1, i)
		array[i], array[j] = array[j], array[i]
	end
	array[1] = firstItem
	return array
end

function getTableLength(tableInstance)
	local count = 0
	for _ in pairs(tableInstance) do
		count = count + 1
	end
	return count
end

function exclude(list, excludeList)
	local excludeLookup = {}
	for _, str in ipairs(excludeList) do
		excludeLookup[str] = true
	end

	local filteredList = {}
	for _, str in ipairs(list) do
		if excludeLookup[str] == nil then
			table.insert(filteredList, str)
		end
	end

	return filteredList
end

function concat(list1, list2)
	local result = {}
	for _, value in ipairs(list1) do
		table.insert(result, value)
	end
	for _, value in ipairs(list2) do
		table.insert(result, value)
	end
	return result
end

function setTemplateVariables()
	local fgVars, bgVars, calcVars = getTemplateVars()
	settings.fgVars = fgVars
	settings.bgVars = bgVars
	settings.calcVars = calcVars
	settings.fgVarsExceptFgDefault = exclude(fgVars, {
		"fgDefault"
	})
end





function loadCustomColorSchemeNames()
	local dir = os.UserHomeDir() .. "/.config/micro/colorschemes"
	local colorSchemeNames = {}
	local colorSchemeGroups = {}

	local files, err = ioutil.ReadDir(dir)
	if err ~= nil then
		showError("Error reading directory " .. dir)
	else
		for i = 1, #files do
			local filename = files[i]:Name()
			colorSchemeNames[i] = filename:gsub("%.micro", "")
			local groupName = string.gsub(colorSchemeNames[i], "%d+", "")
			if colorSchemeGroups[groupName] == nil then
				colorSchemeGroups[groupName] = true
			end
		end
	end
	settings.colorSchemes = colorSchemeNames

	for groupName, _ in pairs(colorSchemeGroups) do
		table.insert(settings.colorSchemeGroups, groupName)
	end
end

function getNextString(array, currentString)
	local currentIndex = nil
	for i, v in ipairs(array) do
		if v == currentString then
			currentIndex = i
			break
		end
	end

	if not currentIndex then
		return array[1]
	end

	local nextIndex = (currentIndex % #array) + 1
	return array[nextIndex]
end

function getPreviousString(array, currentString)
	local currentIndex = nil
	for i, v in ipairs(array) do
		if v == currentString then
			currentIndex = i
			break
		end
	end

	if not currentIndex then
		return array[1]
	end

	local nextIndex = currentIndex - 1
	if nextIndex < 1 then
		nextIndex = #array
	end
	return array[nextIndex]
end

function selectColorScheme(colorScheme)
	if colorScheme ~= nil then
		config.SetGlobalOption("colorscheme", colorScheme)
		createRulesFromScheme()
		showMessage(string.format("Color scheme set to %s max channel value is %s", padToWidth(colorScheme, 20), settings.originalRulesMaxChannelValue))
	else
		showMessage("selectColorScheme: received nil for colorScheme")
	end
end

function nextColorScheme()
	local colorScheme = getNextString(settings.colorSchemes, config.GetGlobalOption("colorscheme"))
	selectColorScheme(colorScheme)
end

function previousColorScheme()
	local colorScheme = getPreviousString(settings.colorSchemes, config.GetGlobalOption("colorscheme"))
	selectColorScheme(colorScheme)
end

function firstColorScheme()
	if settings.colorSchemes[1] ~= nil then
		selectColorScheme(settings.colorSchemes[1])
	else
		showMessage("No color schemes were detected")
	end
end

function randomColorScheme()
	if settings.colorSchemes[1] ~= nil then
		local colorScheme = settings.colorSchemes[math.random(1, #settings.colorSchemes)]
		selectColorScheme(colorScheme)
	else
		showMessage("No color schemes were detected")
	end
end

function nextGroup()
	if not (#settings.colorSchemes > 0 and #settings.colorSchemeGroups > 0) then
		showMessage("~/.config/micro/colorschemes is empty, create some color schemes first.")
		return
	end
	local currentScheme = config.GetGlobalOption("colorscheme")
	local currentGroup = string.gsub(currentScheme, "%d+", "")
	local nextGroup = getNextString(settings.colorSchemeGroups, currentGroup)

	local found = false
	for _, schemeName in ipairs(settings.colorSchemes) do
		if string.gsub(schemeName, "%d+", "") == nextGroup then
			found = true
			selectColorScheme(schemeName)
			break
		end
	end

	if not found then
		showMessage("nextGroup: could not find the next scheme")
	end
end

function setColorSchemeA()
	local currentColorScheme = config.GetGlobalOption("colorscheme")
	settings.colorSchemeA = currentColorScheme
	showMessage(currentColorScheme .. " saved to A")
end

function setColorSchemeB()
	local currentColorScheme = config.GetGlobalOption("colorscheme")
	settings.colorSchemeB = currentColorScheme
	showMessage(currentColorScheme .. " saved to B")
end

function selectColorSchemeA()
	if settings.colorSchemeA ~= nil then
		selectColorScheme(settings.colorSchemeA)
	else
		showMessage("Color scheme A has not been set")
	end
end

function selectColorSchemeB()
	if settings.colorSchemeB ~= nil then
		selectColorScheme(settings.colorSchemeB)
	else
		showMessage("Color scheme B has not been set")
	end
end





function extractVariables(template)
	local variables = {}
	local seen = {}

	for var in template:gmatch("{{(%w+)}}") do
		if not seen[var] then
			seen[var] = true
			table.insert(variables, var)
		end
	end

	return variables
end

function replaceVariables(template, vars)
	local result = template
	for name, hslValue in pairs(vars) do
		local pattern = "{{(" .. name .. ")}}"
		result = result:gsub(pattern, "#" .. hslToHex(hslValue))
	end
	return result
end

function makeHsl(hue, sat, lig)
	return { h = hue, s = sat, l = lig }
end

function splitHsl(hslValue)
	return hslValue.h, hslValue.s, hslValue.l
end

function hslToString(hslValue)
	return hslValue.h .. " " .. hslValue.s .. " " .. hslValue.l
end

function colorsAreTooClose(a, b)
	local h1, s1, l1 = splitHsl(a)
	local h2, s2, l2 = splitHsl(b)
	return math.abs(h1 - h2) < 10 and math.abs(s1 - s2) < 10 and math.abs(l1 - l2) < 10
end

function isNotTooGarish(r, g, b)
	if r > 127 and g < 127 then
		return false
	end
	return true
end

function hslToRgb(hslValue)
	assert(isValidHsl(hslValue), debugInvalidHsl(hslValue))

	local h = hslValue.h
	local s = hslValue.s
	local l = hslValue.l

	h = h % 360 / 360
	s = math.max(0, math.min(1, s / 100))
	l = math.max(0, math.min(1, l / 100))

	if s == 0 then
		return l * 100, l * 100, l * 100
	end

	local temp2 = l < 0.5 and l * (1 + s) or l + s - l * s
	local temp1 = 2 * l - temp2

	local function hueToRgb(t)
		if t < 0 then t = t + 1 end
		if t > 1 then t = t - 1 end
		if t < 1/6 then return temp1 + (temp2 - temp1) * 6 * t end
		if t < 1/2 then return temp2 end
		if t < 2/3 then return temp1 + (temp2 - temp1) * (2/3 - t) * 6 end
		return temp1
	end

	local r = hueToRgb(h + 1/3)
	local g = hueToRgb(h)
	local b = hueToRgb(h - 1/3)

	r = math.floor(r * 255 + 0.5)
	g = math.floor(g * 255 + 0.5)
	b = math.floor(b * 255 + 0.5)

	return r, g, b
end

function rgbToHex(r, g, b)
	return string.format("%02x%02x%02x", r, g, b)
end

function hexToRgb(hex)
	assert(isValidHex(hex), "hexToRgb: invalid hex value")
	local r = tonumber(hex:sub(1, 2), 16)
	local g = tonumber(hex:sub(3, 4), 16)
	local b = tonumber(hex:sub(5, 6), 16)
	return r, g, b
end

function dimForBackground(hslValue)
	return makeHsl(hslValue.h, hslValue.s, math.min(hslValue.l, settings.backgroundLightness))
end

function varyLightness(hsl, amount)
	local lightness = hsl.l + amount > settings.maxFgLightness and hsl.l - amount or hsl.l + amount
	if lightness < settings.minFgLightness then lightness = settings.minFgLightness end
	return makeHsl(hsl.h, hsl.s, lightness)
end

function varySaturation(hsl, amount)
	local saturation = hsl.s + amount > settings.paletteMaxSaturation and hsl.s - amount or hsl.s + amount
	if saturation < settings.paletteMinSaturation then saturation = settings.paletteMinSaturation end
	return makeHsl(hsl.h, saturation, hsl.l)
end

function ensureSeparationFromDefault(...)
	local fgColor = settings.rulesMap.fgDefault
	for _, scope in ipairs({ ... }) do
		local color = settings.rulesMap[scope]
		if colorsAreTooClose(color, fgColor) then
			setScopeColor(scope, varyLightness(color, 10))
		end
	end
end

function multiplyHexColor(hex, multiplier)
	local r, g, b = hexToRgb(hex)
	r = math.floor(clamp(r * multiplier, 0, settings.maxChannelValue))
	g = math.floor(clamp(g * multiplier, 0, settings.maxChannelValue))
	b = math.floor(clamp(b * multiplier, 0, settings.maxChannelValue))
	return rgbToHex(r, g, b)
end

function hslToHex(hslValue)
	assert(isValidHsl(hslValue), debugInvalidHsl(hslValue))

	local h = hslValue.h
	local s = hslValue.s
	local l = hslValue.l

	h = h % 360 / 360
	s = tonumber(s, 10)
	l = tonumber(l, 10)
	s = math.max(0, math.min(1, s / 100))
	l = math.max(0, math.min(1, l / 100))

	local temp2 = l < 0.5 and l * (1 + s) or l + s - l * s
	local temp1 = 2 * l - temp2

	local function hueToRgb(t)
		if t < 0 then t = t + 1 end
		if t > 1 then t = t - 1 end
		if t < 1/6 then return temp1 + (temp2 - temp1) * 6 * t end
		if t < 1/2 then return temp2 end
		if t < 2/3 then return temp1 + (temp2 - temp1) * (2/3 - t) * 6 end
		return temp1
	end

	local r = hueToRgb(h + 1/3)
	local g = hueToRgb(h)
	local b = hueToRgb(h - 1/3)

	r = math.floor(r * 255 + 0.5)
	g = math.floor(g * 255 + 0.5)
	b = math.floor(b * 255 + 0.5)

	return string.format("%02x%02x%02x", r, g, b)
end

function hexToHsl(hex)
	assert(isValidHex(hex), "hexToHsl: invalid hex value")

	local r = tonumber(hex:sub(1, 2), 16) / 255
	local g = tonumber(hex:sub(3, 4), 16) / 255
	local b = tonumber(hex:sub(5, 6), 16) / 255

	local max = math.max(r, g, b)
	local min = math.min(r, g, b)

	local h, s, l = 0, 0, (max + min) / 2

	if max ~= min then
		local d = max - min
		s = l > 0.5 and d / (2 - max - min) or d / (max + min)

		if max == r then
			h = (g - b) / d + (g < b and 6 or 0)
		elseif max == g then
			h = (b - r) / d + 2
		elseif max == b then
			h = (r - g) / d + 4
		end
		h = h / 6
	end

	h = round(h * 360)
	s = round(s * 100)
	l = l * 100

	return makeHsl(h, s, l)
end

function hexToHslWithFallback(hex)
	if isValidHex(hex) then
		return hexToHsl(hex)
	end
	forceLog(string.format("%s is not a valid hex color", hex))
	return makeHsl(66, 66, 66)
end

function isBackgroundScope(scope)
	assert(type(scope) == "string" and string.len(scope) > 0, "scope is not a string or has zero length")
	if scope:match("^bg") ~= nil or scope:match("^calcBg") ~= nil then return true else return false end
end

function isForegroundScope(scope)
	assert(type(scope) == "string" and string.len(scope) > 0, "scope is not a string or has zero length")
	if scope:match("^fg") ~= nil or scope:match("^calcFg") ~= nil then return true else return false end
end

function groupByPrefix(variables)
	local groups = {}

	for _, var in ipairs(variables) do
		local prefix = string.sub(var, 1, 2)
		if not groups[prefix] then
			groups[prefix] = {}
		end
		table.insert(groups[prefix], var)
	end

	return groups
end

function getBaseColorName(hsl)
	local hue = hsl.h
	if hsl.s < 15 then return "Gray"
	elseif (hue >= 0 and hue < 10) or (hue >= 320 and hue <= 359) then return "Red"
	elseif hue >= 10  and hue < 50  then return "Orange"
	elseif hue >= 50  and hue < 80  then return "Yellow"
	elseif hue >= 80  and hue < 170 then return "Green"
	elseif hue >= 170 and hue < 200 then return "Cyan"
	elseif hue >= 200 and hue < 250 then return "Blue"
	elseif hue >= 250 and hue < 270 then return "Violet"
	elseif hue >= 270 and hue < 290 then return "Purple"
	elseif hue >= 290 and hue < 320 then return "Pink"
	end
end

function saveCurrentThemeToNumberedFile()
	local directory = settings.colorSchemeFolderPath
	directory = directory:match("/$") and directory or directory .. "/"

	local handle = io.popen("ls " .. directory .. "ck*.micro")
	local files = handle:read("*a")
	handle:close()

	local baseColorName = getBaseColorName(settings.rulesMap.fgDefault)

	local prefix = settings.colorSchemePrefix .. baseColorName
	local maxNum = 0
	for file in files:gmatch(prefix .. "(%d+)%.micro") do
		local num = tonumber(file)
		if num and num > maxNum then
			maxNum = num
		end
	end

	local newNum = maxNum + 1
	local filename = string.format("%s%s%02d.micro", directory, prefix, newNum)

	local file, err = io.open(filename, "w")
	if not file then
		log("Failed to open file: " .. err)
	end

	file:write(settings.colorSchemeText)
	file:close()
	showMessage("saved theme to " .. filename)
end

function writeStringToFile(content, filepath)
	if type(content) ~= "string" or string.len(content) == 0 then
		showError("writeStringToFile: content must be a non-empty string")
		return false
	end
	if type(filepath) ~= "string" or filepath == "" then
		showError("writeStringToFile: filepath must be a non-empty string")
		return false
	end

	local file, err = io.open(filepath, "w")
	if not file then
		showError("Failed to open file: " .. err)
		return false
	end

	file:write(content)
	file:close()

	return true
end

function stripHash(str)
	return str:gsub("#", "")
end

function applyColorScheme()
	settings.currentColorScheme = config.GetGlobalOption("colorscheme")
	if settings.currentColorScheme == "zzChromaKeys1" then
		settings.currentColorScheme = "zzChromaKeys2"
	else
		settings.currentColorScheme = "zzChromaKeys1"
	end

	local themeFilePath = settings.colorSchemeFolderPath .. "/" .. settings.currentColorScheme .. ".micro"
	local success, err = pcall(function()
		writeStringToFile(settings.colorSchemeText, themeFilePath)
	end)
	if not success then
		showMessage("Error: " .. err)
	else
		log("Saved " .. settings.currentColorScheme .. ".micro")
		showStatus()
		config.SetGlobalOption("colorscheme", settings.currentColorScheme)
	end
end

function getTemplateVars()
	local templateVars = extractVariables(colorSchemeTemplate)
	local groupedTemplateVars = groupByPrefix(templateVars)

	local fgVars
	local bgVars
	local calcVars

	for prefix, group in pairs(groupedTemplateVars) do
		if prefix == "fg" then
			fgVars = group
		end
		if prefix == "bg" then
			bgVars = group
		end
		if prefix == "ca" then
			calcVars = group
		end
	end

	return fgVars, bgVars, calcVars
end

function resetBaseSaturationAndLightness()
	settings.base.s = 50
	settings.base.l = 50
	createDemoRules()
	createColorSchemeText()
	applyColorScheme()
end

function round (x)
	local f = math.floor(x)
	if x == f then return f
	else return math.floor(x + 0.5)
	end
end

function adjustHsl(hslValue, action, scope)
	assert(isValidHsl(hslValue), debugInvalidHsl(hslValue))
	local h = hslValue.h
	local s = hslValue.s
	local l = hslValue.l
	local hueStep = settings.hueStep
	local saturationStep = settings.saturationStep
	local lightnessStep = settings.lightnessStep
	if action == ACTIONS.HUE_INCREASE then
		h = addHue(h, hueStep)
		if hueStep > 1 then h = math.floor(h / hueStep) * hueStep end
	elseif action == ACTIONS.HUE_DECREASE then
		h = addHue(h, -hueStep)
		if hueStep > 1 then h = math.floor(h / hueStep) * hueStep end
	elseif action == ACTIONS.SATURATION_INCREASE then
		s = math.min(s + saturationStep, 100)
		if saturationStep > 1 then s = math.floor(s / saturationStep) * saturationStep end
	elseif action == ACTIONS.SATURATION_DECREASE then
		s = math.max(s - saturationStep, 0)
		if saturationStep > 1 then s = math.floor(s / saturationStep) * saturationStep end
	elseif action == ACTIONS.LIGHTNESS_INCREASE then
		l = math.min(l + lightnessStep, settings.maxFgLightness)
	elseif action == ACTIONS.LIGHTNESS_DECREASE then
		l = math.max(l - lightnessStep, 0)
	elseif action == ACTIONS.HUE_INCREASE_LARGE then
		h = round(addHue(h, settings.hueCycleStep) / settings.hueCycleStep) * settings.hueCycleStep
	elseif action == ACTIONS.HUE_DECREASE_LARGE then
		h = round(addHue(h, -settings.hueCycleStep) / settings.hueCycleStep) * settings.hueCycleStep
	elseif action == ACTIONS.SATURATION_INCREASE_LARGE then
		s = clamp(round((s + 5) / 5) * 5, 0, 100)
	elseif action == ACTIONS.SATURATION_DECREASE_LARGE then
		s = clamp(round((s - 5) / 5) * 5, 0, 100)
	elseif action == ACTIONS.LIGHTNESS_INCREASE_LARGE then
		l = clamp(round((l + 5) / 5) * 5, 0, 100)
	elseif action == ACTIONS.LIGHTNESS_DECREASE_LARGE then
		l = clamp(round((l - 5) / 5) * 5, 0, 100)
	elseif action == ACTIONS.RANDOMISE then
		h = math.random(0, 359)
		s = math.random(10, 90)
		l = isBackgroundScope(scope) and settings.backgroundLightness or math.random(settings.minFgLightness, settings.maxFgLightness)
	elseif action == ACTIONS.RANDOMISE_HUE then
		h = math.random(0, 359)
	elseif action == ACTIONS.RANDOMISE_SATURATION then
		s = math.random(20, 80)
	elseif action == ACTIONS.RANDOMISE_LIGHTNESS then
		l = math.random(settings.minFgLightness, settings.maxFgLightness)
	end
	return makeHsl(h, s, l)
end

function createAdjustmentCommand(command)
	return function()
		adjustCurrentScopeColor(command)
	end
end

function adjustCurrentScopeColor(action)
	if getTableLength(settings.rulesMap) == 0 then
		forceLog("adjustCurrentScopeColor: settings.rulesMap is empty")
		generateColorScheme()
	end
	local currentScope = settings.scopes:current()
	if currentScope == SPECIAL_SCOPES.BASE then
		setBaseColor(adjustHsl(settings.base, action, currentScope))
		createDemoRules()
	elseif currentScope == SPECIAL_SCOPES.ALL then
		for scope, currentColor in pairs(settings.rulesMap) do
			if scope ~= "bgDefault" then
				setScopeColor(scope, adjustHsl(currentColor, action, scope))
			end
		end
	elseif currentScope == SPECIAL_SCOPES.ALL_EXCEPT_FGDEFAULT then
		for scope, currentColor in pairs(settings.rulesMap) do
			if scope ~= "fgDefault" and scope ~= "bgDefault" then
				setScopeColor(scope, adjustHsl(currentColor, action, scope))
			end
		end
	elseif currentScope == SPECIAL_SCOPES.ALL_EXCEPT_FGDEFAULT_AS_ONE then
		local currentColor = settings.allExceptFgDefaultAsOne
		local adjustedHsl = adjustHsl(currentColor, action, currentScope)
		if action == ACTIONS.RANDOMISE_HUE or action == ACTIONS.HUE_INCREASE or action == ACTIONS.HUE_INCREASE_LARGE or action == ACTIONS.HUE_DECREASE or action == ACTIONS.HUE_DECREASE_LARGE then
			for _, scope in ipairs(settings.fgVarsExceptFgDefault) do
				settings.rulesMap[scope].h = adjustedHsl.h
			end
		elseif action == ACTIONS.RANDOMISE_SATURATION or action == ACTIONS.SATURATION_INCREASE or action == ACTIONS.SATURATION_INCREASE_LARGE or action == ACTIONS.SATURATION_DECREASE or action == ACTIONS.SATURATION_DECREASE_LARGE then
			for _, scope in ipairs(settings.fgVarsExceptFgDefault) do
				settings.rulesMap[scope].s = adjustedHsl.s
			end
		elseif action == ACTIONS.RANDOMISE_LIGHTNESS or action == ACTIONS.LIGHTNESS_INCREASE or action == ACTIONS.LIGHTNESS_INCREASE_LARGE or action == ACTIONS.LIGHTNESS_DECREASE or action == ACTIONS.LIGHTNESS_DECREASE_LARGE then
			for _, scope in ipairs(settings.fgVarsExceptFgDefault) do
				settings.rulesMap[scope].l = adjustedHsl.l
			end
		else
			for _, scope in ipairs(settings.fgVarsExceptFgDefault) do
				setScopeColor(scope, adjustedHsl)
			end
		end
		settings.rulesMap.bgDefault = forceLightness(settings.rulesMap.bgDefault, settings.backgroundLightness)
		settings.allExceptFgDefaultAsOne = adjustedHsl
	else
		setScopeColor(currentScope, adjustHsl(settings.rulesMap[currentScope], action, currentScope))
	end

	local scopesThatTriggerRecalculationOfDerivedColors = {
		[SPECIAL_SCOPES.BASE] = true,
		[SPECIAL_SCOPES.ALL] = true,
		[SPECIAL_SCOPES.ALL_EXCEPT_FGDEFAULT] = true,
	}

	if scopesThatTriggerRecalculationOfDerivedColors[currentScope] then
		settings.shouldRecalculateDerivedColors = true
	else
		settings.shouldRecalculateDerivedColors = false
	end

	applyConstraintsToRules()
	createColorSchemeText()
	applyColorScheme()
end

function setBaseColor(hsl)
	settings.base = hsl
end

function setBackgroundColor(hsl)
	settings.backgroundLightness = hsl.l
	settings.backgroundSaturation = hsl.s
end

function setScopeColor(scope, hsl)
	settings.rulesMap[scope] = hsl
	if scope == "fgDefault" then
		deriveBgDefaultFromFgDefault()
	elseif scope == "fgComment" then
		deriveBgCommentFromFgComment()
	elseif scope == "bgDefault" or scope == SPECIAL_SCOPES.ALL or scope == SPECIAL_SCOPES.ALL_EXCEPT_FGDEFAULT or scope == SPECIAL_SCOPES.ALL_EXCEPT_FGDEFAULT_AS_ONE then
		setBackgroundColor(settings.rulesMap.bgDefault)
	elseif scope == "calcFgMessage" then
		settings.rulesMap.calcFgLineNumber.h = settings.rulesMap.calcFgMessage.h
		settings.rulesMap.calcFgStatusLine.h = settings.rulesMap.calcFgMessage.h
	elseif scope == "calcFgLineNumber" then
		settings.rulesMap.calcFgMessage.h = settings.rulesMap.calcFgLineNumber.h
		settings.rulesMap.calcFgStatusLine.h = settings.rulesMap.calcFgLineNumber.h
	elseif scope == "calcFgStatusLine" then
		settings.rulesMap.calcFgLineNumber.h = settings.rulesMap.calcFgStatusLine.h
		settings.rulesMap.calcFgMessage.h = settings.rulesMap.calcFgStatusLine.h
	end
end

function forceBrightness(hslValue, desiredBrightness)
	local hexColor = hslToHex(hslValue)
	local multiplier = desiredBrightness / calcBrightnessHex(hexColor)
	local adjustedHexColor = multiplyHexColor(hexColor, multiplier)
	return hexToHsl(adjustedHexColor)
end

function adjustPerceptualBrightness(hsl)
	local hueKey = math.floor(hsl.h / 10) * 10
	local adjustmentLookup = {
		[210] = 4,
		[220] = 9,
		[230] = 12,
		[240] = 16,
		[250] = 14,
		[260] = 12,
		[270] = 11,
		[280] = 9,
	}
	local adjustment = adjustmentLookup[hueKey]
	if adjustment ~= nil then
		hsl.l = math.min(hsl.l + adjustment, 100)
	end
	return hsl
end

function forceLightness(hslValue, desiredLightness)
	return makeHsl(hslValue.h, hslValue.s, desiredLightness)
end

function clampSaturation(hslValue, min, max)
	return makeHsl(hslValue.h, clamp(hslValue.s, min, max), hslValue.l)
end

function clampLightness(hslValue, min, max)
	return makeHsl(hslValue.h, hslValue.s, clamp(hslValue.l, min, max))
end

function forceSaturation(hslValue, desiredSaturation)
	return makeHsl(hslValue.h, desiredSaturation, hslValue.l)
end

function limitChannelBrightness(hslValue, scope)
	local r, g, b = hslToRgb(hslValue)
	local brightestChannel = math.max(r, g, b)
	if brightestChannel == 0 then brightestChannel = 1 end
	if brightestChannel > settings.maxChannelValue then
		local multiplier = settings.maxChannelValue / brightestChannel
		r = r * multiplier
		g = g * multiplier
		b = b * multiplier
		local hex = rgbToHex(r, g, b)
		local newHslValue = hexToHsl(hex)
		return newHslValue
	end
	return hslValue
end





function deriveBgDefaultFromFgDefault()
	setScopeColor("bgDefault", forceSaturation(forceLightness(settings.rulesMap.fgDefault, settings.backgroundLightness), settings.backgroundSaturation))
end

function deriveBgCommentFromFgComment()
	setScopeColor("calcBgComment", forceLightness(settings.rulesMap.fgComment, settings.commentBgLightness))
end

function getDimmestColor(hslColors)
	local minL = 100
	local dimmestColorIndex = 1
	for index, color in ipairs(hslColors) do
		if color.l < minL then
			minL = color.l
			dimmestColorIndex = index
		end
	end
	return hslColors[dimmestColorIndex]
end

function createRules()
	for i, varName in ipairs(settings.fgVars) do
		setScopeColor(varName, settings.fgColors[i])
	end
	for i, varName in ipairs(settings.bgVars) do
		setScopeColor(varName, makeHsl(settings.fgColors[1].h, settings.backgroundSaturation, settings.backgroundLightness))
	end
	for i, varName in ipairs(settings.calcVars) do
		setScopeColor(varName, makeHsl(66, 66, 66))
	end
	if settings.shouldLockFgDefaultToBaseColor then
		setScopeColor("fgDefault", settings.base)
	end
	if settings.shouldAdjustPerceptualBrightness then
		for _, varName in ipairs(settings.fgVars) do
			settings.rulesMap[varName] = adjustPerceptualBrightness(settings.rulesMap[varName])
		end
	end
end

function createDemoRules()
	local fgColor = settings.base
	local bgColor = dimForBackground(fgColor)
	for _, varName in ipairs(settings.fgVars) do
		settings.rulesMap[varName] = fgColor
	end
	for _, varName in ipairs(settings.bgVars) do
		settings.rulesMap[varName] = bgColor
	end
	for _, varName in ipairs(settings.calcVars) do
		settings.rulesMap[varName] = fgColor
	end
	for _, varName in ipairs(SPECIAL_SCOPES) do
		settings.rulesMap[varName] = fgColor
	end
	applyConstraintsToRules()
end

function sanitizeScopeFromFile(scope)
	assert(type(scope) == "string", "sanitizeScopeFromFile: scope is not a string")
	return string.gsub(scope, "[-.]", "")
end

function createRulesFromScheme()
	local currentColorScheme = config.GetGlobalOption("colorscheme")
	local currentColorSchemeFile = settings.colorSchemeFolderPath .. "/" .. currentColorScheme .. ".micro"

	local schemeVarsToSanitizedKeys = {
		default           = "fgDefault",
		statement         = "fgStatement",
		constant          = "fgConstant",
		constantstring    = "fgConstantString",
		constantregex     = "fgConstantRegex",
		comment           = "fgComment",
		identifier        = "fgIdentifier",
		preproc           = "fgPreproc",
		special           = "fgSpecial",
		symbol            = "fgSymbol",
		type              = "fgType",
		statusline        = "StatusLine",
		message           = "Message",
		linenumber        = "LineNumber",
		currentlinenumber = "CurrentLineNumber"
	}

	local colorTable = {}

	local data, err = ioutil.ReadFile(currentColorSchemeFile)

	if err ~= nil then
		showMessage("Chromakeys: Could not read file " .. currentColorSchemeFile)
		createDemoRules()
		return
	else
		log("Creating rules from color scheme " .. currentColorScheme)
		local fileDataAsString = fmt.Sprintf("%s", data)
		for line in fileDataAsString:gmatch("[^\r\n]+") do
			local scope, colors = line:match('color%-link%s+([%w%-%.]+)%s+"([^"]+)"')
			if scope then scope = sanitizeScopeFromFile(scope) end
			if scope and colors and schemeVarsToSanitizedKeys[scope] ~= nil then
				local sanitizedKey = schemeVarsToSanitizedKeys[scope]
				local scopeColors = {}
				for color in colors:gmatch("[^,]+") do
					local colorHex = color:gsub("bold ", "")
					colorHex = colorHex:gsub("#", "")
					table.insert(scopeColors, colorHex)
				end

				colorTable[sanitizedKey] = {}
				if #scopeColors == 1 then
					colorTable[sanitizedKey].fg = scopeColors[1]
				elseif #scopeColors == 2 then
					colorTable[sanitizedKey].fg = scopeColors[1]
					colorTable[sanitizedKey].bg = scopeColors[2]
				end
			end
		end
	end

	for sanitizedKey, colors in pairs(colorTable) do
		if sanitizedKey == "fgDefault" then
			settings.rulesMap.fgDefault = hexToHslWithFallback(colors.fg)
			settings.rulesMap.bgDefault = hexToHslWithFallback(colors.bg)
			setBackgroundColor(settings.rulesMap.bgDefault)
		elseif sanitizedKey == "fgComment" then
			settings.rulesMap.fgComment = hexToHslWithFallback(colors.fg)
			settings.rulesMap.calcBgComment = hexToHslWithFallback(colors.bg)
		elseif sanitizedKey == "StatusLine" then
			settings.rulesMap.calcFgStatusLine = hexToHslWithFallback(colors.fg)
			settings.rulesMap.calcBgStatusLine = hexToHslWithFallback(colors.bg)
		elseif sanitizedKey == "Message" then
			settings.rulesMap.calcFgMessage = hexToHslWithFallback(colors.fg)
		elseif sanitizedKey == "LineNumber" then
			settings.rulesMap.calcFgLineNumber = hexToHslWithFallback(colors.fg)
		elseif sanitizedKey == "CurrentLineNumber" then
			settings.rulesMap.calcFgCurrentLineNumber = hexToHslWithFallback(colors.fg)
		else
			settings.rulesMap[sanitizedKey] = hexToHslWithFallback(colors.fg)
		end
	end

	log("Original rules:")
	logRules()
	settings.originalRulesMaxChannelValue = getMaxChannelValue(settings.rulesMap)
	limitChannelBrightnessForAllRules()
	log("Rules after limiting channel brightness:")
	logRules()
	createColorSchemeText()
	setBaseColor(settings.rulesMap.fgDefault)
end

function isValidHsl(value)
	return type(value) == "table" and value.h ~= nil and value.s ~= nil and value.l ~= nil
end

function isValidHex(value)
	return type(value) == "string" and string.len(value) == 6
end

function checkRulesValidity()
	for _, scope in ipairs(settings.fgVars) do
		if settings.rulesMap[scope] == nil then
			forceLog(scope .. " is nil")
			return false
		elseif not isValidHsl(settings.rulesMap[scope]) then
			forceLog(string.format("checkRulesValidity: settings.rulesMap[%s] is not an HSL value", scope))
			return false
		end
	end
	return true
end

function ensureFgBgLightness()
	for _, scope in ipairs(settings.fgVars) do
		settings.rulesMap[scope] = clampLightness(settings.rulesMap[scope], settings.minFgLightness, settings.maxFgLightness)
	end
	for _, scope in ipairs(settings.bgVars) do
		settings.rulesMap[scope] = clampLightness(settings.rulesMap[scope], 0, settings.maxBgLightness)
	end
end

function applyConstraintsToRules()
	local areRulesValid = checkRulesValidity()
	if not areRulesValid then
		forceLog("applyConstraintsToRules: rules are not valid, returning")
		return false
	end

	-- settings.rulesMap.fgDefault.l = getDimmestColor(settings.fgColors).l
	ensureFgBgLightness()

	local fg = settings.rulesMap.fgDefault
	local bg = settings.rulesMap.bgDefault

	if settings.shouldRecalculateDerivedColors then
		settings.rulesMap.fgSymbol                = varyLightness(fg, 15)
		settings.rulesMap.fgComment               = clampLightness(settings.rulesMap.fgComment, 50, 75)
		settings.rulesMap.calcBgComment           = forceLightness(settings.rulesMap.fgComment, 15)
		settings.rulesMap.calcFgStatusLine        = clampSaturation(forceLightness(fg, 35), 0, 35)
		settings.rulesMap.calcBgStatusLine        = clampSaturation(forceLightness(fg, 4), 0, 35)
		settings.rulesMap.calcBgStatusLine.l      = math.min(settings.rulesMap.calcBgStatusLine.l, bg.l)
		settings.rulesMap.calcFgLineNumber        = clampSaturation(forceLightness(fg, 25), 0, 40)
		settings.rulesMap.calcFgCurrentLineNumber = clampSaturation(forceLightness(fg, 65), 0, 40)
		settings.rulesMap.calcFgMessage           = clampSaturation(forceLightness(fg, 35), 0, 35)

		settings.rulesMap.fgConstantString.h = settings.rulesMap.fgConstant.h
		settings.rulesMap.fgConstantString.l = settings.rulesMap.fgConstant.l
	end

	if settings.shouldForceUniformBrightness then
		for _, varName in ipairs(settings.fgVars) do
			settings.rulesMap[varName] = forceBrightness(settings.rulesMap[varName], settings.uniformBrightness)
		end
	end

	if settings.shouldEnsureSeparation then
		ensureSeparationFromDefault("fgStatement", "fgConstant", "fgConstantString")
	end

	if settings.shouldLimitChannelValues then
		limitChannelBrightnessForAllRules()
	end

	logRules()
end

function limitChannelBrightnessForAllRules()
	for scope, _ in pairs(settings.rulesMap) do
		if isBackgroundScope(scope) then
			settings.rulesMap[scope] = clampLightness(settings.rulesMap[scope], 0, settings.maxBgLightness)
		else
			settings.rulesMap[scope] = limitChannelBrightness(settings.rulesMap[scope], scope)
		end
	end
end

function createColorSchemeText()
	settings.colorSchemeText = replaceVariables(colorSchemeTemplate, settings.rulesMap)
end



function getVarianceBasedOnNumberOfHues(numHues)
	local varianceLookup = {
		[1] = 60,
		[2] = 50,
		[3] = 40,
		[4] = 30,
		[5] = 20,
		[6] = 10,
		[7] = 10,
		[8] = 10,
		[9] = 10,
		[10] = 10,
	}

	local variance = varianceLookup[numHues]
	if variance == nil then variance = 30 end
	return variance
end

function generateColorsByPalette(hues, numColors)
	if #hues == 0 then
		showMessage(string.format("Palette '%s' is empty", paletteName))
		return {}
	end
	local colorsPerHue = math.ceil(numColors / #hues)
	local colors = {}
	local s = settings.base.s
	local l = settings.base.l

	local hVariance = 10
	local variance = getVarianceBasedOnNumberOfHues(#hues)
	local sVariance = variance
	local lVariance = variance
	local hFinal, sFinal, lFinal

	if settings.useBaseSL then
		for _, hue in ipairs(hues) do
			for _ = 1, colorsPerHue do
				hFinal = addHue(hue, math.random(0, hVariance))
				sFinal = clamp(s + (math.random(0, sVariance) - sVariance * 0.5), 0, 100)
				lFinal = clamp(l + (math.random(0, lVariance) - lVariance * 0.5), 0, 100)
				table.insert(colors, makeHsl(hFinal, sFinal, lFinal))
				if #colors == numColors then break end
			end
			if #colors == numColors then break end
		end
	else
		for _, hue in ipairs(hues) do
			for _ = 1, colorsPerHue do
				hFinal = addHue(hue, math.random(0, hVariance))
				sFinal = math.random(10, 100)
				lFinal = math.random(settings.minFgLightness, 60)
				table.insert(colors, makeHsl(hFinal, sFinal, lFinal))
				if #colors == numColors then break end
			end
			if #colors == numColors then break end
		end
	end

	shuffleExcludingFirstItem(colors)

	return colors
end

function createPaletteFunction(paletteName)
	return function(numColors)
		local hues = settings.palettes[paletteName]
		return generateColorsByPalette(hues, numColors)
	end
end

function generateColorsByRandomPalette(numColors)
	settings.palettes[settings.CUSTOM_PALETTE_NAME] = { math.random(0, 359), math.random(0, 359) }
	return generateColorsByPalette(settings.palettes[settings.CUSTOM_PALETTE_NAME], numColors)
end

function generateColorsByCustomHues(numColors)
	return generateColorsByPalette(settings.palettes[settings.CUSTOM_PALETTE_NAME], numColors)
end

function generateColorsBySemiRandomPalette(numColors)
	if math.random() > 0.5 then
		settings.palettes[settings.CUSTOM_PALETTE_NAME] = { settings.base.h, math.random(0, 359) }
	else
		settings.palettes[settings.CUSTOM_PALETTE_NAME] = { math.random(0, 359), settings.base.h }
	end
	return generateColorsByPalette(settings.palettes[settings.CUSTOM_PALETTE_NAME], numColors)
end

function generateColorsBySemiRandomFixedBaseH(numColors)
	settings.palettes[settings.CUSTOM_PALETTE_NAME] = { settings.base.h, math.random(0, 359) }
	return generateColorsByPalette(settings.palettes[settings.CUSTOM_PALETTE_NAME], numColors)
end

function generateColorsBySemiRandomFixedBaseHS(numColors)
	settings.palettes[settings.CUSTOM_PALETTE_NAME] = { settings.base.h, math.random(0, 359) }
	local colors = generateColorsByPalette(settings.palettes[settings.CUSTOM_PALETTE_NAME], numColors)
	colors[1].h = settings.base.h
	colors[1].s = settings.base.s
	return colors
end

function generateColorsBySemiRandomFixedBaseHSL(numColors)
	settings.palettes[settings.CUSTOM_PALETTE_NAME] = { settings.base.h, math.random(0, 359) }
	local colors = generateColorsByPalette(settings.palettes[settings.CUSTOM_PALETTE_NAME], numColors)
	colors[1] = settings.base
	return colors
end

function generateColorsByAdjacentHues(numColors)
	local hue = settings.base.h
	local hueStep = math.random(3, 6)
	local hues = {}

	for _ = 1, 4 do
		hue = addHue(hue, hueStep)
		table.insert(hues, hue)
	end

	return generateColorsByPalette(hues, numColors)
end

function generateColorsByRandomHueForEveryColor(numColors)
	local hues = {}
	for _ = 1, numColors do
		local hue = math.random(0, 359)
		table.insert(hues, hue)
	end

	return generateColorsByPalette(hues, numColors)
end

function generateColorsByRandomLightness(numColors)
	local colors = {}
	for _ = 1, numColors do
		table.insert(colors, makeHsl(settings.base.h, settings.base.s, math.random(settings.minFgLightness, 60)))
	end
	return colors
end

function generateColorsBySteppedLightness(numColors)
	local colors = {}
	local lightnessRange = 65 - settings.minFgLightness
	local step = lightnessRange / numColors
	local lightness = settings.minFgLightness
	for _ = 1, numColors do
		table.insert(colors, makeHsl(settings.base.h, settings.base.s, lightness))
		lightness = lightness + step
	end
	shuffle(colors)
	return colors
end

function generateColorsByShadesOfBaseHue(numColors)
	return generateColorsByPalette({ settings.base.h }, numColors)
end

function generateColorsByShadesOfRandomHue(numColors)
	return generateColorsByPalette({ math.random(0, 359) }, numColors)
end

function generateColorsByShadesOfCyclicHue(numColors)
	return generateColorsByPalette({ math.floor(settings.generationCount * 2 % 360) }, numColors)
end





function initScopeCycler()
	settings.scopes = Cyclable.new(settings.bgVars)
	for _, scope in ipairs(settings.fgVars) do
		settings.scopes:add(scope)
	end
	for _, scope in ipairs(settings.calcVars) do
		settings.scopes:add(scope)
	end
	for scope, _ in pairs(SPECIAL_SCOPES) do
		settings.scopes:addAndSelect(SPECIAL_SCOPES[scope])
	end
end

function previousScope()
	settings.scopes:previous()
	showStatus()
end

function nextScope()
	settings.scopes:next()
	showStatus()
end

function initColorFuncCycler()
	settings.colorFunctions = Cyclable.new({})
	for paletteName, paletteHues in pairs(settings.palettes) do
		settings.colorFunctions:add({ paletteName, createPaletteFunction(paletteName) })
	end
	settings.colorFunctions:add({ "RandomHue",              generateColorsByRandomHue              })
	settings.colorFunctions:add({ "RandomHueForEveryColor", generateColorsByRandomHueForEveryColor })
	settings.colorFunctions:add({ "AdjacentHues",           generateColorsByAdjacentHues           })
	settings.colorFunctions:add({ "ShadesOfCyclicHue",      generateColorsByShadesOfCyclicHue      })
	settings.colorFunctions:add({ "ShadesOfBaseHue",        generateColorsByShadesOfBaseHue        })
	settings.colorFunctions:add({ "ShadesOfRandomHue",      generateColorsByShadesOfRandomHue      })
	settings.colorFunctions:add({ "RandomLightness",        generateColorsByRandomLightness        })
	settings.colorFunctions:add({ "SteppedLightness",       generateColorsBySteppedLightness       })
	settings.colorFunctions:add({ "SemiRandomFixedBaseHSL", generateColorsBySemiRandomFixedBaseHSL })
	settings.colorFunctions:add({ "SemiRandomFixedBaseHS",  generateColorsBySemiRandomFixedBaseHS  })
	settings.colorFunctions:add({ "SemiRandomFixedBaseH",   generateColorsBySemiRandomFixedBaseH   })
	settings.colorFunctions:add({ "SemiRandomPalette",      generateColorsBySemiRandomPalette      })
	settings.colorFunctions:add({ "RandomPalette",          generateColorsByRandomPalette          })
	settings.colorFunctions:add({ "CustomHues",             generateColorsByCustomHues             })

	settings.colorFunctions:select("CustomHues")
end

function previousColorFunction()
	settings.colorFunctions:previous()
	generateColorScheme()
	showStatus()
end

function nextColorFunction()
	settings.colorFunctions:next()
	generateColorScheme()
	showStatus()
end

function generateColorScheme()
	-- math.randomseed(time.Now():Unix())
	assert(#settings.fgVars > 1, "fgVars are not set")
	settings.shouldRecalculateDerivedColors = true
	local colorGenFunc = settings.colorFunctions:current()[2]
	settings.fgColors = colorGenFunc(#settings.fgVars)

	if #settings.fgColors == #settings.fgVars then
		if settings.shouldForceOneColorToWhite then
			local index = math.random(1, #settings.fgColors)
			settings.fgColors[index] = makeHsl(0, 0, settings.maxFgLightness)
		end
		createRules()
		applyConstraintsToRules()
		createColorSchemeText()
		applyColorScheme()
		settings.generationCount = settings.generationCount + 1
	else
		forceLog(string.format("Expected %s colors, received %s", #settings.fgVars, #settings.fgColors))
	end
end





function showCustomPalette()
	showMessage("Custom palette is now { " .. table.concat(settings.palettes[settings.CUSTOM_PALETTE_NAME], ", ") .. " }")
end

function customPaletteSetHues(bp, args)
	if args ~= nil and #args > 0 then
		local hues = {}
		for i = 1, #args do
			local hue = tonumber(args[i])
			if type(hue) == "number" then
				table.insert(hues, hue)
			end
		end
		if #hues > 0 then
			settings.palettes[settings.CUSTOM_PALETTE_NAME] = hues
			settings.colorFunctions:select(settings.CUSTOM_PALETTE_NAME)
			generateColorScheme()
		end
	end
end

function randomizeCustomPaletteAndGenerate()
	randomizeCustomPalette()
	generateColorScheme()
end

function randomizeCustomPalette()
	settings.palettes[settings.CUSTOM_PALETTE_NAME] = { math.random(0, 359), math.random(0, 359) }
	settings.colorFunctions:select(settings.CUSTOM_PALETTE_NAME)
end





function createScratchFilesIfRequired()
	local scratchFiles = {
		settings.colorSchemeFolderPath .. "/zzChromaKeys1.micro",
		settings.colorSchemeFolderPath .. "/zzChromaKeys2.micro"
	}

	local isReloadRequired = false

	for _, filePath in ipairs(scratchFiles) do
		local data, err = ioutil.ReadFile(filePath)
		if err ~= nil then
			isReloadRequired = true
			forceLog(filePath .. " does not exist, creating...")
			createDemoRules()
			createColorSchemeText()
			writeStringToFile(settings.colorSchemeText, filePath)
		end
	end

	if isReloadRequired then
		config.Reload()
	end
end

function init()
	math.randomseed(time.Now():Unix())
	settings.colorSchemeFolderPath = os.UserHomeDir() .. "/.config/micro/colorschemes"
	loadCustomColorSchemeNames()
	setTemplateVariables()
	initScopeCycler()
	initColorFuncCycler()
	createRulesFromScheme()
	createColorSchemeText()
	createScratchFilesIfRequired()
	randomizeCustomPalette()

	if settings.showStatusOnLoad then
		showStatus()
	end

	config.MakeCommand("ckRefreshColorSchemeList",          loadCustomColorSchemeNames,                                 config.NoComplete)
	config.MakeCommand("ckGenerateColorScheme",             generateColorScheme,                                        config.NoComplete)
	config.MakeCommand("ckPreviousColorFunction",           previousColorFunction,                                      config.NoComplete)
	config.MakeCommand("ckNextColorFunction",               nextColorFunction,                                          config.NoComplete)
	config.MakeCommand("ckScopeNext",                       nextScope,                                                  config.NoComplete)
	config.MakeCommand("ckScopePrevious",                   previousScope,                                              config.NoComplete)
	config.MakeCommand("ckHueInc",                          createAdjustmentCommand(ACTIONS.HUE_INCREASE),              config.NoComplete)
	config.MakeCommand("ckHueDec",                          createAdjustmentCommand(ACTIONS.HUE_DECREASE),              config.NoComplete)
	config.MakeCommand("ckSaturationInc",                   createAdjustmentCommand(ACTIONS.SATURATION_INCREASE),       config.NoComplete)
	config.MakeCommand("ckSaturationDec",                   createAdjustmentCommand(ACTIONS.SATURATION_DECREASE),       config.NoComplete)
	config.MakeCommand("ckLightnessInc",                    createAdjustmentCommand(ACTIONS.LIGHTNESS_INCREASE),        config.NoComplete)
	config.MakeCommand("ckLightnessDec",                    createAdjustmentCommand(ACTIONS.LIGHTNESS_DECREASE),        config.NoComplete)
	config.MakeCommand("ckHueIncLarge",                     createAdjustmentCommand(ACTIONS.HUE_INCREASE_LARGE),        config.NoComplete)
	config.MakeCommand("ckHueDecLarge",                     createAdjustmentCommand(ACTIONS.HUE_DECREASE_LARGE),        config.NoComplete)
	config.MakeCommand("ckSaturationIncLarge",              createAdjustmentCommand(ACTIONS.SATURATION_INCREASE_LARGE), config.NoComplete)
	config.MakeCommand("ckSaturationDecLarge",              createAdjustmentCommand(ACTIONS.SATURATION_DECREASE_LARGE), config.NoComplete)
	config.MakeCommand("ckLightnessIncLarge",               createAdjustmentCommand(ACTIONS.LIGHTNESS_INCREASE_LARGE),  config.NoComplete)
	config.MakeCommand("ckLightnessDecLarge",               createAdjustmentCommand(ACTIONS.LIGHTNESS_DECREASE_LARGE),  config.NoComplete)
	config.MakeCommand("ckRandomiseHue",                    createAdjustmentCommand(ACTIONS.RANDOMISE_HUE),             config.NoComplete)
	config.MakeCommand("ckRandomiseSaturation",             createAdjustmentCommand(ACTIONS.RANDOMISE_SATURATION),      config.NoComplete)
	config.MakeCommand("ckRandomiseLightness",              createAdjustmentCommand(ACTIONS.RANDOMISE_LIGHTNESS),       config.NoComplete)
	config.MakeCommand("ckRandomiseColor",                  createAdjustmentCommand(ACTIONS.RANDOMISE),                 config.NoComplete)
	config.MakeCommand("ckResetBaseSaturationAndLightness", resetBaseSaturationAndLightness,                            config.NoComplete)
	config.MakeCommand("ckSaveCurrentTheme",                saveCurrentThemeToNumberedFile,                             config.NoComplete)
	config.MakeCommand("ckCreateRulesFromScheme",           createRulesFromScheme,                                      config.NoComplete)
	config.MakeCommand("ckToggleDebugMode",                 toggleDebugMode,                                            config.NoComplete)
	config.MakeCommand("ckToggleConstraints",               toggleConstraints,                                          config.NoComplete)
	config.MakeCommand("ckForceLogRules",                   forceLogRules,                                              config.NoComplete)
	config.MakeCommand("ckFirstColorScheme",                firstColorScheme,                                           config.NoComplete)
	config.MakeCommand("ckNextGroup",                       nextGroup,                                                  config.NoComplete)
	config.MakeCommand("ckPreviousColorScheme",             previousColorScheme,                                        config.NoComplete)
	config.MakeCommand("ckNextColorScheme",                 nextColorScheme,                                            config.NoComplete)
	config.MakeCommand("ckRandomizeCustomPalette",          randomizeCustomPaletteAndGenerate,                          config.NoComplete)

	config.MakeCommand("ckABSetA",                          setColorSchemeA,                                            config.NoComplete)
	config.MakeCommand("ckABSetB",                          setColorSchemeB,                                            config.NoComplete)
	config.MakeCommand("ckABSelectA",                       selectColorSchemeA,                                         config.NoComplete)
	config.MakeCommand("ckABSelectB",                       selectColorSchemeB,                                         config.NoComplete)

	config.MakeCommand("ckCustomPaletteSetHues",            customPaletteSetHues,                                       config.NoComplete)

	config.MakeCommand("ckSettingsSetMaxChannelValue",      setMaxChannelValue,                                         config.NoComplete)
	config.MakeCommand("ckSettingsToggleUseBaseSL",         toggleBooleanOption("useBaseSL"),                           config.NoComplete)

	config.MakeCommand("ckSelectColorFunction",             selectColorFunction,                                        config.NoComplete)
end
