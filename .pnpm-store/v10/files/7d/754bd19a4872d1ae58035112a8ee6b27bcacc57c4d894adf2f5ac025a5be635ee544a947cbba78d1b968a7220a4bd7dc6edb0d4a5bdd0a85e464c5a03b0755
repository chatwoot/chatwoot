/**
 * Given a series colors, this function will return a `scale(x)` function that
 * accepts a percentage as a decimal between 0 and 1 and returns the color at
 * that percentage in the scale.
 *
 * ```js
 * const scale = getScale('red', 'yellow', 'green');
 * console.log(scale(0)); // rgba(255, 0, 0, 1)
 * console.log(scale(0.5)); // rgba(255, 255, 0, 1)
 * console.log(scale(1)); // rgba(0, 128, 0, 1)
 * ```
 *
 * If you'd like to limit the domain and range like chroma-js, we recommend
 * wrapping scale again.
 *
 * ```js
 * const _scale = getScale('red', 'yellow', 'green');
 * const scale = x => _scale(x / 100);
 *
 * console.log(scale(0)); // rgba(255, 0, 0, 1)
 * console.log(scale(50)); // rgba(255, 255, 0, 1)
 * console.log(scale(100)); // rgba(0, 128, 0, 1)
 * ```
 */
declare function getScale(...colors: string[]): (n: number) => string;
export default getScale;
