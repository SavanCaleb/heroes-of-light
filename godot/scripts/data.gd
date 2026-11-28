extends RefCounted
## Game data shared with the web version: heroes, enemies and level layouts.

const T := 48.0          # tile size in pixels
const ROWS := 15         # rows per level (the web game's 14 plus one extra floor row)
const K := 3.0           # web units -> Godot pixels

const HEROES := [
	{id="alisa", name="Alisa", title="The Explorer", hp=100, spd=2.5, jmp=8.2, dbl=true,
		s1="Mango Mayhem", s2="Bottomless Backpack", sup="Jungle Jamboree",
		look={skin="#f3d2b8", hair="#2a160c", style="bangs", shirt="#ff6fa8", pants="#ff9a3c", shoe="#7a3fa0", pack="#8a4fd8", monkey=true}},
	{id="sarah", name="Sarah", title="The Butterfly", hp=100, spd=2.4, jmp=8.1, float=true,
		s1="Flutter Storm", s2="Red Rocket Ride", sup="Butterfly Blizzard",
		look={skin="#f6d6bd", hair="#7a4a26", style="medium", shirt="#d8343a", pants="#2d5bd8", shoe="#ffffff", glasses=true, flower=true, butterfly="#4fd0ff"}},
	{id="shalom", name="Shalom", title="The Techie", hp=100, spd=2.4, jmp=8.0,
		s1="Laser Bot 3000", s2="Firewall Bubble", sup="System Reboot",
		look={skin="#4a2a18", hair="#141414", style="curly", shirt="#2c3e50", pants="#1c2833", shoe="#3ef0ff", visor=true}},
	{id="zion", name="Zion", title="The Tower", hp=130, spd=2.3, jmp=8.0, dmg=1.25,
		s1="Thunder Stomp", s2="Hype Train", sup="Tower Quake",
		look={skin="#4a2a18", hair="#1a0f08", style="dreads", shirt="#f2c230", pants="#1a1a1a", shoe="#d8343a", glasses=true, scale=1.12}},
	{id="mariana", name="Mariana", title="The Physio", hp=100, spd=2.5, jmp=8.1,
		s1="Snap-Back Band", s2="Mega Roller", sup="Therapy Tornado",
		look={skin="#4a2a18", hair="#140c08", style="ponytail", shirt="#1fb5a8", pants="#2f3e6b", shoe="#ffffff", scale=0.9}},
	{id="steven", name="Steven", title="The Sprinter", hp=110, spd=3.1, jmp=8.2,
		s1="Lightning Lap", s2="Squad Goals", sup="Victory Relay",
		look={skin="#4a2a18", hair="#111111", style="short", shirt="#e8463c", pants="#1c2833", shoe="#ffffff", bib=true, band="#ffffff", muscle=true, scale=0.93}},
	{id="edikan", name="Edikan", title="The Youth Leader", hp=100, spd=2.6, jmp=8.6,
		s1="Hallelujah Blast", s2="Doctor's Orders", sup="Revival Fire",
		look={skin="#5a3420", hair="#140c08", style="long", shirt="#9b5bff", pants="#2a2a3a", shoe="#333333", coat=true}},
	{id="savan", name="Savan", title="The Agent", hp=120, spd=2.7, jmp=8.4, dbl=true, dmg=1.15,
		s1="Spirit Blade", s2="Full Armor Mode", sup="Code Name: Glory",
		look={skin="#a8714a", hair="#0e0e12", style="straight", shirt="#17171f", pants="#17171f", shoe="#050508", suit=true, shades=true}},
]

const NPCS := {
	francis={name="Elder Francis", look={skin="#4a2a18", hair="#1a1a1a", style="short", shirt="#2b3a5a", pants="#22263a", shoe="#111111", beard="#2a2a2a", tie="#c8312f", item="bible"}},
	belinda={name="Grandma Belinda", look={skin="#e8c09a", hair="#f4f4f4", style="bun", shirt="#9b5bff", pants="#7a3fa0", shoe="#333333", shawl="#e0a0c0", glasses=true, item="cane", bent=true}},
	heike={name="Pastor Heike", look={skin="#f0cfb0", hair="#c9a36a", style="medium", shirt="#3a3a5a", pants="#2b2b3b", shoe="#111111", item="bible"}},
	marie={name="Marie", look={skin="#f3d2b8", hair="#5a3a22", style="long", shirt="#5bb8ff", pants="#2f3e6b", shoe="#ffffff", item="mic"}},
}

const MINION := {skin="#2e1d40", hair="#2e1d40", style="none", shirt="#3e2656", pants="#24163a", shoe="#150c20", eye="#ff4b5c", horns=true, shadow=true}
const THROWER := {skin="#2e1d40", hair="#2e1d40", style="none", shirt="#5a2440", pants="#24163a", shoe="#150c20", eye="#ff4b5c", horns=true, shadow=true, item="orb"}
const BRUTE := {skin="#2e1d40", hair="#2e1d40", style="none", shirt="#46305a", pants="#24163a", shoe="#150c20", eye="#ffb020", horns=true, shadow=true, muscle=true, scale=1.35}
const GIANT := {skin="#2e1d40", hair="#2e1d40", style="none", shirt="#46305a", pants="#24163a", shoe="#150c20", eye="#ffb020", horns=true, shadow=true, muscle=true, item="club", scale=2.2}
const BELINDA := {id="belinda", name="Grandma Belinda", title="The Prayer Warrior", hp=100, spd=2.2, jmp=7.6, look={skin="#e8c09a", hair="#f4f4f4", style="bun", shirt="#9b5bff", pants="#7a3fa0", shoe="#333333", shawl="#e0a0c0", glasses=true, item="cane"}}

## What each hero's SKILL button does.
const SKILL := {alisa="monkey", sarah="swarm", shalom="laser", zion="pound", mariana="band", steven="sprint", edikan="praise", savan="sword", belinda="praise"}

const C := {
	start=["................","................","..P.............","................","################","################"],
	end=["................","..........G.....","................","................","################","################"],
	npc=["................","........n.......","################","################"],
	A=["........ooo.....","................",".......?X!X.....","................","................","...o.o......e...","################","################"],
	B=["......ooo.......","................","................","................","#####...########","#####...########"],
	Cw=["................","..o..o...o..o...","................","....e......e....","################","################"],
	M=["................","....o.o.o.......","................","......m.........","################","################"],
	Tz=["................","...........t....","..........XXX...","....m.....XXX...","################","################"],
	D=[".........oo.....","........XX......","......XXXX......","....XXXXXX...e..","################","################"],
	E=["........oo......","................","................",".......----.....","................","................","####........####","####........####"],
	F=[".....oooo.......","................","................","......^^^.......","################","################"],
	G=["................","......=?=.......","................","................","..........j.....","################","################"],
	Hf=[".........f......","................","....XX......XX..","....o........o..","................","................","################","################"],
	I=["..........s.....","........-----...","................","................","....----........","................","...........m....","################","################"],
	J=["................",".......c........","################","################"],
	K=["....o....o......","...XX...XX......","...XX...XX......","###XX...XX...###","###XX...XX...###"],
	L=["...h............","..---...........","................","......=?==......","................","................","....j.....e.....","################","################"],
	R=["................","...b......o.o...","................","..........m.....","################","################"],
	battle=["W...........................","............................","............................","............................","############################","############################"],
	arena=["B...........................","............................","....----............----....","............................","............................","............................","############################","############################"],
}

## m = shadow, t = thrower, e/j/f = shadow too (blob hoppers and flyers become shadows here), b = brute
const LEVELS := [
	{name="Garden of Hope", theme="garden", npcs=["heike", "francis", "belinda"],
		chunks=["start","npc","A","npc","Cw","B","M","D","J","battle","E","npc","F","I","Tz","end"],
		waves=[["m"], ["m", "m"]],
		intro="Shadows have crept into the garden. Push through and reach the cross!",
		verse="Thy word is a lamp unto my feet. (Psalm 119:105)"},
	{name="Wilderness of Trust", theme="desert", npcs=["marie"], boss="giant",
		chunks=["start","Cw","F","K","M","J","npc","D","Hf","R","Tz","battle","B","I","arena"],
		waves=[["m", "m"], ["m", "t", "m"]],
		intro="The road is dry and the ground is shaking...",
		boss_talk=[["boss", "I am the GIANT OF FEAR! I am too big for you. RUN AWAY!"], ["hero", "You come with fear, but I come in the name of the LORD! (1 Samuel 17:45)"]],
		verse="Trust in the LORD with all thine heart. (Proverbs 3:5)"},
	{name="Sea of Faith", theme="sea", npcs=["heike"],
		chunks=["start","B","E","npc","K","Hf","J","M","battle","E","L","R","K","Tz","Hf","B","end"],
		waves=[["m", "t"], ["m", "m", "b"], ["t", "m", "m"]],
		intro="A storm is raging over the water! Keep your eyes on Jesus.",
		verse="Be not afraid, only believe. (Mark 5:36)"},
	{name="Valley of Shadows", theme="forest", npcs=["francis"],
		chunks=["start","Cw","npc","D","K","J","R","M","battle","Hf","E","L","Tz","R","end"],
		waves=[["m", "m", "t"], ["b", "m"], ["t", "t", "m"]],
		intro="The valley is dark tonight. Follow the fireflies and don't be afraid.",
		verse="Though I walk through the valley of the shadow of death, I will fear no evil. (Psalm 23:4)"},
	{name="City of Courage", theme="city", npcs=["belinda"], boss="serpent",
		chunks=["start","G","Hf","M","npc","F","J","R","Tz","battle","I","K","L","Hf","E","arena"],
		waves=[["m", "m", "t"], ["m", "b", "m", "t"]],
		intro="Something is whispering in the dark alleys...",
		boss_talk=[["boss", "Hsssss... Nobody cares about you. You are too small. Give up..."], ["hero", "That's a lie! For God so loved the world. (John 3:16)"]],
		verse="Be strong and of a good courage. (Joshua 1:9)"},
	{name="Peaks of Patience", theme="snow", npcs=["marie"],
		chunks=["start","K","npc","Hf","D","J","R","E","battle","K","L","R","Tz","I","B","end"],
		waves=[["m", "t", "m"], ["b", "b"], ["t", "m", "m", "t"]],
		intro="The mountain is cold and steep. One step at a time!",
		verse="They that wait upon the LORD shall renew their strength. (Isaiah 40:31)"},
	{name="The Hill", theme="mount", npcs=["heike"], boss="satan",
		chunks=["start","npc","A","M","Hf","K","J","R","Tz","battle","L","arena"],
		waves=[["m", "m", "t"], ["t", "b", "m", "m"]],
		intro="The church is at the top, still wrapped in chains.",
		boss_talk=[["boss", "So, you made it this far. But you are ALONE. These chains will stay forever!"], ["hero", "I am not alone."], ["n", "All of your friends run up the hill to stand with you!"]],
		verse="If the Son therefore shall make you free, ye shall be free indeed. (John 8:36)"},
]

const TALK := {
	francis=["Welcome, young warrior! Tap ATTACK again and again: punch, punch, kick, then an UPPERCUT that sends shadows flying.", "Hold BLOCK when a shadow swings at you. Fill the gold meter, then press SUPER!"],
	belinda=["There you are! You look hungry. Have some of my cookies.", "I may be old, but I am a FIGHTER. Pray first, then keep fighting!"],
	marie=["You made it! Let me sing a worship song for you.", "The joy of the LORD is your strength! (Nehemiah 8:10) Be brave up ahead!"],
	heike=["#NAME#! The whole church is praying for you.", "Fear not: for I am with thee. (Isaiah 41:10) Keep going, and bring the songs home!"],
}

const SHOP := [
	{id="heart", name="Lion Heart", desc="+20 max HP. Be bold as a lion!", price=60, max=3},
	{id="glove", name="Gideon Gloves", desc="+12% damage on every hit.", price=80, max=3},
	{id="helmet", name="Helmet of Salvation", desc="Take 12% less damage.", price=90, max=2},
	{id="sandal", name="Swift Sandals", desc="Run 8% faster.", price=50, max=2},
	{id="wings", name="Eagle Wings", desc="Jump higher, plus one extra jump in the air.", price=120, max=1},
	{id="oil", name="Lamp Oil", desc="Skill energy refills 25% faster.", price=70, max=3},
	{id="zeal", name="Burning Zeal", desc="SUPER meter fills 30% faster.", price=90, max=2},
	{id="shield", name="Shield of Faith", desc="Blocking stops almost all damage.", price=80, max=1},
	{id="magnet", name="Manna Magnet", desc="Coins fly to you from far away.", price=90, max=1},
	{id="angel", name="Guardian Angel", desc="Once per land, an angel lifts you up with full HP.", price=140, max=1},
	{id="halo", name="Golden Halo", desc="Looks only: a shining halo over your head.", price=110, max=1},
	{id="cape", name="Royal Cape", desc="Looks only: a flowing purple cape.", price=130, max=1},
	{id="rainbow", name="Rainbow Trail", desc="Looks only: a rainbow follows you when you run.", price=150, max=1},
]

static func col(s: String) -> Color:
	return Color(s)
