module.exports = function(forceSimilar) {
	if (typeof Map !== 'function' || forceSimilar) {
		var Similar = require('./similar');
		return new Similar();
	}
	else {
		return new Map();
	}
}
