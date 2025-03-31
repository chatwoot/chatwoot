export function unique<T>(array: T[]): T[] {
  return [...new Set(array)];
}

export function groupBy<T, K>(array: T[], toKey: (item: T) => K): Map<K, T[]> {
  const map = new Map<K, T[]>();

  for (const item of array) {
    const key = toKey(item);
    const oldValue = map.get(key);
    const newValue = oldValue ? [...oldValue, item] : [item];
    map.set(key, newValue);
  }

  return map;
}
