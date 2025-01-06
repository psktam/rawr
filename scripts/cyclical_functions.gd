extends Resource
class_name TF


var timers = {}


func cyclical_call(
	key: String,
	cycle_time_ms: int,
	callback: Callable,
	force_call: bool = false
):
	var curr_time = Time.get_ticks_msec()
	if not timers.has(key):
		timers[key] = curr_time

	var time_of_last_call = timers[key]

	if (
		((curr_time - time_of_last_call) >= cycle_time_ms) or
		force_call
	):
		timers[key] = curr_time
		return callback.call()

var t_ons = {}
func t_on(
	key: String,
	input_sig: bool,
	delay_ms: int,
	reset: bool = false
) -> bool:
	var curr_time = Time.get_ticks_msec()
	if not t_ons.has(key) or reset:
		t_ons[key] = [false, curr_time]

	if input_sig and not t_ons[key][0]:
		t_ons[key][0] = true
		t_ons[key][1] = curr_time
	elif not input_sig:
		t_ons[key][0] = false

	return t_ons[key][0] and ((curr_time - t_ons[key][1]) >= delay_ms)
