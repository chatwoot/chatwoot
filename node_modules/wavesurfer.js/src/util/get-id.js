/**
 * Get a random prefixed ID
 *
 * @param {String} prefix Prefix to use. Default is `'wavesurfer_'`.
 * @returns {String} Random prefixed ID
 * @example
 * console.log(getId()); // logs 'wavesurfer_b5pors4ru6g'
 *
 * let prefix = 'foo-';
 * console.log(getId(prefix)); // logs 'foo-b5pors4ru6g'
 */
export default function getId(prefix) {
    if (prefix === undefined) {
        prefix = 'wavesurfer_';
    }
    return (
        prefix +
        Math.random()
            .toString(32)
            .substring(2)
    );
}
