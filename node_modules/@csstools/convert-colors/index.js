import { rgb2hsl, hsl2rgb } from './lib/rgb-hsl';
import { rgb2hwb, hwb2rgb } from './lib/rgb-hwb';
import { rgb2hsv, hsv2rgb } from './lib/rgb-hsv';
import { rgb2xyz, xyz2rgb } from './lib/rgb-xyz';
import { hsl2hsv, hsv2hsl } from './lib/hsl-hsv';
import { hwb2hsv, hsv2hwb } from './lib/hwb-hsv';
import { lab2xyz, xyz2lab } from './lib/lab-xyz';
import { lab2lch, lch2lab } from './lib/lab-lch';
import { rgb2hue } from './lib/util';

/* Convert between RGB and Lab
/* ========================================================================== */

function rgb2lab(rgbR, rgbG, rgbB) {
	const [ xyzX, xyzY, xyzZ ] = rgb2xyz(rgbR, rgbG, rgbB);
	const [ labL, labA, labB ] = xyz2lab(xyzX, xyzY, xyzZ);

	return [ labL, labA, labB ];
}

function lab2rgb(labL, labA, labB) {
	const [ xyzX, xyzY, xyzZ ] = lab2xyz(labL, labA, labB);
	const [ rgbR, rgbG, rgbB ] = xyz2rgb(xyzX, xyzY, xyzZ);

	return [ rgbR, rgbG, rgbB ];
}

/* Convert between RGB and LCH
/* ========================================================================== */

function rgb2lch(rgbR, rgbG, rgbB) {
	const [ xyzX, xyzY, xyzZ ] = rgb2xyz(rgbR, rgbG, rgbB);
	const [ labL, labA, labB ] = xyz2lab(xyzX, xyzY, xyzZ);
	const [ lchL, lchC, lchH ] = lab2lch(labL, labA, labB);

	return [ lchL, lchC, lchH ];
}

function lch2rgb(lchL, lchC, lchH) {
	const [ labL, labA, labB ] = lch2lab(lchL, lchC, lchH);
	const [ xyzX, xyzY, xyzZ ] = lab2xyz(labL, labA, labB);
	const [ rgbR, rgbG, rgbB ] = xyz2rgb(xyzX, xyzY, xyzZ);

	return [ rgbR, rgbG, rgbB ];
}

/* Convert between HSL and HWB
/* ========================================================================== */

function hwb2hsl(hwbH, hwbW, hwbB) {
	const [ hsvH, hsvS, hsvV ] = hwb2hsv(hwbH, hwbW, hwbB);
	const [ hslH, hslS, hslL ] = hsv2hsl(hsvH, hsvS, hsvV);

	return [ hslH, hslS, hslL ];
}

function hsl2hwb(hslH, hslS, hslL) {
	const [ , hsvS, hsvV ] = hsl2hsv(hslH, hslS, hslL);
	const [ , hwbW, hwbB ] = hsv2hwb(hslH, hsvS, hsvV);

	return [ hslH, hwbW, hwbB ];
}

/* Convert between HSL and Lab
/* ========================================================================== */

function hsl2lab(hslH, hslS, hslL) {
	const [ rgbR, rgbG, rgbB ] = hsl2rgb(hslH, hslS, hslL);
	const [ xyzX, xyzY, xyzZ ] = rgb2xyz(rgbR, rgbG, rgbB);
	const [ labL, labA, labB ] = xyz2lab(xyzX, xyzY, xyzZ);

	return [ labL, labA, labB ];
}

function lab2hsl(labL, labA, labB, fallbackhue) {
	const [ xyzX, xyzY, xyzZ ] = lab2xyz(labL, labA, labB);
	const [ rgbR, rgbG, rgbB ] = xyz2rgb(xyzX, xyzY, xyzZ);
	const [ hslH, hslS, hslL ] = rgb2hsl(rgbR, rgbG, rgbB, fallbackhue);

	return [ hslH, hslS, hslL ];
}

/* Convert between HSL and LCH
/* ========================================================================== */

function hsl2lch(hslH, hslS, hslL) {
	const [ rgbR, rgbG, rgbB ] = hsl2rgb(hslH, hslS, hslL);
	const [ xyzX, xyzY, xyzZ ] = rgb2xyz(rgbR, rgbG, rgbB);
	const [ labL, labA, labB ] = xyz2lab(xyzX, xyzY, xyzZ);
	const [ lchL, lchC, lchH ] = lab2lch(labL, labA, labB);

	return [ lchL, lchC, lchH ];
}

function lch2hsl(lchL, lchC, lchH, fallbackhue) {
	const [ labL, labA, labB ] = lch2lab(lchL, lchC, lchH);
	const [ xyzX, xyzY, xyzZ ] = lab2xyz(labL, labA, labB);
	const [ rgbR, rgbG, rgbB ] = xyz2rgb(xyzX, xyzY, xyzZ);
	const [ hslH, hslS, hslL ] = rgb2hsl(rgbR, rgbG, rgbB, fallbackhue);

	return [ hslH, hslS, hslL ];
}

/* Convert between HSL and XYZ
/* ========================================================================== */

function hsl2xyz(hslH, hslS, hslL) {
	const [ rgbR, rgbG, rgbB ] = hsl2rgb(hslH, hslS, hslL);
	const [ xyzX, xyzY, xyzZ ] = rgb2xyz(rgbR, rgbG, rgbB);

	return [ xyzX, xyzY, xyzZ ];
}

function xyz2hsl(xyzX, xyzY, xyzZ, fallbackhue) {
	const [ rgbR, rgbG, rgbB ] = xyz2rgb(xyzX, xyzY, xyzZ);
	const [ hslH, hslS, hslL ] = rgb2hsl(rgbR, rgbG, rgbB, fallbackhue);

	return [ hslH, hslS, hslL ];
}

/* Convert between HWB and Lab
/* ========================================================================== */

function hwb2lab(hwbH, hwbW, hwbB) {
	const [ rgbR, rgbG, rgbB ] = hwb2rgb(hwbH, hwbW, hwbB);
	const [ xyzX, xyzY, xyzZ ] = rgb2xyz(rgbR, rgbG, rgbB);
	const [ labL, labA, labB ] = xyz2lab(xyzX, xyzY, xyzZ);

	return [ labL, labA, labB ];
}

function lab2hwb(labL, labA, labB, fallbackhue) {
	const [ xyzX, xyzY, xyzZ ] = lab2xyz(labL, labA, labB);
	const [ rgbR, rgbG, rgbB ] = xyz2rgb(xyzX, xyzY, xyzZ);
	const [ hwbH, hwbW, hwbB ] = rgb2hwb(rgbR, rgbG, rgbB, fallbackhue);

	return [ hwbH, hwbW, hwbB ];
}

/* Convert between HWB and LCH
/* ========================================================================== */

function hwb2lch(hwbH, hwbW, hwbB) {
	const [ rgbR, rgbG, rgbB ] = hwb2rgb(hwbH, hwbW, hwbB);
	const [ xyzX, xyzY, xyzZ ] = rgb2xyz(rgbR, rgbG, rgbB);
	const [ labL, labA, labB ] = xyz2lab(xyzX, xyzY, xyzZ);
	const [ lchL, lchC, lchH ] = lab2lch(labL, labA, labB);

	return [ lchL, lchC, lchH ];
}

function lch2hwb(lchL, lchC, lchH, fallbackhue) {
	const [ labL, labA, labB ] = lch2lab(lchL, lchC, lchH);
	const [ xyzX, xyzY, xyzZ ] = lab2xyz(labL, labA, labB);
	const [ rgbR, rgbG, rgbB ] = xyz2rgb(xyzX, xyzY, xyzZ);
	const [ hwbH, hwbW, hwbB ] = rgb2hwb(rgbR, rgbG, rgbB, fallbackhue);

	return [ hwbH, hwbW, hwbB ];
}

/* Convert between HWB and XYZ
/* ========================================================================== */

function hwb2xyz(hwbH, hwbW, hwbB) {
	const [ rgbR, rgbG, rgbB ] = hwb2rgb(hwbH, hwbW, hwbB);
	const [ xyzX, xyzY, xyzZ ] = rgb2xyz(rgbR, rgbG, rgbB);

	return [ xyzX, xyzY, xyzZ ];
}

function xyz2hwb(xyzX, xyzY, xyzZ, fallbackhue) {
	const [ rgbR, rgbG, rgbB ] = xyz2rgb(xyzX, xyzY, xyzZ);
	const [ hwbH, hwbW, hwbB ] = rgb2hwb(rgbR, rgbG, rgbB, fallbackhue);

	return [ hwbH, hwbW, hwbB ];
}

/* Convert between HSV and Lab
/* ========================================================================== */

function hsv2lab(hsvH, hsvS, hsvV) {
	const [ rgbR, rgbG, rgbB ] = hsv2rgb(hsvH, hsvS, hsvV);
	const [ xyzX, xyzY, xyzZ ] = rgb2xyz(rgbR, rgbG, rgbB);
	const [ labL, labA, labB ] = xyz2lab(xyzX, xyzY, xyzZ);

	return [ labL, labA, labB ];
}

function lab2hsv(labL, labA, labB, fallbackhue) {
	const [ xyzX, xyzY, xyzZ ] = lab2xyz(labL, labA, labB);
	const [ rgbR, rgbG, rgbB ] = xyz2rgb(xyzX, xyzY, xyzZ);
	const [ hsvH, hsvS, hsvV ] = rgb2hsv(rgbR, rgbG, rgbB, fallbackhue);

	return [ hsvH, hsvS, hsvV ];
}

/* Convert between HSV and LCH
/* ========================================================================== */

function hsv2lch(hsvH, hsvS, hsvV) {
	const [ rgbR, rgbG, rgbB ] = hsv2rgb(hsvH, hsvS, hsvV);
	const [ xyzX, xyzY, xyzZ ] = rgb2xyz(rgbR, rgbG, rgbB);
	const [ labL, labA, labB ] = xyz2lab(xyzX, xyzY, xyzZ);
	const [ lchL, lchC, lchH ] = lab2lch(labL, labA, labB);

	return [ lchL, lchC, lchH ];
}

function lch2hsv(lchL, lchC, lchH, fallbackhue) {
	const [ labL, labA, labB ] = lch2lab(lchL, lchC, lchH);
	const [ xyzX, xyzY, xyzZ ] = lab2xyz(labL, labA, labB);
	const [ rgbR, rgbG, rgbB ] = xyz2rgb(xyzX, xyzY, xyzZ);
	const [ hsvH, hsvS, hsvV ] = rgb2hsv(rgbR, rgbG, rgbB, fallbackhue);

	return [ hsvH, hsvS, hsvV ];
}

/* Convert between HSV and XYZ
/* ========================================================================== */

function hsv2xyz(hsvH, hsvS, hsvV) {
	const [ rgbR, rgbG, rgbB ] = hsv2rgb(hsvH, hsvS, hsvV);
	const [ xyzX, xyzY, xyzZ ] = rgb2xyz(rgbR, rgbG, rgbB);

	return [ xyzX, xyzY, xyzZ ];
}

function xyz2hsv(xyzX, xyzY, xyzZ, fallbackhue) {
	const [ rgbR, rgbG, rgbB ] = xyz2rgb(xyzX, xyzY, xyzZ);
	const [ hsvH, hsvS, hsvV ] = rgb2hsv(rgbR, rgbG, rgbB, fallbackhue);

	return [ hsvH, hsvS, hsvV ];
}

/* Convert between XYZ and LCH
/* ========================================================================== */

function xyz2lch(xyzX, xyzY, xyzZ) {
	const [ labL, labA, labB ] = xyz2lab(xyzX, xyzY, xyzZ);
	const [ lchL, lchC, lchH ] = lab2lch(labL, labA, labB);

	return [ lchL, lchC, lchH ];
}

function lch2xyz(lchL, lchC, lchH) {
	const [ labL, labA, labB ] = lch2lab(lchL, lchC, lchH);
	const [ xyzX, xyzY, xyzZ ] = lab2xyz(labL, labA, labB);

	return [ xyzX, xyzY, xyzZ ];
}

/* All Conversions
/* ========================================================================== */

export {
	rgb2hsl,
	rgb2hwb,
	rgb2lab,
	rgb2lch,
	rgb2hsv,
	rgb2xyz,

	hsl2rgb,
	hsl2hwb,
	hsl2lab,
	hsl2lch,
	hsl2hsv,
	hsl2xyz,

	hwb2rgb,
	hwb2hsl,
	hwb2lab,
	hwb2lch,
	hwb2hsv,
	hwb2xyz,

	lab2rgb,
	lab2hsl,
	lab2hwb,
	lab2lch,
	lab2hsv,
	lab2xyz,

	lch2rgb,
	lch2hsl,
	lch2hwb,
	lch2lab,
	lch2hsv,
	lch2xyz,

	hsv2rgb,
	hsv2hsl,
	hsv2hwb,
	hsv2lab,
	hsv2lch,
	hsv2xyz,

	xyz2rgb,
	xyz2hsl,
	xyz2hwb,
	xyz2lab,
	xyz2lch,
	xyz2hsv,

	rgb2hue
};

export default {
	rgb2hsl,
	rgb2hwb,
	rgb2lab,
	rgb2lch,
	rgb2hsv,
	rgb2xyz,

	hsl2rgb,
	hsl2hwb,
	hsl2lab,
	hsl2lch,
	hsl2hsv,
	hsl2xyz,

	hwb2rgb,
	hwb2hsl,
	hwb2lab,
	hwb2lch,
	hwb2hsv,
	hwb2xyz,

	lab2rgb,
	lab2hsl,
	lab2hwb,
	lab2lch,
	lab2hsv,
	lab2xyz,

	lch2rgb,
	lch2hsl,
	lch2hwb,
	lch2lab,
	lch2hsv,
	lch2xyz,

	hsv2rgb,
	hsv2hsl,
	hsv2hwb,
	hsv2lab,
	hsv2lch,
	hsv2xyz,

	xyz2rgb,
	xyz2hsl,
	xyz2hwb,
	xyz2lab,
	xyz2lch,
	xyz2hsv,

	rgb2hue
};
