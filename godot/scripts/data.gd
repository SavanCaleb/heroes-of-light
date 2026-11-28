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
	{id="edekan", name="Edekan", title="The Youth Leader", hp=100, spd=2.6, jmp=8.6,
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
	I=["..........s.....","........-----...","................","................","....----........","................","...........m....","################","################"],
	J=["................",".......c........","################","################"],
	battle=["W.......................","........................","........................","........................","########################","########################"],
}

const LEVELS := [
	{name="Garden of Hope", theme="garden", npcs=["francis", "belinda"],
		chunks=["start","npc","A","Cw","B","M","D","J","battle","E","npc","F","I","Tz","end"]},
]

static func col(s: String) -> Color:
	return Color(s)
