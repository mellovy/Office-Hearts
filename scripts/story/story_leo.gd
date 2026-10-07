extends RefCounted
## Leo route chapters.
## Format: see scripts/story/STORY_SCHEMA.md
## Owns: leo_ch2..leo_ch6, leo_end_good, leo_end_true, leo_end_bad

const CHAPTERS: Dictionary = {

	"leo_ch2": {
		"title": "Chapter 2 — Neon Lights & Silent Signals",
		"location": "Graphic Design Studio — 11:30 PM",
		"bgm_key": "warm",
		"bg_scene": "design_studio",
		"route": "leo",
		"lines": [
			{"speaker": "", "text": "The studio is dark except for the neon strip above Leo's monitors and a small speaker playing something soft and instrumental. Maya leans over his shoulder, close enough to catch mint and charcoal."},
			{"speaker": "LEO", "text": "[i](Typing fast)[/i] Look at the colour-channel metadata. Whoever leaked this did not just export the graphics — they hid steganographic code inside our campaign watermarks. Invisible to the eye. Screaming in the data."},
			{"speaker": "MAYA", "text": "Wait. That encryption key format — that is the Lead Architect's custom signature."},
			{"speaker": "LEO", "text": "[i](Turning his head, dark eyes catching hers)[/i] Sharp eye. You catch things no one else in this building notices."},
			{"speaker": "MAYA", "text": "[i](Blushing, straightening up)[/i] I just... pay attention when you explain things."},
			{"speaker": "LEO", "text": "[i](Leaning back, twirling his stylus)[/i] You're the only reason I haven't handed in my notice, you know. This office is all noise. Working beside you is the one place it goes quiet."},
			{"speaker": "MAYA (NARRATION)", "text": "He says it like a fact, not a confession. Somehow that makes it land harder."},
		],
		"choice": {
			"prompt": "How do you respond?",
			"options": [
				{"text": "\"Then stay. Quiet is better with two people in it.\"", "next": "leo_ch3", "char": "leo", "points": 5},
				{"text": "\"Good. Because I'm not done learning how you see the world.\"", "next": "leo_ch3", "char": "leo", "points": 4},
				{"text": "\"It's just a job, Leo. Don't read into it.\"", "next": "leo_ch3", "char": "leo", "points": -2},
			],
		},
	},

	"leo_ch3": {
		"title": "Chapter 3 — The Secret Sketchbook",
		"location": "Roof Garden — 1:00 AM",
		"bgm_key": "warm",
		"bg_scene": "roof_garden",
		"route": "leo",
		"lines": [
			{"speaker": "", "text": "They take a breather on the terrace above the sleeping city, rain glinting on the railing, the night finally theirs."},
			{"speaker": "LEO", "text": "[i](Pulling a worn leather sketchbook from his coat)[/i] I was not going to show anyone this. Ever. I am aware how it looks."},
			{"speaker": "MAYA", "text": "[i](Opening the cover)[/i] Leo... these are all of me."},
			{"speaker": "", "text": "Page after page: Maya with her coffee, Maya laughing at her desk, Maya frowning at a monitor, Maya watching rain through a window."},
			{"speaker": "LEO", "text": "[i](Looking away, rubbing his neck)[/i] Six months. I told myself I was just an observer. But I kept drawing the one thing in this building that made me want to stay.", "expr": "blush"},
			{"speaker": "MAYA", "text": "[i](Heart pounding, taking his hand)[/i] You are not just an observer to me. You are the best part of coming to work."},
			{"speaker": "", "text": "His hand, which is always steady on a stylus, is not steady now."},
		],
		"choice": {
			"prompt": "He is waiting for you to decide what this is.",
			"options": [
				{"text": "Ask him to draw you right here, right now — and stay close while he does.", "next": "leo_ch4", "char": "leo", "points": 5},
				{"text": "Tell him you want to keep the sketchbook, and the secret with it.", "next": "leo_ch4", "char": "leo", "points": 4},
				{"text": "Close the book gently and hand it back.", "next": "leo_ch4", "char": "leo", "points": 0},
			],
		},
	},

	"leo_ch4": {
		"title": "Chapter 4 — The Watermark Trap",
		"location": "Design Studio Server Room — Monday, 7:15 AM",
		"bgm_key": "tense",
		"bg_scene": "server_room",
		"route": "leo",
		"lines": [
			{"speaker": "", "text": "Eighteen hours of decoding later, the render resolves: the leaked files carry the Lead Architect's direct IP tag, routed through a staging server hidden behind the design department's own watermark library."},
			{"speaker": "MAYA (NARRATION)", "text": "We have him. But the discovery is fragile — the evidence only exists on this machine, and the morning executive showcase starts in forty-five minutes."},
			{"speaker": "LEO", "text": "[i](Backing up the decoded map to a second drive without being asked)[/i] I put it on two drives and a private server you've never heard of. I don't trust anything that only exists once."},
			{"speaker": "MAYA", "text": "You think he knows we're onto him?"},
			{"speaker": "LEO", "text": "[i](A thin, cold smile)[/i] I think he is about to find out exactly how long I look at things."},
		],
		"minigame": {"id": "watermark_forensics", "success_flag": "leo_evidence", "difficulty": 0.55, "prompt": "Decode the watermark to expose the real author."},
		"choice": {
			"prompt": "How do you use the decoded evidence?",
			"options": [
				{"text": "Queue it for the executive showcase broadcast so the whole company sees the truth.", "next": "leo_ch5", "char": "leo", "points": 4},
				{"text": "Make three copies and leave one with the ethics hotline as insurance.", "next": "leo_ch5", "char": "leo", "points": 4},
				{"text": "Sit on it. Getting this wrong would end both your careers.", "next": "leo_ch5", "char": "leo", "points": 0},
			],
		},
	},

	"leo_ch5": {
		"title": "Chapter 5 — Before the Canvas",
		"location": "Design Studio — Sunday, Midnight",
		"bgm_key": "warm",
		"bg_scene": "design_studio",
		"route": "leo",
		"lines": [
			{"speaker": "", "text": "The night before the showcase, the studio is lit by neon and the blue glow of a screen full of evidence. Leo has pushed his chair aside and is working at a small easel instead."},
			{"speaker": "MAYA", "text": "[i](Watching over his shoulder)[/i] You're drawing? Tomorrow might decide both our careers and you're drawing?"},
			{"speaker": "LEO", "text": "[i](Not looking up)[/i] That is exactly why. When everything is loud, this is how I stay honest."},
			{"speaker": "", "text": "The canvas resolves into Maya again — this time standing in a doorway, turning back, half-lit by neon."},
			{"speaker": "LEO", "text": "[i](Quietly)[/i] I have spent my whole life drawing the thing I wanted and never telling it. I am trying not to do that anymore.", "expr": "sad"},
			{"speaker": "MAYA (NARRATION)", "text": "He offers me the brush. The canvas is finished except for one empty corner — small, deliberate, plainly left for me."},
		],
		"choice": {
			"prompt": "There is one corner of the canvas left.",
			"options": [
				{"text": "Add your own mark — then tell him exactly what he means to you.", "next": "leo_ch6", "char": "leo", "points": 4},
				{"text": "Tell him you would rather he paint that part tomorrow, after you both win.", "next": "leo_ch6", "char": "leo", "points": 2},
			],
		},
	},

	"leo_ch6": {
		"title": "Chapter 6 — The Grand Canvas",
		"location": "Main Lobby & Design Studio — Monday, 8:15 AM",
		"bgm_key": "tense",
		"bg_scene": "lobby_day",
		"route": "leo",
		"lines": [
			{"speaker": "", "text": "The executive showcase is in full swing when the monitors stutter. The Lead Architect stands at the podium, mid-sentence, about to be praised for the very launch he sabotaged."},
			{"speaker": "MAYA (NARRATION)", "text": "Leo's hand hovers over the override. The decoded watermark map is loaded. One keystroke, and the room learns what their star architect really built."},
		],
		"minigame": {"id": "surveillance_dodge", "success_flag": "leo_evidence", "difficulty": 0.6, "prompt": "Slip the evidence past the showcase cameras."},
		"choice": {
			"prompt": "The Architect is about to be applauded.",
			"options": [
				{"text": "Give Leo the nod. Override the showcase and project the decoded map.", "next": "leo_end_good", "char": "leo", "points": 2, "requires": {"flag": "leo_evidence", "char": "leo", "min": 12}},
				{"text": "Take the podium yourself and walk the room through every hidden layer, with Leo beside you.", "next": "leo_end_true", "char": "leo", "points": 2, "requires": {"flag": "leo_evidence", "char": "leo", "min": 22}},
				{"text": "Let it go. The machine is too big, and you'd both be crushed speaking against it.", "next": "leo_end_bad"},
			],
		},
	},

	"leo_end_good": {
		"title": "Ending — Designed Together",
		"location": "\"Designed Together\" — Good Ending",
		"bgm_key": "warm",
		"bg_scene": "lobby_day",
		"route": "leo",
		"ending": "good",
		"ending_name": "Designed Together",
		"ending_desc": "Leo hijacks the executive showcase and exposes the corrupt architect, then leads Maya away from the chaos to the roof garden.",
		"lines": [
			{"speaker": "", "text": "The lobby displays snap to the decoded malware map. The Architect's own IP trail scrolls across every screen in the building."},
			{"speaker": "LEO", "text": "[i](Hands in his coat pockets, deadpan)[/i] And that is how you trace digital malware, folks. Have a great Monday."},
			{"speaker": "", "text": "The lobby erupts. Leo takes Maya's hand and walks her out of the noise, up to the roof, into the morning."},
			{"speaker": "MAYA", "text": "[i](Gasping for breath, grinning)[/i] Leo! You just hijacked the entire executive showcase!"},
			{"speaker": "LEO", "text": "[i](Pulling her close, forehead to hers)[/i] I do not care about executives. I care about this canvas. And you."},
			{"speaker": "MAYA", "text": "What happens now?"},
			{"speaker": "LEO", "text": "[i](Kissing her under the morning sun)[/i] Now we decide what we want to make next. Together.", "expr": "blush"},
			{"speaker": "", "text": "★ END — Designed Together ★"},
		],
		"next": "game_end",
	},

	"leo_end_true": {
		"title": "Ending — Our Own Studio",
		"location": "\"Our Own Studio\" — True Ending",
		"bgm_key": "warm",
		"bg_scene": "roof_morning",
		"route": "leo",
		"ending": "true",
		"ending_name": "Our Own Studio",
		"ending_desc": "Maya and Leo expose the Architect side by side, then walk out of Aether Dynamics for good to build a studio that belongs to both of them.",
		"lines": [
			{"speaker": "MAYA", "text": "[i](At the podium, calm and clear)[/i] Every pixel of this launch was signed. Every layer carried a watermark. We just read the ones you were never supposed to see."},
			{"speaker": "LEO", "text": "[i](Standing beside her, adding quietly)[/i] The Architect did not steal our work. He signed it. Twice."},
			{"speaker": "", "text": "The room turns, slowly, away from the Architect and toward the truth on every screen. Security is already moving."},
			{"speaker": "MAYA (NARRATION)", "text": "Afterward, on the roof, Leo does not say anything for a long time. He does not need to."},
			{"speaker": "LEO", "text": "[i](Finally, offering her the finished canvas — the corner she painted now part of it)[/i] I quit this morning. So did you, technically — you just haven't told them yet."},
			{"speaker": "MAYA", "text": "[i](Laughing)[/i] Presumptuous."},
			{"speaker": "LEO", "text": "[i](Pulling her in, quiet and certain)[/i] Say yes anyway. Let's build a studio where nobody's work ever gets signed by someone else again. Just ours."},
			{"speaker": "", "text": "★ TRUE END — Our Own Studio ★"},
		],
		"next": "game_end",
	},

	"leo_end_bad": {
		"title": "Ending — Faded Sketch",
		"location": "\"Faded Sketch\" — Bittersweet Ending",
		"bgm_key": "sad",
		"bg_scene": "cubicle_empty",
		"route": "leo",
		"ending": "bad",
		"ending_name": "Faded Sketch",
		"ending_desc": "They stay silent and the Architect keeps his stage. Leo resigns that night, leaving Maya a single charcoal drawing and a note.",
		"lines": [
			{"speaker": "", "text": "They stay silent. The Architect receives his applause. By evening, the evidence on the second drive is quietly overwritten by routine backups nobody will ever question."},
			{"speaker": "MAYA (NARRATION)", "text": "Leo submitted his resignation that night. On Monday his cubicle was empty, the monitors unplugged, the walls stripped of pinned sketches."},
			{"speaker": "", "text": "On Maya's desk, a single charcoal drawing: her sitting alone by a window, rain on the glass. Beneath it, a note in careful handwriting."},
			{"speaker": "LEO", "text": "[i]\"Keep looking at things longer than is polite. It was never a flaw.\"[/i]", "expr": "sad"},
			{"speaker": "MAYA", "text": "[i](Tears falling on the paper)[/i] I let him walk away."},
			{"speaker": "", "text": "✦ END — Faded Sketch ✦"},
		],
		"next": "game_end",
	},

}
