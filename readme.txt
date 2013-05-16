-- add minimum to dice roll function (so that wet climates can more consistently put forests & jungles)?
-- try to figure out what causes texture errors?
-- allow more than one ally, with probabilities for each and make the appearance of any ally dependent upon latitudes. (plains for example should have tundra, desert, and grassland)
-- code change: regionIndex and regionName are now redundant. merge them.
-- better system for figuring out where deep & shallow areas are for expanding coasts
-- posibility of seperating regions with rivers?

v14 --> v15
-- climates tweaked a lot. no more terraintypes completely excluded from any climate, and hot and cool latitudes less extreme.
-- map options tweaked a bit:
	-- "normal" continent shape is now paintedratio 0.5, and default
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
