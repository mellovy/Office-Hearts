extends RefCounted
## Arthur route chapters.
## Format: see scripts/story/STORY_SCHEMA.md
## Owns: arthur_ch2..arthur_ch6, arthur_end_good, arthur_end_true, arthur_end_bad

const CHAPTERS: Dictionary = {

	"arthur_ch2": {
		"title": "Chapter 2 — Cold Espresso & High Stakes",
		"location": "Arthur's Executive Corner Office — 11:00 PM",
		"bgm_key": "warm",
		"bg_scene": "exec_office",
		"route": "arthur",
		"lines": [
			{"speaker": "", "text": "The executive suite is vast and silent, floor-to-ceiling windows holding the rain-slicked city like a painting. Arthur has shed his jacket. His tie hangs loose — a crack in the armour."},
			{"speaker": "MAYA", "text": "[i](Setting a fresh espresso beside his keyboard)[/i] You have been staring at those board access logs for three hours without blinking, Mr. Pendelton."},
			{"speaker": "ARTHUR", "text": "[i](Rubbing the bridge of his nose)[/i] If the leak traces back to my credentials, the board will use it as leverage to force my resignation on Monday. They have wanted a more... pliable CEO for years."},
			{"speaker": "MAYA", "text": "That is absurd. You practically live in this office. You built Valkyrie's strategic plan from nothing."},
			{"speaker": "ARTHUR", "text": "[i](Looking up — and for once there is no wall behind his eyes)[/i] In corporate governance, loyalty is secondary to convenience. Ten years I have stood in this room alone at night, Miss Lin. Tonight the numbers finally stopped adding up."},
			{"speaker": "MAYA", "text": "[i](Quietly)[/i] You're not alone in here tonight."},
			{"speaker": "", "text": "The rain ticks against the glass. Arthur's hand rests on the desk between them, close enough that the slightest movement would close the distance."},
			{"speaker": "ARTHUR", "text": "[i](Voice lower than she has ever heard it)[/i] I have spent a decade learning to need nothing. You are making that very difficult."},
		],
		"choice": {
			"prompt": "What do you say?",
			"options": [
				{"text": "\"Then stop trying to need nothing. I'm right here.\"", "next": "arthur_ch3", "char": "arthur", "points": 5},
				{"text": "\"Let's prove your credentials were spoofed first. Everything else can wait.\"", "next": "arthur_ch3", "char": "arthur", "points": 2},
				{"text": "\"You're my boss, Mr. Pendelton. Let's keep this professional.\"", "next": "arthur_ch3", "char": "arthur", "points": -2},
			],
		},
	},

	"arthur_ch3": {
		"title": "Chapter 3 — Behind the Suit",
		"location": "Arthur's Private Executive Lounge — 1:15 AM",
		"bgm_key": "warm",
		"bg_scene": "exec_lounge",
		"route": "arthur",
		"lines": [
			{"speaker": "", "text": "Arthur sits on the leather sofa holding a box of cheap, lukewarm takeout noodles like it might bite him."},
			{"speaker": "ARTHUR", "text": "[i](Staring at the chopsticks)[/i] I must confess I have not eaten food like this in over seven years. Dietary caterers. Board dinners. A sad rotation of steamed vegetables.", "expr": "neutral"},
			{"speaker": "MAYA", "text": "[i](Laughing)[/i] Arthur, they are just sesame noodles. Here — like this."},
			{"speaker": "", "text": "She leans across and closes her hand over his to guide his grip. He goes very still. Cedarwood cologne and rain. His face is inches from hers."},
			{"speaker": "ARTHUR", "text": "[i](Low)[/i] You make everything look effortless. My entire life has been calculated risk. Around you I keep forgetting the metrics."},
			{"speaker": "MAYA", "text": "[i](Blushing)[/i] Is that a good thing, boss-man?"},
			{"speaker": "ARTHUR", "text": "[i](And then he smiles — a real one, unguarded and startlingly young)[/i] It is the most terrifyingly wonderful thing to happen to me in a decade.", "expr": "happy"},
		],
		"choice": {
			"prompt": "The moment hangs, fragile and open.",
			"options": [
				{"text": "Lean in and close the space between you.", "next": "arthur_ch4", "char": "arthur", "points": 5},
				{"text": "Squeeze his hand once, then let go and finish your noodles.", "next": "arthur_ch4", "char": "arthur", "points": 2},
				{"text": "Change the subject back to the audit.", "next": "arthur_ch4", "char": "arthur", "points": -2},
			],
		},
	},

	"arthur_ch4": {
		"title": "Chapter 4 — The Boardroom Trap",
		"location": "Executive Hallway — Monday, 7:40 AM",
		"bgm_key": "tense",
		"bg_scene": "boardroom",
		"route": "arthur",
		"lines": [
			{"speaker": "", "text": "Monday arrives gray and vicious. The audit found the payload — and found it wearing Arthur's credentials. The board meets in twenty minutes to strip his title."},
			{"speaker": "MAYA (NARRATION)", "text": "Except last night, doing a morning sweep, I found something the audit missed. A physical encrypted keycard, tucked inside a drawer that does not belong to Arthur."},
			{"speaker": "", "text": "It is VP Sterling's badge, duplicated. The access log on it matches the exact minute the payload was planted. Sterling framed Arthur — and I am holding the proof."},
			{"speaker": "MAYA (NARRATION)", "text": "I have one copy in my hand and one shot to use it. Sterling's security detail is pacing the main hallway, and the board doors are closing."},
			{"speaker": "", "text": "Down the corridor, Arthur catches her eye. He does not know what she has found. But he trusts her enough not to ask."},
		],
		"minigame": {"id": "pursuit_chase", "difficulty": 0.55, "prompt": "Slip the keycard past Sterling's night guard before the boardroom doors close."},
		"choice": {
			"prompt": "What do you do with the keycard?",
			"options": [
				{"text": "Photograph it and cross-reference the access log before anyone can dismiss it.", "next": "arthur_ch5", "char": "arthur", "points": 4},
				{"text": "Pocket it and walk straight into the boardroom to present it live.", "next": "arthur_ch5", "char": "arthur", "points": 4},
				{"text": "Leave it where it is. It could be a plant to bait you.", "next": "arthur_ch5", "char": "arthur", "points": 0},
			],
		},
	},

	"arthur_ch5": {
		"title": "Chapter 5 — The Night Before the Storm",
		"location": "Arthur's Office — Sunday Midnight",
		"bgm_key": "warm",
		"bg_scene": "balcony_night",
		"route": "arthur",
		"lines": [
			{"speaker": "", "text": "The night before the board convenes, Arthur and Maya stand out on the executive balcony above the sleeping city."},
			{"speaker": "ARTHUR", "text": "[i](Watching the skyline)[/i] If this goes badly tomorrow, I lose the company I built. If it goes well, I keep a job that has been eating my life one year at a time."},
			{"speaker": "MAYA", "text": "And which one scares you more?"},
			{"speaker": "ARTHUR", "text": "[i](Turning to her — no armour at all now)[/i] Neither. What scares me is that you might be the only thing I want to keep, and I have no plan for that.", "expr": "blush"},
			{"speaker": "MAYA (NARRATION)", "text": "The wind is cold. He shrugs off his coat before I can argue and wraps it around my shoulders, hands resting there a moment too long."},
			{"speaker": "ARTHUR", "text": "[i](Quietly)[/i] Whatever happens in that room tomorrow — I would rather lose the board than lie to you tonight."},
		],
		"choice": {
			"prompt": "How do you answer him?",
			"options": [
				{"text": "\"Then don't lose either. We go in together and we win.\"", "next": "arthur_ch6", "char": "arthur", "points": 4},
				{"text": "\"I'll be standing behind you no matter what the board decides.\"", "next": "arthur_ch6", "char": "arthur", "points": 2},
			],
		},
	},

	"arthur_ch6": {
		"title": "Chapter 6 — The Boardroom",
		"location": "Boardroom — Monday, 8:00 AM",
		"bgm_key": "tense",
		"bg_scene": "boardroom",
		"route": "arthur",
		"lines": [
			{"speaker": "", "text": "The board sits in a long row behind polished mahogany. Sterling is already speaking, calm and rehearsed, laying out the case against Arthur with the confidence of a man who has practiced."},
			{"speaker": "STERLING", "text": "The credentials are indisputable. I move that we accept the CEO's resignation effective immediately."},
			{"speaker": "", "text": "Arthur does not flinch. Maya's hand closes around the evidence in her pocket. The room turns, waiting."},
			{"speaker": "MAYA (NARRATION)", "text": "This is it. Everything we found, everything he risked, everything I feel — all of it comes down to the next ten seconds."},
		],
		"minigame": {"id": "boardroom_rebuttal", "success_flag": "arthur_evidence", "difficulty": 0.6, "prompt": "Hold the boardroom with the evidence you gathered."},
		"choice": {
			"prompt": "The board is waiting. What do you do?",
			"options": [
				{"text": "Stand, and lay out the evidence with every cross-reference you have.", "next": "arthur_end_good", "char": "arthur", "points": 2, "requires": {"flag": "arthur_evidence", "char": "arthur", "min": 12}},
				{"text": "Stand, name Sterling's duplicate keycard, and tell the board exactly what you and Arthur became here.", "next": "arthur_end_true", "char": "arthur", "points": 2, "requires": {"flag": "arthur_evidence", "char": "arthur", "min": 22}},
				{"text": "Stay seated. Without irrefutable proof, speaking up would only burn you both.", "next": "arthur_end_bad"},
			],
		},
	},

	"arthur_end_good": {
		"title": "Ending — Executive Partnership",
		"location": "\"Executive Partnership\" — Good Ending",
		"bgm_key": "warm",
		"bg_scene": "balcony_night",
		"route": "arthur",
		"ending": "good",
		"ending_name": "Executive Partnership",
		"ending_desc": "Maya clears Arthur's name before the board. He keeps the company, and finally admits he doesn't want to run it alone.",
		"lines": [
			{"speaker": "MAYA", "text": "Vice President Sterling. This duplicate token matches your private office access log at 11:14 PM on Thursday. The same minute the payload went live."},
			{"speaker": "STERLING", "text": "[i](Chair scraping back)[/i] This is unverified slander from an associate!"},
			{"speaker": "ARTHUR", "text": "[i](Standing, radiating quiet executive power)[/i] It is verified by the audit log I am submitting to federal investigators now. Security — escort him out."},
			{"speaker": "", "text": "The board votes unanimously to retain Arthur. The room empties. He finds her in the hallway, and for the first time all week, he is not a CEO at all."},
			{"speaker": "ARTHUR", "text": "[i](Taking her hand, careful and certain)[/i] You saved my legacy today. I find I care far less about that than I expected."},
			{"speaker": "MAYA", "text": "And what do you care about?"},
			{"speaker": "ARTHUR", "text": "[i](A slow, real smile)[/i] Dinner. Tomorrow. No board, no audit, no noodles that intimidate me. Just you."},
			{"speaker": "", "text": "★ END — Executive Partnership ★"},
		],
		"next": "game_end",
	},

	"arthur_end_true": {
		"title": "Ending — Heart & Empire",
		"location": "\"Heart & Empire\" — True Ending",
		"bgm_key": "warm",
		"bg_scene": "roof_morning",
		"route": "arthur",
		"ending": "true",
		"ending_name": "Heart & Empire",
		"ending_desc": "Maya doesn't just clear Arthur's name — she tells the board who he became. He chooses her over the board seat, and they build something that belongs to both of them.",
		"lines": [
			{"speaker": "MAYA", "text": "Sterling didn't just steal files. He tried to erase the only person in this building who ever worked harder than his title asked. That is the real fraud in this room."},
			{"speaker": "", "text": "She lays the keycard on the table. Then the cross-referenced logs. Then the email timestamps. One by one, the board's certainty collapses into silence."},
			{"speaker": "ARTHUR", "text": "[i](Standing beside her — not in front of her)[/i] For the record, I am not resigning. But I am changing the terms of this job. Beginning with the part where I stop pretending I have nothing to lose."},
			{"speaker": "", "text": "Sterling is escorted out. The board, chastened, offers Arthur anything he wants. He asks for one thing they did not expect: shorter weeks."},
			{"speaker": "ARTHUR", "text": "[i](Later, on the roof as the morning breaks gold over the city)[/i] I have spent ten years earning this skyline. I would trade the whole view for one more morning like this."},
			{"speaker": "MAYA", "text": "[i](Leaning into him)[/i] Careful. I might hold you to that."},
			{"speaker": "ARTHUR", "text": "[i](Kissing her as the sun clears the towers)[/i] Please do. I am finally, catastrophically, in the mood to be held.", "expr": "blush"},
			{"speaker": "", "text": "★ TRUE END — Heart & Empire ★"},
		],
		"next": "game_end",
	},

	"arthur_end_bad": {
		"title": "Ending — Silent Departure",
		"location": "\"Silent Departure\" — Bittersweet Ending",
		"bgm_key": "sad",
		"bg_scene": "office_lobby_night",
		"route": "arthur",
		"ending": "bad",
		"ending_name": "Silent Departure",
		"ending_desc": "Without proof, the board takes Arthur's title. He leaves at dawn, and Maya watches the elevator doors close on everything unsaid.",
		"lines": [
			{"speaker": "", "text": "Maya hesitates. By the time the words are ready, Sterling's legal team has already buried the evidence review. The board forces Arthur to step down before lunch."},
			{"speaker": "ARTHUR", "text": "[i](Boxing his office in silence)[/i] You did what you could, Maya. Speed was everything. I should have taught you that.", "expr": "sad"},
			{"speaker": "MAYA", "text": "Arthur, please — don't go."},
			{"speaker": "ARTHUR", "text": "[i](A distant, tired smile as the elevator doors slide shut)[/i] Goodbye, Miss Lin. Take care of yourself. You were the best thing about the last ten years.", "expr": "sad"},
			{"speaker": "", "text": "✦ END — Silent Departure ✦"},
		],
		"next": "game_end",
	},

}
