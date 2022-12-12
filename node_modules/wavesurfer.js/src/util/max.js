/**
 * Get the largest value
 *
 * @param   {Array} values Array of numbers
 * @returns {Number} Largest number found
 * @example console.log(max([1, 2, 3])); // logs 3
 */
export default function max(values) {
    let largest = -Infinity;
    Object.keys(values).forEach(i => {
        if (values[i] > largest) {
            largest = values[i];
        }
    });
    return largest;
}
