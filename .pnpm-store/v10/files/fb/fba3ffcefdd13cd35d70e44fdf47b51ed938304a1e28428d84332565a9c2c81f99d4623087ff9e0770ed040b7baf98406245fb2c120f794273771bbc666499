export const pickBy = <T, K extends keyof T>(
  obj: T,
  fn: (key: K, v: T[K]) => boolean
) => {
  return (Object.keys(obj) as K[])
    .filter((k) => fn(k, obj[k]))
    .reduce((acc, key) => ((acc[key] = obj[key]), acc), {} as Partial<T>)
}
