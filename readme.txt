
-- drastic change: seperate map into seperate areas of contiguous coast before growing continents within them, to control how many pre-astronomy contiguous areas there are
-- try to figure out what causes texture errors?
-- code change: regionIndex and regionName are now redundant. merge them.

v19 --> v20
-- revert to relative continent sizes
-- use Map.Rand instead of math.random, which should fix multiplayer sync issues
-- add 1 Billion Years as a World Age option
-- adjust World Age config
-- remove one Continent Shape option
-- replace Latitude-Sensitive Climate option with Map Type option
-- add option to create non-wrapping map ("territory")
-- nearly copy civ 5's native coast generator, to prevent wrapping coast tiles on nonwrapping maps
-- increase lake chance when pangaea is active (because of ismuthchance)
-- randomize (and reduce) polar ice slightly
-- add "realistic realm" map option with randomized latitude range

v18 --> v19
-- allow more than one ally, with probabilities for each and make the appearance of any ally dependent upon latitudes and also on non-latitude tmult. (plains for example have tundra, desert, and grassland)
-- minor optimizations

v17 --> v18
-- add mountain clumpiness, set it to 0.75 for more evenly distributed mountains

v16 --> v17
-- cut mountainousness to about 1/3 of before, to match default Continent script better

v15 --> v16
-- pangaea shape much improved (ismuthChance = 1.0; cSizeMin = 11; cSizeMax = 1/2 non-island land area)
-- preplanned landmass sizes
-- control over amount of islands as a ratio of the total land area
-- islands now seperate from pangaea landmass
-- continent size distribution earth-like
-- absolute continent ("landmass"?) size

- continent size is now absolute, no longer dependent upon map area & ocean size
- control over amount of islands as a ratio of the land area
- islands now seperate from pangaea landmass
- pangaea shape much improved (less patchy, fewer tiny isthmuses)

v14 --> v15
-- randomized latitudes if random climate
-- region sizes lessened and smaller variance
-- climates tweaked a lot. no more terraintypes completely excluded from any climate, and hot and cool latitudes less extreme.
-- map options tweaked a bit:
	-- "normal" continent shape is now paintedratio 0.5
	-- most options now have "random" option
-- rename map options for clarity
	-- continent size should be arranged small to large
		-- same with continent shape (extra snakey to total blobs), region size, 
-- restrict region drawing to designated latitudes, with randomized tolerance for fewer straight horizontal edges
-- World Age "Random" option works
-- region sizes: the maximum must be no larger than the largest continent and no smaller than 10, and the minimum must be no larger than 1/2 the largest continent and no smaller than 5.
-- mountains map option = "World Age" thousands of years
-- improve latitude sensitive terraintype selection: if none of the terrains in tmult are allowed at the latitude, then find the terraintype with the largest distance from the specified latitude to the terrain's maximum and minimum.
	-- also, the randomization should be a random chance to select an *allowed* terrain (new list generated each latitude), not just blindly selecting one at random until it's ok
-- restrict land area of climate-specified terrain types, to prevent maps that are entirely one thing. as in use the probabilities to calculate maximum total area of each terrain type, and remove that terrain type from the list of possibilities if it goes over.
	
v13 --> v14
-- allow mountains on 1 hex wide peninsulas. in general make mountain placement more lax
	-- interregion ranges now do not ever form on coasts (hence can be gotten aroound
	-- 2 or 4 tiles are dropped from ranges when raised if they're large, to allow better passage
-- "directedness" of continent expansion to avoid hexagonal shapes
-- similar favoring of eighths of its angle from the continental center of mass (calculated when painted)
	
v12 --> v13
-- switch jungles from grassland to plains

v11 --> v12
-- ice placement improved for navigability
-- drop down menus reorganized
-- land area (now "ocean size") and intercontinent distance merged, as a result continent shapes are more interesting
-- climate system rather than a single drop-down menu (temperature and rainfall)
-- chance of ice appearing in the middle of the ocean based on ice featureLatitudes

v10 --> v11 (done)
-- merge tiny regions into larger ones if there is a larger region neighbor (i.e., not on small islands)
-- polar ice no longer creates coast, and ignores blocking checks as long as it's in the deep ocean

v9 --> v10 (done)
-- procedural region types
-- location of regions can be based on latitude
-- polar ice possible

v8 --> v9 (done)
-- correct mountain range pairing
-- remove mountain range line checking from non-prozaced mountain options
-- fill in empty continent tiles with nearby larger region
== reorganize some code from GeneratePlotTypes into seperate functions
-- fix pangaea

-------------------

earth 80x50: 1160
