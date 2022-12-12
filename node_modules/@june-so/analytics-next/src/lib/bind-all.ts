/* eslint-disable @typescript-eslint/no-explicit-any */
export default function bindAll<
  ObjType extends { [key: string]: any },
  KeyType extends keyof ObjType
>(obj: ObjType): ObjType {
  const proto = obj.constructor.prototype
  for (const key of Object.getOwnPropertyNames(proto)) {
    if (key !== 'constructor') {
      const desc = Object.getOwnPropertyDescriptor(
        obj.constructor.prototype,
        key
      )
      if (!!desc && typeof desc.value === 'function') {
        obj[key as KeyType] = obj[key].bind(obj)
      }
    }
  }

  return obj
}
/* eslint-enable @typescript-eslint/no-explicit-any */
