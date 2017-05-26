// getting things started
(
Server.local.boot;
~b = NetAddr.new("127.0.0.1", 57121);
)


// activate organ instrument synth

(
SynthDef(\bpfsaw2, {
	arg atk=2, sus=0, rel=3, c1=1, c2=(-1),
	freq=500, detune=0.01, pan=0, cfhzmin=0.1, cfhzmax=0.3,
	cfmin=300, cfmax=350, rqmin=0.1, rqmax=0.2,
	lsf=200, ldb=12, amp=1, out=0;
	var sig, env;
	env = EnvGen.kr(Env([0,1,1,0],[atk, sus, rel], [c1,0,c2]), doneAction:2);
	sig = Saw.ar(freq * {LFNoise1.kr(0.5, detune).midiratio}!2);
	sig = BPF.ar(
		sig,
		{LFNoise1.kr(
			LFNoise1.kr(4).exprange(cfhzmin, cfhzmax)
		).exprange(cfmin, cfmax)}!2,
		{LFNoise1.kr(0.1).exprange(rqmin, rqmax)}!2
	);
	sig = BLowShelf.ar(sig, lsf, 0.5, ldb);
	sig = Balance2.ar(sig[0], sig[1], pan);
	sig = sig * env * amp;
	Out.ar(out, sig);
}).add;
)

~chords.stop;

// activate flute / pipes instrument

(
SynthDef("pipes", { arg scl = 0.2, freq = 440, ipress = 0.9, ibreath = 0.09, ifeedbk1 = 0.4, ifeedbk2 = 0.4, dur = 1, gate = 1, amp = 2;

	var kenv1, kenv2, kenvibr, kvibr, sr, cr, block;
	var poly, signalOut, ifqc;
	var aflow1, asum1, asum2, afqc, atemp1, ax, apoly, asum3, avalue, atemp2, aflute1;
	var fdbckArray;

	sr = SampleRate.ir;
	cr = ControlRate.ir;
	block = cr.reciprocal;

	ifqc = freq;

	// noise envelope
	kenv1 = EnvGen.kr(Env.new(
		[ 0.0, 1.1 * ipress, ipress, ipress, 0.0 ], [ 0.06, 0.2, dur - 0.46, 0.2 ], 'linear' )
	);
	// overall envelope
	kenv2 = EnvGen.kr(Env.new(
		[ 0.0, amp, amp, 0.0 ], [ 0.1, dur - 0.02, 0.1 ], 'linear' ), doneAction: 2
	);
	// vibrato envelope
	kenvibr = EnvGen.kr(Env.new( [ 0.0, 0.0, 1, 1, 0.0 ], [ 0.5, 0.5, dur - 1.5, 0.5 ], 'linear') );

	// create air flow and vibrato
	aflow1 = LFClipNoise.ar( sr, kenv1 ) * 0.3 ;
	kvibr = SinOsc.ar( 5, 0, 0.1 * kenvibr );

	asum1 = ( ibreath * aflow1 ) + kenv1 + kvibr;
	afqc = ifqc.reciprocal - ( asum1/20000 ) - ( 9/sr ) + ( ifqc/12000000 ) - block;

	fdbckArray = LocalIn.ar( 1 );

	aflute1 = fdbckArray;
	asum2 = asum1 + ( aflute1 * ifeedbk1 );

	ax = DelayC.ar( asum2, ifqc.reciprocal - block * 0.5, afqc * 0.5 - ( asum1/ifqc/cr ) + 0.001 );

	apoly = ax - ( ax.cubed );
	asum3 = apoly + ( aflute1 * ifeedbk2 );
	avalue = LPF.ar( asum3, 2000 );

	aflute1 = DelayC.ar( avalue, ifqc.reciprocal - block, afqc );

	fdbckArray = [ aflute1 ];

	LocalOut.ar( fdbckArray );

	signalOut = avalue;

	OffsetOut.ar( 0, [ signalOut * kenv2, signalOut * kenv2 ] );

}).add;
)

// test flute noise
(
Pbind(
	\instrument, "pipes",
	\degree, Pseq([0, 1, 2, 3, 4], 2),
	\dur, Pwhite(0.2, 0.5),
	\amp, Pwhite(0.1, 0.4)
).play
)



// drone noise, 5 sec note
(
OSCdef.new(
	\drone,
	{
		arg msg, time, addr, port;
		(msg[1].asInteger).postln;
		n = msg[1];
		n.postln;
		(
			Synth.new(\bpfsaw2, [
				\freq, msg[1].asInteger.midicps,
				\dur, 3.5, \atk, 0.3, \rel, 4.5, \amp, 0.45, \out, 0, \pan, 0,
			]);
		)
	},
	'/drone'
);


// SOUND 1: quiet longer notes
(
OSCdef.new(
	\half,
	{
		arg msg, time, addr, port;
		(msg[1].asInteger).postln;
		n = msg[1];
		n.postln;
		(
			Synth.new(\bpfsaw2, [
				\freq, msg[1].asInteger.midicps,
				\dur, 0.8, \atk, 0.25, \rel, 1.1, \amp, 1.0, \out, 0, \pan, 0,
			]);
		)
	},
	'/half'
);

OSCdef.new(
	\eighth,
	{
		arg msg, time, addr, port;
		(msg[1].asInteger).postln;
		n = msg[1];
		n.postln;
		Synth.new(\pipes, [\freq, msg[1].asInteger.midicps, \dur, 0.1, \amp, 0.45]);
	},
	'/eighth'
);


OSCdef.new(
	\quarter,
	{
		arg msg, time, addr, port;
		(msg[1].asInteger).postln;
		n = msg[1];
		n.postln;
		Synth.new(\pipes, [\freq, msg[1].asInteger.midicps, \dur, 0.2, \amp, 0.5]);
	},
	'/quarter'
);
)


)
// SOUND 2: flute / pipes sound (used in talk)
(
OSCdef.new(
	\eighth,
	{
		arg msg, time, addr, port;
		(msg[1].asInteger).postln;
		n = msg[1];
		n.postln;
		Synth.new(\pipes, [\freq, msg[1].asInteger.midicps, \dur, 0.1, \amp, 0.40]);
	},
	'/eighth'
);


OSCdef.new(
	\quarter,
	{
		arg msg, time, addr, port;
		(msg[1].asInteger).postln;
		n = msg[1];
		n.postln;
		Synth.new(\pipes, [\freq, msg[1].asInteger.midicps, \dur, 0.2, \amp, 0.39]);
	},
	'/quarter'
);

OSCdef.new(
	\half,
	{
		arg msg, time, addr, port;
		(msg[1].asInteger).postln;
		n = msg[1];
		n.postln;
		Synth.new(\pipes, [\freq, msg[1].asInteger.midicps, \dur, 0.4, \amp, 0.35]);
	},
	'/half'
);
)
