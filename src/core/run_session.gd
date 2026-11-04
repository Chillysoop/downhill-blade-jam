class_name RunSession
extends RefCounted
## State that survives reloading the main scene when the player switches maps.

## Id of the course picked in map select ("" = use the launch argument or the
## catalog default).
static var course_id: String = ""
