var v3Err;
try {
	module.exports = require("chokidar");
	return;
} catch(e) {
	v3Err = e;
}

var v2Err;
try {
	module.exports = require("watchpack-chokidar2");
	return;
} catch(e) {
	v2Err = e;
}

throw new Error(
	"No version of chokidar is available. Tried chokidar@2 and chokidar@3.\n" +
	"You could try to manually install any chokidar version.\n" +
	"chokidar@3: " + v3Err + "\n" +
	"chokidar@2: " + v2Err + "\n"
)
