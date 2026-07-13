extends AudioStreamPlayer

const BPM := 92.0
const MIX_RATE := 22050.0
const STEP_DURATION := 60.0 / BPM / 2.0
const LOOP_STEPS := 64
const LOOP_SAMPLES := int(MIX_RATE * STEP_DURATION * LOOP_STEPS)

# Eight bars of a light C major / A minor melody. Each entry is an eighth note;
# -1 is a rest. MIDI notes keep the score compact and easy to edit.
const MELODY := [
	64, 67, 69, 67, 64, 62, 60, -1,
	64, 69, 72, 69, 67, 64, 60, -1,
	65, 69, 72, 69, 67, 65, 64, -1,
	67, 71, 74, 71, 69, 67, 62, -1,
	64, 67, 72, 71, 69, 67, 64, -1,
	69, 72, 76, 72, 71, 69, 67, -1,
	65, 69, 72, 74, 72, 69, 65, -1,
	67, 71, 74, 76, 74, 71, 67, -1,
]
const CHORD_ROOTS := [48, 45, 41, 43, 48, 45, 41, 43]
const ARPEGGIO_OFFSETS := [12, 16, 19, 24, 19, 16, 12, 19]

var generator_playback: AudioStreamGeneratorPlayback
var sample_cursor := 0


func _ready() -> void:
	_ensure_music_bus()

	var generator := AudioStreamGenerator.new()
	generator.mix_rate = MIX_RATE
	generator.buffer_length = 1.0
	stream = generator
	bus = &"Music"
	volume_db = -14.0
	play()
	generator_playback = get_stream_playback() as AudioStreamGeneratorPlayback
	set_process(generator_playback != null)


func _process(_delta: float) -> void:
	if generator_playback == null:
		return
	var frames_available := generator_playback.get_frames_available()
	for _frame in frames_available:
		generator_playback.push_frame(_synthesize_frame())


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_M:
		stream_paused = not stream_paused
		get_viewport().set_input_as_handled()


func _synthesize_frame() -> Vector2:
	var time := float(sample_cursor) / MIX_RATE
	var step_number := int(time / STEP_DURATION)
	var step_index := step_number % LOOP_STEPS
	var local_step_time := fmod(time, STEP_DURATION)
	var bar_index := (step_index / 8) as int
	var chord_root: int = CHORD_ROOTS[bar_index]

	var melody := 0.0
	var melody_note: int = MELODY[step_index]
	if melody_note >= 0:
		var melody_phase := TAU * _midi_to_frequency(melody_note) * local_step_time
		var soft_pulse := 1.0 if sin(melody_phase) >= 0.0 else -1.0
		melody = (
			sin(melody_phase) * 0.78
			+ soft_pulse * 0.14
			+ sin(melody_phase * 2.0) * 0.08
		) * _note_envelope(local_step_time, STEP_DURATION, 0.025, 0.09)

	var arp_note: int = chord_root + ARPEGGIO_OFFSETS[step_index % 8]
	var arp_phase := TAU * _midi_to_frequency(arp_note) * local_step_time
	var arpeggio := (
		sin(arp_phase) + sin(arp_phase * 2.0) * 0.18
	) * _note_envelope(local_step_time, STEP_DURATION * 0.72, 0.018, 0.11)

	var bass_duration := STEP_DURATION * 2.0
	var local_bass_time := fmod(time, bass_duration)
	var bass_phase := TAU * _midi_to_frequency(chord_root - 12) * local_bass_time
	var bass := (
		sin(bass_phase) * 0.85 + sin(bass_phase * 2.0) * 0.15
	) * _note_envelope(local_bass_time, bass_duration, 0.035, 0.16)

	# A tiny rounded kick marks quarter notes without turning the loop into a
	# dominant drum track.
	var beat_time := fmod(time, bass_duration)
	var kick := 0.0
	if beat_time < 0.16:
		var kick_frequency := lerpf(72.0, 42.0, beat_time / 0.16)
		kick = sin(TAU * kick_frequency * beat_time) * exp(-beat_time * 24.0)

	var center := melody * 0.115 + bass * 0.09 + kick * 0.045
	var left := center + arpeggio * 0.052
	var right := center + arpeggio * 0.064

	sample_cursor = (sample_cursor + 1) % LOOP_SAMPLES
	return Vector2(left, right)


func _midi_to_frequency(note: int) -> float:
	return 440.0 * pow(2.0, (note - 69) / 12.0)


func _note_envelope(
	local_time: float,
	duration: float,
	attack: float,
	release: float
) -> float:
	if local_time < 0.0 or local_time >= duration:
		return 0.0
	var attack_level := minf(local_time / attack, 1.0)
	var release_level := minf((duration - local_time) / release, 1.0)
	return maxf(0.0, minf(attack_level, release_level))


func _ensure_music_bus() -> void:
	var bus_index := AudioServer.get_bus_index(&"Music")
	if bus_index < 0:
		AudioServer.add_bus()
		bus_index = AudioServer.get_bus_count() - 1
		AudioServer.set_bus_name(bus_index, &"Music")
		AudioServer.set_bus_volume_db(bus_index, -2.0)
