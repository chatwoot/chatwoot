/**
 * Caches the decoded peaks data to improve rendering speed for large audio
 *
 * Is used if the option parameter `partialRender` is set to `true`
 */
export default class PeakCache {
    /**
     * Instantiate cache
     */
    constructor() {
        this.clearPeakCache();
    }

    /**
     * Empty the cache
     */
    clearPeakCache() {
        /**
         * Flat array with entries that are always in pairs to mark the
         * beginning and end of each subrange.  This is a convenience so we can
         * iterate over the pairs for easy set difference operations.
         * @private
         */
        this.peakCacheRanges = [];
        /**
         * Length of the entire cachable region, used for resetting the cache
         * when this changes (zoom events, for instance).
         * @private
         */
        this.peakCacheLength = -1;
    }

    /**
     * Add a range of peaks to the cache
     *
     * @param {number} length The length of the range
     * @param {number} start The x offset of the start of the range
     * @param {number} end The x offset of the end of the range
     * @return {Number.<Array[]>} Array with arrays of numbers
     */
    addRangeToPeakCache(length, start, end) {
        if (length != this.peakCacheLength) {
            this.clearPeakCache();
            this.peakCacheLength = length;
        }

        // Return ranges that weren't in the cache before the call.
        let uncachedRanges = [];
        let i = 0;
        // Skip ranges before the current start.
        while (
            i < this.peakCacheRanges.length &&
            this.peakCacheRanges[i] < start
        ) {
            i++;
        }
        // If |i| is even, |start| falls after an existing range.  Otherwise,
        // |start| falls between an existing range, and the uncached region
        // starts when we encounter the next node in |peakCacheRanges| or
        // |end|, whichever comes first.
        if (i % 2 == 0) {
            uncachedRanges.push(start);
        }
        while (
            i < this.peakCacheRanges.length &&
            this.peakCacheRanges[i] <= end
        ) {
            uncachedRanges.push(this.peakCacheRanges[i]);
            i++;
        }
        // If |i| is even, |end| is after all existing ranges.
        if (i % 2 == 0) {
            uncachedRanges.push(end);
        }

        // Filter out the 0-length ranges.
        uncachedRanges = uncachedRanges.filter((item, pos, arr) => {
            if (pos == 0) {
                return item != arr[pos + 1];
            } else if (pos == arr.length - 1) {
                return item != arr[pos - 1];
            }
            return item != arr[pos - 1] && item != arr[pos + 1];
        });

        // Merge the two ranges together, uncachedRanges will either contain
        // wholly new points, or duplicates of points in peakCacheRanges.  If
        // duplicates are detected, remove both and extend the range.
        this.peakCacheRanges = this.peakCacheRanges.concat(uncachedRanges);
        this.peakCacheRanges = this.peakCacheRanges
            .sort((a, b) => a - b)
            .filter((item, pos, arr) => {
                if (pos == 0) {
                    return item != arr[pos + 1];
                } else if (pos == arr.length - 1) {
                    return item != arr[pos - 1];
                }
                return item != arr[pos - 1] && item != arr[pos + 1];
            });

        // Push the uncached ranges into an array of arrays for ease of
        // iteration in the functions that call this.
        const uncachedRangePairs = [];
        for (i = 0; i < uncachedRanges.length; i += 2) {
            uncachedRangePairs.push([uncachedRanges[i], uncachedRanges[i + 1]]);
        }

        return uncachedRangePairs;
    }

    /**
     * For testing
     *
     * @return {Number.<Array[]>} Array with arrays of numbers
     */
    getCacheRanges() {
        const peakCacheRangePairs = [];
        let i;
        for (i = 0; i < this.peakCacheRanges.length; i += 2) {
            peakCacheRangePairs.push([
                this.peakCacheRanges[i],
                this.peakCacheRanges[i + 1]
            ]);
        }
        return peakCacheRangePairs;
    }
}
