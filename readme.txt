-- allow more than one ally, with probabilities for each and make the appearance of any ally dependent upon latitudes. (plains for example should have tundra, desert, and grassland)
-- code change: regionIndex and regionName are now redundant. merge them.
-- better system for figuring out where deep & shallow areas are for expanding coasts
-- posibility of seperating regions with rivers?

v13 --> v14
-- allow mountains on 1 hex wide peninsulas. in general make mountain placement more lax
	-- interregion ranges now do not ever form on coasts (hence can be gotten aroound
	-- 2 or 4 tiles are dropped from ranges when raised if they're large, to allow better passage
-- experiment with "directedness" of continent expansion to avoid hexagonal shapes
	
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
