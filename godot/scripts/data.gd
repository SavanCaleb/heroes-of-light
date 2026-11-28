extends RefCounted
## Game data shared with the web version: heroes, enemies and level layouts.

const T := 48.0          # tile size in pixels
const ROWS := 15         # rows per level (the web game's 14 plus one extra floor row)
const K := 3.0           # web units -> Godot pixels

const HEROES := [
	{id="alisa", name="Alisa", title="The Explorer", hp=110, dbl=true, spd=2.6, jmp=8.3,
		s1="Mango Mayhem", s2="Bottomless Backpack", sup="Jungle Jamboree",
		look={skin="#f3d2b8", hair="#2a160c", style="bangs", shirt="#ff6fa8", pants="#ff9a3c", shoe="#7a3fa0", pack="#8a4fd8", monkey=true}},
	{id="sarah", name="Sarah", title="The Butterfly", hp=110, dbl=true, spd=2.6, jmp=8.3,
		s1="Flutter Storm", s2="Red Rocket Ride", sup="Butterfly Blizzard",
		look={skin="#f6d6bd", hair="#7a4a26", style="medium", shirt="#d8343a", pants="#2d5bd8", shoe="#ffffff", glasses=true, flower=true, butterfly="#4fd0ff"}},
	{id="shalom", name="Shalom", title="The Techie", hp=110, dbl=true, spd=2.6, jmp=8.3,
		s1="Laser Bot 3000", s2="Firewall Bubble", sup="System Reboot",
		look={skin="#4a2a18", hair="#141414", style="curly", shirt="#2c3e50", pants="#1c2833", shoe="#3ef0ff", visor=true}},
	{id="zion", name="Zion", title="The Tower", hp=110, dbl=true, spd=2.6, jmp=8.3,
		s1="Thunder Stomp", s2="Hype Train", sup="Tower Quake",
		look={skin="#4a2a18", hair="#1a0f08", style="dreads", shirt="#f2c230", pants="#1a1a1a", shoe="#d8343a", glasses=true, scale=1.12}},
	{id="mariana", name="Mariana", title="The Physio", hp=110, dbl=true, spd=2.6, jmp=8.3,
		s1="Snap-Back Band", s2="Mega Roller", sup="Therapy Tornado",
		look={skin="#4a2a18", hair="#140c08", style="ponytail", shirt="#1fb5a8", pants="#2f3e6b", shoe="#ffffff", scale=0.9}},
	{id="steven", name="Steven", title="The Sprinter", hp=110, dbl=true, spd=2.6, jmp=8.3,
		s1="Lightning Lap", s2="Squad Goals", sup="Victory Relay",
		look={skin="#4a2a18", hair="#111111", style="short", shirt="#e8463c", pants="#1c2833", shoe="#ffffff", bib=true, band="#ffffff", muscle=true, scale=0.93}},
	{id="edikan", name="Edikan", title="The Youth Leader", hp=110, dbl=true, spd=2.6, jmp=8.3,
		s1="Hallelujah Blast", s2="Doctor's Orders", sup="Revival Fire",
		look={skin="#5a3420", hair="#140c08", style="long", shirt="#9b5bff", pants="#2a2a3a", shoe="#333333", coat=true}},
	{id="savan", name="Savan", title="The Agent", hp=110, dbl=true, spd=2.6, jmp=8.3,
		s1="Spirit Blade", s2="Full Armor Mode", sup="Code Name: Glory",
		look={skin="#a8714a", hair="#0e0e12", style="straight", shirt="#17171f", pants="#17171f", shoe="#050508", suit=true, shades=true}},
]

const NPCS := {
	noah={name="Noah", look={skin="#c9956a", hair="#eeeeee", style="long", shirt="#8a6a4a", pants="#8a6a4a", shoe="#5a3a22", beard="#f0f0f0", robe="#8a6a4a", item="staff"}},
	david={name="David", look={skin="#c9956a", hair="#5a3418", style="curly", shirt="#d8b070", pants="#d8b070", shoe="#7a4a2a", robe="#d8b070", item="sling"}},
	peter={name="Peter", look={skin="#c08a60", hair="#2a1a10", style="short", shirt="#4a6a8a", pants="#4a6a8a", shoe="#5a3a22", beard="#2a1a10", robe="#4a6a8a"}},
	daniel={name="Daniel", look={skin="#b8855a", hair="#1a1008", style="short", shirt="#6a3a8a", pants="#6a3a8a", shoe="#5a3a22", band="#ffd25a", robe="#6a3a8a"}},
	joshua={name="Joshua", look={skin="#b8855a", hair="#2a1a10", style="short", shirt="#8a2a2a", pants="#8a2a2a", shoe="#5a3a22", beard="#2a1a10", robe="#8a2a2a", item="trumpet"}},
	moses={name="Moses", look={skin="#c08a60", hair="#f4f4f4", style="long", shirt="#b04a2a", pants="#b04a2a", shoe="#5a3a22", beard="#f4f4f4", robe="#b04a2a", item="staff"}},
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
## Each land is a Bible story the heroes step into, to help and to learn its lesson.
const LEVELS := [
	{name="Noah's Ark", theme="garden", npcs=["noah", "francis", "heike"],
		chunks=["start","npc","A","npc","Cw","B","M","D","J","battle","E","npc","F","I","Tz","end"],
		waves=[["m"], ["m", "m"]],
		story=[["n", "Pastor Heike opened the big Bible, and a warm light pulled the friends right inside the story..."], ["n", "Genesis, chapter 6. God told Noah to build a giant ark, because a great flood was coming."], ["noah", "Hello, friends! God told me to build this ark, and I obeyed. But shadows are scaring the animals away!"], ["hero", "Don't worry, Noah. We'll clear the path to the ark!"]],
		goal="Clear the path to Noah's ark!",
		outro=[["noah", "Every animal made it inside! Thank you, friends."], ["n", "It rained for forty days. Then God put a rainbow in the sky as a promise."], ["j", "Noah trusted God even when it was hard. Will you obey God too?"]],
		lesson="Obey God, even when others don't understand.", verse="Thus did Noah; according to all that God commanded him. (Genesis 6:22)"},
	{name="David and Goliath", theme="desert", npcs=["david", "marie"], boss="giant",
		chunks=["start","npc","Cw","F","K","M","J","npc","D","Hf","R","Tz","battle","B","I","arena"],
		waves=[["m", "m"], ["m", "t", "m"]],
		story=[["n", "1 Samuel, chapter 17. A giant named Goliath shouted at God's people every day, and everyone was afraid."], ["david", "I'm just a shepherd boy with a sling. But God is bigger than any giant!"], ["hero", "We're with you, David. Let's go!"]],
		goal="Cross the valley and face the giant!",
		boss_talk=[["boss", "I am GOLIATH, the GIANT OF FEAR! You are too small. RUN AWAY!"], ["david", "You come with a sword, but I come in the name of the LORD!"], ["hero", "Let's do this together!"]],
		outro=[["david", "The giant fell! It wasn't my strength. It was God's!"], ["j", "When you feel small and afraid, remember: God is with you."]],
		lesson="With God, you don't have to be afraid of giants.", verse="The battle is the LORD'S. (1 Samuel 17:47)"},
	{name="Jesus Calms the Storm", theme="sea", npcs=["peter", "heike"],
		chunks=["start","npc","B","E","K","Hf","J","M","battle","E","npc","L","R","K","Tz","Hf","B","end"],
		waves=[["m", "t"], ["m", "m", "b"], ["t", "m", "m"]],
		story=[["n", "Mark, chapter 4. Jesus and his friends were crossing the sea in a boat when a terrible storm came."], ["peter", "The waves are huge! We're going to sink! Where is Jesus? He's... sleeping?!"], ["hero", "Hold on, Peter! We'll get through the storm to Jesus!"]],
		goal="Get through the storm to Jesus!",
		outro=[["j", "Peace, be still."], ["n", "The wind stopped and the sea became calm."], ["peter", "Even the wind and the waves obey Him!"]],
		lesson="When life feels stormy, Jesus is in the boat with you.", verse="Peace, be still. (Mark 4:39)"},
	{name="Daniel and the Lions", theme="forest", npcs=["daniel", "francis"],
		chunks=["start","npc","Cw","D","K","J","R","M","battle","Hf","npc","E","L","Tz","R","end"],
		waves=[["m", "m", "t"], ["b", "m"], ["t", "t", "m"]],
		story=[["n", "Daniel, chapter 6. The king made a law: nobody may pray to God. But Daniel prayed anyway, three times a day."], ["daniel", "They threw me into the lions' den tonight. But I'm not afraid. I keep praying."], ["hero", "We'll get through this dark valley and stand with you, Daniel!"]],
		goal="Cross the dark valley to Daniel!",
		outro=[["daniel", "God sent His angel and shut the lions' mouths! I am safe!"], ["j", "Daniel never stopped talking to God. You can talk to Him anytime too."]],
		lesson="Keep praying, even when it's hard.", verse="My God hath sent his angel, and hath shut the lions' mouths. (Daniel 6:22)"},
	{name="The Walls of Jericho", theme="city", npcs=["joshua", "belinda"], boss="serpent",
		chunks=["start","npc","G","Hf","M","F","J","npc","R","Tz","battle","I","K","L","Hf","E","arena"],
		waves=[["m", "m", "t"], ["m", "b", "m", "t"]],
		story=[["n", "Joshua, chapter 6. The city of Jericho had huge, strong walls."], ["joshua", "God told us to march around the city for seven days, then blow the trumpets and shout!"], ["hero", "That sounds strange... but if God said it, let's do it!"]],
		goal="March through the city with Joshua!",
		boss_talk=[["boss", "Hsssss... Marching? Shouting? That will never work. Give up..."], ["joshua", "That's a lie! God always keeps His promises!"]],
		outro=[["n", "The trumpets blew, the people shouted, and the walls of Jericho came tumbling down!"], ["joshua", "God's way works, even when it seems strange."]],
		lesson="Trust God's plan, even when you don't understand it.", verse="Be strong and of a good courage. (Joshua 1:9)"},
	{name="Moses on the Mountain", theme="snow", npcs=["moses", "marie"],
		chunks=["start","npc","K","Hf","D","J","R","E","battle","K","npc","L","R","Tz","I","B","end"],
		waves=[["m", "t", "m"], ["b", "b"], ["t", "m", "m", "t"]],
		story=[["n", "Exodus, chapter 19. God called Moses up a high mountain to give His people His good rules."], ["moses", "The way up is steep and cold. Will you climb with me?"], ["hero", "All the way to the top!"]],
		goal="Climb the mountain with Moses!",
		outro=[["moses", "God gave us the Ten Commandments, to show us how to love Him and love each other."], ["j", "Love the Lord your God with all your heart, and love your neighbour as yourself."]],
		lesson="God's rules show us how to love.", verse="Thou shalt love thy neighbour as thyself. (Matthew 22:39)"},
	{name="The Hill", theme="mount", npcs=["heike"], boss="satan",
		chunks=["start","npc","A","M","Hf","K","J","R","Tz","battle","L","arena"],
		waves=[["m", "m", "t"], ["t", "b", "m", "m"]],
		story=[["n", "The friends stepped out of the Bible, back home. Every story had made their light shine brighter."], ["heike", "Now go! The church is at the top of the hill, still wrapped in chains."]],
		goal="Climb the hill and free the church!",
		boss_talk=[["boss", "So, you made it this far. But you are ALONE. These chains will stay forever!"], ["hero", "I am not alone."], ["n", "All of your friends run up the hill to stand with you!"]],
		outro=[],
		lesson="Jesus sets us free.", verse="If the Son therefore shall make you free, ye shall be free indeed. (John 8:36)"},
]

const TALK := {
	noah=["Thank you for helping! Look out for the shadows near the water.", "Keep going, the ark is just ahead!"],
	david=["I fought lions and bears to protect my sheep. God helped me every time!", "The giant is waiting at the end of the valley. Be brave!"],
	peter=["I'm a fisherman, but I've never seen waves like these!", "Keep your eyes on Jesus, not on the storm!"],
	daniel=["I'll keep praying while you fight. God is with us!", "The lions are just ahead... but so is God."],
	joshua=["Six more days of marching! Then we shout!", "Be strong and courageous!"],
	moses=["Careful, the path is icy here!", "Almost at the top. God is waiting!"],
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
