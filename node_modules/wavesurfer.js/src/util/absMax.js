import utilMax from './max';
import utilmin from './min';

/**
 * Get the largest absolute value in an array
 *
 * @param   {Array} values Array of numbers
 * @returns {Number} Largest number found
 * @example console.log(max([-3, 2, 1]), max([-3, 2, 4])); // logs 3 4
 * @since 4.3.0
 */
export default function absMax(values) {
    const max = utilMax(values);
    const min = utilmin(values);
    return -min > max ? -min : max;
}
