// NOTE: In the future if performance becomes an issue, we can memoize the functions

import { unref } from 'vue';
import camelcaseKeys from 'camelcase-keys';
import snakecaseKeys from 'snakecase-keys';

/**
 * Vue composable that converts object keys to camelCase
 * @param {Object|Array|import('vue').Ref<Object|Array>} payload - Object or array to convert
 * @returns {Object|Array} Converted payload with camelCase keys
 */
export function useCamelCase(payload) {
  const unrefPayload = unref(payload);

  if (Array.isArray(unrefPayload)) {
    return unrefPayload.map(camelcaseKeys);
  }

  return camelcaseKeys(unrefPayload);
}

/**
 * Vue composable that converts object keys to snake_case
 * @param {Object|Array|import('vue').Ref<Object|Array>} payload - Object or array to convert
 * @returns {Object|Array} Converted payload with snake_case keys
 */
export function useSnakeCase(payload) {
  const unrefPayload = unref(payload);

  if (Array.isArray(unrefPayload)) {
    return unrefPayload.map(snakecaseKeys);
  }

  return snakecaseKeys(unrefPayload);
}
