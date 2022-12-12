const { randomBytes } = require('crypto');

function random(len) {
	return randomBytes(len);
}

exports.random = random;