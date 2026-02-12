/*Execution Instructions:
1, Turn on the Server
2. Evaluate "SynthDef Declaration"
3. Evaluate "Program"
4. In order to shut down the program, please close the window

NB: The program comes with already set values for Filter and Amplfier. In order to modify them, please rotate knobs.
In order to generate sound, choose a waveform from one oscillator, turn on oscillator volume and then turn on general volume
*/


//"SynthDef Declaration"
(
//Oscillator
SynthDef(\osc, { arg outBus, freq = 440, saw_on = 0, pulse_on = 0, pulse2_on = 0, pulse3_on = 0, tri_on = 0, gain = 0;
	//Oscillators with different waveforms declaration:
	var tri = LFTri.ar(freq:freq, mul:gain*tri_on);
	var saw = LFSaw.ar(freq:freq, mul:gain*saw_on);
	var pulse = Pulse.ar(freq:freq, mul:gain*pulse_on);
	var pulse2 = Pulse.ar(freq:freq, width: 0.7, mul:gain*pulse2_on);
	var pulse3 = Pulse.ar(freq:freq, width: 0.9, mul:gain*pulse3_on);
	var mix = Mix([tri, saw, pulse, pulse2, pulse3]); //Oscillators mix
	Out.ar(outBus, mix); //sending resulting signal to the outBus
}).add;

//Noise Generator
SynthDef(\noisegenerator, { arg gain = 0, outBus;
	var noise = WhiteNoise.ar(mul:gain); //Creating noise
	Out.ar(outBus, noise); //sending noise to outBus
}).add;

//Mixer
SynthDef(\a, {
	 arg vol = 1, cutoff = 500, reso, amp_gate = 0, amp_env_atck = 0.02, amp_env_dcy = 1, amp_env_sus = 0.7, amp_env_curve = -4, inBus, fil_env_atck=0, fil_env_dcy=5, fil_env_sus=0, contour = 1000, fil_gate = 0;

	//Amplifier Envelope Path Declaration
	var amp_env_path = Env.adsr(attackTime:amp_env_atck, decayTime:amp_env_dcy, sustainLevel:amp_env_sus, releaseTime:0.05, curve:amp_env_curve);
	//Amplifier envelope generation
	var amp_env = EnvGen.ar(amp_env_path, gate:amp_gate);

	//Filter Envelope Path Declaration
	var fil_env_path = Env.adsr(attackTime:fil_env_atck, decayTime:fil_env_dcy, sustainLevel:fil_env_sus, releaseTime:0.05, curve:0);
	//Filter envelope generation
	var env_cutoff = EnvGen.ar(fil_env_path, gate:fil_gate);

	//Filter Declaration
	var filter = MoogFF.ar(In.ar(inBus, 1), freq:(cutoff+(contour*env_cutoff)).clip(20, 20000), gain:reso, mul:vol*amp_env);

	//Sending resulting signal to the speakers
	Out.ar([0, 1], filter!2); // !2 duplicates mono to stereo
}).add;
)

//Program
(
//Variables Declarations
//Keyboard GUI variables
var heigth, width, keys_number, base, keyboard;

//Gui Labels variables
var noise_gen_label, filter_cutoff_label, filter_emphasis_label, filter_contour_label, filter_attack_label, filter_decay_label, filter_sustain_label, env_attack_label, env_decay_label, env_sustain_label, arp_menu_label, arp_rate_label, arp_start_label;

/*Creating bus and synths and connecting synths togethere*/
~bus = Bus.audio(s, 4);
~x1 = Synth(\osc, [\outBus, ~bus.index]);
~x2 = Synth(\osc, [\outBus, ~bus.index]);
~x3 = Synth(\osc, [\outBus, ~bus.index]);
~noisegenerator = Synth(\noisegenerator, [\outBus, ~bus.index]);
~mixer = Synth.tail(s, \a, [\inBus, ~bus.index]);
~mixer.set(\vol, 0.5);

//Arpeggiator
/*Contains all arpaggiator patterns (selecatable from GUI)*/
~arpeggios = [[0, 4, 8, 12], [0, 3, 8, 12], [0, 4, 8, 12, 16, 20, 24], [0, 3, 8, 12, 15, 20, 24],
	[0, 4, 0, 8, 0, 12]
];
~start = 60; //start note of the arpeggio
~index = 0; //index in ~arpeggios (updatable from GUI)
~rate = 0.3; //arpeggio speed (updatable from GUI)
~arp_onoff = 1; //auxiliar variable

//Arpeggiator
~arp = Routine({
	inf.do({ arg i;
		var freq, notes;
		notes = ~start + ~arpeggios[~index]; //Creates the notes to play
		freq = (notes[i%notes.size]).midicps; //Converts notes to frequencies
		~x1.set(\freq, freq); //set frequencies into 3 oscillators
		~x2.set(\freq, freq);
		~x3.set(\freq, freq);

		// Quickly close and reopen the gate to restart the ADSR envelope
        ~mixer.set(\amp_gate, 0, \fil_gate, 0);
        0.01.wait;
        ~mixer.set(\amp_gate, 1, \fil_gate, 1);

		(~rate - 0.01).max(0.01).wait; //Waits before re-execute
	});
});


/*Creating window*/
w = Window("Prova", Rect(50, 50, 1380, 360)).front;
w.background = Color.black;

//Frees all synths when window is closed
w.onClose_({
	s.freeAll;
	s.quit({postln("Server quitted");});
});

//Drawing GUI into window
w.drawFunc = {
	Pen.strokeColor = Color.white;
	Pen.width = 3;
	Pen.strokeRect(Rect(30, 10, 240, 260)); //osc rect
	Pen.strokeRect(Rect(300, 10, 240, 260)); //filter rect
	Pen.strokeRect(Rect(570, 10, 240, 260)); //amp rect
	Pen.strokeRect(Rect(840, 10, 300, 260)); //Arp rect
};
w.refresh;


//Osc1 Controls
/*Creating volume control knob for oscillator #1 and wave form menu selection
Repeated for oscillator #2 and #3*/
~gain1 = Knob(w, Rect(180, 45, 50, 50)).action_({arg me; ~x1.set(\gain, me.value)})
.color_([Color.white, Color.red, Color.white]);
~menu1 = PopUpMenu(w, Rect(60, 60, 90, 20))
.items_(["Select", "Saw", "Pulse", "Tri", "Pulse2", "Pulse3"])
.action_({ arg me;
	if (me.value == 1) {
	("Saw").postln;
		~x1.set(\saw_on, 1);
		~x1.set(\pulse_on, 0);
		~x1.set(\tri_on, 0);
	    ~x1.set(\pulse2_on, 0);
		~x1.set(\pulse3_on, 0);
	};
	if (me.value == 2) {
		("Pulse").postln;
		~x1.set(\saw_on, 0);
		~x1.set(\pulse_on, 1);
		~x1.set(\tri_on, 0);
	    ~x1.set(\pulse2_on, 0);
	    ~x1.set(\pulse3_on, 0);
	};
	if (me.value == 3) {
		("Tri").postln;
		~x1.set(\saw_on, 0);
		~x1.set(\pulse_on, 0);
		~x1.set(\tri_on, 1);
	    ~x1.set(\pulse2_on, 0);
	    ~x1.set(\pulse3_on, 0);
	};
	if (me.value == 4) {
		("Pulse2").postln;
		~x1.set(\saw_on, 0);
		~x1.set(\pulse_on, 0);
		~x1.set(\tri_on, 0);
	    ~x1.set(\pulse2_on, 1);
	    ~x1.set(\pulse3_on, 0);
	};
	if (me.value == 5) {
		("Pulse3").postln;
		~x1.set(\saw_on, 0);
		~x1.set(\pulse_on, 0);
		~x1.set(\tri_on, 0);
		~x1.set(\pulse2_on, 0);
	    ~x1.set(\pulse3_on, 1);
	};
}).allowsReselection;

//Osc2 Controls
~gain2 = Knob(w, Rect(180, 100, 50, 50)).action_({arg me; ~x2.set(\gain, me.value)})
.color_([Color.white, Color.red, Color.white]);
~menu2 = PopUpMenu(w, Rect(60, 115, 90, 20))
.items_(["Select", "Saw", "Pulse", "Tri", "Pulse2", "Pulse3"])
.action_({ arg me;
	if (me.value == 1) {
		("Saw").postln;
		~x2.set(\saw_on, 1);
		~x2.set(\pulse_on, 0);
		~x2.set(\tri_on, 0);
	    ~x2.set(\pulse2_on, 0);
	    ~x2.set(\pulse3_on, 0);
	};
	if (me.value == 2) {
		("Pulse").postln;
		~x2.set(\saw_on, 0);
		~x2.set(\pulse_on, 1);
		~x2.set(\tri_on, 0);
	    ~x2.set(\pulse2_on, 0);
	    ~x2.set(\pulse3_on, 0);
	};
	if (me.value == 3) {
		("Tri").postln;
		~x2.set(\saw_on, 0);
		~x2.set(\pulse_on, 0);
		~x2.set(\tri_on, 1);
	    ~x2.set(\pulse2_on, 0);
	    ~x2.set(\pulse3_on, 0);
	};
	if (me.value == 4) {
		("Pulse2").postln;
		~x2.set(\saw_on, 0);
		~x2.set(\pulse_on, 0);
		~x2.set(\tri_on, 0);
	    ~x2.set(\pulse2_on, 1);
	    ~x2.set(\pulse3_on, 0);
	};
	if (me.value == 5) {
		("Pulse3").postln;
		~x2.set(\saw_on, 0);
		~x2.set(\pulse_on, 0);
		~x2.set(\tri_on, 0);
	    ~x2.set(\pulse2_on, 0);
	    ~x2.set(\pulse3_on, 1);
	};
}).allowsReselection;

//Osc3 Controls
~gain3 = Knob(w, Rect(180, 155, 50, 50)).action_({arg me; ~x3.set(\gain, me.value)})
.color_([Color.white, Color.red, Color.white]);
~menu3 = PopUpMenu(w, Rect(60, 170, 90, 20))
.items_(["Select", "Saw", "Pulse", "Tri", "Pulse2", "Pulse3"])
.action_({ arg me;
	if (me.value == 1) {
		("Saw").postln;
		~x3.set(\saw_on, 1);
		~x3.set(\pulse_on, 0);
		~x3.set(\tri_on, 0);
	    ~x3.set(\pulse2_on, 0);
	    ~x3.set(\pulse3_on, 0);
	};
	if (me.value == 2) {
		("Pulse").postln;
		~x3.set(\saw_on, 0);
		~x3.set(\pulse_on, 1);
		~x3.set(\tri_on, 0);
	    ~x3.set(\pulse2_on, 0);
	    ~x3.set(\pulse3_on, 0);
	};
	if (me.value == 3) {
		("Tri").postln;
		~x3.set(\saw_on, 0);
		~x3.set(\pulse_on, 0);
		~x3.set(\tri_on, 1);
	    ~x3.set(\pulse2_on, 0);
	    ~x3.set(\pulse3_on, 0);
	};
	if (me.value == 4) {
		("Pulse2").postln;
		~x3.set(\saw_on, 0);
		~x3.set(\pulse_on, 0);
		~x3.set(\tri_on, 0);
	    ~x3.set(\pulse2_on, 1);
	    ~x3.set(\pulse3_on, 0);
	};
	if (me.value == 5) {
		("Pulse3").postln;
		~x3.set(\saw_on, 0);
		~x3.set(\pulse_on, 0);
		~x3.set(\tri_on, 0);
	    ~x3.set(\pulse2_on, 0);
	    ~x3.set(\pulse3_on, 1);
	};
}).allowsReselection;


//Noise Control
/*Gain control knob for noise generator*/
~noisegain = Knob(w, Rect(180, 210, 50, 50))
.action_({arg me; ~noisegenerator.set(\gain, me.value)})
.color_([Color.white, Color.red, Color.white]);


//Filter Controls
/*Creation of filter controls. For each filter parameter, creating a knob and inserting it into GUI*/
~filter_cutoff = Knob(w, Rect(330, 80, 40, 40))
.value_(500.explin(40, 18000, 0, 1)) // Set initial value to match default cutoff=500
.color_([Color.white, Color.red, Color.white])
.action_({
	arg me;
	var cal_cutoff = me.value.linexp(0, 1, 40, 18000);
	~mixer.set(\cutoff, cal_cutoff)});

~filter_emphasis = Knob(w, Rect(400, 80, 40, 40))
.color_([Color.white, Color.red, Color.white])
.action_({
	arg me;
	var cal_reso = me.value.linlin(0, 1, 0, 3.8);
	~mixer.set(\reso, cal_reso)});

~filter_contour = Knob(w, Rect(470, 80, 40, 40))
.color_([Color.white, Color.red, Color.white])
.action_({
	arg me;
	var cal_contour = me.value.linlin(0, 1, 0, 10000);
	~mixer.set(\contour, cal_contour);});

~fil_env_atck = Knob(w, Rect(330, 180, 40, 40))
.color_([Color.white, Color.red, Color.white])
.action_({
	arg me;
	~mixer.set(\fil_env_atck, me.value)});

~fil_env_dcy = Knob(w, Rect(400, 180, 40, 40))
.color_([Color.white, Color.red, Color.white])
.action_({
	arg me;
	~mixer.set(\fil_env_dcy, me.value * 10)});

~fil_env_sus = Knob(w, Rect(470, 180, 40, 40))
.color_([Color.white, Color.red, Color.white])
.action_({
	arg me;
	~mixer.set(\fil_env_sus, me.value)});

//Amplifier Controls
/*Creation of amplifier controls. For each amplifier parameter, creating a knob and inserting it into GUI*/
~env_attack = Knob(w, Rect(720, 60, 40, 40))
.action_({ arg me; ~mixer.set(\amp_env_atck, me.value)})
.color_([Color.white, Color.red, Color.white]);

~env_decay = Knob(w, Rect(720, 120, 40, 40))
.action_({ arg me; ~mixer.set(\amp_env_dcy, me.value)})
.color_([Color.white, Color.red, Color.white]);

~env_sustain = Knob(w, Rect(720, 180, 40, 40))
.value_(0.7) // Set to match default
.action_({ arg me; ~mixer.set(\amp_env_sus, me.value)})
.color_([Color.white, Color.red, Color.white]);


//Arpeggiator GUI Controls
//Creation od arpeggiator menu for pattern selection
~arpmenu = PopUpMenu(w, Rect(1020, 70, 90, 20))
.items_(["Select", "Major", "Minor", "Major x2", "Minor x2", " Mj Up/Down"])
.action_({ arg me;
	if (me.value == 1) {
		~index = 0;
	};
	if (me.value == 2) {
		~index = 1;
	};
	if (me.value == 3) {
		~index = 2;
	};
	if (me.value == 4) {
		~index = 3;
	};
	if (me.value == 5) {
		~index = 4;
	};
});

//Knob di selezione del rate
//Creation of rate control knob
~rate_knob = Knob(w, Rect(1040, 120, 50, 50))
.action_({arg me; ~rate = me.value.linlin(0, 1, 0.8, 0.05)}) // Mapping 0..1 to 0.8s..0.05s
.color_([Color.white, Color.red, Color.white]);

//Start Button
//Creation of arpeggiator start button into GUI
~arp_button = Button(w, Rect(1040, 200, 50, 50))
.states_([["Off", Color.red], ["On", Color.white, Color.red]]);
~arp_button.action_({
	arg me;
	me.value.postln;
	if (me.value == 0) {
		postln("Arp OFF");
		~arp_onoff = 0;
		~arp.stop;
	} {
		postln("Arp ON");
		~arp_onoff = 1;
		~arp.reset.play;
	}
});

//Creation of master volume control into GUI
~volume_knob = Knob (w, Rect(1230, 150, 50, 50))
.value_(0.5) // Set to match default vol=0.5
.action_({arg me; ~mixer.set(\vol, me.value)})
.color_([Color.white, Color.red, Color.white]);

//Creation of GUI Keyboard
//This beyboard has two-states button, because this synth is gonna be used on a pc and without a keyboard.
//This way we can manage to try out every control into the synth easier
heigth = 60; //height of a note on the GUI
width = 30; //width of a note on the GUI
keys_number = 44;
base = 21; //Starts from A2

//Creation of a buttons array, each one when pressed setting oscillator frequency to the correct one and triggerin amplifer and filter evenlopes
keyboard = Array.fill(keys_number, { arg i;
	Button(w, Rect(i*width+30, 300, width, heigth))
	.states_([[(base+i), Color.black], [i, Color.white]])
	.action_({ arg me;
		~x1.set(\freq, (base+i).midicps);
		~x2.set(\freq, (base+i).midicps);
		~x3.set(\freq, (base+i).midicps);
		~start = (base+i);
		if(me.value == 1) {
			~mixer.set(\amp_gate, 1);
			~mixer.set(\fil_gate, 1);
		}{
			~mixer.set(\amp_gate, 0);
			~mixer.set(\fil_gate, 0);
			//~arp.reset.stop;
		};
	});
} );


//GUI LABELS
//For each label, creating the object and setting all its values for the GUI
//Oscillators Group Label
c = StaticText(w, Rect(75, 20, 150, 20));
c.string = "OSCILLATORS";
c.stringColor = Color.white;
c.font = Font("Helvetica", 20);
c.align = \center;

//Filter Group Label
d = StaticText(w, Rect(345, 20, 150, 20));
d.string = "FILTER";
d.stringColor = Color.white;
d.font = Font("Helvetica", 20);
d.align = \center;

//Amp Group Label
e = StaticText(w, Rect(615, 20, 150, 20));
e.string = "AMPLIFIER";
e.stringColor = Color.white;
e.font = Font("Helvetica", 20);
e.align = \center;

//Arp Group Label
f = StaticText(w, Rect(915, 20, 150, 20));
f.string = "ARPEGGIATOR";
f.stringColor = Color.white;
f.font = Font("Helvetica", 20);
f.align = \center;

//Volume Label
g = StaticText(w, Rect(1180, 100, 150, 20));
g.string = "Volume";
g.stringColor = Color.white;
g.font = Font("Helvetica", 20);
g.align = \center;

//Noise Label
noise_gen_label = StaticText(w, Rect(60, 225, 100, 20));
noise_gen_label.string = "Noise";
noise_gen_label.stringColor = Color.white;
noise_gen_label.font = Font("Helvetica", 20);
noise_gen_label.align = \center;

//First row filter controls label
filter_cutoff_label = StaticText(w, Rect(330, 60, 40, 15));
filter_cutoff_label.string = "Cutoff";
filter_cutoff_label.stringColor = Color.white;
filter_cutoff_label.font = Font("Helvetica", 15);

filter_emphasis_label = StaticText(w, Rect(386, 60, 70, 15));
filter_emphasis_label.string = "Emphasis";
filter_emphasis_label.stringColor = Color.white;
filter_emphasis_label.font = Font("Helvetica", 15);

filter_contour_label = StaticText(w, Rect(465, 60, 70, 15));
filter_contour_label.string = "Contour";
filter_contour_label.stringColor = Color.white;
filter_contour_label.font = Font("Helvetica", 15);

//Second row filter controls labels
filter_attack_label = StaticText(w, Rect(330, 160, 40, 15));
filter_attack_label.string = "Attack";
filter_attack_label.stringColor = Color.white;
filter_attack_label.font = Font("Helvetica", 15);

filter_decay_label = StaticText(w, Rect(400, 160, 70, 15));
filter_decay_label.string = "Decay";
filter_decay_label.stringColor = Color.white;
filter_decay_label.font = Font("Helvetica", 15);

filter_sustain_label = StaticText(w, Rect(465, 160, 70, 15));
filter_sustain_label.string = "Sustain";
filter_sustain_label.stringColor = Color.white;
filter_sustain_label.font = Font("Helvetica", 15);


//Amplifier Envelope Controls Labels
env_attack_label = StaticText(w, Rect(610, 70, 100, 20));
env_attack_label.string ="Attack";
env_attack_label.stringColor = Color.white;
env_attack_label.font = Font("Helvetica", 20);

env_decay_label = StaticText(w, Rect(610, 130, 100, 20));
env_decay_label.string ="Decay";
env_decay_label.stringColor = Color.white;
env_decay_label.font = Font("Helvetica", 20);

env_sustain_label = StaticText(w, Rect(610, 190, 100, 20));
env_sustain_label.string ="Sustain";
env_sustain_label.stringColor = Color.white;
env_sustain_label.font = Font("Helvetica", 20);


//Arpeggiator controla labels
arp_menu_label = StaticText(w, Rect(880, 70, 100, 20));
arp_menu_label.string = "Arp Type";
arp_menu_label.stringColor = Color.white;
arp_menu_label.font = Font("Helvetica", 20);
arp_menu_label.align = \center;

arp_rate_label = StaticText(w, Rect(880, 135, 100, 20));
arp_rate_label.string = "Rate";
arp_rate_label.stringColor = Color.white;
arp_rate_label.font = Font("Helvetica", 20);
arp_rate_label.align = \center;

arp_start_label = StaticText(w, Rect(880, 215, 100, 20));
arp_start_label.string = "Start";
arp_start_label.stringColor = Color.white;
arp_start_label.font = Font("Helvetica", 20);
arp_start_label.align = \center;

) //end of program