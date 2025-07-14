/**
 * Remove Index Signature
 */
export type RemoveIndexSignature<T> = {
  [K in keyof T as {} extends Record<K, 1> ? never : K]: T[K]
}

/**
 * Recursively make all object properties nullable
 */
export type DeepNullable<T> = {
  [K in keyof T]: T[K] extends object ? DeepNullable<T[K]> | null : T[K] | null
}
