class_name BuildId
extends RefCounted
## Identifies this build. CI overwrites SHA with the commit it built;
## "dev" means a local build, which never self-updates.
const SHA: String = "dev"
