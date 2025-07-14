/**
 *  Check if  thenable
 *  (instanceof Promise doesn't respect realms)
 */
export const isThenable = (value: unknown): boolean =>
  typeof value === 'object' &&
  value !== null &&
  'then' in value &&
  typeof (value as any).then === 'function'
