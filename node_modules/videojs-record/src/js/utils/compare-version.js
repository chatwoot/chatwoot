/**
 * @file compare-version.js
 * @since 3.8.0
 */

/**
 * Compare 2 version number strings.
 *
 * @param {string} v1 - First version number to compare.
 * @param {string} v2 - Second version number to compare.
 * @returns {number} - Returns 0 if versions are equal,
 *     1 if `v1` is greater, and -1 if `v2` is smaller.
 */
const compareVersion = function(v1, v2) {
    if (typeof v1 !== 'string') return false;
    if (typeof v2 !== 'string') return false;
    v1 = v1.split('.');
    v2 = v2.split('.');
    const k = Math.min(v1.length, v2.length);
    let i = 0;
    for (i; i < k; ++ i) {
        // buddy ignore:start
        v1[i] = parseInt(v1[i], 10);
        v2[i] = parseInt(v2[i], 10);
        // buddy ignore:end
        if (v1[i] > v2[i]) return 1;
        if (v1[i] < v2[i]) return -1;
    }
    return v1.length === v2.length ? 0 : (v1.length < v2.length ? -1 : 1);
};

export default compareVersion;
