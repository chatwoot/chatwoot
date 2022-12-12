'use strict';
class SilentRenderer {
	static get nonTTY() {
		return true;
	}
	render() { }
	end() {	}
}

module.exports = SilentRenderer;
