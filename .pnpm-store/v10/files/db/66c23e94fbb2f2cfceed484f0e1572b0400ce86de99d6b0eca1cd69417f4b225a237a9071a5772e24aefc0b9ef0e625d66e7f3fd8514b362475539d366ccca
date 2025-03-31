export function hasProperties<T extends object, K extends string>(
  obj: T,
  ...keys: K[]
): obj is T & { [J in K]: unknown } {
  // eslint-disable-next-line no-prototype-builtins
  return !!obj && keys.every((key) => obj.hasOwnProperty(key))
}
