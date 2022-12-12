import { Parameters } from '@storybook/addons';
/**
 * Safely combine parameters recursively. Only copy objects when needed.
 * Algorithm = always overwrite the existing value UNLESS both values
 * are plain objects. In this case flag the key as "special" and handle
 * it with a heuristic.
 */
export declare const combineParameters: (...parameterSets: (Parameters | undefined)[]) => Parameters;
