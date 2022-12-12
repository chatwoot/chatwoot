function merge(a, b, k) {
	if (typeof a === 'object' && typeof b === 'object')  {
		if (Array.isArray(a) && Array.isArray(b)) {
			for (k=0; k < b.length; k++) {
				a[k] = merge(a[k], b[k]);
			}
		} else {
			for (k in b) {
				if (k === '__proto__' || k === 'constructor' || k === 'prototype') break;
				a[k] = merge(a[k], b[k]);
			}
		}
		return a;
	}
	return b;
}

function dset(obj, keys, val) {
	keys.split && (keys=keys.split('.'));
	var i=0, l=keys.length, t=obj, x, k;
	while (i < l) {
		k = keys[i++];
		if (k === '__proto__' || k === 'constructor' || k === 'prototype') break;
		t = t[k] = (i === l) ? merge(t[k],val) : (typeof(x=t[k])===typeof keys) ? x : (keys[i]*0 !== 0 || !!~(''+keys[i]).indexOf('.')) ? {} : [];
	}
}

exports.dset = dset;
exports.merge = merge;