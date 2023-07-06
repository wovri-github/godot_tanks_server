class_name Logger



static func info(message):
	var time = get_formatted_datetime("[hh:mm:ss DD.MM] ")
	print(time, message)

# el suspect
static func sus(message):
	var time = get_formatted_datetime("[hh:mm:ss DD.MM] ")
	print("[!SUS] ", time, message)

static func get_formatted_datetime(time_format):
	var datetime = OS.get_datetime()
	var result = time_format
	result = result.replace("YYYY", "%04d" % [datetime.year])
	result = result.replace("MM", "%02d" % [datetime.month])
	result = result.replace("DD", "%02d" % [datetime.day])
	result = result.replace("hh", "%02d" % [datetime.hour])
	result = result.replace("mm", "%02d" % [datetime.minute])
	result = result.replace("ss", "%02d" % [datetime.second])
	return result
