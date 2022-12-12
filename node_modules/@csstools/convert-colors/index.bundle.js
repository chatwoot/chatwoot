'use strict';

Object.defineProperty(exports, '__esModule', { value: true });

/* Convert between RGB and Hue
/* ========================================================================== */

function rgb2hue(rgbR, rgbG, rgbB) {
	var fallbackhue = arguments.length > 3 && arguments[3] !== undefined ? arguments[3] : 0;

	var value = rgb2value(rgbR, rgbG, rgbB);
	var whiteness = rgb2whiteness(rgbR, rgbG, rgbB);
	var delta = value - whiteness;

	if (delta) {
		// calculate segment
		var segment = value === rgbR ? (rgbG - rgbB) / delta : value === rgbG ? (rgbB - rgbR) / delta : (rgbR - rgbG) / delta;

		// calculate shift
		var shift = value === rgbR ? segment < 0 ? 360 / 60 : 0 / 60 : value === rgbG ? 120 / 60 : 240 / 60;

		// calculate hue
		var hue = (segment + shift) * 60;

		return hue;
	} else {
		// otherwise return the fallback hue
		return fallbackhue;
	}
}

function hue2rgb(t1, t2, hue) {
	// calculate the ranged hue
	var rhue = hue < 0 ? hue + 360 : hue > 360 ? hue - 360 : hue;

	// calculate the rgb value
	var rgb = rhue * 6 < 360 ? t1 + (t2 - t1) * rhue / 60 : rhue * 2 < 360 ? t2 : rhue * 3 < 720 ? t1 + (t2 - t1) * (240 - rhue) / 60 : t1;

	return rgb;
}

/* RGB tooling
/* ========================================================================== */

function rgb2value(rgbR, rgbG, rgbB) {
	var value = Math.max(rgbR, rgbG, rgbB);

	return value;
}

function rgb2whiteness(rgbR, rgbG, rgbB) {
	var whiteness = Math.min(rgbR, rgbG, rgbB);

	return whiteness;
}

/* Math matrix
/* ========================================================================== */

function matrix(params, mats) {
	return mats.map(function (mat) {
		return mat.reduce(function (acc, value, index) {
			return acc + params[index] * value;
		}, 0);
	});
}

/* D50 reference white
/* ========================================================================== */

var wd50X = 96.42;
var wd50Y = 100;
var wd50Z = 82.49;

var epsilon = Math.pow(6, 3) / Math.pow(29, 3);

/* Kappa
/* ========================================================================== */

var kappa = Math.pow(29, 3) / Math.pow(3, 3);

/* Convert between RGB and HSL
/* ========================================================================== */

function rgb2hsl(rgbR, rgbG, rgbB, fallbackhue) {
	var hslH = rgb2hue(rgbR, rgbG, rgbB, fallbackhue);
	var hslV = rgb2value(rgbR, rgbG, rgbB);
	var hslW = rgb2whiteness(rgbR, rgbG, rgbB);

	// calculate value/whiteness delta
	var hslD = hslV - hslW;

	// calculate lightness
	var hslL = (hslV + hslW) / 2;

	// calculate saturation
	var hslS = hslD === 0 ? 0 : hslD / (100 - Math.abs(2 * hslL - 100)) * 100;

	return [hslH, hslS, hslL];
}

function hsl2rgb(hslH, hslS, hslL) {
	// calcuate t2
	var t2 = hslL <= 50 ? hslL * (hslS + 100) / 100 : hslL + hslS - hslL * hslS / 100;

	// calcuate t1
	var t1 = hslL * 2 - t2;

	// calculate rgb
	var _ref = [hue2rgb(t1, t2, hslH + 120), hue2rgb(t1, t2, hslH), hue2rgb(t1, t2, hslH - 120)],
	    rgbR = _ref[0],
	    rgbG = _ref[1],
	    rgbB = _ref[2];


	return [rgbR, rgbG, rgbB];
}

/*

References
----------

- https://www.w3.org/TR/css-color-3/#hsl-color
- https://www.w3.org/TR/css-color-4/#hsl-to-rgb
- https://www.rapidtables.com/convert/color/rgb-to-hsl.html
- https://www.rapidtables.com/convert/color/hsl-to-rgb.html

/* ========================================================================== */

var _slicedToArray = function () { function sliceIterator(arr, i) { var _arr = []; var _n = true; var _d = false; var _e = undefined; try { for (var _i = arr[Symbol.iterator](), _s; !(_n = (_s = _i.next()).done); _n = true) { _arr.push(_s.value); if (i && _arr.length === i) break; } } catch (err) { _d = true; _e = err; } finally { try { if (!_n && _i["return"]) _i["return"](); } finally { if (_d) throw _e; } } return _arr; } return function (arr, i) { if (Array.isArray(arr)) { return arr; } else if (Symbol.iterator in Object(arr)) { return sliceIterator(arr, i); } else { throw new TypeError("Invalid attempt to destructure non-iterable instance"); } }; }();

/* Convert between RGB and HWB
/* ========================================================================== */

function rgb2hwb(rgbR, rgbG, rgbB, fallbackhue) {
	var hwbH = rgb2hue(rgbR, rgbG, rgbB, fallbackhue);
	var hwbW = rgb2whiteness(rgbR, rgbG, rgbB);
	var hwbV = rgb2value(rgbR, rgbG, rgbB);
	var hwbB = 100 - hwbV;

	return [hwbH, hwbW, hwbB];
}

function hwb2rgb(hwbH, hwbW, hwbB, fallbackhue) {
	var _hsl2rgb$map = hsl2rgb(hwbH, 100, 50, fallbackhue).map(function (v) {
		return v * (100 - hwbW - hwbB) / 100 + hwbW;
	}),
	    _hsl2rgb$map2 = _slicedToArray(_hsl2rgb$map, 3),
	    rgbR = _hsl2rgb$map2[0],
	    rgbG = _hsl2rgb$map2[1],
	    rgbB = _hsl2rgb$map2[2];

	return [rgbR, rgbG, rgbB];
}

/*

References
----------

- https://www.w3.org/TR/css-color-4/#hwb-to-rgb
- http://alvyray.com/Papers/CG/hwb2rgb.htm

/* ========================================================================== */

var _slicedToArray$1 = function () { function sliceIterator(arr, i) { var _arr = []; var _n = true; var _d = false; var _e = undefined; try { for (var _i = arr[Symbol.iterator](), _s; !(_n = (_s = _i.next()).done); _n = true) { _arr.push(_s.value); if (i && _arr.length === i) break; } } catch (err) { _d = true; _e = err; } finally { try { if (!_n && _i["return"]) _i["return"](); } finally { if (_d) throw _e; } } return _arr; } return function (arr, i) { if (Array.isArray(arr)) { return arr; } else if (Symbol.iterator in Object(arr)) { return sliceIterator(arr, i); } else { throw new TypeError("Invalid attempt to destructure non-iterable instance"); } }; }();

/* Convert between RGB and HSV
/* ========================================================================== */

function rgb2hsv(rgbR, rgbG, rgbB, fallbackhue) {
	var hsvV = rgb2value(rgbR, rgbG, rgbB);
	var hsvW = rgb2whiteness(rgbR, rgbG, rgbB);
	var hsvH = rgb2hue(rgbR, rgbG, rgbB, fallbackhue);

	// calculate saturation
	var hsvS = hsvV === hsvW ? 0 : (hsvV - hsvW) / hsvV * 100;

	return [hsvH, hsvS, hsvV];
}

function hsv2rgb(hsvH, hsvS, hsvV) {
	var rgbI = Math.floor(hsvH / 60);

	// calculate rgb parts
	var rgbF = hsvH / 60 - rgbI & 1 ? hsvH / 60 - rgbI : 1 - hsvH / 60 - rgbI;
	var rgbM = hsvV * (100 - hsvS) / 100;
	var rgbN = hsvV * (100 - hsvS * rgbF) / 100;

	var _ref = rgbI === 5 ? [hsvV, rgbM, rgbN] : rgbI === 4 ? [rgbN, rgbM, hsvV] : rgbI === 3 ? [rgbM, rgbN, hsvV] : rgbI === 2 ? [rgbM, hsvV, rgbN] : rgbI === 1 ? [rgbN, hsvV, rgbM] : [hsvV, rgbN, rgbM],
	    _ref2 = _slicedToArray$1(_ref, 3),
	    rgbR = _ref2[0],
	    rgbG = _ref2[1],
	    rgbB = _ref2[2];

	return [rgbR, rgbG, rgbB];
}

/*

References
----------

- http://alvyray.com/Papers/CG/hsv2rgb.htm

/* ========================================================================== */

var _slicedToArray$2 = function () { function sliceIterator(arr, i) { var _arr = []; var _n = true; var _d = false; var _e = undefined; try { for (var _i = arr[Symbol.iterator](), _s; !(_n = (_s = _i.next()).done); _n = true) { _arr.push(_s.value); if (i && _arr.length === i) break; } } catch (err) { _d = true; _e = err; } finally { try { if (!_n && _i["return"]) _i["return"](); } finally { if (_d) throw _e; } } return _arr; } return function (arr, i) { if (Array.isArray(arr)) { return arr; } else if (Symbol.iterator in Object(arr)) { return sliceIterator(arr, i); } else { throw new TypeError("Invalid attempt to destructure non-iterable instance"); } }; }();

/* Convert between RGB and XYZ
/* ========================================================================== */

function rgb2xyz(rgbR, rgbG, rgbB) {
	var _map = [rgbR, rgbG, rgbB].map(function (v) {
		return v > 4.045 ? Math.pow((v + 5.5) / 105.5, 2.4) * 100 : v / 12.92;
	}),
	    _map2 = _slicedToArray$2(_map, 3),
	    lrgbR = _map2[0],
	    lrgbB = _map2[1],
	    lrgbG = _map2[2];

	var _matrix = matrix([lrgbR, lrgbB, lrgbG], [[0.4124564, 0.3575761, 0.1804375], [0.2126729, 0.7151522, 0.0721750], [0.0193339, 0.1191920, 0.9503041]]),
	    _matrix2 = _slicedToArray$2(_matrix, 3),
	    xyzX = _matrix2[0],
	    xyzY = _matrix2[1],
	    xyzZ = _matrix2[2];

	return [xyzX, xyzY, xyzZ];
}

function xyz2rgb(xyzX, xyzY, xyzZ) {
	var _matrix3 = matrix([xyzX, xyzY, xyzZ], [[3.2404542, -1.5371385, -0.4985314], [-0.9692660, 1.8760108, 0.0415560], [0.0556434, -0.2040259, 1.0572252]]),
	    _matrix4 = _slicedToArray$2(_matrix3, 3),
	    lrgbR = _matrix4[0],
	    lrgbB = _matrix4[1],
	    lrgbG = _matrix4[2];

	var _map3 = [lrgbR, lrgbB, lrgbG].map(function (v) {
		return v > 0.31308 ? 1.055 * Math.pow(v / 100, 1 / 2.4) * 100 - 5.5 : 12.92 * v;
	}),
	    _map4 = _slicedToArray$2(_map3, 3),
	    rgbR = _map4[0],
	    rgbG = _map4[1],
	    rgbB = _map4[2];

	return [rgbR, rgbG, rgbB];
}

/*

References
----------

- https://www.w3.org/TR/css-color-4/#rgb-to-lab
- https://www.w3.org/TR/css-color-4/#color-conversion-code

/* ========================================================================== */

/* Convert between HSL and HSV
/* ========================================================================== */

function hsl2hsv(hslH, hslS, hslL) {
	var hsv1 = hslS * (hslL < 50 ? hslL : 100 - hslL) / 100;
	var hsvS = hsv1 === 0 ? 0 : 2 * hsv1 / (hslL + hsv1) * 100;
	var hsvV = hslL + hsv1;

	return [hslH, hsvS, hsvV];
}

function hsv2hsl(hsvH, hsvS, hsvV) {
	var hslL = (200 - hsvS) * hsvV / 100;

	var hslS = hslL === 0 || hslL === 200 ? 0 : hsvS * hsvV / 100 / (hslL <= 100 ? hslL : 200 - hslL) * 100,
	    hslV = hslL * 5 / 10;


	return [hsvH, hslS, hslV];
}

/*

References
----------

- https://gist.github.com/defims/0ca2ef8832833186ed396a2f8a204117

/* ========================================================================== */

/* Convert between HWB and HSV
/* ========================================================================== */

function hwb2hsv(hwbH, hwbW, hwbB) {
	var hsvH = hwbH,
	    hsvS = hwbB === 100 ? 0 : 100 - hwbW / (100 - hwbB) * 100,
	    hsvV = 100 - hwbB;


	return [hsvH, hsvS, hsvV];
}

function hsv2hwb(hsvH, hsvS, hsvV) {
	var hwbH = hsvH,
	    hwbW = (100 - hsvS) * hsvV / 100,
	    hwbB = 100 - hsvV;


	return [hwbH, hwbW, hwbB];
}

/*

References
----------

- https://en.wikipedia.org/wiki/HWB_color_model#Converting_to_and_from_HSV

/* ========================================================================== */

var _slicedToArray$3 = function () { function sliceIterator(arr, i) { var _arr = []; var _n = true; var _d = false; var _e = undefined; try { for (var _i = arr[Symbol.iterator](), _s; !(_n = (_s = _i.next()).done); _n = true) { _arr.push(_s.value); if (i && _arr.length === i) break; } } catch (err) { _d = true; _e = err; } finally { try { if (!_n && _i["return"]) _i["return"](); } finally { if (_d) throw _e; } } return _arr; } return function (arr, i) { if (Array.isArray(arr)) { return arr; } else if (Symbol.iterator in Object(arr)) { return sliceIterator(arr, i); } else { throw new TypeError("Invalid attempt to destructure non-iterable instance"); } }; }();

/* Convert between Lab and XYZ
/* ========================================================================== */

function lab2xyz(labL, labA, labB) {
	// compute f, starting with the luminance-related term
	var f2 = (labL + 16) / 116;
	var f1 = labA / 500 + f2;
	var f3 = f2 - labB / 200;

	// compute pre-scaled XYZ
	var initX = Math.pow(f1, 3) > epsilon ? Math.pow(f1, 3) : (116 * f1 - 16) / kappa,
	    initY = labL > kappa * epsilon ? Math.pow((labL + 16) / 116, 3) : labL / kappa,
	    initZ = Math.pow(f3, 3) > epsilon ? Math.pow(f3, 3) : (116 * f3 - 16) / kappa;

	var _matrix = matrix(
	// compute XYZ by scaling pre-scaled XYZ by reference white
	[initX * wd50X, initY * wd50Y, initZ * wd50Z],
	// calculate D65 XYZ from D50 XYZ
	[[0.9555766, -0.0230393, 0.0631636], [-0.0282895, 1.0099416, 0.0210077], [0.0122982, -0.0204830, 1.3299098]]),
	    _matrix2 = _slicedToArray$3(_matrix, 3),
	    xyzX = _matrix2[0],
	    xyzY = _matrix2[1],
	    xyzZ = _matrix2[2];

	return [xyzX, xyzY, xyzZ];
}

function xyz2lab(xyzX, xyzY, xyzZ) {
	// calculate D50 XYZ from D65 XYZ
	var _matrix3 = matrix([xyzX, xyzY, xyzZ], [[1.0478112, 0.0228866, -0.0501270], [0.0295424, 0.9904844, -0.0170491], [-0.0092345, 0.0150436, 0.7521316]]),
	    _matrix4 = _slicedToArray$3(_matrix3, 3),
	    d50X = _matrix4[0],
	    d50Y = _matrix4[1],
	    d50Z = _matrix4[2];

	// calculate f


	var _map = [d50X / wd50X, d50Y / wd50Y, d50Z / wd50Z].map(function (value) {
		return value > epsilon ? Math.cbrt(value) : (kappa * value + 16) / 116;
	}),
	    _map2 = _slicedToArray$3(_map, 3),
	    f1 = _map2[0],
	    f2 = _map2[1],
	    f3 = _map2[2];

	var labL = 116 * f2 - 16,
	    labA = 500 * (f1 - f2),
	    labB = 200 * (f2 - f3);


	return [labL, labA, labB];
}

/*

References
----------

- https://www.w3.org/TR/css-color-4/#rgb-to-lab
- https://www.w3.org/TR/css-color-4/#color-conversion-code
- https://www.easyrgb.com/en/math.php

/* ========================================================================== */

/* Convert between Lab and XYZ
/* ========================================================================== */

function lab2lch(labL, labA, labB) {
	var _ref = [Math.sqrt(Math.pow(labA, 2) + Math.pow(labB, 2)), // convert to chroma
	Math.atan2(labB, labA) * 180 / Math.PI // convert to hue, in degrees
	],
	    lchC = _ref[0],
	    lchH = _ref[1];


	return [labL, lchC, lchH];
}

function lch2lab(lchL, lchC, lchH) {
	// convert to Lab a and b from the polar form
	var labA = lchC * Math.cos(lchH * Math.PI / 180),
	    labB = lchC * Math.sin(lchH * Math.PI / 180);


	return [lchL, labA, labB];
}

/*

References
----------

- https://www.w3.org/TR/css-color-4/#lch-to-lab
- https://www.w3.org/TR/css-color-4/#color-conversion-code

/* ========================================================================== */

var _slicedToArray$4 = function () { function sliceIterator(arr, i) { var _arr = []; var _n = true; var _d = false; var _e = undefined; try { for (var _i = arr[Symbol.iterator](), _s; !(_n = (_s = _i.next()).done); _n = true) { _arr.push(_s.value); if (i && _arr.length === i) break; } } catch (err) { _d = true; _e = err; } finally { try { if (!_n && _i["return"]) _i["return"](); } finally { if (_d) throw _e; } } return _arr; } return function (arr, i) { if (Array.isArray(arr)) { return arr; } else if (Symbol.iterator in Object(arr)) { return sliceIterator(arr, i); } else { throw new TypeError("Invalid attempt to destructure non-iterable instance"); } }; }();

/* Convert between RGB and Lab
/* ========================================================================== */

function rgb2lab(rgbR, rgbG, rgbB) {
	var _rgb2xyz = rgb2xyz(rgbR, rgbG, rgbB),
	    _rgb2xyz2 = _slicedToArray$4(_rgb2xyz, 3),
	    xyzX = _rgb2xyz2[0],
	    xyzY = _rgb2xyz2[1],
	    xyzZ = _rgb2xyz2[2];

	var _xyz2lab = xyz2lab(xyzX, xyzY, xyzZ),
	    _xyz2lab2 = _slicedToArray$4(_xyz2lab, 3),
	    labL = _xyz2lab2[0],
	    labA = _xyz2lab2[1],
	    labB = _xyz2lab2[2];

	return [labL, labA, labB];
}

function lab2rgb(labL, labA, labB) {
	var _lab2xyz = lab2xyz(labL, labA, labB),
	    _lab2xyz2 = _slicedToArray$4(_lab2xyz, 3),
	    xyzX = _lab2xyz2[0],
	    xyzY = _lab2xyz2[1],
	    xyzZ = _lab2xyz2[2];

	var _xyz2rgb = xyz2rgb(xyzX, xyzY, xyzZ),
	    _xyz2rgb2 = _slicedToArray$4(_xyz2rgb, 3),
	    rgbR = _xyz2rgb2[0],
	    rgbG = _xyz2rgb2[1],
	    rgbB = _xyz2rgb2[2];

	return [rgbR, rgbG, rgbB];
}

/* Convert between RGB and LCH
/* ========================================================================== */

function rgb2lch(rgbR, rgbG, rgbB) {
	var _rgb2xyz3 = rgb2xyz(rgbR, rgbG, rgbB),
	    _rgb2xyz4 = _slicedToArray$4(_rgb2xyz3, 3),
	    xyzX = _rgb2xyz4[0],
	    xyzY = _rgb2xyz4[1],
	    xyzZ = _rgb2xyz4[2];

	var _xyz2lab3 = xyz2lab(xyzX, xyzY, xyzZ),
	    _xyz2lab4 = _slicedToArray$4(_xyz2lab3, 3),
	    labL = _xyz2lab4[0],
	    labA = _xyz2lab4[1],
	    labB = _xyz2lab4[2];

	var _lab2lch = lab2lch(labL, labA, labB),
	    _lab2lch2 = _slicedToArray$4(_lab2lch, 3),
	    lchL = _lab2lch2[0],
	    lchC = _lab2lch2[1],
	    lchH = _lab2lch2[2];

	return [lchL, lchC, lchH];
}

function lch2rgb(lchL, lchC, lchH) {
	var _lch2lab = lch2lab(lchL, lchC, lchH),
	    _lch2lab2 = _slicedToArray$4(_lch2lab, 3),
	    labL = _lch2lab2[0],
	    labA = _lch2lab2[1],
	    labB = _lch2lab2[2];

	var _lab2xyz3 = lab2xyz(labL, labA, labB),
	    _lab2xyz4 = _slicedToArray$4(_lab2xyz3, 3),
	    xyzX = _lab2xyz4[0],
	    xyzY = _lab2xyz4[1],
	    xyzZ = _lab2xyz4[2];

	var _xyz2rgb3 = xyz2rgb(xyzX, xyzY, xyzZ),
	    _xyz2rgb4 = _slicedToArray$4(_xyz2rgb3, 3),
	    rgbR = _xyz2rgb4[0],
	    rgbG = _xyz2rgb4[1],
	    rgbB = _xyz2rgb4[2];

	return [rgbR, rgbG, rgbB];
}

/* Convert between HSL and HWB
/* ========================================================================== */

function hwb2hsl(hwbH, hwbW, hwbB) {
	var _hwb2hsv = hwb2hsv(hwbH, hwbW, hwbB),
	    _hwb2hsv2 = _slicedToArray$4(_hwb2hsv, 3),
	    hsvH = _hwb2hsv2[0],
	    hsvS = _hwb2hsv2[1],
	    hsvV = _hwb2hsv2[2];

	var _hsv2hsl = hsv2hsl(hsvH, hsvS, hsvV),
	    _hsv2hsl2 = _slicedToArray$4(_hsv2hsl, 3),
	    hslH = _hsv2hsl2[0],
	    hslS = _hsv2hsl2[1],
	    hslL = _hsv2hsl2[2];

	return [hslH, hslS, hslL];
}

function hsl2hwb(hslH, hslS, hslL) {
	var _hsl2hsv = hsl2hsv(hslH, hslS, hslL),
	    _hsl2hsv2 = _slicedToArray$4(_hsl2hsv, 3),
	    hsvS = _hsl2hsv2[1],
	    hsvV = _hsl2hsv2[2];

	var _hsv2hwb = hsv2hwb(hslH, hsvS, hsvV),
	    _hsv2hwb2 = _slicedToArray$4(_hsv2hwb, 3),
	    hwbW = _hsv2hwb2[1],
	    hwbB = _hsv2hwb2[2];

	return [hslH, hwbW, hwbB];
}

/* Convert between HSL and Lab
/* ========================================================================== */

function hsl2lab(hslH, hslS, hslL) {
	var _hsl2rgb = hsl2rgb(hslH, hslS, hslL),
	    _hsl2rgb2 = _slicedToArray$4(_hsl2rgb, 3),
	    rgbR = _hsl2rgb2[0],
	    rgbG = _hsl2rgb2[1],
	    rgbB = _hsl2rgb2[2];

	var _rgb2xyz5 = rgb2xyz(rgbR, rgbG, rgbB),
	    _rgb2xyz6 = _slicedToArray$4(_rgb2xyz5, 3),
	    xyzX = _rgb2xyz6[0],
	    xyzY = _rgb2xyz6[1],
	    xyzZ = _rgb2xyz6[2];

	var _xyz2lab5 = xyz2lab(xyzX, xyzY, xyzZ),
	    _xyz2lab6 = _slicedToArray$4(_xyz2lab5, 3),
	    labL = _xyz2lab6[0],
	    labA = _xyz2lab6[1],
	    labB = _xyz2lab6[2];

	return [labL, labA, labB];
}

function lab2hsl(labL, labA, labB, fallbackhue) {
	var _lab2xyz5 = lab2xyz(labL, labA, labB),
	    _lab2xyz6 = _slicedToArray$4(_lab2xyz5, 3),
	    xyzX = _lab2xyz6[0],
	    xyzY = _lab2xyz6[1],
	    xyzZ = _lab2xyz6[2];

	var _xyz2rgb5 = xyz2rgb(xyzX, xyzY, xyzZ),
	    _xyz2rgb6 = _slicedToArray$4(_xyz2rgb5, 3),
	    rgbR = _xyz2rgb6[0],
	    rgbG = _xyz2rgb6[1],
	    rgbB = _xyz2rgb6[2];

	var _rgb2hsl = rgb2hsl(rgbR, rgbG, rgbB, fallbackhue),
	    _rgb2hsl2 = _slicedToArray$4(_rgb2hsl, 3),
	    hslH = _rgb2hsl2[0],
	    hslS = _rgb2hsl2[1],
	    hslL = _rgb2hsl2[2];

	return [hslH, hslS, hslL];
}

/* Convert between HSL and LCH
/* ========================================================================== */

function hsl2lch(hslH, hslS, hslL) {
	var _hsl2rgb3 = hsl2rgb(hslH, hslS, hslL),
	    _hsl2rgb4 = _slicedToArray$4(_hsl2rgb3, 3),
	    rgbR = _hsl2rgb4[0],
	    rgbG = _hsl2rgb4[1],
	    rgbB = _hsl2rgb4[2];

	var _rgb2xyz7 = rgb2xyz(rgbR, rgbG, rgbB),
	    _rgb2xyz8 = _slicedToArray$4(_rgb2xyz7, 3),
	    xyzX = _rgb2xyz8[0],
	    xyzY = _rgb2xyz8[1],
	    xyzZ = _rgb2xyz8[2];

	var _xyz2lab7 = xyz2lab(xyzX, xyzY, xyzZ),
	    _xyz2lab8 = _slicedToArray$4(_xyz2lab7, 3),
	    labL = _xyz2lab8[0],
	    labA = _xyz2lab8[1],
	    labB = _xyz2lab8[2];

	var _lab2lch3 = lab2lch(labL, labA, labB),
	    _lab2lch4 = _slicedToArray$4(_lab2lch3, 3),
	    lchL = _lab2lch4[0],
	    lchC = _lab2lch4[1],
	    lchH = _lab2lch4[2];

	return [lchL, lchC, lchH];
}

function lch2hsl(lchL, lchC, lchH, fallbackhue) {
	var _lch2lab3 = lch2lab(lchL, lchC, lchH),
	    _lch2lab4 = _slicedToArray$4(_lch2lab3, 3),
	    labL = _lch2lab4[0],
	    labA = _lch2lab4[1],
	    labB = _lch2lab4[2];

	var _lab2xyz7 = lab2xyz(labL, labA, labB),
	    _lab2xyz8 = _slicedToArray$4(_lab2xyz7, 3),
	    xyzX = _lab2xyz8[0],
	    xyzY = _lab2xyz8[1],
	    xyzZ = _lab2xyz8[2];

	var _xyz2rgb7 = xyz2rgb(xyzX, xyzY, xyzZ),
	    _xyz2rgb8 = _slicedToArray$4(_xyz2rgb7, 3),
	    rgbR = _xyz2rgb8[0],
	    rgbG = _xyz2rgb8[1],
	    rgbB = _xyz2rgb8[2];

	var _rgb2hsl3 = rgb2hsl(rgbR, rgbG, rgbB, fallbackhue),
	    _rgb2hsl4 = _slicedToArray$4(_rgb2hsl3, 3),
	    hslH = _rgb2hsl4[0],
	    hslS = _rgb2hsl4[1],
	    hslL = _rgb2hsl4[2];

	return [hslH, hslS, hslL];
}

/* Convert between HSL and XYZ
/* ========================================================================== */

function hsl2xyz(hslH, hslS, hslL) {
	var _hsl2rgb5 = hsl2rgb(hslH, hslS, hslL),
	    _hsl2rgb6 = _slicedToArray$4(_hsl2rgb5, 3),
	    rgbR = _hsl2rgb6[0],
	    rgbG = _hsl2rgb6[1],
	    rgbB = _hsl2rgb6[2];

	var _rgb2xyz9 = rgb2xyz(rgbR, rgbG, rgbB),
	    _rgb2xyz10 = _slicedToArray$4(_rgb2xyz9, 3),
	    xyzX = _rgb2xyz10[0],
	    xyzY = _rgb2xyz10[1],
	    xyzZ = _rgb2xyz10[2];

	return [xyzX, xyzY, xyzZ];
}

function xyz2hsl(xyzX, xyzY, xyzZ, fallbackhue) {
	var _xyz2rgb9 = xyz2rgb(xyzX, xyzY, xyzZ),
	    _xyz2rgb10 = _slicedToArray$4(_xyz2rgb9, 3),
	    rgbR = _xyz2rgb10[0],
	    rgbG = _xyz2rgb10[1],
	    rgbB = _xyz2rgb10[2];

	var _rgb2hsl5 = rgb2hsl(rgbR, rgbG, rgbB, fallbackhue),
	    _rgb2hsl6 = _slicedToArray$4(_rgb2hsl5, 3),
	    hslH = _rgb2hsl6[0],
	    hslS = _rgb2hsl6[1],
	    hslL = _rgb2hsl6[2];

	return [hslH, hslS, hslL];
}

/* Convert between HWB and Lab
/* ========================================================================== */

function hwb2lab(hwbH, hwbW, hwbB) {
	var _hwb2rgb = hwb2rgb(hwbH, hwbW, hwbB),
	    _hwb2rgb2 = _slicedToArray$4(_hwb2rgb, 3),
	    rgbR = _hwb2rgb2[0],
	    rgbG = _hwb2rgb2[1],
	    rgbB = _hwb2rgb2[2];

	var _rgb2xyz11 = rgb2xyz(rgbR, rgbG, rgbB),
	    _rgb2xyz12 = _slicedToArray$4(_rgb2xyz11, 3),
	    xyzX = _rgb2xyz12[0],
	    xyzY = _rgb2xyz12[1],
	    xyzZ = _rgb2xyz12[2];

	var _xyz2lab9 = xyz2lab(xyzX, xyzY, xyzZ),
	    _xyz2lab10 = _slicedToArray$4(_xyz2lab9, 3),
	    labL = _xyz2lab10[0],
	    labA = _xyz2lab10[1],
	    labB = _xyz2lab10[2];

	return [labL, labA, labB];
}

function lab2hwb(labL, labA, labB, fallbackhue) {
	var _lab2xyz9 = lab2xyz(labL, labA, labB),
	    _lab2xyz10 = _slicedToArray$4(_lab2xyz9, 3),
	    xyzX = _lab2xyz10[0],
	    xyzY = _lab2xyz10[1],
	    xyzZ = _lab2xyz10[2];

	var _xyz2rgb11 = xyz2rgb(xyzX, xyzY, xyzZ),
	    _xyz2rgb12 = _slicedToArray$4(_xyz2rgb11, 3),
	    rgbR = _xyz2rgb12[0],
	    rgbG = _xyz2rgb12[1],
	    rgbB = _xyz2rgb12[2];

	var _rgb2hwb = rgb2hwb(rgbR, rgbG, rgbB, fallbackhue),
	    _rgb2hwb2 = _slicedToArray$4(_rgb2hwb, 3),
	    hwbH = _rgb2hwb2[0],
	    hwbW = _rgb2hwb2[1],
	    hwbB = _rgb2hwb2[2];

	return [hwbH, hwbW, hwbB];
}

/* Convert between HWB and LCH
/* ========================================================================== */

function hwb2lch(hwbH, hwbW, hwbB) {
	var _hwb2rgb3 = hwb2rgb(hwbH, hwbW, hwbB),
	    _hwb2rgb4 = _slicedToArray$4(_hwb2rgb3, 3),
	    rgbR = _hwb2rgb4[0],
	    rgbG = _hwb2rgb4[1],
	    rgbB = _hwb2rgb4[2];

	var _rgb2xyz13 = rgb2xyz(rgbR, rgbG, rgbB),
	    _rgb2xyz14 = _slicedToArray$4(_rgb2xyz13, 3),
	    xyzX = _rgb2xyz14[0],
	    xyzY = _rgb2xyz14[1],
	    xyzZ = _rgb2xyz14[2];

	var _xyz2lab11 = xyz2lab(xyzX, xyzY, xyzZ),
	    _xyz2lab12 = _slicedToArray$4(_xyz2lab11, 3),
	    labL = _xyz2lab12[0],
	    labA = _xyz2lab12[1],
	    labB = _xyz2lab12[2];

	var _lab2lch5 = lab2lch(labL, labA, labB),
	    _lab2lch6 = _slicedToArray$4(_lab2lch5, 3),
	    lchL = _lab2lch6[0],
	    lchC = _lab2lch6[1],
	    lchH = _lab2lch6[2];

	return [lchL, lchC, lchH];
}

function lch2hwb(lchL, lchC, lchH, fallbackhue) {
	var _lch2lab5 = lch2lab(lchL, lchC, lchH),
	    _lch2lab6 = _slicedToArray$4(_lch2lab5, 3),
	    labL = _lch2lab6[0],
	    labA = _lch2lab6[1],
	    labB = _lch2lab6[2];

	var _lab2xyz11 = lab2xyz(labL, labA, labB),
	    _lab2xyz12 = _slicedToArray$4(_lab2xyz11, 3),
	    xyzX = _lab2xyz12[0],
	    xyzY = _lab2xyz12[1],
	    xyzZ = _lab2xyz12[2];

	var _xyz2rgb13 = xyz2rgb(xyzX, xyzY, xyzZ),
	    _xyz2rgb14 = _slicedToArray$4(_xyz2rgb13, 3),
	    rgbR = _xyz2rgb14[0],
	    rgbG = _xyz2rgb14[1],
	    rgbB = _xyz2rgb14[2];

	var _rgb2hwb3 = rgb2hwb(rgbR, rgbG, rgbB, fallbackhue),
	    _rgb2hwb4 = _slicedToArray$4(_rgb2hwb3, 3),
	    hwbH = _rgb2hwb4[0],
	    hwbW = _rgb2hwb4[1],
	    hwbB = _rgb2hwb4[2];

	return [hwbH, hwbW, hwbB];
}

/* Convert between HWB and XYZ
/* ========================================================================== */

function hwb2xyz(hwbH, hwbW, hwbB) {
	var _hwb2rgb5 = hwb2rgb(hwbH, hwbW, hwbB),
	    _hwb2rgb6 = _slicedToArray$4(_hwb2rgb5, 3),
	    rgbR = _hwb2rgb6[0],
	    rgbG = _hwb2rgb6[1],
	    rgbB = _hwb2rgb6[2];

	var _rgb2xyz15 = rgb2xyz(rgbR, rgbG, rgbB),
	    _rgb2xyz16 = _slicedToArray$4(_rgb2xyz15, 3),
	    xyzX = _rgb2xyz16[0],
	    xyzY = _rgb2xyz16[1],
	    xyzZ = _rgb2xyz16[2];

	return [xyzX, xyzY, xyzZ];
}

function xyz2hwb(xyzX, xyzY, xyzZ, fallbackhue) {
	var _xyz2rgb15 = xyz2rgb(xyzX, xyzY, xyzZ),
	    _xyz2rgb16 = _slicedToArray$4(_xyz2rgb15, 3),
	    rgbR = _xyz2rgb16[0],
	    rgbG = _xyz2rgb16[1],
	    rgbB = _xyz2rgb16[2];

	var _rgb2hwb5 = rgb2hwb(rgbR, rgbG, rgbB, fallbackhue),
	    _rgb2hwb6 = _slicedToArray$4(_rgb2hwb5, 3),
	    hwbH = _rgb2hwb6[0],
	    hwbW = _rgb2hwb6[1],
	    hwbB = _rgb2hwb6[2];

	return [hwbH, hwbW, hwbB];
}

/* Convert between HSV and Lab
/* ========================================================================== */

function hsv2lab(hsvH, hsvS, hsvV) {
	var _hsv2rgb = hsv2rgb(hsvH, hsvS, hsvV),
	    _hsv2rgb2 = _slicedToArray$4(_hsv2rgb, 3),
	    rgbR = _hsv2rgb2[0],
	    rgbG = _hsv2rgb2[1],
	    rgbB = _hsv2rgb2[2];

	var _rgb2xyz17 = rgb2xyz(rgbR, rgbG, rgbB),
	    _rgb2xyz18 = _slicedToArray$4(_rgb2xyz17, 3),
	    xyzX = _rgb2xyz18[0],
	    xyzY = _rgb2xyz18[1],
	    xyzZ = _rgb2xyz18[2];

	var _xyz2lab13 = xyz2lab(xyzX, xyzY, xyzZ),
	    _xyz2lab14 = _slicedToArray$4(_xyz2lab13, 3),
	    labL = _xyz2lab14[0],
	    labA = _xyz2lab14[1],
	    labB = _xyz2lab14[2];

	return [labL, labA, labB];
}

function lab2hsv(labL, labA, labB, fallbackhue) {
	var _lab2xyz13 = lab2xyz(labL, labA, labB),
	    _lab2xyz14 = _slicedToArray$4(_lab2xyz13, 3),
	    xyzX = _lab2xyz14[0],
	    xyzY = _lab2xyz14[1],
	    xyzZ = _lab2xyz14[2];

	var _xyz2rgb17 = xyz2rgb(xyzX, xyzY, xyzZ),
	    _xyz2rgb18 = _slicedToArray$4(_xyz2rgb17, 3),
	    rgbR = _xyz2rgb18[0],
	    rgbG = _xyz2rgb18[1],
	    rgbB = _xyz2rgb18[2];

	var _rgb2hsv = rgb2hsv(rgbR, rgbG, rgbB, fallbackhue),
	    _rgb2hsv2 = _slicedToArray$4(_rgb2hsv, 3),
	    hsvH = _rgb2hsv2[0],
	    hsvS = _rgb2hsv2[1],
	    hsvV = _rgb2hsv2[2];

	return [hsvH, hsvS, hsvV];
}

/* Convert between HSV and LCH
/* ========================================================================== */

function hsv2lch(hsvH, hsvS, hsvV) {
	var _hsv2rgb3 = hsv2rgb(hsvH, hsvS, hsvV),
	    _hsv2rgb4 = _slicedToArray$4(_hsv2rgb3, 3),
	    rgbR = _hsv2rgb4[0],
	    rgbG = _hsv2rgb4[1],
	    rgbB = _hsv2rgb4[2];

	var _rgb2xyz19 = rgb2xyz(rgbR, rgbG, rgbB),
	    _rgb2xyz20 = _slicedToArray$4(_rgb2xyz19, 3),
	    xyzX = _rgb2xyz20[0],
	    xyzY = _rgb2xyz20[1],
	    xyzZ = _rgb2xyz20[2];

	var _xyz2lab15 = xyz2lab(xyzX, xyzY, xyzZ),
	    _xyz2lab16 = _slicedToArray$4(_xyz2lab15, 3),
	    labL = _xyz2lab16[0],
	    labA = _xyz2lab16[1],
	    labB = _xyz2lab16[2];

	var _lab2lch7 = lab2lch(labL, labA, labB),
	    _lab2lch8 = _slicedToArray$4(_lab2lch7, 3),
	    lchL = _lab2lch8[0],
	    lchC = _lab2lch8[1],
	    lchH = _lab2lch8[2];

	return [lchL, lchC, lchH];
}

function lch2hsv(lchL, lchC, lchH, fallbackhue) {
	var _lch2lab7 = lch2lab(lchL, lchC, lchH),
	    _lch2lab8 = _slicedToArray$4(_lch2lab7, 3),
	    labL = _lch2lab8[0],
	    labA = _lch2lab8[1],
	    labB = _lch2lab8[2];

	var _lab2xyz15 = lab2xyz(labL, labA, labB),
	    _lab2xyz16 = _slicedToArray$4(_lab2xyz15, 3),
	    xyzX = _lab2xyz16[0],
	    xyzY = _lab2xyz16[1],
	    xyzZ = _lab2xyz16[2];

	var _xyz2rgb19 = xyz2rgb(xyzX, xyzY, xyzZ),
	    _xyz2rgb20 = _slicedToArray$4(_xyz2rgb19, 3),
	    rgbR = _xyz2rgb20[0],
	    rgbG = _xyz2rgb20[1],
	    rgbB = _xyz2rgb20[2];

	var _rgb2hsv3 = rgb2hsv(rgbR, rgbG, rgbB, fallbackhue),
	    _rgb2hsv4 = _slicedToArray$4(_rgb2hsv3, 3),
	    hsvH = _rgb2hsv4[0],
	    hsvS = _rgb2hsv4[1],
	    hsvV = _rgb2hsv4[2];

	return [hsvH, hsvS, hsvV];
}

/* Convert between HSV and XYZ
/* ========================================================================== */

function hsv2xyz(hsvH, hsvS, hsvV) {
	var _hsv2rgb5 = hsv2rgb(hsvH, hsvS, hsvV),
	    _hsv2rgb6 = _slicedToArray$4(_hsv2rgb5, 3),
	    rgbR = _hsv2rgb6[0],
	    rgbG = _hsv2rgb6[1],
	    rgbB = _hsv2rgb6[2];

	var _rgb2xyz21 = rgb2xyz(rgbR, rgbG, rgbB),
	    _rgb2xyz22 = _slicedToArray$4(_rgb2xyz21, 3),
	    xyzX = _rgb2xyz22[0],
	    xyzY = _rgb2xyz22[1],
	    xyzZ = _rgb2xyz22[2];

	return [xyzX, xyzY, xyzZ];
}

function xyz2hsv(xyzX, xyzY, xyzZ, fallbackhue) {
	var _xyz2rgb21 = xyz2rgb(xyzX, xyzY, xyzZ),
	    _xyz2rgb22 = _slicedToArray$4(_xyz2rgb21, 3),
	    rgbR = _xyz2rgb22[0],
	    rgbG = _xyz2rgb22[1],
	    rgbB = _xyz2rgb22[2];

	var _rgb2hsv5 = rgb2hsv(rgbR, rgbG, rgbB, fallbackhue),
	    _rgb2hsv6 = _slicedToArray$4(_rgb2hsv5, 3),
	    hsvH = _rgb2hsv6[0],
	    hsvS = _rgb2hsv6[1],
	    hsvV = _rgb2hsv6[2];

	return [hsvH, hsvS, hsvV];
}

/* Convert between XYZ and LCH
/* ========================================================================== */

function xyz2lch(xyzX, xyzY, xyzZ) {
	var _xyz2lab17 = xyz2lab(xyzX, xyzY, xyzZ),
	    _xyz2lab18 = _slicedToArray$4(_xyz2lab17, 3),
	    labL = _xyz2lab18[0],
	    labA = _xyz2lab18[1],
	    labB = _xyz2lab18[2];

	var _lab2lch9 = lab2lch(labL, labA, labB),
	    _lab2lch10 = _slicedToArray$4(_lab2lch9, 3),
	    lchL = _lab2lch10[0],
	    lchC = _lab2lch10[1],
	    lchH = _lab2lch10[2];

	return [lchL, lchC, lchH];
}

function lch2xyz(lchL, lchC, lchH) {
	var _lch2lab9 = lch2lab(lchL, lchC, lchH),
	    _lch2lab10 = _slicedToArray$4(_lch2lab9, 3),
	    labL = _lch2lab10[0],
	    labA = _lch2lab10[1],
	    labB = _lch2lab10[2];

	var _lab2xyz17 = lab2xyz(labL, labA, labB),
	    _lab2xyz18 = _slicedToArray$4(_lab2xyz17, 3),
	    xyzX = _lab2xyz18[0],
	    xyzY = _lab2xyz18[1],
	    xyzZ = _lab2xyz18[2];

	return [xyzX, xyzY, xyzZ];
}

var index = {
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

exports.rgb2hsl = rgb2hsl;
exports.rgb2hwb = rgb2hwb;
exports.rgb2lab = rgb2lab;
exports.rgb2lch = rgb2lch;
exports.rgb2hsv = rgb2hsv;
exports.rgb2xyz = rgb2xyz;
exports.hsl2rgb = hsl2rgb;
exports.hsl2hwb = hsl2hwb;
exports.hsl2lab = hsl2lab;
exports.hsl2lch = hsl2lch;
exports.hsl2hsv = hsl2hsv;
exports.hsl2xyz = hsl2xyz;
exports.hwb2rgb = hwb2rgb;
exports.hwb2hsl = hwb2hsl;
exports.hwb2lab = hwb2lab;
exports.hwb2lch = hwb2lch;
exports.hwb2hsv = hwb2hsv;
exports.hwb2xyz = hwb2xyz;
exports.lab2rgb = lab2rgb;
exports.lab2hsl = lab2hsl;
exports.lab2hwb = lab2hwb;
exports.lab2lch = lab2lch;
exports.lab2hsv = lab2hsv;
exports.lab2xyz = lab2xyz;
exports.lch2rgb = lch2rgb;
exports.lch2hsl = lch2hsl;
exports.lch2hwb = lch2hwb;
exports.lch2lab = lch2lab;
exports.lch2hsv = lch2hsv;
exports.lch2xyz = lch2xyz;
exports.hsv2rgb = hsv2rgb;
exports.hsv2hsl = hsv2hsl;
exports.hsv2hwb = hsv2hwb;
exports.hsv2lab = hsv2lab;
exports.hsv2lch = hsv2lch;
exports.hsv2xyz = hsv2xyz;
exports.xyz2rgb = xyz2rgb;
exports.xyz2hsl = xyz2hsl;
exports.xyz2hwb = xyz2hwb;
exports.xyz2lab = xyz2lab;
exports.xyz2lch = xyz2lch;
exports.xyz2hsv = xyz2hsv;
exports.rgb2hue = rgb2hue;
exports['default'] = index;
