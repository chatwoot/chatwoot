declare class OrderedMap<T = any> {
  private constructor(content: Array<string | T>)

  get(key: string): T | undefined

  update(key: string, value: T, newKey?: string): OrderedMap<T>

  remove(key: string): OrderedMap<T>

  addToStart(key: string, value: T): OrderedMap<T>

  addToEnd(key: string, value: T): OrderedMap<T>

  addBefore(place: string, key: string, value: T): OrderedMap<T>

  forEach(fn: (key: string, value: T) => any): void

  prepend(map: MapLike<T>): OrderedMap<T>

  append(map: MapLike<T>): OrderedMap<T>

  subtract(map: MapLike<T>): OrderedMap<T>

  readonly size: number

  static from<T>(map: MapLike<T>): OrderedMap<T>
}

export type MapLike<T = any> = Record<string, T> | OrderedMap<T>

export default OrderedMap
