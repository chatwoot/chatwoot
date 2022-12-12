/* Convert between Lab and XYZ
/* ========================================================================== */

export function lab2lch(labL, labA, labB) {
	const [ lchC, lchH ] = [
		Math.sqrt(Math.pow(labA, 2) + Math.pow(labB, 2)), // convert to chroma
		Math.atan2(labB, labA) * 180 / Math.PI // convert to hue, in degrees
	];

	return [ labL, lchC, lchH ];
}

export function lch2lab(lchL, lchC, lchH) {
	// convert to Lab a and b from the polar form
	const [ labA, labB ] = [
		lchC * Math.cos(lchH * Math.PI / 180),
		lchC * Math.sin(lchH * Math.PI / 180)
	];

	return [ lchL, labA, labB ];
}

/*

References
----------

- https://www.w3.org/TR/css-color-4/#lch-to-lab
- https://www.w3.org/TR/css-color-4/#color-conversion-code

/* ========================================================================== */
