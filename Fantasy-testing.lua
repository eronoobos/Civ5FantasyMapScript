-- Map Script: Fantasy
-- Author: zoggop
-- version 17

--------------------------------------------------------------
if include == nil then
	package.path = package.path..';C:\\Program Files (x86)\\Steam\\steamapps\\common\\Sid Meier\'s Civilization V\\Assets\\Gameplay\\Lua\\?.lua'
	include = require
end

include("math")
include("MapGenerator")
include("FractalWorld")
include("FeatureGenerator")
include("TerrainGenerator")

function GetMapScriptInfo()
	local world_age, temperature, rainfall, sea_level, resources = GetCoreMapOptions()
	return {
		Name = "Fantasy testing",
		Description = "A map of distinct regions.",
		IconIndex = 5,
		CustomOptions = {
			{
                Name = "Ocean Size",
                Values = {
					"Channels",
                    "Navegable Channels",
                    "Mostly Land",
					"Half Land",
					"Earth",
					"Waterworld",
					"The Great Flood",
					"Random",
                },
                DefaultValue = 5,
                SortPriority = 1,
            },
			{
                Name = "Coast Width",
                Values = {
                    "Thin",
                    "Normal",
					"Wide",
					"Really Wide",
                },
                DefaultValue = 2,
                SortPriority = 1,
            },
			{
                Name = "Continent Size",
                Values = {
					"Tiny",
					"Small",
					"Medium",
					"Big",
					"Pangaea",
					"Random",
                },
                DefaultValue = 3,
                SortPriority = 1,
            },
			{
                Name = "Continent Shape",
                Values = {
					"Extra Snakey",
					"Total Snakes",
					"Snakey",
					"Normal",
					"Blobby",
                    "Total Blobs",
					"Random",
                },
                DefaultValue = 5,
                SortPriority = 1,
            },
			{
                Name = "Island Amount",
                Values = {
					"None",
					"Few",
					"Some",
					"Lots",
					"Tons",
					"Random",
                },
                DefaultValue = 3,
                SortPriority = 1,
            },
			{
                Name = "World Age",
                Values = {
                    "2 Billion Years",
                    "3 Billion Years",
					"4 Billion Years",
					"5 Billion Years",
					"6 Billion Years",
					"Random",
                },
                DefaultValue = 3,
                SortPriority = 1,
            },
			{
                Name = "Region Size",
                Values = {
					"Tiny",
					"Small",
					"Medium",
					"Big",
                    "Ginormous",
					"Random",
                },
                DefaultValue = 3,
                SortPriority = 1,
            },
			{
                Name = "Latitude-Sensitive Climate",
                Values = {
					"No",
					"Yes",
                },
                DefaultValue = 1,
                SortPriority = 1,
            },
            {
            	Name = "Mountain Clumpiness",
            	Values = {
            		"Epic Clumps",
            		"Normal",
            		"Scattered",
            		"Very Scattered",
            		"Completely Scattered",
            	},
            	DefaultValue = 2,
            	SortPriority = 1,
            },
			temperature,
			rainfall,
			resources,
		},
	};
end

----------------------------------------------------------------------------------

local oceanSizeOption = Map.GetCustomOption(1)
local waterDepthOption = Map.GetCustomOption(2)
local continentSizeOption = Map.GetCustomOption(3)
local continentShapeOption = Map.GetCustomOption(4)
local islandAmountOption = Map.GetCustomOption(5)
local worldAgeOption = Map.GetCustomOption(6)
local regionSizeOption = Map.GetCustomOption(7)
local latitudeSensitiveOption = Map.GetCustomOption(8)
local mountainClumpinessOption = Map.GetCustomOption(9)
local temperatureOption = Map.GetCustomOption(10)
local rainfallOption = Map.GetCustomOption(11)

----------------------------------------------------------------------------------

local landRatio = 0.5
local regionNoExpandRatio = 0.333
local continentLargeBrushChance = 15
local regionMinSize = 30
local regionMaxSize = 100
local baseTile = "Grass"
local maxTileIterations = 150
local maxInContinentIterations = 2000
local maxContinentIterations = 50
local paintedRatio = 0.6
local regionPaintedRatio = 0.75
local breakAtPoles = true
local evadePoles = true
local keepItInside = true
local coastRangeRatio = 0.3
local mountainRatio = 0.15
local rangeHillRatio = 0.4
local mountainClumpiness = 0.75
local cSizeMin = 11
local cSizeMax = 50
local iceChance = 0.5
local atollChance = 0.2
local coastExpandChance = 0.1
local coastRecedeChance = 1
local ismuthChance = 0
local levelMountains = 0
local mountainThickness = 0.0
local coastLimitMin = 1
local coastLimitMax = 8
local skinnyMountainRanges = false
local pangaea = false
local hillsness = 0.5
local mountainness = 0.0
local allyness = 0.06
local pWorld = "Mix"
local useLatitude = false
local differenciatePaint = 0.5
local polarIce = false
local smallestRegionSize = 5
local temperature = 2
local rainfall = 2
local directednessTotal = 3
local eighthFavoringTotal = 4
local latitudeTolerance = 5
local islandRatio = 0.1
local islandSizeMax = 10

----

local regionAvgSize = math.floor( (regionMinSize + regionMaxSize) / 2 )

local iW
local iH
local mapArea
local maxRegions
local landArea
local xMax
local yMax
local tileTiles = {}
local regionalTiles = {}
local regionNames = {}
local continentalTiles = {}
local continentalTotalTiles
local continentalXY = {}
local regionList = {}
local totalRegions
local availableIndices = {}
local southPole
local northPole
local tileDictionary = { }
local coastRange = { }
local regionRange = { }
local isCoastRange = { }
local isRegionRange = { }
local regionRangeTileCount = 0
local coastRangeTileCount = 0
local stillOcean = {}
local soQuad = { {}, {}, {}, {} }
local featureAtoll
local totalRegions
local tilesByRegion = {}
local regions = {}
local mountainCount = 0
local isCoast = {}
local terrainAlly = {}
local terrainList = {}
local terrains = {}
local fness = {}
local tmult= {}
local fcurve= {}
local possibleFeatures = {}
local terrainLatitudes = {}
local featureLatitudes = {}
local regionDictionary = {}
local nearOceanIce = {}
local terrainMaxArea = {}
local terrainFilledTiles = {}
local biggestContinentSize = 0
----


local function diceRoll(dice, invert, maximum)
	if invert == nil then invert = false end
	if maximum == nil then maximum = 1.0 end
	local n = 0
	for d = 1, dice do
		n = n + (math.random() / dice)
	end
	if invert == true then
		if n >= 0.5 then n = n - 0.5 else n = n + 0.5 end
	end
	n = n * maximum
	return n
end


local function setBeforeOptions()
	-- ocean size
	if oceanSizeOption == 1 then
		landRatio = 0.94
	elseif oceanSizeOption == 2 then
		landRatio = 0.75
	elseif oceanSizeOption == 3 then
		landRatio = 0.6
	elseif oceanSizeOption == 4 then
		landRatio = 0.5
	elseif oceanSizeOption == 5 then
		landRatio = 0.29
	elseif oceanSizeOption == 6 then
		landRatio = 0.15
	elseif oceanSizeOption == 7 then
		landRatio = 0.02
	elseif oceanSizeOption == 8 then
		landRatio = ((math.random() ^ 1.75) * 0.92) + 0.02
		print("random land ratio: ", landRatio)
	end

	-- water depth
	if waterDepthOption == 1 then
		coastRecedeChance = 1.0
		coastExpandChance = 0.0
	elseif waterDepthOption == 2 then
		coastRecedeChance = 0.0
		coastExpandChance = 0.0
	elseif waterDepthOption == 3 then
		coastRecedeChance = 0.0
		coastExpandChance = 0.15
	elseif waterDepthOption == 4 then
		coastRecedeChance = 0.67
		coastExpandChance = 1.0
	end

		-- continent size
	if continentSizeOption == 1 then -- tiny
		cSizeMin = 11
		cSizeMax = 50
	elseif continentSizeOption == 2 then -- small
		cSizeMin = 25
		cSizeMax = 200
	elseif continentSizeOption == 3 then -- medium
		cSizeMin = 70
		cSizeMax = 540
	elseif continentSizeOption == 4 then -- big
		cSizeMin = 170
		cSizeMax = 1300
	elseif continentSizeOption == 5 then -- pangaea
		pangaea = true
		cSizeMin = 11
		cSizeMax = 180
		ismuthChance = 1.0
	elseif continentSizeOption == 6 then -- random
		cSizeMin = math.ceil( ((math.random() ^ 1.44) * 158) + 12 )
		cSizeMax = math.ceil( cSizeMin * 7.7 )
		print("random min size: ", cSizeMin, "  random max size: ", cSizeMax)
	end

	-- continent shape
	if continentShapeOption == 1 then --extra snakey
		paintedRatio = 1.0
		continentLargeBrushChance = 100
	elseif continentShapeOption == 2 then --total snakes
		paintedRatio = 1.0
	elseif continentShapeOption == 3 then --snakey
		paintedRatio = 0.8
	elseif continentShapeOption == 4 then --normal
		paintedRatio = 0.5
	elseif continentShapeOption == 5 then -- blobby
		paintedRatio = 0.3
	elseif continentShapeOption == 6 then -- total blobs
		paintedRatio = 0.1
	elseif continentShapeOption == 7 then -- random
		paintedRatio = (math.random() * 0.9) + 0.1
		print("random painted ratio: ", paintedRatio)
	end

	-- island amount
	if islandAmountOption == 1 then --none
		islandRatio = 0.0
	elseif islandAmountOption == 2 then --few
		islandRatio = 0.03
	elseif islandAmountOption == 3 then --some
		islandRatio = 0.06
	elseif islandAmountOption == 4 then --lots
		islandRatio = 0.25
	elseif islandAmountOption == 5 then -- tons
		islandRatio = 0.5
	elseif islandAmountOption == 6 then -- random
		islandRatio = (diceRoll(3, false, 1) ^ 3) * 0.5
		print("random island percentage: ", math.floor(islandRatio * 100))
	end

	-- world age
	if worldAgeOption == 1 then
		mountainRatio = 0.25
		coastRangeRatio = 0.35
		rangeHillRatio = 0.25
		hillsness = 0.9
	elseif worldAgeOption == 2 then
		mountainRatio = 0.1
		coastRangeRatio = 0.3
		rangeHillRatio = 0.3
		hillsness = 0.75
	elseif worldAgeOption == 3 then
		mountainRatio = 0.03
		coastRangeRatio = 0.25
		rangeHillRatio = 0.35
		hillsness = 0.6
	elseif worldAgeOption == 4 then
		mountainRatio = 0.015
		coastRangeRatio = 0.2
		skinnyMountainRanges = true
		rangeHillRatio = 0.4
		hillsness = 0.5
	elseif worldAgeOption == 5 then
		mountainRatio = 0.0
		levelMountains = 1.0
		hillsness = 0.25
	elseif worldAgeOption == 6 then
		local mountainsFrodoMountains = math.random()
		print("random mountainousness, 0 to 100: ", math.floor(mountainsFrodoMountains * 100))
		mountainRatio = (mountainsFrodoMountains ^ 3.05) * 0.25
		coastRangeRatio = (mountainsFrodoMountains * 0.2) + 0.15
		rangeHillRatio = ((1 - mountainsFrodoMountains) * 0.2) + 0.2
		hillsness = (mountainsFrodoMountains * 0.65) + 0.25
	end

	--region size
	if regionSizeOption == 1 then -- tiny
		regionMinSize = 10
		regionMaxSize = 20
	elseif regionSizeOption == 2 then -- small
		regionMinSize = 20
		regionMaxSize = 40
	elseif regionSizeOption == 3 then -- medium
		regionMinSize = 40
		regionMaxSize = 80
	elseif regionSizeOption == 4 then -- big
		regionMinSize = 80
		regionMaxSize = 140
	elseif regionSizeOption == 5 then -- Ginormous
		regionMinSize = 140
		regionMaxSize = 280
	elseif regionSizeOption == 6 then -- random
		local r = math.random()
		regionMinSize = math.ceil( ((r * 295) ^ 0.67) + 5 )
		regionMaxSize = math.ceil( ((r * 580) ^ 0.77) + 20 )
		print("random region min size: ", regionMinSize, "  random region max size: ", regionMaxSize)
	end

	-- latitude-based climate
	if latitudeSensitiveOption == 1 then
		useLatitude = false
	elseif latitudeSensitiveOption == 2 then
		useLatitude = true
		polarIce = true
		evadePoles = false
	end

	--temperature
	if temperatureOption == 1 then
		temperature = 1
		iceChance = 0.7
	elseif temperatureOption == 2 then
		temperature = 2
		iceChance = 0.6
	elseif temperatureOption == 3 then
		temperature = 3
		iceChance = 0.5
	elseif temperatureOption == 4 then
		temperature = -1
		iceChance = (math.random() * 0.2) + 0.5
	end

	--rainfall
	if rainfallOption == 1 then
		rainfall = 1
	elseif rainfallOption == 2 then
		rainfall = 2
	elseif rainfallOption == 3 then
		rainfall = 3
	elseif rainfallOption == 4 then
		rainfall = -1
	end

	--mountain clumpiness
	if mountainClumpinessOption ~= nil then
		if mountainClumpinessOption == 1 then
			mountainClumpiness = 1.0
		elseif mountainClumpinessOption == 2 then
			mountainClumpiness = 0.75
		elseif mountainClumpinessOption == 3 then
			mountainClumpiness = 0.5
		elseif mountainClumpinessOption == 4 then
			mountainClumpiness = 0.25
		elseif mountainClumpinessOption == 5 then
			mountainClumpiness = 0.0
		end
	end

end


local function setAfterOptions()

	-- ocean size and latitude-based climate
	if oceanSizeOption == 1 or latitudeSensitiveOption == 2 then
		southPole = -1
		northPole = yMax
		evadePoles = false
	end

	--expand pangaea "continent size maximum" to half of land area
	-- and half the number of islands
	if continentSizeOption == 5 then
		islandRatio = islandRatio / 2
		cSizeMax = math.ceil( (landArea * (1 - islandRatio)) / 2 )
	end

end


local function setTileDictionary()
tileDictionary = {
		["Plains"] = {
			plotType = PlotTypes.PLOT_LAND,
			terrainType = GameInfoTypes["TERRAIN_PLAINS"],
			feature = FeatureTypes.NO_FEATURE,
		},
		["Grass"] = {
			plotType = PlotTypes.PLOT_LAND,
			terrainType = GameInfoTypes["TERRAIN_GRASS"],
			feature = FeatureTypes.NO_FEATURE,
		},
		["Desert"] = {
			plotType = PlotTypes.PLOT_LAND,
			terrainType = GameInfoTypes["TERRAIN_DESERT"],
			feature = FeatureTypes.NO_FEATURE,
		},
		["HillsDesert"] = {
			plotType = PlotTypes.PLOT_HILLS,
			terrainType = GameInfoTypes["TERRAIN_DESERT"],
			feature = FeatureTypes.NO_FEATURE,
		},
		["MountainDesert"] = {
			plotType = PlotTypes.PLOT_MOUNTAIN,
			terrainType = GameInfoTypes["TERRAIN_DESERT"],
			feature = FeatureTypes.NO_FEATURE,
		},
		["DesertOasis"] = {
			plotType = PlotTypes.PLOT_LAND,
			terrainType = GameInfoTypes["TERRAIN_DESERT"],
			feature = FeatureTypes.FEATURE_OASIS,
		},
		["PlainsForest"] = {
			plotType = PlotTypes.PLOT_LAND,
			terrainType = GameInfoTypes["TERRAIN_PLAINS"],
			feature = FeatureTypes.FEATURE_FOREST,
		},
		["HillsPlains"] = {
			plotType = PlotTypes.PLOT_HILLS,
			terrainType = GameInfoTypes["TERRAIN_PLAINS"],
			feature = FeatureTypes.NO_FEATURE,
		},
		["HillsGrass"] = {
			plotType = PlotTypes.PLOT_HILLS,
			terrainType = GameInfoTypes["TERRAIN_Grass"],
			feature = FeatureTypes.NO_FEATURE,
		},
		["GrassMarsh"] = {
			plotType = PlotTypes.PLOT_LAND,
			terrainType = GameInfoTypes["TERRAIN_GRASS"],
			feature = FeatureTypes.FEATURE_MARSH,
		},
		["GrassForest"] = {
			plotType = PlotTypes.PLOT_LAND,
			terrainType = GameInfoTypes["TERRAIN_GRASS"],
			feature = FeatureTypes.FEATURE_FOREST,
		},
		["PlainsJungle"] = {
			plotType = PlotTypes.PLOT_LAND,
			terrainType = GameInfoTypes["TERRAIN_PLAINS"],
			feature = FeatureTypes.FEATURE_JUNGLE,
			terrainMasquerade = GameInfoTypes["TERRAIN_GRASS"],
		},
		["HillsPlainsJungle"] = {
			plotType = PlotTypes.PLOT_HILLS,
			terrainType = GameInfoTypes["TERRAIN_PLAINS"],
			feature = FeatureTypes.FEATURE_JUNGLE,
			terrainMasquerade = GameInfoTypes["TERRAIN_GRASS"],
		},
		["HillsGrassForest"] = {
			plotType = PlotTypes.PLOT_HILLS,
			terrainType = GameInfoTypes["TERRAIN_GRASS"],
			feature = FeatureTypes.FEATURE_FOREST,
		},
		["HillsPlainsForest"] = {
			plotType = PlotTypes.PLOT_HILLS,
			terrainType = GameInfoTypes["TERRAIN_PLAINS"],
			feature = FeatureTypes.FEATURE_FOREST,
		},
		["OceanIce"] = {
			plotType = PlotTypes.PLOT_OCEAN,
			terrainType = GameInfoTypes["TERRAIN_COAST"],
			feature = FeatureTypes.FEATURE_ICE,
		},
		["MountainGrass"] = {
			plotType = PlotTypes.PLOT_MOUNTAIN,
			terrainType = GameInfoTypes["TERRAIN_GRASS"],
			feature = FeatureTypes.NO_FEATURE,
		},
		["MountainPlains"] = {
			plotType = PlotTypes.PLOT_MOUNTAIN,
			terrainType = GameInfoTypes["TERRAIN_PLAINS"],
			feature = FeatureTypes.NO_FEATURE,
		},
		["MountainDesert"] = {
			plotType = PlotTypes.PLOT_MOUNTAIN,
			terrainType = GameInfoTypes["TERRAIN_DESERT"],
			feature = FeatureTypes.NO_FEATURE,
		},
		["MountainTundra"] = {
			plotType = PlotTypes.PLOT_MOUNTAIN,
			terrainType = GameInfoTypes["TERRAIN_TUNDRA"],
			feature = FeatureTypes.NO_FEATURE,
		},
		["MountainSnow"] = {
			plotType = PlotTypes.PLOT_MOUNTAIN,
			terrainType = GameInfoTypes["TERRAIN_SNOW"],
			feature = FeatureTypes.NO_FEATURE,
		},
		["Snow"] = {
			plotType = PlotTypes.PLOT_LAND,
			terrainType = GameInfoTypes["TERRAIN_SNOW"],
			feature = FeatureTypes.NO_FEATURE,
		},
		["HillsSnow"] = {
			plotType = PlotTypes.PLOT_HILLS,
			terrainType = GameInfoTypes["TERRAIN_SNOW"],
			feature = FeatureTypes.NO_FEATURE,
		},
		["Tundra"] = {
			plotType = PlotTypes.PLOT_LAND,
			terrainType = GameInfoTypes["TERRAIN_TUNDRA"],
			feature = FeatureTypes.NO_FEATURE,
		},
		["HillsTundra"] = {
			plotType = PlotTypes.PLOT_HILLS,
			terrainType = GameInfoTypes["TERRAIN_TUNDRA"],
			feature = FeatureTypes.NO_FEATURE,
		},
		["HillsTundraForest"] = {
			plotType = PlotTypes.PLOT_HILLS,
			terrainType = GameInfoTypes["TERRAIN_TUNDRA"],
			feature = FeatureTypes.FEATURE_FOREST,
		},
		["TundraForest"] = {
			plotType = PlotTypes.PLOT_LAND,
			terrainType = GameInfoTypes["TERRAIN_TUNDRA"],
			feature = FeatureTypes.FEATURE_FOREST,
		},
	}
end


local function setNesses()

	terrainAlly[GameInfoTypes["TERRAIN_TUNDRA"]] = GameInfoTypes["TERRAIN_SNOW"]
	terrainAlly[GameInfoTypes["TERRAIN_SNOW"]] = GameInfoTypes["TERRAIN_TUNDRA"]
	terrainAlly[GameInfoTypes["TERRAIN_PLAINS"]] = GameInfoTypes["TERRAIN_GRASS"]
	terrainAlly[GameInfoTypes["TERRAIN_GRASS"]] = GameInfoTypes["TERRAIN_PLAINS"]

	possibleFeatures[GameInfoTypes["TERRAIN_GRASS"]] = 4
	possibleFeatures[GameInfoTypes["TERRAIN_PLAINS"]] = 2
	possibleFeatures[GameInfoTypes["TERRAIN_TUNDRA"]] = 2
	possibleFeatures[GameInfoTypes["TERRAIN_DESERT"]] = 2
	possibleFeatures[GameInfoTypes["TERRAIN_SNOW"]] = 1

	terrainLatitudes[GameInfoTypes["TERRAIN_GRASS"]] = { mini = 0, maxi = 40, }
	terrainLatitudes[GameInfoTypes["TERRAIN_PLAINS"]] = { mini = 10, maxi = 50, }
	terrainLatitudes[GameInfoTypes["TERRAIN_TUNDRA"]] = { mini = 50, maxi = 75, }
	terrainLatitudes[GameInfoTypes["TERRAIN_DESERT"]] = { mini = 15, maxi = 45, }
	terrainLatitudes[GameInfoTypes["TERRAIN_SNOW"]] = { mini = 70, maxi = 90, }

	featureLatitudes[FeatureTypes.NO_FEATURE] = { mini = 0, maxi = 90, }
	featureLatitudes[FeatureTypes.FEATURE_FOREST] = { mini = 25, maxi = 60 }
	featureLatitudes[FeatureTypes.FEATURE_JUNGLE] = { mini = 0, maxi = 30, }
	featureLatitudes[FeatureTypes.FEATURE_MARSH] = terrainLatitudes[GameInfoTypes["TERRAIN_GRASS"]]
	featureLatitudes[FeatureTypes.FEATURE_OASIS] = terrainLatitudes[GameInfoTypes["TERRAIN_DESERT"]]
	featureLatitudes[FeatureTypes.FEATURE_ICE] = { mini = 70, maxi = 90, }

	fness[FeatureTypes.NO_FEATURE] = 1.0
	fness[FeatureTypes.FEATURE_FOREST] = 0.7
	fcurve[FeatureTypes.FEATURE_FOREST] = { dice = 5, invert = true, maximum = 1.0, }
	fness[FeatureTypes.FEATURE_ICE] = 0.0
	fness[FeatureTypes.FEATURE_OASIS] = 1.0
	fcurve[FeatureTypes.FEATURE_OASIS] = { dice = 1, invert = false, maximum = 0.05, }
	fness[FeatureTypes.FEATURE_MARSH] = 0.2
	fcurve[FeatureTypes.FEATURE_MARSH] = { dice = 1, invert = false, maximum = 0.33, }
	fness[FeatureTypes.FEATURE_JUNGLE] = 0.6
	fcurve[FeatureTypes.FEATURE_JUNGLE] = { dice = 8, invert = true, maximum = 1.0, }

	if temperature == -1 and rainfall ~= -1 then
		temperature = math.random(1,3)
	elseif rainfall == -1 and temperature ~= -1 then
		rainfall = math.random(1,3)
	elseif temperature == -1 and rainfall == -1 then
		pWorld = "Random"
	end

	if temperature == 1 then
		terrainLatitudes[GameInfoTypes["TERRAIN_GRASS"]] = { mini = 0, maxi = 30, }
		terrainLatitudes[GameInfoTypes["TERRAIN_PLAINS"]] = { mini = 10, maxi = 40, }
		terrainLatitudes[GameInfoTypes["TERRAIN_TUNDRA"]] = { mini = 40, maxi = 70, }
		terrainLatitudes[GameInfoTypes["TERRAIN_DESERT"]] = { mini = 5, maxi = 35, }
		terrainLatitudes[GameInfoTypes["TERRAIN_SNOW"]] = { mini = 60, maxi = 90, }
		featureLatitudes[FeatureTypes.FEATURE_FOREST] = { mini = 15, maxi = 50 }
		featureLatitudes[FeatureTypes.FEATURE_JUNGLE] = { mini = 0, maxi = 10, }
		featureLatitudes[FeatureTypes.FEATURE_MARSH] = terrainLatitudes[GameInfoTypes["TERRAIN_GRASS"]]
		featureLatitudes[FeatureTypes.FEATURE_OASIS] = terrainLatitudes[GameInfoTypes["TERRAIN_DESERT"]]
		featureLatitudes[FeatureTypes.FEATURE_ICE] = { mini = 60, maxi = 90, }
		if rainfall == 1 then
			featureLatitudes[FeatureTypes.FEATURE_FOREST] = { mini = 10, maxi = 40 }
			pWorld = "Cold Arid"
		elseif rainfall == 2 then
			pWorld = "Cold"
		elseif rainfall == 3 then
			featureLatitudes[FeatureTypes.FEATURE_FOREST] = { mini = 0, maxi = 65 }
			pWorld = "Cold Wet"
		end
	elseif temperature == 2 then
		if rainfall == 1 then
			featureLatitudes[FeatureTypes.FEATURE_FOREST] = { mini = 30, maxi = 50 }
			featureLatitudes[FeatureTypes.FEATURE_JUNGLE] = { mini = 0, maxi = 20, }
			pWorld = "Temperate Arid"
		elseif rainfall == 2 then
			pWorld = "Temperate"
		elseif rainfall == 3 then
			featureLatitudes[FeatureTypes.FEATURE_FOREST] = { mini = 10, maxi = 70 }
			featureLatitudes[FeatureTypes.FEATURE_JUNGLE] = { mini = 0, maxi = 35, }
			pWorld = "Temperate Wet"
		end
	elseif temperature == 3 then
		terrainLatitudes[GameInfoTypes["TERRAIN_GRASS"]] = { mini = 0, maxi = 50, }
		terrainLatitudes[GameInfoTypes["TERRAIN_PLAINS"]] = { mini = 20, maxi = 60, }
		terrainLatitudes[GameInfoTypes["TERRAIN_TUNDRA"]] = { mini = 60, maxi = 85, }
		terrainLatitudes[GameInfoTypes["TERRAIN_DESERT"]] = { mini = 10, maxi = 60, }
		terrainLatitudes[GameInfoTypes["TERRAIN_SNOW"]] = { mini = 80, maxi = 90, }
		featureLatitudes[FeatureTypes.FEATURE_FOREST] = { mini = 35, maxi = 70 }
		featureLatitudes[FeatureTypes.FEATURE_JUNGLE] = { mini = 0, maxi = 40 }
		featureLatitudes[FeatureTypes.FEATURE_MARSH] = terrainLatitudes[GameInfoTypes["TERRAIN_GRASS"]]
		featureLatitudes[FeatureTypes.FEATURE_OASIS] = terrainLatitudes[GameInfoTypes["TERRAIN_DESERT"]]
		featureLatitudes[FeatureTypes.FEATURE_ICE] = { mini = 80, maxi = 90, }
		if rainfall == 1 then
			terrainLatitudes[GameInfoTypes["TERRAIN_GRASS"]] = { mini = 0, maxi = 30, }
			terrainLatitudes[GameInfoTypes["TERRAIN_DESERT"]] = { mini = 5, maxi = 65, }
			terrainLatitudes[GameInfoTypes["TERRAIN_PLAINS"]] = { mini = 20, maxi = 70, }
			pWorld = "Hot Arid"
		elseif rainfall == 2 then
			pWorld = "Hot"
		elseif rainfall == 3 then
			pWorld = "Hot Wet"
		end
	end

	if pWorld == "Cold Arid" then
		fness[FeatureTypes.FEATURE_FOREST] = 0.1
		fcurve[FeatureTypes.FEATURE_FOREST] = { dice = 1, invert = false, maximum = 0.1, }
		fness[FeatureTypes.FEATURE_JUNGLE] = 0.0
		fness[FeatureTypes.FEATURE_MARSH] = 0.0
		tmult[GameInfoTypes["TERRAIN_GRASS"]] = 2
		tmult[GameInfoTypes["TERRAIN_PLAINS"]] = 3
		tmult[GameInfoTypes["TERRAIN_DESERT"]] = 10
		tmult[GameInfoTypes["TERRAIN_TUNDRA"]] = 20
		tmult[GameInfoTypes["TERRAIN_SNOW"]] = 5
		baseTile = "Desert"
	elseif pWorld == "Cold" then
		fness[FeatureTypes.FEATURE_JUNGLE] = 0.0
		tmult[GameInfoTypes["TERRAIN_GRASS"]] = 3
		tmult[GameInfoTypes["TERRAIN_PLAINS"]] = 3
		tmult[GameInfoTypes["TERRAIN_DESERT"]] = 3
		tmult[GameInfoTypes["TERRAIN_TUNDRA"]] = 20
		tmult[GameInfoTypes["TERRAIN_SNOW"]] = 10
		baseTile = "Snow"
	elseif pWorld == "Cold Wet" then
		fness[FeatureTypes.FEATURE_FOREST] = 1.0
		fcurve[FeatureTypes.FEATURE_FOREST] = { dice = 1, invert = false, maximum = 1.0, }
		fness[FeatureTypes.FEATURE_JUNGLE] = 0.0
		fness[FeatureTypes.FEATURE_MARSH] = 0.25
		fcurve[FeatureTypes.FEATURE_MARSH] = { dice = 1, invert = false, maximum = 0.4, }
		fcurve[FeatureTypes.NO_FEATURE] = { dice = 1, invert = false, maximum = 0.5, }
		tmult[GameInfoTypes["TERRAIN_GRASS"]] = 4
		tmult[GameInfoTypes["TERRAIN_PLAINS"]] = 6
		tmult[GameInfoTypes["TERRAIN_DESERT"]] = 2
		tmult[GameInfoTypes["TERRAIN_TUNDRA"]] = 20
		tmult[GameInfoTypes["TERRAIN_SNOW"]] = 20
		baseTile = "TundraForest"
	elseif pWorld == "Temperate Arid" then
		fness[FeatureTypes.FEATURE_FOREST] = 0.1
		fcurve[FeatureTypes.FEATURE_FOREST] = { dice = 1, invert = false, maximum = 0.1, }
		fness[FeatureTypes.FEATURE_JUNGLE] = 0.1
		fcurve[FeatureTypes.FEATURE_JUNGLE] = { dice = 1, invert = false, maximum = 0.1, }
		fness[FeatureTypes.FEATURE_MARSH] = 0.0
		tmult[GameInfoTypes["TERRAIN_GRASS"]] = 3
		tmult[GameInfoTypes["TERRAIN_PLAINS"]] = 10
		tmult[GameInfoTypes["TERRAIN_DESERT"]] = 20
		tmult[GameInfoTypes["TERRAIN_TUNDRA"]] = 4
		tmult[GameInfoTypes["TERRAIN_SNOW"]] = 2
		baseTile = "Desert"
	elseif pWorld == "Temperate" then
		fness[FeatureTypes.FEATURE_FOREST] = 0.7
		fness[FeatureTypes.FEATURE_JUNGLE] = 0.5
		tmult[GameInfoTypes["TERRAIN_GRASS"]] = 20
		tmult[GameInfoTypes["TERRAIN_PLAINS"]] = 20
		tmult[GameInfoTypes["TERRAIN_DESERT"]] = 12
		tmult[GameInfoTypes["TERRAIN_TUNDRA"]] = 6
		tmult[GameInfoTypes["TERRAIN_SNOW"]] = 6
		baseTile = "Grass"
	elseif pWorld == "Temperate Wet" then
		fness[FeatureTypes.FEATURE_FOREST] = 1.0
		fcurve[FeatureTypes.FEATURE_FOREST] = { dice = 1, invert = false, maximum = 1.0, }
		fness[FeatureTypes.FEATURE_JUNGLE] = 0.6
		fcurve[FeatureTypes.FEATURE_JUNGLE] = { dice = 1, invert = false, maximum = 1.0, }
		fness[FeatureTypes.FEATURE_MARSH] = 0.25
		fcurve[FeatureTypes.FEATURE_MARSH] = { dice = 1, invert = false, maximum = 0.4, }
		fcurve[FeatureTypes.NO_FEATURE] = { dice = 1, invert = false, maximum = 0.5, }
		tmult[GameInfoTypes["TERRAIN_GRASS"]] = 20
		tmult[GameInfoTypes["TERRAIN_PLAINS"]] = 12
		tmult[GameInfoTypes["TERRAIN_DESERT"]] = 2
		tmult[GameInfoTypes["TERRAIN_TUNDRA"]] = 3
		tmult[GameInfoTypes["TERRAIN_SNOW"]] = 6
		baseTile = "GrassForest"
	elseif pWorld == "Hot Arid" then
		fness[FeatureTypes.FEATURE_FOREST] = 0.1
		fcurve[FeatureTypes.FEATURE_FOREST] = { dice = 1, invert = false, maximum = 0.1, }
		fness[FeatureTypes.FEATURE_JUNGLE] = 0.3
		fcurve[FeatureTypes.FEATURE_JUNGLE] = { dice = 1, invert = false, maximum = 0.3, }
		fness[FeatureTypes.FEATURE_MARSH] = 0.0
		tmult[GameInfoTypes["TERRAIN_GRASS"]] = 6
		tmult[GameInfoTypes["TERRAIN_PLAINS"]] = 6
		tmult[GameInfoTypes["TERRAIN_DESERT"]] = 20
		tmult[GameInfoTypes["TERRAIN_TUNDRA"]] = 1
		tmult[GameInfoTypes["TERRAIN_SNOW"]] = 1
		baseTile = "Desert"
	elseif pWorld == "Hot" then
		fness[FeatureTypes.FEATURE_JUNGLE] = 1.0
		fcurve[FeatureTypes.FEATURE_JUNGLE] = { dice = 3, invert = true, maximum = 1.0, }
		fness[FeatureTypes.FEATURE_FOREST] = 0.3
		fcurve[FeatureTypes.FEATURE_FOREST] = { dice = 1, invert = true, maximum = 1.0, }
		tmult[GameInfoTypes["TERRAIN_GRASS"]] = 20
		tmult[GameInfoTypes["TERRAIN_PLAINS"]] = 18
		tmult[GameInfoTypes["TERRAIN_DESERT"]] = 13
		tmult[GameInfoTypes["TERRAIN_TUNDRA"]] = 1
		tmult[GameInfoTypes["TERRAIN_SNOW"]] = 1
		baseTile = "Grass"
	elseif pWorld == "Hot Wet" then
		fness[FeatureTypes.FEATURE_FOREST] = 0.5
		fcurve[FeatureTypes.FEATURE_FOREST] = { dice = 1, invert = false, maximum = 1.0, }
		fness[FeatureTypes.FEATURE_JUNGLE] = 1.0
		fcurve[FeatureTypes.FEATURE_JUNGLE] = { dice = 1, invert = false, maximum = 1.0, }
		fness[FeatureTypes.FEATURE_MARSH] = 0.25
		fcurve[FeatureTypes.FEATURE_MARSH] = { dice = 1, invert = false, maximum = 0.4, }
		fcurve[FeatureTypes.NO_FEATURE] = { dice = 1, invert = false, maximum = 0.5, }
		tmult[GameInfoTypes["TERRAIN_GRASS"]] = 20
		tmult[GameInfoTypes["TERRAIN_PLAINS"]] = 6
		tmult[GameInfoTypes["TERRAIN_DESERT"]] = 2
		tmult[GameInfoTypes["TERRAIN_TUNDRA"]] = 1
		tmult[GameInfoTypes["TERRAIN_SNOW"]] = 1
		baseTile = "PlainsJungle"
	elseif pWorld == "Random" then
		local grasslat = math.random(30,50)
		print("random max grass latitude", grasslat)
		terrainLatitudes[GameInfoTypes["TERRAIN_GRASS"]] = { mini = 0, maxi = grasslat, }
		terrainLatitudes[GameInfoTypes["TERRAIN_PLAINS"]] = { mini = grasslat - 10, maxi = grasslat + 10, }
		terrainLatitudes[GameInfoTypes["TERRAIN_TUNDRA"]] = { mini = grasslat + 10, maxi = grasslat + 25, }
		terrainLatitudes[GameInfoTypes["TERRAIN_DESERT"]] = { mini = grasslat - 25, maxi = grasslat + 5, }
		terrainLatitudes[GameInfoTypes["TERRAIN_SNOW"]] = { mini = grasslat + 20, maxi = 90, }
		featureLatitudes[FeatureTypes.FEATURE_FOREST] = { mini = grasslat - 15, maxi = grasslat + 15 }
		featureLatitudes[FeatureTypes.FEATURE_JUNGLE] = { mini = 0, maxi = grasslat - 10 }
		featureLatitudes[FeatureTypes.FEATURE_MARSH] = terrainLatitudes[GameInfoTypes["TERRAIN_GRASS"]]
		featureLatitudes[FeatureTypes.FEATURE_OASIS] = terrainLatitudes[GameInfoTypes["TERRAIN_DESERT"]]
		featureLatitudes[FeatureTypes.FEATURE_ICE] = { mini = grasslat + 20, maxi = 90, }

		fness[FeatureTypes.FEATURE_JUNGLE] = math.random()
		fness[FeatureTypes.FEATURE_FOREST] = math.random()
		fcurve[FeatureTypes.FEATURE_FOREST] = { dice = math.random(1,5), invert = true, maximum = math.min(math.random() * 1.5, 1), }
		fcurve[FeatureTypes.FEATURE_JUNGLE] = { dice = math.random(1,5), invert = true, maximum = math.min(math.random() * 1.5, 1), }
		fness[FeatureTypes.FEATURE_MARSH] = math.random() * 0.25
		fcurve[FeatureTypes.FEATURE_MARSH] = { dice = 1, invert = false, maximum = math.random() * 0.4, }
		fcurve[FeatureTypes.NO_FEATURE] = { dice = 1, invert = false, maximum = math.min(math.random()+0.5, 1), }
		tmult[GameInfoTypes["TERRAIN_GRASS"]] = math.random(1,20)
		tmult[GameInfoTypes["TERRAIN_PLAINS"]] = math.random(1,20)
		tmult[GameInfoTypes["TERRAIN_DESERT"]] = math.random(1,20)
		tmult[GameInfoTypes["TERRAIN_TUNDRA"]] = math.random(1,20)
		tmult[GameInfoTypes["TERRAIN_SNOW"]] = math.random(1,20)
	end

	if useLatitude == true then
		fness[FeatureTypes.FEATURE_FOREST] = math.min(fness[FeatureTypes.FEATURE_FOREST] * 1.4, 1.0)
		fness[FeatureTypes.FEATURE_JUNGLE] = math.min(fness[FeatureTypes.FEATURE_JUNGLE] * 1.4, 1.0)
		if tmult[GameInfoTypes["TERRAIN_GRASS"]] == 0 then tmult[GameInfoTypes["TERRAIN_GRASS"]] = 1 end
		if tmult[GameInfoTypes["TERRAIN_PLAINS"]] == 0 then tmult[GameInfoTypes["TERRAIN_PLAINS"]] = 1 end
		if tmult[GameInfoTypes["TERRAIN_DESERT"]] == 0 then tmult[GameInfoTypes["TERRAIN_DESERT"]] = 1 end
		if tmult[GameInfoTypes["TERRAIN_TUNDRA"]] == 0 then tmult[GameInfoTypes["TERRAIN_TUNDRA"]] = 1 end
		if tmult[GameInfoTypes["TERRAIN_SNOW"]] == 0 then tmult[GameInfoTypes["TERRAIN_SNOW"]] = 1 end
	end

end


local function generateRegionType(latitude)
	local largeBrushChance = math.random(1,10)
	local rotationType = math.random(0,1)
	local rotationChance = math.random(1, 4)
	local paintedRatio = (math.random() * 0.7) + 0.1
--	print(largeBrushChance, rotationType, rotationChance, paintedRatio)
	local region = {
		tileList = {},
		paintTileList = {},
		largeBrushChance = largeBrushChance,
		rotationType = rotationType,
		rotationChance = rotationChance,
		paintedRatio = paintedRatio,
	}
	local terrainType
	if useLatitude == true and latitude ~= nil then
		-- generate list of terrains allowed at this latitude
		local terrainsHere = {}
--		print("latitude", latitude)
		for tt, mult in pairs(tmult) do
			if mult > 0 and latitude >= terrainLatitudes[tt].mini and latitude <= terrainLatitudes[tt].maxi then
				for m = 1, mult do
					table.insert(terrainsHere, tt)
				end
				print(tt, mult)
			end
		end
		if #terrainsHere > 0 then
			local ti = math.random(1,#terrainsHere)
			terrainType = terrainsHere[ti]
--			print(terrainType)
		else
			-- if no listed terrains are allowed at this latitude, find the closest one
			print("using terrain closest to latitude", latitude)
			local maxdist = -1
			local maxtt
			for tt, tudes in pairs(terrainLatitudes) do
				if latitude >= tudes.mini and latitude <= tudes.maxi then
					local minidist = latitude - tudes.mini
					local maxidist = tudes.maxi - latitude
					local dist = math.min(minidist, maxidist)
--					print(tt, tudes.mini, tudes.maxi, minidist, maxidist, dist)
					if dist > maxdist then
						maxdist = dist
						maxtt = tt
					end
				end
			end
			if maxtt ~= nil then terrainType = maxtt end
		end
	else
		local ti = math.random(1,#terrains)
		terrainType = terrains[ti]
	end
	local tileTypeList = terrainList[terrainType]
	local ally = terrainAlly[terrainType]
	local allyTileTypeList = terrainList[ally]
--	print (terrainType, #tileTypeList)
	for p = 0, 1 do
		local i = 1
		local iterations = 0
		local length = math.random(20, 40)
--		print("maxmountain, maxhills", maxmountain, maxhills)
		local totalmountain = 0
		local totalhills = 0
		local lengthleft = length
		local thisness = {}
		local thismountainness = math.random() * mountainness
		local thishillsness = diceRoll(3, true, hillsness)
		local thisallyness = math.random() * allyness
		local maxmountain = math.floor(thismountainness * length)
		local maxhills = math.floor(thishillsness * length)
		local tlist = {}
		local totalf = {}
		local maxf = {}
		local allocated = 0
		local featuresallocated = 0
		repeat
			local ttl
			if math.random() < thisallyness and ally ~= nil then
				ttl = allyTileTypeList
			else
				ttl = tileTypeList
			end
			local tti = math.random(1, #ttl)
			local tileName = ttl[tti]
			local tile = tileDictionary[tileName]
	--		print(tti, tileName)
			local insert = true
			if tile.plotType == PlotTypes.PLOT_MOUNTAIN then
				if totalmountain >= maxmountain then
					insert = false
				else
					totalmountain = totalmountain + 1
				end
			elseif tile.plotType == PlotTypes.PLOT_HILLS then
				if totalhills >= maxhills then
					insert = false
				else
					totalhills = totalhills + 1
				end
			end
			if thisness[tile.feature] == nil then
				local canBeHere = true
				if useLatitude == true and latitude ~= nil then
					if latitude < featureLatitudes[tile.feature].mini or latitude > featureLatitudes[tile.feature].maxi then
						canBeHere = false
					end
				end
				if math.random() < fness[tile.feature] and canBeHere == true then
					if fcurve[tile.feature] == nil then
						thisness[tile.feature] = math.random()
					else
						thisness[tile.feature] = diceRoll(fcurve[tile.feature].dice, fcurve[tile.feature].invert, fcurve[tile.feature].maximum)
--						print(tile.feature, fcurve[tile.feature].dice, fcurve[tile.feature].invert, fcurve[tile.feature].maximum, thisness[tile.feature])
					end
				else
					thisness[tile.feature] = 0
				end
			end
			if maxf[tile.feature] == nil and math.floor(thisness[tile.feature]*100) > 0 and allocated < length then
				maxf[tile.feature] = math.floor(thisness[tile.feature] * length)
				if maxf[tile.feature] > lengthleft then maxf[tile.feature] = lengthleft end
				lengthleft = lengthleft - maxf[tile.feature]
				allocated = allocated + maxf[tile.feature]
				featuresallocated = featuresallocated + 1
--				print("f:", tile.feature, "percent:", math.floor(thisness[tile.feature] * 100), "maxf:", maxf[tile.feature], "left:", lengthleft, "out of:", length)
				totalf[tile.feature] = 0
			elseif maxf[tile.feature] == nil then
				totalf[tile.feature] = 0
				maxf[tile.feature] = 0
			end
			if maxf[tile.feature] == 0 then
				insert = false
			elseif totalf[tile.feature] >= maxf[tile.feature] then
				insert = false
			end
			if i >= allocated and featuresallocated == possibleFeatures[terrainType] then break end
			if insert == true then
				table.insert(tlist, tileName)
				totalf[tile.feature] = totalf[tile.feature] + 1
--				print(tileName)
				i = i + 1
			end
			iterations = iterations + 1
		until i >= length or iterations > 200
--		print("done with", i, length, iterations)
		if p == 0 then
			region.tileList = tlist
			if math.random() > differenciatePaint then
				region.paintTileList = tlist
				break
			end
		else
			region.paintTileList = tlist
		end
	end
	return region
end


local function prepareTileListByTerrain(terrainType)
	local list = {}
	for tileName, tile in pairs(tileDictionary) do
		local tt
		-- terrainMasquerade is so that plains jungle tiles are placed where grassland is placed
		if tile.terrainMasquerade == nil then
			tt = tile.terrainType
		else
			tt = tile.terrainMasquerade
		end
		if tt == terrainType then
			table.insert(list, tileName)
--			print(terrainType, tileName)
		end
	end
	return list
end


local function prepareTerrainTileLists()
	local terrainList = {}
	local terrains = {}
	local terrainMaxArea = {}

	-- creating the lists of tiles from the tile dictionary that are of each terrain type specified in tmult
	-- and creating the list of possible terrains, weighted by tmult
	for terrainType, mult in pairs(tmult) do
		local list = prepareTileListByTerrain(terrainType)
		if #list > 0 then
			terrainList[terrainType] = list
			for i = 1, mult do
				table.insert(terrains, terrainType)
			end
		end
	end

	-- calculating the percentage of the land that should be a certain terrain type (used as a maximum)
	for terrainType, mult in pairs(tmult) do
		terrainMaxArea[terrainType] = math.floor( (mult / #terrains) * continentalTotalTiles )
	end

	return terrainList, terrains, terrainMaxArea
end


local function getXY(index)
	index = index - 1
	return index % iW, math.floor(index / iW) -- lua can return two variables
end

local function getIndex(x, y)
	return (y * iW) + x + 1
end


local function pairEm(a, b)
--	return ((0.5 * (a+b)) * (a+b+1)) + b
	local as = tostring(a)
	local bs = tostring(b)
	if a > b then
		return as .. bs
	else
		return bs .. as
	end
end


local function findClosest(number, list)
	local smallest = 10000
	local closest
	for i, v in pairs(list) do
		local dist
		if v > number then
			dist = v - number
		elseif v < number then
			dist = number - v
		else
			--dist = 0
			return i
		end
		if dist < smallest then
			smallest = dist
			closest = i
		end
	end
	return closest
end


local function directionalTransform(direction, x, y)
	local nx = x
	local ny = y
	local odd = y % 2
	if direction == 0 then

	elseif direction == 1 then
		nx = x - 1
	elseif direction == 2 then
		nx = x - 1 + odd
		ny = y + 1
	elseif direction == 3 then
		nx = x + odd
		ny = y + 1
	elseif direction == 4 then
		nx = x + 1
	elseif direction == 5 then
		nx = x + odd
		ny = y - 1
	elseif direction == 6 then
		nx = x - 1 + odd
		ny = y - 1
	end
	if nx > xMax then nx = 0 elseif nx < 0 then nx = xMax end
	if ny > yMax then
		ny = yMax
		direction = 5
	end
	if ny < 0 then
		ny = 0
		direction = 3
	end
	return nx, ny, direction
end


local function cardinalToHex(northEastSouthWest)
	local direction
	if northEastSouthWest == 1 then
		direction = 2 + math.random(0,1)
	elseif northEastSouthWest == 2 then
		direction = 4
	elseif northEastSouthWest == 3 then
		direction = 5 + math.random(0,1)
	elseif northEastSouthWest == 4 then
		direction = 1
	end
	return direction
end

local function randomCardinalDirection()
	local northEastSouthWest = math.random(1,4)
	return cardinalToHex(northEastSouthWest)
end


local function neighborTest(x, y, id)
	local neighbortest = true
	for d = 1, 6 do
		local tnx, tny = directionalTransform(d, x, y)
		local index = getIndex(tnx, tny)
		if continentalTiles[index] ~= nil and continentalTiles[index] ~= id then
			neighbortest = false
--					print("neighbor test failed")
		end
	end
	return neighbortest
end


local function emptyQuadTile()
	local q
	local qmax = math.max(#soQuad[1],#soQuad[2],#soQuad[3],#soQuad[4])
	if qmax == #soQuad[1] then
		q = 1
	elseif qmax == #soQuad[2] then
		q = 2
	elseif qmax == #soQuad[3] then
		q = 3
	elseif qmax == #soQuad[4] then
		q = 4
	end

	local i
	if #soQuad[q] > 1 then
		i = math.random(1, #soQuad[q])
	else
		return nil
	end
	return soQuad[q][i]
end


local function fillQuadrants()
	local halfx = math.floor(xMax / 2)
	local halfy = math.floor(yMax / 2)
	for q = 1, 4 do
		local xa = 1
		if q == 2 or q == 4 then xa = halfx + 1 end
		local xb = halfx
		if q == 2 or q == 4 then xb = xMax end
		local ya = 1
		if q == 3 or q == 4 then ya = halfy + 1 end
		local yb = halfy
		if q == 3 or q == 4 then yb = yMax end
		for y=ya, yb do
			for x=xa, xb do
				local index = getIndex(x, y)
				table.insert(soQuad[q], index)
			end
		end
	end
end


local function getCenter(tiles)
	if #tiles == 0 then
		return -1, -1
	elseif #tiles == 1 then
		return getXY(tiles[1])
	end
	local sumx = 0
	local sumy = 0
	local tilecount = 0
	for nothing, index in pairs(tiles) do
		local x, y = getXY(index)
		sumx = sumx + x
		sumy = sumy + y
		tilecount = tilecount + 1
	end
	return math.floor(sumx / tilecount), math.floor(sumy / tilecount)
end


local function getQuadrant(cx, cy, x, y)
	local q
	if x >= cx then
		q = 1
	else
		q = 3
	end
	if y < cy then
		q = q + 1
	end
	return q
end


local function getEighth(cx, cy, x, y)
	local diffx = x - cx
	local diffy = y - cy
	if diffy >= 0 then
		if diffx >= 0 then
			if diffx <= diffy then
				return 1
			else
				return 2
			end
		else
			if math.abs(diffx) <= diffy then
				return 3
			else
				return 4
			end
		end
	else
		if diffx >= 0 then
			if diffx <= math.abs(diffy) then
				return 5
			else
				return 6
			end
		else
			if diffx <= diffy then
				return 7
			else
				return 8
			end
		end
	end
end


local function canExpandContinentHere(index, continentIndex, isolateContinent)
	local nx, ny = getXY(index)
	local neighbortest = true
	local nearcoast = false
	local friendlyNeighbors = 0
	for dd = 0, 6 do
		local tnx, tny = directionalTransform(dd, nx, ny)
		local nindex = getIndex(tnx, tny)
		if continentalTiles[nindex] ~= continentIndex and continentalTiles[nindex] ~= nil then
			neighbortest = false
--			print("neighbor test failed")
		elseif continentalTiles[nindex] == continentIndex and dd > 0 then
			friendlyNeighbors = friendlyNeighbors + 1
		elseif continentalTiles[nindex] == nil then
			if isCoast[nindex] ~= nil and isCoast[nindex] ~= continentIndex then
				nearcoast = true
				if isolateContinent then
					neighbortest = false
				end
			end
		end
	end
	return neighbortest, nearcoast, friendlyNeighbors
end


local function paintContinent(x, y, continentIndex, continentSize, isolateContinent)
	-- loop continues until the continent is done
	local inContinentIterations = 0
	local newTiles = { }
	local filledContinentTiles = 0
	local continentConnected
	repeat
		local dLimit = 0
		if math.random(1,continentLargeBrushChance) == 1 then dLimit = 6 end
		for d = 0, dLimit do
			local nx, ny = directionalTransform(d, x, y)
			local index = getIndex(nx, ny)
			local neighbortest, nearcoast, friendlyNeighbors = canExpandContinentHere(index, continentIndex, isolateContinent)
			if ismuthChance > 0 then
				if math.random() < ismuthChance then neighbortest = true end
			end
			if continentalTiles[index] == nil and ny > southPole and ny < northPole and neighbortest == true then
--				if continentIndex == 1 then print("new tile!") end
				continentalTiles[index] = continentIndex
				filledContinentTiles = filledContinentTiles + 1
				table.insert(continentalXY, { x = nx, y = ny })
				table.insert(newTiles, index)
				if nearcoast then continentConnected = true end
			end
		end

		if y == 0 or y == yMax - 1 and breakAtPoles == true then
			break
		end

		if y >= yMax - 4 and evadePoles == true then
			direction = 5 + math.random(0,1)
		elseif y <= 3 and evadePoles == true then
			direction = 2 + math.random(0,1)
		else
			direction = randomCardinalDirection()
		end
		local tx, ty, tdirection
		local adder = 0
		local ci = continentIndex + 1 --just so it doesn't test true the first time through
		local test = false
		repeat
			local adirection = direction + adder
			if adirection > 6 then
				adirection = adirection - 6
			elseif adirection < 0 then
				adirection = adirection + 6
			end
			tx, ty, tdirection = directionalTransform(adirection, x, y)
			local tindex = getIndex(tx, ty)
			ci = continentalTiles[tindex]
			if ci == nil or ci == continentIndex then
				test = canExpandContinentHere(tindex, continentIndex, isolateContinent)
			elseif pangaea == true and ci ~= nil then
				test = true
			end
			adder = adder + 1
		until test == true or ci == continentIndex or adder == 6

		if adder == 6 then
			break
--			print("nowhere else to go")
		else
			direction = tdirection
			y = ty
			x = tx
		end

		inContinentIterations = inContinentIterations + 1
	until filledContinentTiles >= continentSize or inContinentIterations > maxInContinentIterations
	return newTiles, continentConnected
end


local function expandContinent(tiles, id, maxArea, maxIterations, isolateContinent)
	local continentConnected = false
	local continentIndex = id
	if maxIterations == nil then maxIterations = maxArea * 3 end
	local tileBuffer = tiles
	local newTiles = { }
	local newCount = 0
	local iiCount = 0
	local expandCounts = {}
	local sameArea = 0
	local lastCount = 0

	local directedness = { 0, 0, 0, 0, 0, 0 }
	for n = 1, directednessTotal do
		local cd = math.random(1,4)
		local d = cardinalToHex(cd)
		directedness[d] = directedness[d] + 1
	end
--	print(directedness[1], directedness[2], directedness[3], directedness[4], directedness[5], directedness[6])

	local eighthFavoring = { 0, 0, 0, 0, 0, 0, 0, 0 }
	for n = 1, eighthFavoringTotal do
		local e = math.random(1,8)
		eighthFavoring[e] = eighthFavoring[e] + 1
	end
	local centerx, centery = getCenter(tiles)
--	print("center:", centerx, centery)

	repeat
		local bufferIndex
--			print(#tileBuffer)
		if #tileBuffer > 1 then
			bufferIndex = math.random(1,#tileBuffer)
		elseif bufferIndex == 1 then
			bufferIndex = 1
		else
			break
		end
		local tileIndex = tileBuffer[bufferIndex]
		local neigh, nearcoast, friends = canExpandContinentHere(tileIndex, continentIndex, isolateContinent)
		if neigh == true and friends < 6 then
			local tx, ty = getXY(tileIndex)
			local d = randomCardinalDirection()
			local nx, ny = directionalTransform(d, tx, ty)
			local index = getIndex(nx, ny)
			local neighbortest, nearcoast, friendlyNeighbors = canExpandContinentHere(index, continentIndex, isolateContinent)
			if ismuthChance > 0 then
				if math.random() < ismuthChance then neighbortest = true end
			end
			if continentalTiles[index] == nil and ny > southPole and ny < northPole and neighbortest == true then
				continentalTiles[index] = continentIndex
				table.insert(continentalXY, { x = nx, y = ny })
				table.insert(tileBuffer, index)

				-- inserting certain directions twice decreases hexagonal tendency?
				if directedness[d] > 0 then
					for dd = 1, directedness[d] do table.insert(tileBuffer, index) end
				end

				-- inserting certain eighths around continental center of mass
				local e = getEighth(centerx, centery, nx, ny)
				if eighthFavoring[e] > 0 then
					for i = 1, eighthFavoring[e] do table.insert(tileBuffer, index) end
				end

				table.insert(newTiles, index)
				if nearcoast then continentConnected = true end
				newCount = newCount + 1
				if expandCounts[tileIndex] == nil then
					expandCounts[tileIndex] = 1
				else
					expandCounts[tileIndex] = expandCounts[tileIndex] + 1
				end
			elseif ny == 0 or ny == yMax - 1 then
				table.remove(tileBuffer, bufferIndex)
--				print("at pole", #tileBuffer)
				if breakAtPoles then
	--				print("continent terminated at pole", continentIndex)
					break
				end
			end
			if ty <= 1 or ty >= yMax - 2 then
				if evadePoles == true then
					table.remove(tileBuffer, bufferIndex)
				end
			end
			if newCount >= maxArea then break end
		else -- if surrounded by friends, remove from expansion buffer
			table.remove(tileBuffer, bufferIndex)
--			print("can't expand", #tileBuffer)
		end
		if newCount == lastCount then
			sameArea = sameArea + 1
		else
			sameArea = 0
		end
		lastCount = newCount
		iiCount = iiCount + 1
	until #tileBuffer <= 0 or newCount >= maxArea or sameArea > 30 or iiCount > maxIterations
	return newTiles, continentConnected
end


local function planContinentSizes()
-- create idealized list of continent sizes
-- growContinents() picks from this list at random
	local islandArea = math.ceil( islandRatio * landArea )
	local theory = {}
	local left = landArea
	local cleft = landArea - islandArea
	print(cleft, islandArea)
	local i = 1
	repeat
		local size = 0
		if left <= islandArea then
			local maximum = math.min(islandSizeMax, left)
			size = math.random(1, maximum)
		else
			local c = math.ceil( math.random(cSizeMin, cSizeMax) )
			size = math.min(c, cleft)
		end
		theory[i] = size
		left = left - size
		cleft = cleft - size
		print(i, size, left)
		i = i + 1
	until left <= 0
	return theory
end


local function growContinents()
	-- fill stillOcean with all tiles
	for i=1, mapArea do
		table.insert(stillOcean, i)
		local plot = Map.GetPlotByIndex(i - 1)
		plot:SetPlotType(PlotTypes.PLOT_OCEAN)
	end

	-- fill quadrants with all tiles
	fillQuadrants()

	local cSizeTheory = planContinentSizes()

	local oceanArea = mapArea - landArea

	local addCoast = {}
	local addedCoast = {}

	continentalTotalTiles = 0
	local isolateContinent = false
	local continentIndex = 1
	local sameAreaLeft = 0
	local lastContinentalTotalTiles = 0
	local coastLevel = {}
	local blockedTileCount = 0
	repeat
		local left = landArea - continentalTotalTiles
		print("land area left to fill", left)
		local continentSize = left
		if #cSizeTheory > 0 then
			local csti = math.random(1,#cSizeTheory)
			continentSize = cSizeTheory[csti]
		else
			print("end of continent size plans")
		end

		local noBlockingChance = (blockedTileCount / oceanArea) / 2
		local connectedChance = noBlockingChance
--		print("chance not to generate blocking", noBlockingChance)

		local paintedSize = math.ceil(continentSize * paintedRatio)
		if paintedSize == 0 then paintedSize = 1 end
		local expandedSize = continentSize - paintedSize
--		print("land area remaining", landArea - continentalTotalTiles)
		print("new continent", continentIndex, continentSize, paintedSize, expandedSize, noBlockingChance)


		local tileIndex

		if math.random() < connectedChance then
			isolateContinent = false
		else
			isolateContinent = true
		end

		if continentIndex == 1 or isolateContinent == false then
			local oi = math.random(1, #stillOcean)
			tileIndex = stillOcean[oi]
		else
			tileIndex = emptyQuadTile()
		end
		if tileIndex == nil then break end
		local x, y = getXY(tileIndex)
		if x == -1 and y == -1 then
			print("no empty spot found for continent")
			break
		else
			if pangaea == true and (continentSize > islandSizeMax or #cSizeTheory == 0) then
				x = math.floor(xMax / 2)
				y = math.floor(yMax / 2)
			end
		end

		-- painting and expanding continent (expansion only if any tiles were painted at all)
		local actualContinentSize = 0
		print("isolated?", isolateContinent)
		local tiles = paintContinent(x, y, continentIndex, paintedSize, isolateContinent)
		continentalTotalTiles = continentalTotalTiles + #tiles
		print("tiles painted", #tiles)
		actualContinentSize = actualContinentSize + #tiles
		local expandedTiles = {}
		if #tiles > 0 then
			expandedTiles = expandContinent(tiles, continentIndex, expandedSize, nil, isolateContinent)
			continentalTotalTiles = continentalTotalTiles + #expandedTiles
			print("tiles expanded", #expandedTiles)
			actualContinentSize = actualContinentSize + #expandedTiles
		end
		if actualContinentSize > biggestContinentSize then biggestContinentSize = actualContinentSize end

		-- finding the closest match in the continent size list and removing it
		if actualContinentSize > 0 and #cSizeTheory > 0 then
			local closest = findClosest(actualContinentSize, cSizeTheory)
			print("actual size", actualContinentSize, "  closest match", cSizeTheory[closest])
			table.remove(cSizeTheory, closest)
		end

		-- clear occupied continental tiles from available ocean tile list
		-- if the continent wasn't able to grow at all, remove its starting tile and neighbors from possibility
		if #tiles + #expandedTiles == 0 then
			for d = 0, 6 do
				local dx, dy = directionalTransform(d, x, y)
				local dindex = getIndex(dx,dy)
				if continentalTiles[dindex] == nil and isCoast[dindex] == nil and addedCoast[dindex] == nil then
					table.insert(addCoast, dindex)
					addedCoast[dindex] = true
					coastLevel[dindex] = 1
				end
			end
--			print("not suitable for continent", x, y)
		end

		local blockedAreaLimit
		if blockedTileCount < oceanArea and math.random() < noBlockingChance then
			blockedAreaLimit = 0
		else
			blockedAreaLimit = (continentalTotalTiles / landArea) * (oceanArea - blockedTileCount)
			blockedAreaLimit = math.floor(blockedAreaLimit)
		end

		for i, index in pairs(stillOcean) do
			if continentalTiles[index] ~= nil then
				table.remove(stillOcean, i)
				-- this is for coast generation / detection
				local plot = Map.GetPlotByIndex(index - 1)
				plot:SetPlotType(PlotTypes.PLOT_LAND)
				if blockedAreaLimit > 0 then
					for d = 1, 6 do
						local x, y = getXY(index)
						local dx, dy = directionalTransform(d, x, y)
						local dindex = getIndex(dx, dy)
						if continentalTiles[dindex] == nil and isCoast[dindex] == nil and addedCoast[dindex] == nil then
							table.insert(addCoast, dindex)
							addedCoast[dindex] = true
							coastLevel[dindex] = 1
	--						local dplot = Map.GetPlotByIndex(index - 1)
	--						if dplot ~= nil then dplot:SetTerrainType(TerrainTypes.TERRAIN_COAST) end
						end
					end
				end
			end
		end

--		print (#addCoast)
		-- expand isolating coasts (do not translate to real coast terrain)
		if #addCoast > 1 then
			local coastBuffer = {}
			for i,index in pairs(addCoast) do
				table.insert(coastBuffer, index)
			end
			local maxCoastLevel = 0
			local coastLevelLimit = iH
--			print(coastLevelLimit, blockedAreaLimit, continentalTotalTiles, blockedTileCount, #addCoast, oceanArea, landArea)
			repeat
				local i = math.random(1, #coastBuffer)
				local index = coastBuffer[i]
				if coastLevel[index] > maxCoastLevel then
					maxCoastLevel = coastLevel[index]
				end
				if coastLevel[index] < coastLevelLimit then
					for d = 1, 6 do
						local x, y = getXY(index)
						local dx, dy = directionalTransform(d, x, y)
						local dindex = getIndex(dx, dy)
						if continentalTiles[dindex] == nil and isCoast[dindex] == nil and addedCoast[dindex] == nil then
							table.insert(addCoast, dindex)
							table.insert(coastBuffer, dindex)
							addedCoast[dindex] = true
							coastLevel[dindex] = coastLevel[index] + 1
							if coastLevel[dindex] > maxCoastLevel then
								maxCoastLevel = coastLevel[dindex]
							end
						end
					end
				end
				table.remove(coastBuffer, i)
			until #coastBuffer <= 2 or maxCoastLevel >= coastLevelLimit or #addCoast >= blockedAreaLimit

			print ("tiles blocked", #addCoast)
			if #addCoast > 0 then
--				print("ocean!")
				repeat
					local i = math.random(1, #addCoast)
					local index = addCoast[i]
					isCoast[index] = continentIndex
					blockedTileCount = blockedTileCount + 1
					table.remove(addCoast, i)
				until #addCoast < 1 or blockedTileCount >= oceanArea
--				print(blockedTileCount, oceanArea)
				addCoast = {}
				addedCoast = {}
			end
		else
			print("tiles blocked", 0)
		end

		-- do the same for quandrant tile lists
		for q = 1, 4 do
			for i, index in pairs(soQuad[q]) do
				if continentalTiles[index] ~= nil or isCoast[index] ~= nil then table.remove(soQuad[q], i) end
			end
		end

		continentIndex = continentIndex + 1
		if continentalTotalTiles == lastContinentalTotalTiles then
			sameAreaLeft = sameAreaLeft + 1
		else
			sameAreaLeft = 0
		end
		lastContinentalTotalTiles = continentalTotalTiles
		--missing:  continentalTotalTiles >= landArea
	until continentalTotalTiles >= landArea or continentIndex > 512 or sameAreaLeft >= 10 or #soQuad[1] + #soQuad[2] + #soQuad[3] + #soQuad[4] < 24
	print (continentalTotalTiles, continentIndex, sameAreaLeft, #soQuad[1], #soQuad[2], #soQuad[3], #soQuad[4], blockedTileCount)
end


local function fillTinyLakes()
	for index, ci in pairs(isCoast) do
		local landCount = 0
		local x, y = getXY(index)
		for d = 1, 6 do
			local dx, dy = directionalTransform(d, x, y)
			local dindex = getIndex(dx, dy)
			if continentalTiles[dindex] ~= nil then
				landCount = landCount + 1
			end
		end
		if landCount == 6 then
			continentalTiles[index] = ci
--			print("lake filled at", x, y)
		end
	end
end

local function tileLatitudeChecks(index, tileName)
	local tt = tileDictionary[tileName].terrainType
	if tileDictionary[tileName].terrainMasquerade ~= nil then
		tt = tileDictionary[tileName].terrainMasquerade
	end
	local ft = tileDictionary[tileName].feature
	local plot = Map.GetPlotByIndex(index - 1)
	local latitude
	if plot ~= nil then latitude = plot:GetLatitude() end
	if latitude ~= nil then
		local tolerance = math.random(-1,1)
		tolerance = tolerance * latitudeTolerance
		latitude = math.min(math.max(latitude - tolerance, 0), 90)
--		local x, y = getXY(index)
--		if x == 1 then print (x, y, latitude, tt, terrainLatitudes[tt].maxi, terrainLatitudes[tt].mini, ft, featureLatitudes[ft].maxi, featureLatitudes[ft].mini) end
		if latitude > terrainLatitudes[tt].maxi or latitude < terrainLatitudes[tt].mini or latitude > featureLatitudes[ft].maxi or latitude < featureLatitudes[ft].mini then
			return false
		else
			return true
		end
	end
end

local function paintRegion(x, y, regionIndex, regionName, regionSize)
	local region = regionDictionary[regionName]
	local newTiles = {}
	local filledRegionTiles = 0
	local direction = math.random(1,6)
	local tileIterations = 0
	repeat
		local badDirections = {}
		local badDirectionTotal = 0
		local dLimit = 0
		local centerIndex = getIndex(x, y)
		if math.random(1,region.largeBrushChance) == 1 then dLimit = 6 end
		local stopRegion = false
		for d = 0, 6 do
			local nx, ny = directionalTransform(d, x, y)
			local index = getIndex(nx, ny)
			if tileTiles[index] == nil and continentalTiles[index] ~= nil and d <= dLimit then
				local tileNumber = math.random(1, #region.paintTileList)
				local tileName = region.paintTileList[tileNumber]
				local draw = true
				if useLatitude == true then
					draw = tileLatitudeChecks(index, tileName)
				end
				if draw == true then
					tileTiles[index] = tileName
					regionNames[index] = regionName
					regionalTiles[index] = { regionIndex = regionIndex, painted = true }
					table.insert(newTiles, index)
					filledRegionTiles = filledRegionTiles + 1
					-- counting number of tiles of each terrain type
					if terrainFilledTiles[tileDictionary[tileName].terrainType] == nil then
						terrainFilledTiles[tileDictionary[tileName].terrainType] = 1
					else
						terrainFilledTiles[tileDictionary[tileName].terrainType] = terrainFilledTiles[tileDictionary[tileName].terrainType] + 1
					end
				end
			elseif continentalTiles[index] == nil and d > 0 then
--				if filledRegionTiles > 6 then table.insert(coastRange, centerIndex) end
				if keepItInside then
					badDirections[d] = true
					badDirectionTotal = badDirectionTotal + 1
				end
			elseif regionNames[index] ~= nil and regionNames[index] ~= regionName and d > 0 then
--				if filledRegionTiles > 6 then table.insert(regionRange, centerIndex) end
				if keepItInside then
					badDirections[d] = true
					badDirectionTotal = badDirectionTotal + 1
				end
			end
		end

		if stopRegion == true then break end

		if badDirectionTotal >= 6 and keepItInside then
--			print("no good direction")
			break
		end

		if math.random(1,region.rotationChance) == 1 or (badDirections[direction] == true and keepItInside) then
			local dfi = 0
			repeat
				if region.rotationType == 0 then
					direction = randomCardinalDirection()
				elseif region.rotationType == 1 then
					direction = direction + math.random(0,2) - 1
					if direction > 6 then
						direction = 1
					elseif direction < 1 then
						direction = 6
					end
				end
				dfi = dfi + 1
			until badDirections[direction] == nil or dfi > 12
			if dfi > 12 and keepItInside then
--				print("nowhere for region painting to go")
				break
			end
		end
		x, y = directionalTransform(direction, x, y)
		tileIterations = tileIterations + 1
	until filledRegionTiles >= regionSize or tileIterations > maxTileIterations
	return newTiles
end


local function expandRegion(tiles, regionIndex, regionName, maxArea, maxIterations)
	local region = regionDictionary[regionName]
	if maxIterations == nil then maxIterations = 200 end
	local tileBuffer = tiles
	local newTiles = { }
	local iCount = 0
	local newCount = 0
	repeat
		local tempTiles = { }
--		for nothing,tileIndex in pairs(tileBuffer) do
		repeat
			local bufferIndex
--			print(#tileBuffer)
			if #tileBuffer > 1 then
				bufferIndex = math.random(1,#tileBuffer)
			elseif bufferIndex == 1 then
				bufferIndex = 1
			else
				break
			end
			local tileIndex = tileBuffer[bufferIndex]
			local tx, ty = getXY(tileIndex)
			local stopRegion = false
			for d = 1, 6 do
				local nx, ny = directionalTransform(d, tx, ty)
				local index = ny * iW + nx + 1
				if tileTiles[index] == nil and continentalTiles[index] ~= nil and ny > southPole and ny < northPole then
					if math.random() > regionNoExpandRatio then
						local tileNumber = math.random(1, #region.tileList)
						local tileName = region.tileList[tileNumber]
						-- latitude checks
						local draw = true
						if useLatitude == true then
							draw = tileLatitudeChecks(index, tileName)
						end
						if draw == true then
							tileTiles[index] = tileName
							regionNames[index] = regionName
							regionalTiles[index] = { regionIndex = regionIndex, painted = false }
							table.insert(tempTiles, index)
							newCount = newCount + 1
							-- counting number of tiles of each terrain type
							if terrainFilledTiles[tileDictionary[tileName].terrainType] == nil then
								terrainFilledTiles[tileDictionary[tileName].terrainType] = 1
							else
								terrainFilledTiles[tileDictionary[tileName].terrainType] = terrainFilledTiles[tileDictionary[tileName].terrainType] + 1
							end
						end
					end
				elseif ny <= southPole or ny >= northPole then
					iCount = maxIterations
					break
				end
				if newCount >= maxArea then break end
			end
			if stopRegion == true then break end
			table.remove(tileBuffer, bufferIndex)
		until #tileBuffer <= 1 or newCount >= maxArea
		tileBuffer = tempTiles
		for i,v in pairs(tempTiles) do
			table.insert(newTiles, v)
		end
		iCount = iCount + 1
--		print(newCount, maxArea, iCount, maxIterations)
	until newCount >= maxArea or iCount >= maxIterations
	return newTiles
end


local function growRegions()

	-- restrict region size to biggest continent
	print("biggest continent size", biggestContinentSize)
	local halfBiggestContinentSize = math.ceil(biggestContinentSize / 2)
	if regionMaxSize > biggestContinentSize then
		print ("region maximum size", regionMaxSize, "reduced to", biggestContinentSize)
		regionMaxSize = math.max(biggestContinentSize, smallestRegionSize * 2)
	end
	if regionMinSize > halfBiggestContinentSize then
		print ("region minimum size", regionMinSize, "reduced to", halfBiggestContinentSize)
		regionMinSize = math.max(halfBiggestContinentSize, smallestRegionSize)
	end
	regionAvgSize = (regionMinSize + regionMaxSize) / 2
	maxRegions = math.floor( (4 * landArea) / regionAvgSize )
	print("maximum regions", maxRegions)

	-- gather available tiles to fill with regions
	for nothing, xy in pairs(continentalXY) do
		local index = getIndex(xy.x, xy.y)
		table.insert(availableIndices, index)
	end

	print("setting by-terrain tile lists for procedural region types...")
	setNesses()
	terrainList, terrains, terrainMaxArea = prepareTerrainTileLists()

	local totalTiles = continentalTotalTiles
	local filledTiles = 0
	local regionIterations = 0
	local sameAreaLeft = 0
	local lastFilledtiles = 0
	repeat
		regionIterations = regionIterations + 1
		local avi = math.random(1, #availableIndices)
		local index = availableIndices[avi]
		local x, y = getXY(index)
		local regionName, region
		local latitude
		if useLatitude == true then
			local plot = Map.GetPlotByIndex(index - 1)
			if plot ~= nil then latitude = plot:GetLatitude() end
			print(latitude)
		end
		regionName = regionIterations
		repeat
			region = generateRegionType(latitude)
		until #region.tileList > 0 and #region.paintTileList > 0
		table.insert(regionList, regionName)
		table.insert(regionDictionary, region)
		totalRegions = #regionDictionary
		local regionSize = math.random(regionMinSize, regionMaxSize)
		local regionPaintedSize = math.floor(regionSize * region.paintedRatio)
		local regionExpandedSize = regionSize - regionPaintedSize
		local tiles = paintRegion(x, y, regionIterations, regionName, regionPaintedSize)
		print(#tiles, "tiles painted")
		if #tiles > 0 then
			tilesByRegion[regionIterations] = {}
			for nothing,tindex in pairs(tiles) do
				table.insert(tilesByRegion[regionIterations], tindex)
			end
		end
		filledTiles = filledTiles + #tiles
		local expandedTiles = expandRegion(tiles, regionIterations, regionName, regionExpandedSize, maxIterations)
		print(#expandedTiles, "tiles expanded")
		if #expandedTiles > 0 then
			if tilesByRegion[regionIterations] == nil then tilesByRegion[regionIndex] = {} end
			for nothing,tindex in pairs(expandedTiles) do
				table.insert(tilesByRegion[regionIterations], tindex)
			end
		end
		filledTiles = filledTiles + #expandedTiles

		-- check if number of terrain tiles has exceeded maximum, and remove from possible region terrains if so
		for terrainType, count in pairs(terrainFilledTiles) do
			if tmult[terrainType] > 0 and count > terrainMaxArea[terrainType] then
				print(terrainType, "count", count, "above maximum", terrainMaxArea[terrainType], "removing from list of terrains")
				tmult[terrainType] = 0
				for i, tt in pairs(terrains) do
					if tt == terrainType then
						table.remove(terrains, i)
					end
				end
			end
		end

		-- remove filled tiles from availableIndices
		for ai, index in pairs(availableIndices) do
			if tileTiles[index] ~= nil then table.remove(availableIndices, ai) end
		end
		print(#availableIndices, "available tiles left")
		regions[regionIterations] = { regionName = regionName, size = #tiles + #expandedTiles }
		print ("region number", regionIterations, "done")
		if filledTiles == 0 and lastFilledtiles == 0 then
			sameAreaLeft = sameAreaLeft + 1
		else
			sameAreaLeft = 0
		end
		lastFilledtiles = filledTiles
	until filledTiles >= totalTiles or regionIterations >= maxRegions or sameAreaLeft > 10 or #availableIndices < regionMinSize
	totalRegions = regionIterations
end


local function fillRegionGaps()
	for index,continentIndex in pairs(continentalTiles) do
		if regionNames[index] == nil then
--			print("continent tile not in a region")
			local x, y = getXY(index)
			local neighbors = {}
			for d = 1, 6 do
				local dx, dy = directionalTransform(d, x, y)
				local dindex = getIndex(dx, dy)
				if regionNames[dindex] ~= nil then
					table.insert(neighbors, dindex)
				end
			end
			if #neighbors > 0 then
				local ni = 1
				if #neighbors > 1 then ni = math.random(1, #neighbors) end
				local nindex = neighbors[ni]
				local regionName = regionNames[nindex]
				local region = regionDictionary[regionName]
				local tileNumber = math.random(1, #region.tileList)
				local tileName = region.tileList[tileNumber]
				tileTiles[index] = tileName
				regionNames[index] = regionName
				regionalTiles[index] = { regionIndex = regionalTiles[nindex].regionIndex, painted = false }
--				print("filled with", regionName, tileName)
			else
--				print("no neighboring regions")
			end
		end
	end
end


local function fillTinyRegions()
	for regionIndex, tiles in pairs(tilesByRegion) do
		if #tiles < smallestRegionSize then
			local namecounts = {}
			local counted = {}
			local highestcount = 0
			local highestname
			local highestri
			for i, index in pairs(tiles) do
				local x, y = getXY(index)
				for d = 1, 6 do
					local dx, dy = directionalTransform(d, x, y)
					local dindex = getIndex(dx, dy)
					if counted[dindex] ~= true then
						if regionNames[dindex] ~= nil and regionNames[dindex] ~= regionNames[index] then
							if #tilesByRegion[regionalTiles[dindex].regionIndex] >= smallestRegionSize then
								if namecounts[regionNames[dindex]] == nil then namecounts[regionNames[dindex]] = 1 end
								namecounts[regionNames[dindex]] = namecounts[regionNames[dindex]] + 1
								if namecounts[regionNames[dindex]] > highestcount then
									highestcount = namecounts[regionNames[dindex]]
									highestname = regionNames[dindex]
									highestri = regionalTiles[dindex].regionIndex
								end
							end
						end
						counted[dindex] = true
					end
				end
			end
			if highestname ~= nil then
--				print("replacing region", regionIndex, "of", #tiles, "tiles with region", highestri)
				for i, index in pairs(tiles) do
					regionNames[index] = highestname
					local region = regionDictionary[highestname]
					local tileNumber = math.random(1, #region.tileList)
					local tileName = region.tileList[tileNumber]
					tileTiles[index] = tileName
					regionalTiles[index] = { regionIndex = highestri, painted = false }
				end
			end
		end
	end
end


local function mountainLineCheck(x, y)
	local goodD = true
	local lastMountain = -1
	for di = 1, 7 do
		local d = di
		if d > 6 then d = d - 6 end
		local dx, dy = directionalTransform(d, x, y)
		local dindex = getIndex(dx, dy)
		if dindex > 0 and dindex < mapArea then
			local dplot = Map.GetPlotByIndex(dindex - 1)
			if dplot:GetPlotType() == PlotTypes.PLOT_MOUNTAIN then
				local mountainDistance = di - lastMountain
				if mountainDistance == 1 then
					if math.random() > mountainThickness then
						goodD = false
						break
					end
				else
					lastMountain = d
				end
			end
		end
	end
	return goodD
end

-- find mountain range lines (along coasts and between regions), seperated into ranges
local function findRangeTiles()
	for i, xy in pairs(continentalXY) do
		local x = xy.x
		local y = xy.y
		local index = getIndex(x, y)
		local regionName = regionNames[index]
		local selfCount = 0
		local otherCount = 0
		local oceanCount = 0
		local rrCount = 0
		local crCount = 0

		--flatten mountains if custom option is set to "acrophobia"
		local plot = Map.GetPlotByIndex(index - 1)
		if plot ~= nil then
			if plot:GetPlotType() == PlotTypes.PLOT_MOUNTAIN then
				if levelMountains > 0 then
					if math.random() < levelMountains then
						plot:SetPlotType(PlotTypes.PLOT_HILLS)
					else
						mountainCount = mountainCount + 1
					end
				else
					mountainCount = mountainCount + 1
				end
			end
		end
		local lastOther
		for d = 1, 6 do
			local ndx, ndy, nd = directionalTransform(d, x, y)
			local nindex = getIndex(ndx, ndy)
--			print (nd, ndx, ndy)
--			print(d, regionNames[nindex])
			if regionName ~= nil then
				if regionNames[nindex] == regionName then
					selfCount = selfCount + 1
				elseif regionNames[nindex] ~= nil and regionNames[nindex] ~= regionName then
					otherCount = otherCount + 1
--					print(regionNames[nindex], regionalTiles[nindex].regionIndex, regionalTiles[nindex].painted)
					lastOther = regionalTiles[nindex].regionIndex
				end
			end
			if continentalTiles[nindex] == nil then
				oceanCount = oceanCount + 1
			end
			if isRegionRange[nindex] then rrCount = rrCount + 1 end
			if isCoastRange[nindex] then crCount = crCount + 1 end
		end
		local rCount = rrCount + crCount
		--before: selfCount > 2 and othercount > 1 and rCount < 5
		if selfCount > 0 and otherCount > 0 and oceanCount == 0 then
			isRegionRange[index] = true
--			print(lastOther)
			local rangeIndex = pairEm(regionalTiles[index].regionIndex, lastOther)
--			print(rangeIndex, regionalTiles[index].regionIndex, lastOther)
			if regionRange[rangeIndex] == nil then regionRange[rangeIndex] = {} end
			table.insert(regionRange[rangeIndex], index)
			regionRangeTileCount = regionRangeTileCount + 1
--			print(i, x, y, index, selfCount, otherCount, oceanCount, regionName, "region")
		-- before: oceanCount > 0 and oceanCount < 4 and rCount < 5
		elseif oceanCount > 0 then
			isCoastRange[index] = true
			local rangeIndex = -1
			if regionalTiles[index] ~= nil then
				rangeIndex = regionalTiles[index].regionIndex
			end
			if coastRange[rangeIndex] == nil then coastRange[rangeIndex] = {} end
			table.insert(coastRange[rangeIndex], index)
			coastRangeTileCount = coastRangeTileCount + 1
--			print(i, x, y, index, selfCount, otherCount, oceanCount, regionName, "coast")
		end
	end
end

-- collect tiles to be potentially mountainous from coast range and region range
local function collectRange(range, totalArea, perscribedArea)
	perscribedArea = perscribedArea + math.ceil((rangeHillRatio+0.05) * perscribedArea) -- to account for some collected tiles becoming hills
	local areaDifference = totalArea - perscribedArea
	local area = 0
	if areaDifference <= 0 then 
		area = totalArea
	else
		area = totalArea - (areaDifference * mountainClumpiness)
	end
	print(totalArea, perscribedArea, areaDifference, area)
	if area == 0 then return 0 end
	local rangeBuffer = {}
	for rangeIndex, localRange in pairs(range) do
		table.insert(rangeBuffer, rangeIndex)
	end
	if #rangeBuffer <= 1 then return nil end

	local originalArea = 0
	if uniformMountainRanges then
		originalArea = area + 0
		area = mapArea + 0
	end
	local tilesCollected = 0
	local collection = {}
	repeat
		local bufferIndex = math.random(1, #rangeBuffer)
		local rangeIndex = rangeBuffer[bufferIndex]
		local localRange = range[rangeIndex]
		local begin = 1
		local stop = #localRange
		-- if it's a large enough mountain range, skip the beginning and ending one or two tiles, to break up the monotony and allow passage
		if #localRange > 12 then
--			print("range size", #localRange, "skipping 4")
			begin = 3
			stop = #localRange - 2
		elseif #localRange > 6 then
--			print("range size", #localRange, "skipping 2")
			begin = 2
			stop = #localRange - 1
		end
		for lri = begin, stop do
--			print(lri, lrb, lrf, #localRange)
			local index = localRange[lri]
			local x, y = getXY(index)
			local check = true
			if skinnyMountainRanges == true then check = mountainLineCheck(x, y) end
			if check == true then
				table.insert(collection, index)
				tilesCollected = tilesCollected + 1
			end
			if tilesCollected >= area then break end
		end
		table.remove(rangeBuffer, bufferIndex)
	until tilesCollected >= area or #rangeBuffer == 0
	print(tilesCollected, "tiles collected of", totalArea)
	return collection
end

-- raise collected range tiles at random
local function raiseRange(collection, area)
	local buffer = {}
	for i = 1, #collection do
		table.insert(buffer, collection[i])
	end
	local tilesRaised = 0
	local mountainTiles = {}
	repeat
		local index = table.remove(buffer, math.random(1, #buffer))
		local plot = Map.GetPlotByIndex(index - 1)
		if plot ~= nil then
			if math.random() < rangeHillRatio then
				plot:SetPlotType(PlotTypes.PLOT_HILLS, false, false)
				--tilesRaised = tilesRaised + 0.5
			else
				plot:SetPlotType(PlotTypes.PLOT_MOUNTAIN, false, false)
				table.insert(mountainTiles, index)
				tilesRaised = tilesRaised + 1
			end
		end
	until tilesRaised >= area or #buffer == 0
	print(tilesRaised, "tiles raised of", area)
	return tilesRaised, mountainTiles
end

--if not enough tiles raised, expand mountains at random
local function expandMountains(tilesRaised, area, mountainTiles)
	if tilesRaised < area and #mountainTiles > 0 then
		local mountainBuffer = mountainTiles
		local noChange = 0
		repeat
			local bufferIndex = math.random(1,#mountainBuffer)
			local index = mountainBuffer[bufferIndex]
			local x, y = getXY(index)
			local dirs = { 1, 2, 3, 4, 5, 6 }
			repeat
				local di = math.random(1,#dirs)
				local d = dirs[di]
				local dx, dy = directionalTransform(d, x, y)
				local dindex = getIndex(dx, dy)
				local awayFromCoast = true
				if isCoastRange[index] == nil and isCoastRange[dindex] ~= nil then awayFromCoast = false end
				--print(isCoastRange[index], isCoastRange[dindex], awayFromCoast)
				if continentalTiles[dindex] ~= nil and awayFromCoast then
					local plot = Map.GetPlotByIndex(dindex - 1)
					if math.random() < rangeHillRatio and plot:GetPlotType() ~= PlotTypes.PLOT_HILLS and plot:GetPlotType() ~= PlotTypes.PLOT_MOUNTAIN then
						plot:SetPlotType(PlotTypes.PLOT_HILLS, false, false)
						table.insert(mountainBuffer, dindex)
						noChange = 0
						--tilesRaised = tilesRaised + 0.5
					elseif plot:GetPlotType() ~= PlotTypes.PLOT_MOUNTAIN and plot:GetPlotType() ~= PlotTypes.PLOT_HILLS then
						plot:SetPlotType(PlotTypes.PLOT_MOUNTAIN, false, false)
						table.insert(mountainBuffer, dindex)
						--table.remove(mountainBuffer, bufferIndex)
						tilesRaised = tilesRaised + 1
						noChange = 0
					else
						noChange = noChange + 1
					end
				else
					noChange = noChange + 1
				end
				table.remove(dirs, di)
			until #dirs == 0 or tilesRaised >= area
			table.remove(mountainBuffer, bufferIndex)
		until tilesRaised >= area or noChange > 36 or #mountainBuffer == 0
		print(tilesRaised, "tiles raised of", area, "(after expansion)")
	end
	return tilesRaised
end

local function doRange(range, totalArea, perscribedArea)
	print("collecting range tiles...")
	local collection = collectRange(range, totalArea, perscribedArea)
	print("raising range tiles...")
	local tilesRaised, mountainTiles = raiseRange(collection, perscribedArea)
	print("expanding mountains...")
	local tilesRaised = expandMountains(tilesRaised, perscribedArea, mountainTiles)
	return tilesRaised
end

local function popIce(index, noCoast)
	local plot = Map.GetPlotByIndex(index - 1)
	plot:SetFeatureType(FeatureTypes.FEATURE_ICE)
	if noCoast ~= true then
		local x, y = getXY(index)
		for d = 1, 6 do
			local nx, ny = directionalTransform(d, x, y)
			local nindex = getIndex(nx, ny)
			local nplot = Map.GetPlotByIndex(nindex - 1)
			if nplot ~= nil then
				local t = nplot:GetTerrainType()
				if t == 6 then nplot:SetTerrainType(5) end
			end
		end
	end
end


local function popCoasts()
	local oBuffer = stillOcean
	local isNotFlat = {}
	repeat
		local i = math.random(1, #oBuffer)
		local index = oBuffer[i]
		local plot = Map.GetPlotByIndex(index - 1)
		local thisIceChance = iceChance
		if plot ~= nil then
			if useLatitude == true then
				local latitude = plot:GetLatitude()
				local m = (latitude ^ 2) / 8100
				thisIceChance = iceChance * m
			end
			if plot:GetTerrainType() == 5 or nearOceanIce[index] == true then
				local x, y = getXY(index)
				local ice = false
				local atoll = false
				local flat = true
				local deep = false
				local hascoast = false
				local hasland = false
				local firstci
				local betweencontinents = false
				local blockedCount = 0
				local oceanTiles = {}
				local deepTiles = {}
				local od
				local bd
				local bdistance
				for d = 1, 6 do
					local nx, ny = directionalTransform(d, x, y)
					local nindex = getIndex(nx, ny)
					local nplot = Map.GetPlotByIndex(nindex - 1)
					if nplot ~= nil then
						local t = nplot:GetTerrainType()
						local f = nplot:GetFeatureType()
						local p = nplot:GetPlotType()
						if t == 5 then
							hascoast = true
						elseif t ~= 6 then
							hasland = true
							if firstci == nil then
								firstci = continentalTiles[nindex]
							else
								if firstci ~= continentalTiles[nindex] then betweencontinents = true end
							end
						end
						if t == 4 then --snow
							ice = true
						elseif f == FeatureTypes.FEATURE_ICE then
							ice = true
							noland = false
						elseif t == 0 or t == 2 then -- grass or desert
							if p == 2 then
								atoll = true
							end
						elseif p == 0 or p == 1 or isNotFlat[nindex] == true or isNotFlat[index] == true then -- mountains or hills
							flat = false
							isNotFlat[nindex] = true
						elseif t == 6 then -- deep ocean
							deep = true
							table.insert(deepTiles, nindex)
						end
						if f == FeatureTypes.FEATURE_ICE or p ~= 3 then
							blockedCount = blockedCount + 1
							if bd == nil then
								bdistance = 0
							elseif d - bd > bdistance then
								bdistance = d - bd
								bd = d
							end

						elseif p == 3 then
							-- counting ocean tiles in a row
							if od == nil or d - od == 1 then
--								print("yes", od, d)
								table.insert(oceanTiles, nindex)
								--print(nindex, d)
								od = d
							end
						end
					end
				end
				if y == 0 or y == yMax - 1 then blockedCount = blockedCount + 2 end
				if blockedCount == 0 and math.random() < coastRecedeChance then
					plot:SetTerrainType(6)
				elseif (ice == true and betweencontinents == false and blockedCount < 3 and (bdistance == 1 or bdistance == 0 or bdistance == 5)) or (hascoast == false and hasland == false) then
					local isOcean = false
					if nearOceanIce[index] == true then
						isOcean = true
					end
					if math.random() < thisIceChance then
						popIce(index, isOcean)
						if isOcean == true then
							for d = 1, 6 do
								local dx, dy = directionalTransform(d, x, y)
								local dindex = getIndex(dx, dy)
								local dplot = Map.GetPlotByIndex(dindex - 1)
								if dplot ~= nil then
									if dplot:GetTerrainType() == 6 then
										nearOceanIce[dindex] = true
									end
								end
							end
						end
					end
				elseif atoll == true and #oceanTiles > 3 then
					if math.random() < atollChance then
						--print("atoll possible")
						local a = math.random(2, #oceanTiles-1)
						local aplot = Map.GetPlotByIndex(oceanTiles[a] - 1)
						plot:SetTerrainType(5)
						plot:SetFeatureType(featureAtoll)
					end
				elseif deep == true and flat == true and isNotFlat[index] ~= true then
					for nothing, index in pairs(deepTiles) do
						local dplot = Map.GetPlotByIndex(index - 1)
--						print("coast can expand")
						if dplot ~= nil and math.random() < coastExpandChance then
--							print("coast expanded!")
							dplot:SetTerrainType(5)
						end
					end
				end
			end
		end
		table.remove(oBuffer, i)
	until #oBuffer <= 1
end


----


function GeneratePlotTypes()

	setBeforeOptions()

	print("setting tile dictionary...")
	setTileDictionary()

	print("getting map size...")
	iW, iH = Map.GetGridSize()
	xMax = iW - 1
	yMax = iH
	southPole = 0
	northPole = yMax - 1
	mapArea = (iW) * (iH)
	landArea = math.floor( mapArea * landRatio )

	setAfterOptions()

	regionAvgSize = math.floor( (regionMinSize + regionMaxSize) / 2 )

	maxRegions = math.floor( (4 * landArea) / regionAvgSize )
	print(iW, "by", iH)
	print("land area", landArea)
	print("maximum regions", maxRegions)

	print("growing continents...")
	growContinents()

	print("filling tiny lakes...")
	fillTinyLakes()

	print("growing regions...")
	growRegions()

	print("filling region gaps...")
	fillRegionGaps()
	print("filling tiny regions...")
	fillTinyRegions()

	print("setting plots...")
	for index = 1, mapArea do
		local plot = Map.GetPlotByIndex(index - 1)
		local tile
		if continentalTiles[index] == nil then
			plot:SetPlotType(3)
			if isCoast[index] then
--				plot:SetTerrainType(TerrainTypes.TERRAIN_COAST)
			else
				plot:SetTerrainType(TerrainTypes.TERRAIN_OCEAN)
			end
		else
			if tileTiles[index] == nil then
				tile = tileDictionary[baseTile]
			else
				local tileName = tileTiles[index]
				tile = tileDictionary[tileName]
			end
			if tile == nil then print(tileName) end
			plot:SetPlotType(tile.plotType, false, false)
	--		terrainTypes[index - 1] = tile.terrainType
	--		print(tile.terrainType, index)
		end
	end

	print("finding mountain ranges...")
	findRangeTiles()

	if mountainCount >= continentalTotalTiles then
		print("all mountain area taken by regions")
	else
		local totalMountainArea = math.floor(continentalTotalTiles * mountainRatio)
		local mountainAreaLeft = totalMountainArea - mountainCount
		local coastRangeArea = math.floor(mountainAreaLeft * coastRangeRatio)
		local regionRangeArea = mountainAreaLeft - coastRangeArea
		print("inter-region range:")
		local rTilesRaised = doRange(regionRange, regionRangeTileCount, regionRangeArea)
		if rTilesRaised == nil then rTilesRaised = 0 end
		if rTilesRaised < regionRangeArea then
			coastRangeArea = coastRangeArea + (regionRangeArea - rTilesRaised)
			print("only", rTilesRaised, "region range raised out of", regionRangeArea, "coast range increased by", regionRangeArea - rTilesRaised, "to", coastRangeArea)
		end
		print("coast range:")
		local cTilesRaised = doRange(coastRange, coastRangeTileCount, coastRangeArea)
	end

	local args = { bExpandCoasts = false }
	GenerateCoasts(args)

end

----------------------------------------------------------------------------------

function GenerateTerrain()
	print("Generating Terrain (Fantasy) ...");

	local terrainTypes = {}

	for index = 1, mapArea do
		local plot = Map.GetPlotByIndex(index - 1)
		local tile
		if continentalTiles[index] == nil then
			if plot:GetTerrainType() ~= 6 and plot:GetTerrainType() ~= 5 then
				print(plot:GetTerrainType(), index)
				plot:SetTerrainType(7, false, false)
			end
		else
			if tileTiles[index] == nil then
				tile = tileDictionary[baseTile]
			else
				local tileName = tileTiles[index]
				tile = tileDictionary[tileName]
			end
			plot:SetTerrainType(tile.terrainType, false, false)
			if useLatitude == true then
				local x, y = getXY(index)
				if y == yMax - 1 or y == 0 then
					plot:SetTerrainType(TerrainTypes.TERRAIN_SNOW, false, false)
				elseif y == yMax - 2 or y == 1 then
					if tile.terrainType ~= TerrainTypes.TERRAIN_SNOW then
						plot:SetTerrainType(TerrainTypes.TERRAIN_TUNDRA, false, false)
					end
				end
			end
	--		terrainTypes[index - 1] = tile.terrainType
	--		print(tile.terrainType, index)
		end
	end

--	SetTerrainTypes(terrainTypes);

end

----------------------------------------------------------------------------------

function FeatureGenerator:AddIceAtPlot(plot, iX, iY, lat)
	if(plot:CanHaveFeature(self.featureIce)) then
		plot:SetFeatureType(FeatureTypes.FEATURE_ICE)
	end
end

function AddFeatures()
	print("Adding Features (Fantasy) ...");

	for index = 1, mapArea do
		local plot = Map.GetPlotByIndex(index - 1)
		local tile = tileDictionary[baseTile]
		local tileName
		if tileTiles[index] == nil then

		else
			local i = index
--			if i < mapArea then i = i + 1 end
			tileName = tileTiles[i]
			tile = tileDictionary[tileName]
		end
		if tile ~= nil and continentalTiles[index] ~= nil then
			local feature = tile.feature
			if feature == FeatureTypes.NO_FEATURE then
				if plot:CanHaveFeature(FeatureTypes.FEATURE_FLOOD_PLAINS) then
					feature = FeatureTypes.FEATURE_FLOOD_PLAINS
				end
			end
			if plot:CanHaveFeature(feature) then
				plot:SetFeatureType(feature)
			elseif (plot:GetPlotType() == PlotTypes.PLOT_LAND or plot:GetPlotType() == PlotTypes.PLOT_HILLS) and plot:GetTerrainType() == TerrainTypes.TERRAIN_PLAINS and feature == FeatureTypes.FEATURE_JUNGLE then
				-- for some reason civ 5's own checks don't think that jungle should occur on plains
				plot:SetFeatureType(feature)
			end
		end
		if useLatitude == true then
			local x, y = getXY(index)
			if y == yMax - 1 or y == 0 then
				if plot:CanHaveFeature(FeatureTypes.FEATURE_ICE) then
					plot:SetFeatureType(FeatureTypes.FEATURE_ICE)
					popIce(index, true)
					for d = 1, 6 do
						local dx, dy = directionalTransform(d, x, y)
						local dindex = getIndex(dx, dy)
						local dplot = Map.GetPlotByIndex(dindex - 1)
						if dplot ~= nil then
							if dplot:GetTerrainType() == 6 then
								nearOceanIce[dindex] = true
							end
						end
					end
				end
			elseif plot:GetLatitude() > featureLatitudes[FeatureTypes.FEATURE_ICE].mini then
				if plot:GetTerrainType() == 6 and plot:CanHaveFeature(FeatureTypes.FEATURE_ICE) and math.random() < iceChance * (plot:GetLatitude() / 270) then
					local iceHere = true
					local nearice = {}
					for d = 1, 6 do
						local dx, dy = directionalTransform(d, x, y)
						local dindex = getIndex(dx, dy)
						local dplot = Map.GetPlotByIndex(dindex - 1)
						if dplot ~= nil then
							if dplot:GetTerrainType() ~= 6 then
								iceHere = false
								break
							else
								table.insert(nearice, dindex)
							end
						end
					end
					if iceHere == true then
						popIce(index, true)
						for nothing, dindex in pairs(nearice) do
							if  math.random() < iceChance / 12 then nearOceanIce[dindex] = true end
						end
					end
				end
			end
		end

	end

	for thisFeature in GameInfo.Features() do
		if thisFeature.Type == "FEATURE_ATOLL" then
			featureAtoll = thisFeature.ID;
		end
	end

	print("popping coasts w/ ice & atolls...")
	popCoasts()

	-- for debugging, shows where continent isolation is by putting jungle in the ocean
	--[[
	for index, ci in pairs(isCoast) do
		local plot = Map.GetPlotByIndex(index-1)
		if plot ~= nil then
			plot:SetFeatureType(FeatureTypes.FEATURE_JUNGLE)
		end
	end
	]]--

	-- trying to find bugs
	--[[
	for index = 1, mapArea do
		local plot = Map.GetPlotByIndex(index - 1)
		local p = plot:GetPlotType()
		local t = plot:GetTerrainType()
		local f = plot:GetFeatureType()
		if p == PlotTypes.PLOT_MOUNTAIN and t > 4 then
			print("bad mountain plot", p, t, f, "at", index)
		end
		if t > 6 then print ("mountain or hill terrain", p, t, f, "at", index) end
		if f == FeatureTypes.FEATURE_JUNGLE and t ~= TerrainTypes.TERRAIN_PLAINS then
			print ("jungle not on plains", p, t, f, "at", index)
		end
	end
	]]--

end

----------------------------------------------------------------------------------
