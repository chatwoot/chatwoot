import { rgb2value, rgb2whiteness, rgb2hue } from './util';

/* Convert between RGB and HSV
/* ========================================================================== */

export function rgb2hsv(rgbR, rgbG, rgbB, fallbackhue) {
	const hsvV = rgb2value(rgbR, rgbG, rgbB);
	const hsvW = rgb2whiteness(rgbR, rgbG, rgbB);
	const hsvH = rgb2hue(rgbR, rgbG, rgbB, fallbackhue);

	// calculate saturation
	const hsvS = hsvV === hsvW ? 0 : (hsvV - hsvW) / hsvV * 100;

	return [ hsvH, hsvS, hsvV ];
}

export function hsv2rgb(hsvH, hsvS, hsvV) {
	const rgbI = Math.floor(hsvH / 60);

	// calculate rgb parts
	const rgbF = hsvH / 60 - rgbI & 1 ? hsvH / 60 - rgbI : 1 - hsvH / 60 - rgbI;
	const rgbM = hsvV * (100 - hsvS) / 100;
	const rgbN = hsvV * (100 - hsvS * rgbF) / 100;

	const [ rgbR, rgbG, rgbB ] = rgbI === 5
		? [ hsvV, rgbM, rgbN ]
	: rgbI === 4
		? [ rgbN, rgbM, hsvV ]
	: rgbI === 3
		? [ rgbM, rgbN, hsvV ]
	: rgbI === 2
		? [ rgbM, hsvV, rgbN ]
	: rgbI === 1
		? [ rgbN, hsvV, rgbM ]
	: [ hsvV, rgbN, rgbM ];

	return [ rgbR, rgbG, rgbB ];
}

/*

References
----------

- http://alvyray.com/Papers/CG/hsv2rgb.htm

/* ========================================================================== */
