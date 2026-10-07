extends RefCounted
## Common route + "Free Time" hub chapters.
## Format: see scripts/story/STORY_SCHEMA.md
## Owns: common_ch1, common_ch2, hub, hub_arthur, hub_dante, hub_leo

const CHAPTERS: Dictionary = {

	"common_ch1": {
		"title": "Chapter 1 — The 5:58 PM Emergency",
		"location": "Aether Dynamics — Open Marketing Floor — Friday, 5:58 PM",
		"bgm_key": "tense",
		"bg_scene": "office_floor",
		"route": "common",
		"lines": [
			{"speaker": "", "text": "The glow of dual monitors lights Maya's face. Her desk is a battlefield of color-coded sticky notes, cold coffee, and a budget report she has been quietly losing to all week."},
			{"speaker": "MAYA (NARRATION)", "text": "Two minutes. Exactly one hundred and twenty seconds until the glorious dawn of the weekend. My bag is packed. My jacket is on. My soul is already halfway to my couch."},
			{"speaker": "", "text": "Then the hallway screams."},
			{"speaker": "", "text": "[i]SFX: a violent, screeching mechanical crunch echoes from the printer room.[/i]"},
			{"speaker": "MAYA", "text": "[i](Squinting down the corridor)[/i] Please be a paper jam. Please just be someone trying to print a four-hundred-page PDF on cardstock again."},
			{"speaker": "", "text": "Dante Vance skids around the cubicle wall, clutching an iced latte that is now ninety percent melted ice and ten percent prayer."},
			{"speaker": "DANTE", "text": "Maya! Emergency! A crisis of catastrophic, multi-departmental proportions!"},
			{"speaker": "MAYA", "text": "Dante, if this is about the breakroom fridge losing the almond milk again—"},
			{"speaker": "DANTE", "text": "[i](Gasping)[/i] No! Well, yes, that is also a tragedy we will address later, but this is worse! The central shared drive just locked everyone out! My Q3 campaign slides are trapped in digital purgatory, and if I miss the deadline HR is going to make me retake the mandatory compliance seminar. The one with the video. The one that is four hours long."},
			{"speaker": "MAYA", "text": "[i](Wincing)[/i] Okay. That is genuinely worse."},
			{"speaker": "", "text": "Leo Thorne leans against the edge of Maya's cubicle, stylus tucked behind one ear, eyes on his tablet instead of the panic around him."},
			{"speaker": "LEO", "text": "He is overreacting. He is not wrong. The server did not crash. It was quarantined from an executive level — someone triggered a high-level lockdown on the entire marketing directory fifteen minutes ago."},
			{"speaker": "MAYA", "text": "Quarantine? Why would executive servers quarantine our marketing assets?"},
			{"speaker": "LEO", "text": "[i](Lowering his voice, leaning in)[/i] Because someone buried an encrypted payload inside our public launch files. I caught it because my design-layer exports came back stamped with watermarks from NEXUS Megacorp."},
			{"speaker": "MAYA", "text": "[i](Eyes going wide)[/i] NEXUS? Our main competitor? Someone is leaking Project Valkyrie?!"},
			{"speaker": "", "text": "[i]SFX: heavy, measured footsteps echo across the marble floor.[/i]"},
			{"speaker": "", "text": "Arthur Pendelton arrives like a cold front — tailored charcoal suit, hair immaculate, radiating the kind of authority that makes people stand up straighter without being told."},
			{"speaker": "ARTHUR", "text": "Silence. All of you."},
			{"speaker": "", "text": "The floor goes dead quiet. Even Dante stops chewing his straw."},
			{"speaker": "ARTHUR", "text": "The board was notified twenty minutes ago that proprietary files from Project Valkyrie were intercepted on an external server. The breach originated inside this building. Effective immediately, no one leaves until the preliminary audit is complete."},
			{"speaker": "DANTE", "text": "[i](Sinking into a chair)[/i] My weekend. My couch. My plans. Ruined."},
			{"speaker": "ARTHUR", "text": "[i](Glancing down at Maya — his expression softening by a fraction of a millimeter)[/i] Miss Lin. You have the cleanest audit trail in this department. I am assembling an emergency team tonight to isolate the breach before market open on Monday."},
			{"speaker": "MAYA (NARRATION)", "text": "This is a disaster. And yet, standing between the three of them, I realize I get to decide who I stand beside tonight."},
		],
		"choice": {
			"prompt": "Who do you help first?",
			"options": [
				{"text": "\"Mr. Pendelton — I'll take the executive server logs with you.\"", "next": "common_ch2", "char": "arthur", "points": 2},
				{"text": "\"Dante, let's recover your campaign slides together.\"", "next": "common_ch2", "char": "dante", "points": 2},
				{"text": "\"Leo — show me those corrupted design files.\"", "next": "common_ch2", "char": "leo", "points": 2},
			],
		},
	},

	"common_ch2": {
		"title": "Chapter 2 — The Long Night Begins",
		"location": "Marketing Floor — War Room — Friday, 8:10 PM",
		"bgm_key": "mystery",
		"bg_scene": "common_office",
		"route": "common",
		"lines": [
			{"speaker": "", "text": "Three laptops, one whiteboard, and a floor littered with takeout containers. The building has emptied out around them, leaving only the hum of the AC and the occasional flicker of a motion-sensor light."},
			{"speaker": "MAYA (NARRATION)", "text": "The leak is real. Someone with executive access planted a payload that only surfaces after midnight — timed so the theft would complete before anyone thought to look."},
			{"speaker": "DANTE", "text": "[i](Taping a photo of the office to the whiteboard)[/i] Okay. New theory. It is someone who is here late, someone nobody questions, someone who could wander anywhere."},
			{"speaker": "LEO", "text": "That is everyone in this building, Dante."},
			{"speaker": "DANTE", "text": "[i](Pointing the marker at him)[/i] Exactly! That is why it is a perfect crime!"},
			{"speaker": "ARTHUR", "text": "[i](Without looking up from his screen)[/i] Mr. Vance. If you have a name, say it. If you have a marker, put it down."},
			{"speaker": "MAYA", "text": "[i](Rubbing her eyes)[/i] Wait. Leo, pull up the file timestamps again. Arthur, does the executive log show anyone else flagging the same directory this week?"},
			{"speaker": "", "text": "They answer at the same time — three different pieces of the same puzzle — and Maya feels the strange electric click of a team forming."},
			{"speaker": "LEO", "text": "[i](Quietly, almost to himself)[/i] You catch things no one else here notices."},
			{"speaker": "DANTE", "text": "[i](Grinning)[/i] See, this is why we keep her. Also because she is the only one who knows how the coffee machine works."},
			{"speaker": "ARTHUR", "text": "[i](A beat. Then, dry)[/i] That skill is more valuable than half of this floor."},
			{"speaker": "MAYA (NARRATION)", "text": "By ten, the audit has stalled until morning. The breach needs a machine that will not wake up until then. Which leaves us — the four of us — and a building full of quiet, and hours of nothing to do but wait."},
			{"speaker": "", "text": "Arthur loosens his tie. Dante kicks his feet up on a spare chair. Leo slides a fresh sheet of paper out of nowhere and starts to draw. For the first time all night, the crisis loosens its grip."},
			{"speaker": "MAYA (NARRATION)", "text": "The night is long. I could spend it anywhere."},
		],
		"choice": {
			"prompt": "The audit is stalled until morning. What do you do with the wait?",
			"options": [
				{"text": "Sit with Arthur and review the executive access history again.", "next": "hub", "char": "arthur", "points": 2, "sets_flag": "common_favored"},
				{"text": "Let Dante distract you with terrible whiteboard theories.", "next": "hub", "char": "dante", "points": 2, "sets_flag": "common_favored"},
				{"text": "Watch Leo draw and ask him what he keeps seeing in the files.", "next": "hub", "char": "leo", "points": 2, "sets_flag": "common_favored"},
			],
		},
	},

	"hub": {
		"title": "Chapter 3 — Free Time",
		"location": "Aether Dynamics — After Hours — Friday, 10:20 PM",
		"bgm_key": "warm",
		"bg_scene": "hub_office",
		"route": "common",
		"lines": [
			{"speaker": "", "text": "The night stretches out in front of Maya like an unclaimed hour — rare, quiet, hers."},
			{"speaker": "MAYA (NARRATION)", "text": "The breach will still be here in the morning. But so will they. And I have never actually let myself get close enough to find out what that means."},
		],
		"choice": {
			"prompt": "How do you spend the evening?",
			"options": [
				{"text": "Grab coffee with Arthur in his office.", "next": "hub_arthur", "char": "arthur", "points": 3, "sets_flag": "hub_arthur_done", "requires": {"not_flag": "hub_arthur_done"}, "locked_hint": "(already caught up with Arthur)"},
				{"text": "Raid the vending machines with Dante.", "next": "hub_dante", "char": "dante", "points": 3, "sets_flag": "hub_dante_done", "requires": {"not_flag": "hub_dante_done"}, "locked_hint": "(already caught up with Dante)"},
				{"text": "Check on Leo in the design studio.", "next": "hub_leo", "char": "leo", "points": 3, "sets_flag": "hub_leo_done", "requires": {"not_flag": "hub_leo_done"}, "locked_hint": "(already caught up with Leo)"},
				{"text": "Head to the executive floor and commit to Arthur's investigation.", "next": "arthur_ch2"},
				{"text": "Join Dante on the marketing floor to chase the paper trail.", "next": "dante_ch2"},
				{"text": "Follow Leo to the design studio and trace the watermark.", "next": "leo_ch2"},
			],
		},
	},

	"hub_arthur": {
		"title": "Interlude — Cold Espresso",
		"location": "Arthur's Executive Corner Office — 10:40 PM",
		"bgm_key": "warm",
		"bg_scene": "exec_office",
		"route": "common",
		"lines": [
			{"speaker": "", "text": "Arthur's office is enormous and almost empty — floor-to-ceiling windows, a desk like a ship's bow, not a single personal photograph anywhere."},
			{"speaker": "MAYA", "text": "[i](Setting a coffee on his desk)[/i] You take it black, right? I have never seen you drink anything else."},
			{"speaker": "ARTHUR", "text": "[i](Looking up, faintly surprised)[/i] You noticed."},
			{"speaker": "MAYA", "text": "Hard not to. You order the same thing every morning at the same minute. It is a little terrifying."},
			{"speaker": "ARTHUR", "text": "[i](A dry breath of almost-laughter)[/i] Routine is armour, Miss Lin. I built this company by being predictable to no one and punctual to a fault."},
			{"speaker": "MAYA", "text": "And who do you get to be unpredictable with?"},
			{"speaker": "", "text": "He is quiet for a long moment. The city glitters far below, indifferent."},
			{"speaker": "ARTHUR", "text": "[i](Finally)[/i] No one. It has been a very long time since anyone asked me that."},
		],
		"next": "hub",
	},

	"hub_dante": {
		"title": "Interlude — Vending Machine Vigil",
		"location": "Breakroom — 10:40 PM",
		"bgm_key": "upbeat",
		"bg_scene": "breakroom",
		"route": "common",
		"lines": [
			{"speaker": "", "text": "Dante is halfway inside the vending machine, one arm jammed past the flap, muttering threats at a bag of chips that refuses to fall."},
			{"speaker": "DANTE", "text": "[i](Muffled)[/i] Come on. Come on. I know you want to be free."},
			{"speaker": "MAYA", "text": "[i](Leaning on the counter)[/i] Have you considered just buying it like a normal person?"},
			{"speaker": "DANTE", "text": "[i](Emerging triumphant, chips in hand)[/i] Normal people do not get to say they fought a machine and won."},
			{"speaker": "MAYA", "text": "[i](Laughing)[/i] You are so weird."},
			{"speaker": "DANTE", "text": "[i](Offering her the bag, suddenly softer)[/i] Yeah. I know. But you laugh, so I figure the weird thing is working."},
			{"speaker": "", "text": "For a second the grin slips, and something tired and sincere looks out from behind it."},
			{"speaker": "DANTE", "text": "Everyone thinks I'm a joke, Maya. I just... I'd rather be the joke than the problem."},
		],
		"next": "hub",
	},

	"hub_leo": {
		"title": "Interlude — Lines in the Dark",
		"location": "Graphic Design Studio — 10:40 PM",
		"bgm_key": "warm",
		"bg_scene": "design_studio",
		"route": "common",
		"lines": [
			{"speaker": "", "text": "Leo's studio is lit only by the neon strip above his monitors and a small speaker humming something soft and instrumental."},
			{"speaker": "LEO", "text": "[i](Not looking up)[/i] If you are here to tell me to sleep, the answer is no."},
			{"speaker": "MAYA", "text": "[i](Pulling up a chair)[/i] I am here to watch you work. You always see the thing everyone else misses."},
			{"speaker": "LEO", "text": "[i](A pause. Then he turns a sketchbook half an inch toward her)[/i] It is not a talent. It is just that I look at things longer than is polite."},
			{"speaker": "MAYA", "text": "That is not a flaw either."},
			{"speaker": "LEO", "text": "[i](Quietly)[/i] You are the only person in this building who has ever said that to me."},
			{"speaker": "", "text": "He starts to draw again — but Maya catches the corner of the page before he turns it away: it is her, laughing at her desk, weeks old."},
			{"speaker": "MAYA (NARRATION)", "text": "I decide not to mention it. Not yet. But I feel it settle somewhere warm behind my ribs."},
		],
		"next": "hub",
	},

}
