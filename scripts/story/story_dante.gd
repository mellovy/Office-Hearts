extends RefCounted
## Dante route chapters.
## Format: see scripts/story/STORY_SCHEMA.md
## Owns: dante_ch2..dante_ch6, dante_end_good, dante_end_true, dante_end_bad

const CHAPTERS: Dictionary = {

	"dante_ch2": {
		"title": "Chapter 2 — Chaos, Coffee & Accusations",
		"location": "Marketing Breakroom & Open Cubicles — 11:20 PM",
		"bgm_key": "upbeat",
		"bg_scene": "breakroom",
		"route": "dante",
		"lines": [
			{"speaker": "", "text": "Dante paces the breakroom waving a whiteboard marker while Maya nurses a sugar-loaded energy drink that is technically a health hazard."},
			{"speaker": "DANTE", "text": "Maya! Look at this conspiracy board! If you connect the printer logs from Tuesday to the missing glazed donuts from Wednesday—"},
			{"speaker": "MAYA", "text": "Dante, you drew a giant squirrel."},
			{"speaker": "DANTE", "text": "[i](Pointing the marker at her)[/i] A corporate spy squirrel, Maya! Who else moves between floors without a badge?!"},
			{"speaker": "MAYA", "text": "[i](Laughing so hard she nearly drops the can)[/i] You are the only manager in this company who can turn corporate espionage into a comedy sketch."},
			{"speaker": "DANTE", "text": "[i](He stops pacing. The grin fades.)[/i] ...Yeah. Everyone knows I'm the disorganized one. So when the leak showed up on files I touched, it took HR about four minutes to decide I was the guy.", "expr": "sad"},
			{"speaker": "MAYA", "text": "[i](Setting the can down)[/i] Dante. You did not do this."},
			{"speaker": "DANTE", "text": "[i](Quiet, unlike him)[/i] I know I didn't. I just — I was scared you'd think I did. That everyone would finally be right about me."},
		],
		"minigame": {"id": "latte_timing", "difficulty": 0.35, "prompt": "Dial in Dante's chaotic coffee order before the machine wins."},
		"choice": {
			"prompt": "How do you answer?",
			"options": [
				{"text": "\"You're the one who protects this team. Now let us protect you.\"", "next": "dante_ch3", "char": "dante", "points": 5},
				{"text": "\"Then let's find whoever really did it and shove it in HR's face.\"", "next": "dante_ch3", "char": "dante", "points": 4},
				{"text": "\"I mean... you did leave your password on a sticky note.\"", "next": "dante_ch3", "char": "dante", "points": -2},
			],
		},
	},

	"dante_ch3": {
		"title": "Chapter 3 — The Midnight Break-In",
		"location": "Marketing Archive Room — 1:00 AM",
		"bgm_key": "mystery",
		"bg_scene": "archive",
		"route": "dante",
		"lines": [
			{"speaker": "", "text": "Maya and Dante crouch behind a row of filing cabinets, sharing a single flashlight that Dante keeps accidentally pointing at his own chin."},
			{"speaker": "DANTE", "text": "[i](Whispering loudly)[/i] Stealth rule number one: if security comes, we are practicing an emergency tango routine."},
			{"speaker": "MAYA", "text": "[i](Snickering)[/i] That is the worst cover story in the history of cover stories."},
			{"speaker": "DANTE", "text": "[i](Grinning, pulling her back behind a cabinet as a sensor sweeps past)[/i] Maybe. But look how well it is working.", "expr": "happy"},
			{"speaker": "", "text": "His hand stays at the small of her back a beat longer than the moment requires. The flashlight catches his face, and the usual joke is nowhere on it."},
			{"speaker": "DANTE", "text": "Hey. Before we find the real culprit and I go back to being the office idiot... I need you to know I've been in love with your laugh since the day you joined my team.", "expr": "blush"},
			{"speaker": "MAYA", "text": "[i](Breath catching)[/i] Dante..."},
			{"speaker": "DANTE", "text": "[i](Suddenly terrified of his own sentence)[/i] You don't have to say anything! I just — okay, that's a lie, please say something."},
		],
		"minigame": {"id": "evidence_hunt", "success_flag": "dante_evidence", "difficulty": 0.5, "prompt": "Sweep the archive for the real evidence trail."},
		"choice": {
			"prompt": "The flashlight trembles between you.",
			"options": [
				{"text": "\"Then stop talking and prove it.\"", "next": "dante_ch4", "char": "dante", "points": 5},
				{"text": "\"Win first. Then take me to dinner and say it again.\"", "next": "dante_ch4", "char": "dante", "points": 4},
				{"text": "\"Dante... we should focus on the files.\"", "next": "dante_ch4", "char": "dante", "points": 0},
			],
		},
	},

	"dante_ch4": {
		"title": "Chapter 4 — The Sticky-Note Standoff",
		"location": "Central IT Hub — Monday, 7:30 AM",
		"bgm_key": "tense",
		"bg_scene": "it_hub",
		"route": "dante",
		"lines": [
			{"speaker": "", "text": "The server logs finally give it up: the corrupt metadata was uploaded with Dante's old password — pulled straight off a sticky note he stuck to his monitor months ago and forgot."},
			{"speaker": "MAYA (NARRATION)", "text": "Only one person ever walked past that desk without being questioned: Assistant Manager Sterling, who has been quietly managing the very audit that is about to end Dante's career."},
			{"speaker": "", "text": "Maya holds the printed evidence trail. Dante is upstairs in HR, four minutes into an interrogation that is not going his way."},
			{"speaker": "MAYA (NARRATION)", "text": "I can prove he is innocent. But the only server fast enough to broadcast it live reboots during the morning showcase."},
		],
		"minigame": {"id": "password_deduction", "success_flag": "dante_evidence", "difficulty": 0.55, "prompt": "Crack the leftover password before the audit closes in."},
		"choice": {
			"prompt": "How do you clear his name?",
			"options": [
				{"text": "Copy the metadata trail to the showcase presentation, so the whole floor sees it live.", "next": "dante_ch5", "char": "dante", "points": 4},
				{"text": "Back the trail up to a second drive and walk it into HR yourself.", "next": "dante_ch5", "char": "dante", "points": 4},
				{"text": "Wait for the audit to reach the truth on its own. Rushing could backfire.", "next": "dante_ch5", "char": "dante", "points": 0},
			],
		},
	},

	"dante_ch5": {
		"title": "Chapter 5 — Vending Machine Vigil",
		"location": "Breakroom — Sunday, 11:00 PM",
		"bgm_key": "warm",
		"bg_scene": "breakroom",
		"route": "dante",
		"lines": [
			{"speaker": "", "text": "The night before the showcase, Dante and Maya sit on the breakroom floor with a pile of snacks and the vending machine humming beside them like a third friend."},
			{"speaker": "DANTE", "text": "[i](Staring at the ceiling)[/i] If this works tomorrow, I'm keeping my job. If it doesn't, I'm gone by Friday. Either way — I keep thinking about what I almost didn't say in that archive room.", "expr": "sad"},
			{"speaker": "MAYA", "text": "You said plenty."},
			{"speaker": "DANTE", "text": "[i](Turning to her, no joke anywhere in his face)[/i] I said it because I was scared. But I meant it because it's true. Those are different things."},
			{"speaker": "", "text": "He holds up a bright pink sticky note between two fingers, grinning despite himself."},
			{"speaker": "DANTE", "text": "I was going to write something clever on this to give you tomorrow. Turns out everything I come up with just says the same thing."},
			{"speaker": "MAYA (NARRATION)", "text": "He hands me the note. It is blank. Somehow that is the most honest thing anyone has given me in a year."},
		],
		"choice": {
			"prompt": "What do you do with the blank note?",
			"options": [
				{"text": "Write your own number on it and stick it to his forehead.", "next": "dante_ch6", "char": "dante", "points": 4},
				{"text": "Fold it carefully into your pocket and tell him to keep it.", "next": "dante_ch6", "char": "dante", "points": 2},
			],
		},
	},

	"dante_ch6": {
		"title": "Chapter 6 — The Morning Showcase",
		"location": "Central IT Hub & Main Lobby — Monday, 8:30 AM",
		"bgm_key": "tense",
		"bg_scene": "lobby_day",
		"route": "dante",
		"lines": [
			{"speaker": "", "text": "The lobby fills for the morning showcase, executives front and center. Dante is still upstairs with HR. Sterling stands at the podium, calm as ever, ready to name a culprit."},
			{"speaker": "STERLING", "text": "The audit has conclusively identified the employee responsible for the Valkyrie leak."},
			{"speaker": "MAYA (NARRATION)", "text": "My hand is on the keyboard. The presentation is queued. Everything I found — everything Dante almost lost — is one keystroke away."},
		],
		"choice": {
			"prompt": "Sterling is about to name Dante. What do you do?",
			"options": [
				{"text": "Hit enter and put the real metadata trail on every screen in the building.", "next": "dante_end_good", "char": "dante", "points": 2, "requires": {"flag": "dante_evidence", "char": "dante", "min": 12}},
				{"text": "Take the mic yourself and read Sterling's login history aloud, line by line.", "next": "dante_end_true", "char": "dante", "points": 2, "requires": {"flag": "dante_evidence", "char": "dante", "min": 22}},
				{"text": "Stay your hand. Without an airtight trail, you'd only drag yourself down with him.", "next": "dante_end_bad"},
			],
		},
	},

	"dante_end_good": {
		"title": "Ending — Partners in Chaos",
		"location": "\"Partners in Chaos\" — Good Ending",
		"bgm_key": "upbeat",
		"bg_scene": "lobby_day",
		"route": "dante",
		"ending": "good",
		"ending_name": "Partners in Chaos",
		"ending_desc": "The lobby screens expose Sterling, and Dante bursts out of HR to sweep Maya off her feet in front of the whole cheering floor.",
		"lines": [
			{"speaker": "", "text": "Every screen in the building flashes Sterling's own login history, timestamped and undeniable. The lobby erupts."},
			{"speaker": "DANTE", "text": "[i](Bursting out of HR, arms wide)[/i] MAYA! YOU BEAUTIFUL DIGITAL WIZARD!", "expr": "happy"},
			{"speaker": "", "text": "He lifts her off her feet and spins her in front of the entire marketing department, which has absolutely no intention of letting him live it down."},
			{"speaker": "MAYA", "text": "[i](Laughing)[/i] Dante! Put me down, everyone is watching!"},
			{"speaker": "DANTE", "text": "[i](Slapping a neon-pink sticky note onto her forehead)[/i] Official Managerial Directive: dinner with me every Friday, forever, no exceptions."},
			{"speaker": "MAYA", "text": "[i](Peeling it off, smiling)[/i] I accept those terms, boss."},
			{"speaker": "", "text": "★ END — Partners in Chaos ★"},
		],
		"next": "game_end",
	},

	"dante_end_true": {
		"title": "Ending — Every Friday",
		"location": "\"Every Friday\" — True Ending",
		"bgm_key": "upbeat",
		"bg_scene": "roof_morning",
		"route": "dante",
		"ending": "true",
		"ending_name": "Every Friday",
		"ending_desc": "Maya takes the mic and clears Dante herself, then follows him to the roof, where the joke finally lands exactly where it was always aimed.",
		"lines": [
			{"speaker": "MAYA", "text": "[i](Into the mic)[/i] Sterling's own login history uploaded that metadata. Dante's password was stolen off a sticky note — one Sterling walked past every single day."},
			{"speaker": "", "text": "The floor goes silent. Then furious. Sterling's calm shatters as security closes in, and the board starts asking very different questions."},
			{"speaker": "DANTE", "text": "[i](Finding her afterward on the roof, breathless)[/i] You didn't just save my job. You stood up in front of everyone and said my name like it was worth defending."},
			{"speaker": "MAYA", "text": "It is."},
			{"speaker": "DANTE", "text": "[i](Pulling out the sticky note from the breakroom — now with something written on it)[/i] So I finally wrote the clever thing. Want to hear it?"},
			{"speaker": "MAYA", "text": "[i](Leaning in)[/i] I have a feeling it's going to be terrible."},
			{"speaker": "DANTE", "text": "[i](Kissing her, laughing, holding on)[/i] It's the worst. It's also every Friday for the rest of our lives. Deal?", "expr": "blush"},
			{"speaker": "", "text": "★ TRUE END — Every Friday ★"},
		],
		"next": "game_end",
	},

	"dante_end_bad": {
		"title": "Ending — Red Tape Separation",
		"location": "\"Red Tape Separation\" — Bittersweet Ending",
		"bgm_key": "sad",
		"bg_scene": "branch_office",
		"route": "dante",
		"ending": "bad",
		"ending_name": "Red Tape Separation",
		"ending_desc": "Hesitation lets the frame-job stick. Dante is transferred and gone by Monday, leaving Maya at a sterile desk in a distant branch.",
		"lines": [
			{"speaker": "", "text": "The moment passes. HR's process grinds on, and without an airtight trail the company takes the path of least scandal: Dante's contract is terminated, and Maya is quietly transferred."},
			{"speaker": "MAYA (NARRATION)", "text": "Dante packed his desk on Saturday morning. By Monday, the chair was empty and someone had already claimed his mug."},
			{"speaker": "", "text": "Maya sits at a quiet, sterile desk in a suburban branch office, a single yellow sticky note still stuck to her monitor."},
			{"speaker": "MAYA", "text": "[i](Tracing its edge)[/i] I should have taken the bold choice."},
			{"speaker": "", "text": "✦ END — Red Tape Separation ✦"},
		],
		"next": "game_end",
	},

}
