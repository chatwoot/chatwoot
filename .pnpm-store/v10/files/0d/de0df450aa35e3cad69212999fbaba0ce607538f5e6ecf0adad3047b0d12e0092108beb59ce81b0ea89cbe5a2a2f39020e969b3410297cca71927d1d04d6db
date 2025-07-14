type Grouper<T> = (obj: T) => string | number

export function groupBy<T>(
  collection: T[],
  grouper: keyof T | Grouper<T>
): Record<string, T[]> {
  const results: Record<string, T[]> = {}

  collection.forEach((item) => {
    let key: string | number | undefined = undefined

    if (typeof grouper === 'string') {
      const suggestedKey = item[grouper]
      key =
        typeof suggestedKey !== 'string'
          ? JSON.stringify(suggestedKey)
          : suggestedKey
    } else if (grouper instanceof Function) {
      key = grouper(item)
    }

    if (key === undefined) {
      return
    }

    results[key] = [...(results[key] ?? []), item]
  })

  return results
}
