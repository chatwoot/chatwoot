import { matrix } from './util';

/* Convert between RGB and XYZ
/* ========================================================================== */

export function rgb2xyz(rgbR, rgbG, rgbB) {
	const [ lrgbR, lrgbB, lrgbG ] = [ rgbR, rgbG, rgbB ].map(
		v => v > 4.045 ? Math.pow((v + 5.5) / 105.5, 2.4) * 100 : v / 12.92
	);

	const [ xyzX, xyzY, xyzZ ] = matrix([ lrgbR, lrgbB, lrgbG ], [
		[0.4124564, 0.3575761, 0.1804375],
		[0.2126729, 0.7151522, 0.0721750],
		[0.0193339, 0.1191920, 0.9503041]
	]);

	return [ xyzX, xyzY, xyzZ ];
}

export function xyz2rgb(xyzX, xyzY, xyzZ) {
	const [ lrgbR, lrgbB, lrgbG ] = matrix([ xyzX, xyzY, xyzZ ], [
		[ 3.2404542, -1.5371385, -0.4985314],
		[-0.9692660,  1.8760108,  0.0415560],
		[ 0.0556434, -0.2040259,  1.0572252]
	]);

	const [ rgbR, rgbG, rgbB ] = [ lrgbR, lrgbB, lrgbG ].map(
		v => v > 0.31308 ? 1.055 * Math.pow(v / 100, 1 / 2.4) * 100 - 5.5 : 12.92 * v
	);

	return [ rgbR, rgbG, rgbB ];
}

/*

References
----------

- https://www.w3.org/TR/css-color-4/#rgb-to-lab
- https://www.w3.org/TR/css-color-4/#color-conversion-code

/* ========================================================================== */
