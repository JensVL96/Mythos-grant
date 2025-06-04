extends AudioStreamPlayer2D

var has_faded_in := false
var target_volume_db := 0
var default_volume_db := -40

func ensure_playing():
	if not playing:
		volume_db = default_volume_db
		play()

	if not has_faded_in:
		fade_in()
		has_faded_in = true

func fade_in():
	var tween = create_tween()
	tween.tween_property(self, "volume_db", target_volume_db, 3.0)

func fade_out():
	var tween = create_tween()
	tween.tween_property(self, "volume_db", default_volume_db, 2.0)
	await tween.finished
