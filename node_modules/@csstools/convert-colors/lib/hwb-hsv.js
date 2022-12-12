/* Convert between HWB and HSV
/* ========================================================================== */

export function hwb2hsv(hwbH, hwbW, hwbB) {
	const [ hsvH, hsvS, hsvV ] = [
		hwbH,
		hwbB === 100 ? 0 : 100 - hwbW / (100 - hwbB) * 100,
		100 - hwbB
	];

	return [ hsvH, hsvS, hsvV ];
}

export function hsv2hwb(hsvH, hsvS, hsvV) {
	const [ hwbH, hwbW, hwbB ] = [
		hsvH,
		(100 - hsvS) * hsvV / 100,
		100 - hsvV
	];

	return [ hwbH, hwbW, hwbB ];
}

/*

References
----------

- https://en.wikipedia.org/wiki/HWB_color_model#Converting_to_and_from_HSV

/* ========================================================================== */
