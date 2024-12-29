extends Resource
class_name CC


var timers = {}


func cyclical_call(
	key: String,
	cycle_time_ms: int,
	callback: Callable,
	force_call: bool = false
):
	var curr_time = Time.get_ticks_msec()
	var time_of_last_call = curr_time - 2 * cycle_time_ms
	if timers.has(key):
		time_of_last_call = timers[key]

	if (
		((curr_time - time_of_last_call) >= cycle_time_ms) or
		force_call
	):
		return callback.call()
