import { epsilon, kappa, wd50X, wd50Y, wd50Z, matrix } from './util';

/* Convert between Lab and XYZ
/* ========================================================================== */

export function lab2xyz(labL, labA, labB) {
	// compute f, starting with the luminance-related term
	const f2 = (labL + 16) / 116;
	const f1 = labA / 500 + f2;
	const f3 = f2 - labB / 200;

	// compute pre-scaled XYZ
	const [ initX, initY, initZ ] = [
		Math.pow(f1, 3) > epsilon ? Math.pow(f1, 3)                : (116 * f1 - 16) / kappa,
		labL > kappa * epsilon    ? Math.pow((labL + 16) / 116, 3) : labL / kappa,
		Math.pow(f3, 3) > epsilon ? Math.pow(f3, 3)                : (116 * f3 - 16) / kappa
	];

	const [ xyzX, xyzY, xyzZ ] = matrix(
		// compute XYZ by scaling pre-scaled XYZ by reference white
		[ initX * wd50X, initY * wd50Y, initZ * wd50Z ],
		// calculate D65 XYZ from D50 XYZ
		[
			[ 0.9555766, -0.0230393,  0.0631636],
			[-0.0282895,  1.0099416,  0.0210077],
			[ 0.0122982, -0.0204830,  1.3299098]
		]
	);

	return [ xyzX, xyzY, xyzZ ];
}

export function xyz2lab(xyzX, xyzY, xyzZ) {
	// calculate D50 XYZ from D65 XYZ
	const [ d50X, d50Y, d50Z ] = matrix([ xyzX, xyzY, xyzZ ], [
		[ 1.0478112,  0.0228866, -0.0501270],
		[ 0.0295424,  0.9904844, -0.0170491],
		[-0.0092345,  0.0150436,  0.7521316]
	]);

	// calculate f
	const [ f1, f2, f3 ] = [
		d50X / wd50X,
		d50Y / wd50Y,
		d50Z / wd50Z
	].map(
		value => value > epsilon ? Math.cbrt(value) : (kappa * value + 16) / 116
	);

	const [ labL, labA, labB ] = [
		116 * f2 - 16,
		500 * (f1 - f2),
		200 * (f2 - f3)
	];

	return [ labL, labA, labB ];
}

/*

References
----------

- https://www.w3.org/TR/css-color-4/#rgb-to-lab
- https://www.w3.org/TR/css-color-4/#color-conversion-code
- https://www.easyrgb.com/en/math.php

/* ========================================================================== */
