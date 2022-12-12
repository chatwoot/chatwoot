/* Convert between HSL and HSV
/* ========================================================================== */

export function hsl2hsv(hslH, hslS, hslL) {
	const hsv1 = hslS * (hslL < 50 ? hslL : 100 - hslL) / 100;
	const hsvS = hsv1 === 0 ? 0 : 2 * hsv1 / (hslL + hsv1) * 100;
	const hsvV = hslL + hsv1;

	return [ hslH, hsvS, hsvV ];
}

export function hsv2hsl(hsvH, hsvS, hsvV) {
	const hslL = (200 - hsvS) * hsvV / 100;

	const [ hslS, hslV ] = [
		hslL === 0 || hslL === 200 ? 0 : hsvS * hsvV / 100 / (hslL <= 100 ? hslL : 200 - hslL) * 100,
		hslL * 5 / 10
	];

	return [ hsvH, hslS, hslV ];
}

/*

References
----------

- https://gist.github.com/defims/0ca2ef8832833186ed396a2f8a204117

/* ========================================================================== */
