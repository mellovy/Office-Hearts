extends Node
## Story content for "Office Hearts". Autoloaded as "Story".
##
## Each chapter is a dictionary:
##   title      : String shown on the chapter banner
##   location   : String shown under the title
##   bgm        : String label describing the mood music (shown as a small note)
##   bg          : Color hex string for the backdrop
##   route      : "common" | "arthur" | "dante" | "leo"
##   lines      : Array of {speaker, text}. speaker "" = narration.
##   choice     : optional {prompt, options:[{text, next, char, points}]}
##   next       : optional chapter id to auto-advance to when no choice
##   ending     : optional "good" | "bad" label id, e.g. "arthur_good"

const L := "\n"

const CHAPTERS: Dictionary = {

	# ---------------------------------------------------------------- COMMON
	"common_ch1": {
		"title": "Chapter 1 — The 5:58 PM Emergency",
		"location": "Aether Dynamics — Open Marketing Floor — Friday, 5:58 PM",
		"bgm": "♪ Upbeat, fast-paced jazz",
		"bg": "#f4d9c6",
		"route": "common",
		"lines": [
			{"speaker": "", "text": "The glow of dual monitors illuminates Maya's face. Her desk is a mess of color-coded sticky notes, empty coffee cups, and half-finished budget reports."},
			{"speaker": "MAYA (NARRATION)", "text": "Two minutes. Exactly one hundred and twenty seconds until the glorious dawn of the weekend. My bag is packed. My jacket is on. My soul is ready to disconnect from Slack forever."},
			{"speaker": "", "text": "[i]SFX: a violent, screeching mechanical crunch echoes down the hallway.[/i]"},
			{"speaker": "MAYA", "text": "[i](Squints at the printer room)[/i] Please be a paper jam. Please just be someone trying to print a 400-page PDF on cardstock again."},
			{"speaker": "", "text": "Dante Vance rushes into the cubicle aisle, holding an iced latte that is 90% melted ice."},
			{"speaker": "DANTE", "text": "Maya! Emergency! A crisis of catastrophic, multi-departmental proportions!"},
			{"speaker": "MAYA", "text": "Dante, if this is about the breakroom fridge losing the almond milk again—"},
			{"speaker": "DANTE", "text": "[i](Gasp)[/i] No! Well, yes, that's also tragic, but worse! The central shared drive just locked everyone out! My Q3 campaign slides are stuck in digital purgatory, and if I don't submit them, HR is going to make me retake the mandatory corporate compliance seminar!"},
			{"speaker": "", "text": "Leo Thorne leans against Maya's cubicle partition, a stylus tucked behind his ear."},
			{"speaker": "LEO", "text": "He's overreacting, but he's not entirely wrong. The central server didn't crash; it was restricted from an executive level. Someone triggered a high-level quarantine on the entire marketing directory fifteen minutes ago."},
			{"speaker": "MAYA", "text": "Quarantine? Why would executive servers quarantine our marketing assets?"},
			{"speaker": "LEO", "text": "[i](Leans in, lowering his voice)[/i] Because someone embedded an encrypted payload inside our public launch files. I caught it because my design layer assets were flagged with external watermarks from NEXUS Megacorp."},
			{"speaker": "MAYA", "text": "[i](Eyes widening)[/i] NEXUS? Our main competitor? Someone is leaking Project Valkyrie?!"},
			{"speaker": "", "text": "[i]SFX: heavy, measured footsteps echo down the marble floor.[/i]"},
			{"speaker": "", "text": "Arthur Pendelton enters. Tailored three-piece charcoal suit, hair pristine, radiating cold authority."},
			{"speaker": "ARTHUR", "text": "Silence. All of you."},
			{"speaker": "", "text": "The entire floor instantly goes dead quiet. Even Dante stops chewing his latte straw."},
			{"speaker": "ARTHUR", "text": "The board of directors was notified twenty minutes ago that proprietary files from Project Valkyrie were intercepted on an external server. The breach originated within this building. Effective immediately, no one leaves until the preliminary audit is complete."},
			{"speaker": "DANTE", "text": "[i](Sinks into a chair)[/i] My weekend... my weekend plans with my couch... ruined."},
			{"speaker": "ARTHUR", "text": "[i](Glances down at Maya, expression softening by a fraction of a millimeter)[/i] Miss Lin. You have the cleanest audit trail in this department. I am assembling an emergency team tonight to isolate the breach before market opening on Monday."},
			{"speaker": "MAYA (NARRATION)", "text": "This isn't just a corporate crisis — it's a complete disaster. But as I look at the three of them, I realize I hold the choice of where to lend my skills tonight."},
		],
		"choice": {
			"prompt": "Who do you help first?",
			"options": [
				{"text": "\"Mr. Pendelton, I'll assist you in the executive office with the high-level server logs.\"", "next": "arthur_ch2", "char": "arthur", "points": 2},
				{"text": "\"Dante, let's go over the team's shared drives and recover your campaign slides.\"", "next": "dante_ch2", "char": "dante", "points": 2},
				{"text": "\"Leo, show me those corrupted design files in the creative studio.\"", "next": "leo_ch2", "char": "leo", "points": 2},
			],
		},
	},

	# --------------------------------------------------------------- ARTHUR
	"arthur_ch2": {
		"title": "Chapter 2 — Cold Espresso & High Stakes",
		"location": "Arthur's Executive Corner Office — 8:30 PM",
		"bgm": "♪ Soft, moody piano with rain on glass",
		"bg": "#3c4a5e",
		"route": "arthur",
		"lines": [
			{"speaker": "", "text": "The executive suite is massive, floor-to-ceiling windows overlooking the rain-slicked city skyline. Arthur sits at his dark walnut desk, suit jacket off, tie loosened slightly — a rare crack in his armor."},
			{"speaker": "MAYA", "text": "[i](Placing a fresh espresso on his desk)[/i] You've been staring at those board member access logs for three hours without blinking, Mr. Pendelton."},
			{"speaker": "ARTHUR", "text": "[i](Sighs, rubbing the bridge of his nose)[/i] If the leak is traced to my credentials, the board will use it as leverage to force my resignation on Monday. They have wanted a more... pliable CEO for years."},
			{"speaker": "MAYA", "text": "That's absurd! You practically live in this office. You built Valkyrie's strategic plan from scratch!"},
			{"speaker": "ARTHUR", "text": "[i](Looks up, a rare, vulnerable stillness in his eyes)[/i] In corporate governance, Maya, loyalty is secondary to convenience. I have spent ten years building a wall of professionalism around myself. Yet tonight, as everything crumbles... the only person standing in this room with me is you."},
			{"speaker": "MAYA", "text": "[i](Heart skips a beat)[/i] I'm not going anywhere. We're going to prove your credentials were spoofed."},
			{"speaker": "ARTHUR", "text": "[i](Reaches out, fingers brushing yours as he takes the espresso cup)[/i] Thank you, Maya. And please... when we are alone in this room, call me Arthur."},
		],
		"next": "arthur_ch3",
	},
	"arthur_ch3": {
		"title": "Chapter 3 — Behind the Suit",
		"location": "Arthur's Private Executive Lounge — 11:45 PM",
		"bgm": "♪ Warm, quiet jazz piano",
		"bg": "#4a3b52",
		"route": "arthur",
		"lines": [
			{"speaker": "", "text": "Arthur sits on the leather sofa, holding a box of cheap, lukewarm takeout noodles."},
			{"speaker": "ARTHUR", "text": "[i](Staring awkwardly at chopsticks)[/i] I must confess... I have not eaten fast food in over seven years. My schedule is usually handled by dietary caterers."},
			{"speaker": "MAYA", "text": "[i](Giggles)[/i] Arthur, they're just sesame noodles! Here, like this."},
			{"speaker": "", "text": "She leans close, placing her hand over his to guide his grip on the chopsticks. Arthur turns his head, his face inches from hers. Subtle cedarwood cologne."},
			{"speaker": "ARTHUR", "text": "[i](Voice low)[/i] You make things seem so... effortless, Maya. My entire life has been calculated risk management. But with you... I forget the metrics."},
			{"speaker": "MAYA", "text": "[i](Blushing)[/i] Is that a good thing, Mr. Boss-Man?"},
			{"speaker": "ARTHUR", "text": "[i](Smiles genuinely — a full, breathtaking smile)[/i] It is the most terrifyingly wonderful thing that has happened to me in a decade."},
		],
		"next": "arthur_ch4",
	},
	"arthur_ch4": {
		"title": "Chapter 4 — The Boardroom Trap",
		"location": "Boardroom Hallway — Monday, 8:00 AM",
		"bgm": "♪ Tense orchestral strings",
		"bg": "#5e3c3c",
		"route": "arthur",
		"lines": [
			{"speaker": "", "text": "Maya discovers a physical encrypted keycard hidden inside Vice President Sterling's desk drawer during a morning sweep."},
			{"speaker": "MAYA (NARRATION)", "text": "VP Sterling framed Arthur using a duplicate token! The board meeting starts in fifteen minutes. I have the evidence, but Sterling's security guard is monitoring the main hallway."},
		],
		"choice": {
			"prompt": "What do you do?",
			"options": [
				{"text": "Burst into the boardroom right now and present the keycard evidence directly to the board.", "next": "arthur_end_good", "char": "arthur", "points": 2},
				{"text": "Wait for Arthur outside and pass him the keycard quietly so he can handle it through legal channels.", "next": "arthur_end_bad", "char": "", "points": 0},
			],
		},
	},
	"arthur_end_good": {
		"title": "Chapter 5 — Resolution & New Horizons",
		"location": "\"Executive Partnership\" — Good Ending",
		"bgm": "♪ Triumphant strings into a soft ballad",
		"bg": "#6b4a63",
		"route": "arthur",
		"ending": "good",
		"lines": [
			{"speaker": "", "text": "Maya storms into the boardroom, slamming the hardware keycard and server cross-references onto the mahogany table."},
			{"speaker": "MAYA", "text": "Vice President Sterling! This duplicate token matches your private office access log from 11:14 PM on Thursday!"},
			{"speaker": "STERLING", "text": "[i](Panicking, chair scraping backward)[/i] This is unverified slander from an associate!"},
			{"speaker": "ARTHUR", "text": "[i](Standing tall, radiating terrifying executive power)[/i] It is verified by the audit log I am submitting to federal investigators right now. Security, escort Sterling out."},
			{"speaker": "", "text": "The board votes unanimously to retain Arthur. Later that evening, on the private skyscraper balcony..."},
			{"speaker": "ARTHUR", "text": "[i](Wraps his coat gently around Maya's shoulders, pulling her into his arms)[/i] You saved my legacy today, Maya. But more importantly, you taught me how to live outside of work."},
			{"speaker": "MAYA", "text": "Does this mean my performance review will be favorable?"},
			{"speaker": "ARTHUR", "text": "[i](Leans down, kissing her softly against the city skyline)[/i] It means you are promoted to the owner of my heart. Permanently."},
			{"speaker": "", "text": "★ END — Executive Partnership ★"},
		],
		"next": "game_end",
	},
	"arthur_end_bad": {
		"title": "Chapter 5 — Resolution & New Horizons",
		"location": "\"Silent Departure\" — Bittersweet Ending",
		"bgm": "♪ A distant, fading piano",
		"bg": "#2e2e38",
		"route": "arthur",
		"ending": "bad",
		"lines": [
			{"speaker": "", "text": "Maya hesitates in the hallway. By the time Arthur receives the keycard, Sterling's legal team stalls the evidence review. The board forces Arthur to step down immediately."},
			{"speaker": "ARTHUR", "text": "[i](Packing his office in silence)[/i] You did what you could, Maya. But speed was everything. I must accept the board's decision."},
			{"speaker": "MAYA", "text": "Arthur, please... don't go."},
			{"speaker": "ARTHUR", "text": "[i](Gives a sad, distant smile as the elevator doors close)[/i] Goodbye, Miss Lin. Take care of yourself."},
			{"speaker": "", "text": "✦ END — Silent Departure ✦"},
		],
		"next": "game_end",
	},

	# ---------------------------------------------------------------- DANTE
	"dante_ch2": {
		"title": "Chapter 2 — Chaos, Coffee, & Accusations",
		"location": "Marketing Breakroom & Open Cubicles — 9:00 PM",
		"bgm": "♪ Upbeat, quirky mystery track",
		"bg": "#e8b84b",
		"route": "dante",
		"lines": [
			{"speaker": "", "text": "Dante paces back and forth, waving a whiteboard marker frantically while Maya sips a sugar-filled energy drink."},
			{"speaker": "DANTE", "text": "Maya! Look at this conspiracy board I made! If you connect the printer logs from Tuesday to the missing glazed donuts from Wednesday... it all points to ONE THING!"},
			{"speaker": "MAYA", "text": "Dante, you drew a picture of a giant squirrel on the whiteboard."},
			{"speaker": "DANTE", "text": "[i](Stops, pointing marker at you)[/i] A corporate spy squirrel, Maya! Think about it! Who else moves between floors without a badge?!"},
			{"speaker": "MAYA", "text": "[i](Laughs uncontrollably)[/i] Dante, you're the only manager in this company who can make a corporate espionage crisis feel like a comedy sketch!"},
			{"speaker": "DANTE", "text": "[i](Stops pacing, soft expressive eyes)[/i] Hey... I'm glad you're laughing. Honestly, I was terrified you'd think I actually leaked those files. Everyone knows I'm a little disorganized... I was worried you thought I was a failure."},
			{"speaker": "MAYA", "text": "[i](Steps closer, placing a hand on his arm)[/i] You're not a failure, Dante. You care about our team more than anyone in this building. You protect us. Now let us protect you."},
		],
		"next": "dante_ch3",
	},
	"dante_ch3": {
		"title": "Chapter 3 — The Midnight Break-In",
		"location": "Marketing Department Archive Room — 11:30 PM",
		"bgm": "♪ Sneaky, playful synth beat",
		"bg": "#4b4f6b",
		"route": "dante",
		"lines": [
			{"speaker": "", "text": "Maya and Dante crouch behind a row of filing cabinets, sharing a single flashlight."},
			{"speaker": "DANTE", "text": "[i](Whispering)[/i] Okay, stealth mission rule number one: if security comes, pretend we're practicing an emergency tango dance routine."},
			{"speaker": "MAYA", "text": "[i](Snickering)[/i] That is the worst cover story in history!"},
			{"speaker": "DANTE", "text": "[i](Grins, pulling you close to slip past a motion sensor)[/i] Maybe, but look how close it brought you to me."},
			{"speaker": "", "text": "Maya's breath catches. Dante's usual goofiness vanishes for a second, replaced by an intense, tender gaze as his thumb gently traces your cheek."},
			{"speaker": "DANTE", "text": "[i](Softly)[/i] I've been in love with your laugh since the day you joined my team, Maya. Win or lose tonight... I'm never letting go of this moment."},
		],
		"next": "dante_ch4",
	},
	"dante_ch4": {
		"title": "Chapter 4 — The Sticky-Note Standoff",
		"location": "Central IT Hub — Monday, 8:30 AM",
		"bgm": "♪ Fast-paced action-comedy music",
		"bg": "#5e4b3c",
		"route": "dante",
		"lines": [
			{"speaker": "", "text": "Maya discovers that Assistant Manager Sterling used Dante's discarded password sticky note to upload corrupt metadata."},
			{"speaker": "MAYA (NARRATION)", "text": "I have the physical log! But Dante is currently in the HR office being questioned by corporate auditors."},
		],
		"choice": {
			"prompt": "What do you do?",
			"options": [
				{"text": "Hack the lobby presentation screen to broadcast the real culprit's metadata trail live to the floor!", "next": "dante_end_good", "char": "dante", "points": 2},
				{"text": "File an official urgent appeal with HR and wait for the review panel to process it.", "next": "dante_end_bad", "char": "", "points": 0},
			],
		},
	},
	"dante_end_good": {
		"title": "Chapter 5 — Sweet Sweet Justice",
		"location": "\"Partners in Chaos\" — Good Ending",
		"bgm": "♪ Triumphant pop-punk fanfare",
		"bg": "#e8955c",
		"route": "dante",
		"ending": "good",
		"lines": [
			{"speaker": "", "text": "The main lobby flashes bright neon colors. Dante's frame-job is instantly cleared as Sterling's login history flashes across every screen in the building."},
			{"speaker": "DANTE", "text": "[i](Bursting out of HR, running down the hall with arms open)[/i] MAYA! YOU BEAUTIFUL DIGITAL WIZARD!"},
			{"speaker": "", "text": "He grabs Maya around the waist, lifting her up and spinning her around in front of the cheering marketing department."},
			{"speaker": "MAYA", "text": "[i](Laughing hysterically)[/i] Dante! Put me down, everyone is watching us!"},
			{"speaker": "DANTE", "text": "[i](Pulls out a bright neon-pink sticky note and sticks it onto your forehead)[/i] Official Managerial Directive: You are required to go out on a dinner date with me every Friday for the rest of eternity!"},
			{"speaker": "MAYA", "text": "[i](Takes the note off, smiling)[/i] I accept those terms, boss."},
			{"speaker": "", "text": "Dante leans in, kissing her with wild, joyful passion as the whole floor applauds."},
			{"speaker": "", "text": "★ END — Partners in Chaos ★"},
		],
		"next": "game_end",
	},
	"dante_end_bad": {
		"title": "Chapter 5 — Sweet Sweet Justice",
		"location": "\"Red Tape Separation\" — Bittersweet Ending",
		"bgm": "♪ A muted, distant office hum",
		"bg": "#2e2e2e",
		"route": "dante",
		"ending": "bad",
		"lines": [
			{"speaker": "", "text": "HR bureaucracy takes too long to process the appeal. To minimize scandal, corporate terminates Dante's contract and transfers Maya to a suburban branch."},
			{"speaker": "MAYA (NARRATION)", "text": "Dante packed his desk on Saturday morning. By Monday, he was gone."},
			{"speaker": "", "text": "Maya sits at a quiet, sterile desk in a distant office."},
			{"speaker": "MAYA", "text": "[i](Looking at an old yellow sticky note on her monitor)[/i] I should have taken the bold choice..."},
			{"speaker": "", "text": "✦ END — Red Tape Separation ✦"},
		],
		"next": "game_end",
	},

	# ----------------------------------------------------------------- LEO
	"leo_ch2": {
		"title": "Chapter 2 — Neon Lights & Silent Signals",
		"location": "Graphic Design Studio — 9:00 PM",
		"bgm": "♪ Lo-fi chill beats with rain",
		"bg": "#2f3b52",
		"route": "leo",
		"lines": [
			{"speaker": "", "text": "The room is dark except for the neon ambient light from Leo's dual monitors. Soft indie music plays from a small speaker."},
			{"speaker": "LEO", "text": "[i](Typing rapidly on a mechanical keyboard)[/i] Look at this color-channel metadata, Maya. The leaker didn't just export the graphics — they hid steganographic code inside our campaign watermarks."},
			{"speaker": "MAYA", "text": "[i](Leaning over his shoulder, smelling mint and charcoal)[/i] Wait... that encryption key format... that's the Lead Architect's custom signature!"},
			{"speaker": "LEO", "text": "[i](Chuckles quietly, turning his head so his dark eyes meet yours)[/i] Sharp eye, Maya. You catch things no one else in this building notices."},
			{"speaker": "MAYA", "text": "[i](Blushes, stepping back slightly)[/i] I... I just pay attention when you explain things."},
			{"speaker": "LEO", "text": "[i](Leans back in his chair, twirling his stylus)[/i] You're the only reason I haven't handed in my two weeks' notice, you know. This office is full of noise, but working with you... feels like finding quiet."},
		],
		"next": "leo_ch3",
	},
	"leo_ch3": {
		"title": "Chapter 3 — The Secret Sketchbook",
		"location": "Roof Garden — 11:30 PM",
		"bgm": "♪ Melancholic acoustic guitar",
		"bg": "#31384a",
		"route": "leo",
		"lines": [
			{"speaker": "", "text": "Leo and Maya take a breather on the outdoor terrace, looking down at the rainy city below."},
			{"speaker": "LEO", "text": "[i](Pulls out a worn leather sketchbook from his coat)[/i] I wasn't going to show anyone this. Ever."},
			{"speaker": "MAYA", "text": "[i](Opens the cover gently)[/i] Leo... these are... sketches of me?"},
			{"speaker": "", "text": "Page after page shows Maya in different moments: drinking coffee, laughing at her desk, concentrating intensely on her monitor, looking out the window."},
			{"speaker": "LEO", "text": "[i](Looking away, rubbing the back of his neck in rare embarrassment)[/i] I've drawn you every day for six months. I used to think I was just an observer in this corporate machine... until you gave my world color."},
			{"speaker": "MAYA", "text": "[i](Heart pounding, taking his hand)[/i] Leo... you're not just an observer to me. You're my favorite part of coming to work."},
		],
		"next": "leo_ch4",
	},
	"leo_ch4": {
		"title": "Chapter 4 — The Watermark Trap",
		"location": "Design Studio Server Room — Monday, 8:15 AM",
		"bgm": "♪ Suspenseful digital synth pulse",
		"bg": "#3f2f4a",
		"route": "leo",
		"lines": [
			{"speaker": "", "text": "Maya and Leo hold the final decoded render showing the Lead Architect's direct IP tag on the leaked files."},
		],
		"choice": {
			"prompt": "What do you do?",
			"options": [
				{"text": "Directly override the company broadcast server during the morning executive showcase to expose the Lead Architect.", "next": "leo_end_good", "char": "leo", "points": 2},
				{"text": "Submit the findings anonymously to the internal ethics hotline and go back to your desk.", "next": "leo_end_bad", "char": "", "points": 0},
			],
		},
	},
	"leo_end_good": {
		"title": "Chapter 5 — The Grand Canvas",
		"location": "\"Designed Together\" — Good Ending",
		"bgm": "♪ Warm morning strings",
		"bg": "#e8c9a0",
		"route": "leo",
		"ending": "good",
		"lines": [
			{"speaker": "", "text": "During the high-stakes presentation, Leo overrides the lobby displays, projecting the decoded malware map and exposing the corrupt Lead Architect in front of all staff."},
			{"speaker": "LEO", "text": "[i](Standing in the lobby doorway, hands in his coat pockets, smirk on his face)[/i] And that's how you trace digital malware, folks. Have a great Monday."},
			{"speaker": "", "text": "The lobby erupts in shock. Leo takes Maya's hand, leading her away from the chaos up to the roof garden."},
			{"speaker": "MAYA", "text": "[i](Gasping for breath, smiling wide)[/i] Leo! That was crazy! You completely hijacked the executive showcase!"},
			{"speaker": "LEO", "text": "[i](Pulls her close, resting his forehead against hers)[/i] I don't care about executives or corporate showcase slides. I only care about this canvas... and you."},
			{"speaker": "", "text": "He kisses her deeply under the warm morning sun, wrapping his jacket around her."},
			{"speaker": "LEO", "text": "Let's quit this place together and start our own design studio. What do you say, partner?"},
			{"speaker": "", "text": "★ END — Designed Together ★"},
		],
		"next": "game_end",
	},
	"leo_end_bad": {
		"title": "Chapter 5 — The Grand Canvas",
		"location": "\"Faded Sketch\" — Bittersweet Ending",
		"bgm": "♪ A single fading guitar note",
		"bg": "#2e2e38",
		"route": "leo",
		"ending": "bad",
		"lines": [
			{"speaker": "", "text": "The anonymous hotline report gets buried under corporate bureaucracy. Disillusioned and exhausted, Leo quietly submits his resignation letter that night."},
			{"speaker": "MAYA (NARRATION)", "text": "On Monday morning, Leo's cubicle was empty. His monitors were unplugged, and his desk was cleared."},
			{"speaker": "", "text": "Maya finds a single charcoal drawing left on her desk: a drawing of her sitting alone, with a note: \"Keep shining, neighbor.\""},
			{"speaker": "MAYA", "text": "[i](Tears falling onto the paper)[/i] I let him walk away..."},
			{"speaker": "", "text": "✦ END — Faded Sketch ✦"},
		],
		"next": "game_end",
	},
}

# Ordered node list describing the story tree, used by the Flowchart scene.
# Each entry: id, label, route, col (x position group), row (y position group)
const FLOW_NODES: Array = [
	{"id": "common_ch1", "label": "Ch 1\nEmergency", "route": "common", "col": 0, "row": 1},

	{"id": "arthur_ch2", "label": "Arthur\nCh 2", "route": "arthur", "col": 1, "row": 0},
	{"id": "arthur_ch3", "label": "Arthur\nCh 3", "route": "arthur", "col": 2, "row": 0},
	{"id": "arthur_ch4", "label": "Arthur\nCh 4", "route": "arthur", "col": 3, "row": 0},
	{"id": "arthur_end_good", "label": "Executive\nPartnership ♥", "route": "arthur", "col": 4, "row": 0},
	{"id": "arthur_end_bad", "label": "Silent\nDeparture", "route": "arthur", "col": 4, "row": 0.6},

	{"id": "dante_ch2", "label": "Dante\nCh 2", "route": "dante", "col": 1, "row": 1},
	{"id": "dante_ch3", "label": "Dante\nCh 3", "route": "dante", "col": 2, "row": 1},
	{"id": "dante_ch4", "label": "Dante\nCh 4", "route": "dante", "col": 3, "row": 1},
	{"id": "dante_end_good", "label": "Partners\nin Chaos ♥", "route": "dante", "col": 4, "row": 1},
	{"id": "dante_end_bad", "label": "Red Tape\nSeparation", "route": "dante", "col": 4, "row": 1.6},

	{"id": "leo_ch2", "label": "Leo\nCh 2", "route": "leo", "col": 1, "row": 2},
	{"id": "leo_ch3", "label": "Leo\nCh 3", "route": "leo", "col": 2, "row": 2},
	{"id": "leo_ch4", "label": "Leo\nCh 4", "route": "leo", "col": 3, "row": 2},
	{"id": "leo_end_good", "label": "Designed\nTogether ♥", "route": "leo", "col": 4, "row": 2},
	{"id": "leo_end_bad", "label": "Faded\nSketch", "route": "leo", "col": 4, "row": 2.6},
]

const FLOW_EDGES: Array = [
	["common_ch1", "arthur_ch2"], ["common_ch1", "dante_ch2"], ["common_ch1", "leo_ch2"],
	["arthur_ch2", "arthur_ch3"], ["arthur_ch3", "arthur_ch4"],
	["arthur_ch4", "arthur_end_good"], ["arthur_ch4", "arthur_end_bad"],
	["dante_ch2", "dante_ch3"], ["dante_ch3", "dante_ch4"],
	["dante_ch4", "dante_end_good"], ["dante_ch4", "dante_end_bad"],
	["leo_ch2", "leo_ch3"], ["leo_ch3", "leo_ch4"],
	["leo_ch4", "leo_end_good"], ["leo_ch4", "leo_end_bad"],
]

const ROUTE_COLORS: Dictionary = {
	"common": Color("#c9a5e0"),
	"arthur": Color("#7f9bd1"),
	"dante": Color("#f2b34a"),
	"leo": Color("#6bc4a6"),
}

const ROUTE_NAMES: Dictionary = {
	"arthur": "Arthur Pendelton",
	"dante": "Dante Vance",
	"leo": "Leo Thorne",
}


func get_chapter(id: String) -> Dictionary:
	return CHAPTERS.get(id, {})
