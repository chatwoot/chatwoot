export class Emitter {
  private callbacks: Record<string, Function[]> = {}

  on(event: string, callback: Function): this {
    this.callbacks[event] = [...(this.callbacks[event] ?? []), callback]
    return this
  }

  once(event: string, fn: Function): this {
    const on = (...args: unknown[]): void => {
      this.off(event, on)
      fn.apply(this, args)
    }

    this.on(event, on)
    return this
  }

  off(event: string, callback: Function): this {
    const fns = this.callbacks[event] ?? []
    const without = fns.filter((fn) => fn !== callback)
    this.callbacks[event] = without
    return this
  }

  emit(event: string, ...args: unknown[]): this {
    const callbacks = this.callbacks[event] ?? []
    callbacks.forEach((callback) => {
      callback.apply(this, args)
    })
    return this
  }
}
