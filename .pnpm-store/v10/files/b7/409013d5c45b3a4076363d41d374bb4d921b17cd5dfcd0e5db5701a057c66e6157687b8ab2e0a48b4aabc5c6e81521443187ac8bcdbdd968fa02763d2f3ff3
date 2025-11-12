// Importing from a ".js" file is a workaround for Node.js "ES Modules"
// importing system which is even uncapable of importing "*.json" files.
import metadata from '../metadata.min.json.js'

import { PhoneNumberSearch as _PhoneNumberSearch } from '../es6/legacy/findPhoneNumbersInitialImplementation.js'

export function PhoneNumberSearch(text, options) {
	_PhoneNumberSearch.call(this, text, options, metadata)
}

// Deprecated.
PhoneNumberSearch.prototype = Object.create(_PhoneNumberSearch.prototype, {})
PhoneNumberSearch.prototype.constructor = PhoneNumberSearch
