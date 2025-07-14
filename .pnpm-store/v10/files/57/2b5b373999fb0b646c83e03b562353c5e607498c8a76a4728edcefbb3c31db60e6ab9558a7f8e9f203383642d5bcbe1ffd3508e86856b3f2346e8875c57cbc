const { random } = require('@lukeed/csprng');

var SIZE=4096, HEX=[], IDX=0, BUFFER;

for (; IDX < 256; IDX++) {
	HEX[IDX] = (IDX + 256).toString(16).substring(1);
}

function v4() {
	if (!BUFFER || ((IDX + 16) > SIZE)) {
		BUFFER = random(SIZE);
		IDX = 0;
	}

	var i=0, tmp, out='';
	for (; i < 16; i++) {
		tmp = BUFFER[IDX + i];
		if (i==6) out += HEX[tmp & 15 | 64];
		else if (i==8) out += HEX[tmp & 63 | 128];
		else out += HEX[tmp];

		if (i & 1 && i > 1 && i < 11) out += '-';
	}

	IDX += 16;
	return out;
}

exports.v4 = v4;