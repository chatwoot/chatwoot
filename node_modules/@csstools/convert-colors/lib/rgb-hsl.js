import { rgb2hue, rgb2value, rgb2whiteness, hue2rgb } from './util';

/* Convert between RGB and HSL
/* ========================================================================== */

export function rgb2hsl(rgbR, rgbG, rgbB, fallbackhue) {
	const hslH = rgb2hue(rgbR, rgbG, rgbB, fallbackhue);
	const hslV = rgb2value(rgbR, rgbG, rgbB);
	const hslW = rgb2whiteness(rgbR, rgbG, rgbB);

	// calculate value/whiteness delta
	const hslD = hslV - hslW;

	// calculate lightness
	const hslL = (hslV + hslW) / 2;

	// calculate saturation
	const hslS = hslD === 0 ? 0 : hslD / (100 - Math.abs(2 * hslL - 100)) * 100;

	return [ hslH, hslS, hslL ];
}

export function hsl2rgb(hslH, hslS, hslL) {
	// calcuate t2
	const t2 = hslL <= 50 ? hslL * (hslS + 100) / 100 : hslL + hslS - hslL * hslS / 100;

	// calcuate t1
	const t1 = hslL * 2 - t2;

	// calculate rgb
	const [ rgbR, rgbG, rgbB ] = [
		hue2rgb(t1, t2, hslH + 120),
		hue2rgb(t1, t2, hslH),
		hue2rgb(t1, t2, hslH - 120)
	];

	return [ rgbR, rgbG, rgbB ];
}

/*

References
----------

- https://www.w3.org/TR/css-color-3/#hsl-color
- https://www.w3.org/TR/css-color-4/#hsl-to-rgb
- https://www.rapidtables.com/convert/color/rgb-to-hsl.html
- https://www.rapidtables.com/convert/color/hsl-to-rgb.html

/* ========================================================================== */
