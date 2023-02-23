extends Reference
class_name Functions


static func check_version(version) -> int:
	if version == null:
		return OK
	version = version.left(version.find_last("."))
	if version in ProjectSettings.get_setting("application/other/available_versions"):
		return OK
	return ERR_UNAUTHORIZED
