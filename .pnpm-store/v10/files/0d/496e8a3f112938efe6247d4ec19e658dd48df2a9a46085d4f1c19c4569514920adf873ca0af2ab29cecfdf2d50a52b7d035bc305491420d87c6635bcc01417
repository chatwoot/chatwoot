// Importing from a ".js" file is a workaround for Node.js "ES Modules"
// importing system which is even uncapable of importing "*.json" files.
import metadata from '../../metadata.min.json.js'

import { Metadata as _Metadata } from '../../core/index.js'

export function Metadata() {
	return _Metadata.call(this, metadata)
}

Metadata.prototype = Object.create(_Metadata.prototype, {})
Metadata.prototype.constructor = Metadata