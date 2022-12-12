import { rgb2hue, rgb2whiteness, rgb2value } from './util';
import { hsl2rgb } from './rgb-hsl';

/* Convert between RGB and HWB
/* ========================================================================== */

export function rgb2hwb(rgbR, rgbG, rgbB, fallbackhue) {
	const hwbH = rgb2hue(rgbR, rgbG, rgbB, fallbackhue);
	const hwbW = rgb2whiteness(rgbR, rgbG, rgbB);
	const hwbV = rgb2value(rgbR, rgbG, rgbB);
	const hwbB = 100 - hwbV;

	return [hwbH, hwbW, hwbB];
}

export function hwb2rgb(hwbH, hwbW, hwbB, fallbackhue) {
	const [ rgbR, rgbG, rgbB ] = hsl2rgb(hwbH, 100, 50, fallbackhue).map(
		v => v * (100 - hwbW - hwbB) / 100 + hwbW
	);

	return [ rgbR, rgbG, rgbB ];
}

/*

References
----------

- https://www.w3.org/TR/css-color-4/#hwb-to-rgb
- http://alvyray.com/Papers/CG/hwb2rgb.htm

/* ========================================================================== */
