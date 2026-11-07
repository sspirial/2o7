class_name GTAAudio
extends RefCounted

static var _cached_engine: AudioStreamWAV = null
static var _cached_screech: AudioStreamWAV = null
static var _cached_horn: AudioStreamWAV = null
static var _cached_siren: AudioStreamWAV = null
static var _cached_crash: AudioStreamWAV = null
static var _cached_footstep: AudioStreamWAV = null
static var _cached_door: AudioStreamWAV = null
static var _cached_jingle: AudioStreamWAV = null
static var _cached_radio_tracks: Array[AudioStreamWAV] = []

static func get_engine_stream() -> AudioStreamWAV:
	if _cached_engine != null:
		return _cached_engine
	
	var mix_rate: int = 22050
	var duration: float = 0.5
	var sample_count: int = int(mix_rate * duration)
	var bytes := PackedByteArray()
	bytes.resize(sample_count * 2)
	
	var base_freq: float = 75.0
	for i in range(sample_count):
		var t: float = float(i) / float(mix_rate)
		# Complex rich engine timbre (fundamental + harmonics + cylinder rumble noise)
		var val: float = 0.0
		val += sin(t * base_freq * TAU) * 0.45
		val += sin(t * base_freq * 2.0 * TAU) * 0.25
		val += sin(t * base_freq * 3.0 * TAU) * 0.15
		val += sin(t * base_freq * 4.0 * TAU) * 0.1
		# Random intake hiss
		val += (randf() * 2.0 - 1.0) * 0.08
		val = clampf(val, -1.0, 1.0)
		var s: int = int(val * 24000.0)
		bytes.encode_s16(i * 2, s)
		
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = mix_rate
	wav.stereo = false
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_begin = 0
	wav.loop_end = sample_count
	wav.data = bytes
	_cached_engine = wav
	return wav

static func get_screech_stream() -> AudioStreamWAV:
	if _cached_screech != null:
		return _cached_screech
		
	var mix_rate: int = 22050
	var duration: float = 0.4
	var sample_count: int = int(mix_rate * duration)
	var bytes := PackedByteArray()
	bytes.resize(sample_count * 2)
	
	var noise_filter: float = 0.0
	for i in range(sample_count):
		var t: float = float(i) / float(mix_rate)
		var raw_noise: float = randf() * 2.0 - 1.0
		noise_filter = lerpf(noise_filter, raw_noise, 0.4)
		var tone: float = sin(t * 850.0 * TAU) * 0.3 + sin(t * 1280.0 * TAU) * 0.25
		var val: float = (noise_filter * 0.5 + tone * 0.5)
		val = clampf(val, -1.0, 1.0)
		var s: int = int(val * 22000.0)
		bytes.encode_s16(i * 2, s)
		
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = mix_rate
	wav.stereo = false
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_begin = 0
	wav.loop_end = sample_count
	wav.data = bytes
	_cached_screech = wav
	return wav

static func get_horn_stream() -> AudioStreamWAV:
	if _cached_horn != null:
		return _cached_horn
		
	var mix_rate: int = 22050
	var duration: float = 0.4
	var sample_count: int = int(mix_rate * duration)
	var bytes := PackedByteArray()
	bytes.resize(sample_count * 2)
	
	for i in range(sample_count):
		var t: float = float(i) / float(mix_rate)
		# Dual brass frequencies (F# and A#)
		var env: float = 1.0
		if t < 0.02:
			env = t / 0.02
		elif t > 0.35:
			env = (duration - t) / 0.05
		var val: float = (sin(t * 370.0 * TAU) * 0.5 + sin(t * 466.0 * TAU) * 0.5) * env
		var s: int = int(val * 26000.0)
		bytes.encode_s16(i * 2, s)
		
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = mix_rate
	wav.stereo = false
	wav.data = bytes
	_cached_horn = wav
	return wav

static func get_siren_stream() -> AudioStreamWAV:
	if _cached_siren != null:
		return _cached_siren
		
	var mix_rate: int = 22050
	var duration: float = 1.0
	var sample_count: int = int(mix_rate * duration)
	var bytes := PackedByteArray()
	bytes.resize(sample_count * 2)
	
	for i in range(sample_count):
		var t: float = float(i) / float(mix_rate)
		# Sweeping siren frequency between 600Hz and 1100Hz
		var freq: float = 650.0 + sin(t * 2.0 * TAU) * 280.0
		var val: float = sin(t * freq * TAU) * 0.8
		var s: int = int(val * 24000.0)
		bytes.encode_s16(i * 2, s)
		
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = mix_rate
	wav.stereo = false
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_begin = 0
	wav.loop_end = sample_count
	wav.data = bytes
	_cached_siren = wav
	return wav

static func get_crash_stream() -> AudioStreamWAV:
	if _cached_crash != null:
		return _cached_crash
		
	var mix_rate: int = 22050
	var duration: float = 0.5
	var sample_count: int = int(mix_rate * duration)
	var bytes := PackedByteArray()
	bytes.resize(sample_count * 2)
	
	for i in range(sample_count):
		var t: float = float(i) / float(mix_rate)
		var env: float = exp(-t * 9.0)
		var boom: float = sin(t * 65.0 * TAU) * env * 0.7
		var crunch: float = (randf() * 2.0 - 1.0) * env * 0.6
		var val: float = clampf(boom + crunch, -1.0, 1.0)
		var s: int = int(val * 28000.0)
		bytes.encode_s16(i * 2, s)
		
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = mix_rate
	wav.stereo = false
	wav.data = bytes
	_cached_crash = wav
	return wav

static func get_footstep_stream() -> AudioStreamWAV:
	if _cached_footstep != null:
		return _cached_footstep
		
	var mix_rate: int = 22050
	var duration: float = 0.08
	var sample_count: int = int(mix_rate * duration)
	var bytes := PackedByteArray()
	bytes.resize(sample_count * 2)
	
	for i in range(sample_count):
		var t: float = float(i) / float(mix_rate)
		var env: float = exp(-t * 50.0)
		var val: float = (sin(t * 120.0 * TAU) * 0.4 + (randf() * 2.0 - 1.0) * 0.3) * env
		var s: int = int(val * 20000.0)
		bytes.encode_s16(i * 2, s)
		
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = mix_rate
	wav.stereo = false
	wav.data = bytes
	_cached_footstep = wav
	return wav

static func get_door_stream() -> AudioStreamWAV:
	if _cached_door != null:
		return _cached_door
		
	var mix_rate: int = 22050
	var duration: float = 0.15
	var sample_count: int = int(mix_rate * duration)
	var bytes := PackedByteArray()
	bytes.resize(sample_count * 2)
	
	for i in range(sample_count):
		var t: float = float(i) / float(mix_rate)
		var env: float = exp(-t * 25.0)
		var val: float = (sin(t * 180.0 * TAU) * 0.6 + sin(t * 320.0 * TAU) * 0.4) * env
		var s: int = int(val * 24000.0)
		bytes.encode_s16(i * 2, s)
		
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = mix_rate
	wav.stereo = false
	wav.data = bytes
	_cached_door = wav
	return wav

static func get_jingle_stream() -> AudioStreamWAV:
	if _cached_jingle != null:
		return _cached_jingle
		
	var mix_rate: int = 22050
	var notes: Array[float] = [261.63, 329.63, 392.00, 523.25, 659.25] # C4, E4, G4, C5, E5
	var note_dur: float = 0.12
	var total_dur: float = note_dur * float(notes.size()) + 0.4
	var sample_count: int = int(mix_rate * total_dur)
	var bytes := PackedByteArray()
	bytes.resize(sample_count * 2)
	
	for i in range(sample_count):
		var t: float = float(i) / float(mix_rate)
		var note_idx: int = int(t / note_dur)
		var val: float = 0.0
		if note_idx < notes.size():
			var freq: float = notes[note_idx]
			var note_t: float = fmod(t, note_dur)
			var env: float = exp(-note_t * 6.0)
			val = sin(t * freq * TAU) * env * 0.7
		elif t >= note_dur * float(notes.size()):
			var last_t: float = t - note_dur * float(notes.size())
			var env: float = exp(-last_t * 3.0)
			val = sin(t * 523.25 * TAU) * env * 0.6 + sin(t * 659.25 * TAU) * env * 0.4
			
		var s: int = int(clampf(val, -1.0, 1.0) * 24000.0)
		bytes.encode_s16(i * 2, s)
		
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = mix_rate
	wav.stereo = false
	wav.data = bytes
	_cached_jingle = wav
	return wav

static func get_radio_track(station_index: int) -> AudioStreamWAV:
	if _cached_radio_tracks.size() > station_index and _cached_radio_tracks[station_index] != null:
		return _cached_radio_tracks[station_index]
		
	if _cached_radio_tracks.size() <= station_index:
		_cached_radio_tracks.resize(station_index + 1)
		
	var mix_rate: int = 22050
	var duration: float = 4.0 # 4 second seamless musical beat loop
	var sample_count: int = int(mix_rate * duration)
	var bytes := PackedByteArray()
	bytes.resize(sample_count * 2)
	
	# Stations: 0 = Radio 254 (Afrobeats), 1 = Nairobi Night (Synthwave), 2 = Ghetto Heat (Drill/Hip-Hop)
	var bpm: float = 120.0
	if station_index == 1:
		bpm = 128.0
	elif station_index == 2:
		bpm = 140.0
		
	var beat_duration: float = 60.0 / bpm
	
	for i in range(sample_count):
		var t: float = float(i) / float(mix_rate)
		var beat: float = fmod(t, beat_duration) / beat_duration
		var beat_num: int = int(t / beat_duration) % 8
		var val: float = 0.0
		
		# Kick on beats 0, 2, 4, 6
		if beat_num % 2 == 0:
			var kick_env: float = exp(-beat * 18.0)
			var kick_freq: float = 130.0 * (1.0 - beat * 0.7)
			val += sin(t * kick_freq * TAU) * kick_env * 0.6
			
		# Snare / Clap on beats 2, 6 (or 1, 3 in half-time)
		if beat_num == 2 or beat_num == 6:
			var snare_env: float = exp(-beat * 12.0)
			val += (randf() * 2.0 - 1.0) * snare_env * 0.35
			val += sin(t * 220.0 * TAU) * snare_env * 0.2
			
		# Hi-hat on every 8th note
		var eighth: float = fmod(t, beat_duration * 0.5) / (beat_duration * 0.5)
		var hat_env: float = exp(-eighth * 35.0)
		val += (randf() * 2.0 - 1.0) * hat_env * 0.15
		
		# Melodic bassline depending on station
		var bass_freq: float = 110.0
		match station_index:
			0: # Afrobeats bouncy bass
				var bass_notes: Array[float] = [110.0, 110.0, 130.81, 146.83, 110.0, 164.81, 146.83, 130.81]
				bass_freq = bass_notes[beat_num % bass_notes.size()]
				var bass_env: float = exp(-beat * 6.0)
				val += sin(t * bass_freq * TAU) * bass_env * 0.4
			1: # Synthwave arpeggiated bass
				var sixteenth: int = int(t / (beat_duration * 0.25)) % 16
				var arps: Array[float] = [65.41, 130.81, 98.0, 130.81, 77.78, 155.56, 116.54, 155.56]
				bass_freq = arps[sixteenth % arps.size()]
				var synth_env: float = 0.8
				val += (sin(t * bass_freq * TAU) * 0.3 + sin(t * bass_freq * 2.0 * TAU) * 0.15) * synth_env
			_: # Drill sliding sub
				var sub_freq: float = 55.0
				if beat_num >= 4:
					sub_freq = 61.74 # Eb slide
				val += sin(t * sub_freq * TAU) * 0.5
				
		val = clampf(val * 0.7, -1.0, 1.0)
		var s: int = int(val * 24000.0)
		bytes.encode_s16(i * 2, s)
		
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = mix_rate
	wav.stereo = false
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_begin = 0
	wav.loop_end = sample_count
	wav.data = bytes
	_cached_radio_tracks[station_index] = wav
	return wav
