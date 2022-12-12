import glob = require('glob')

export = promise

declare const promise: Export

declare type GlobPromise = (pattern: string, options?: glob.IOptions) => Promise<string[]>

declare interface Export extends GlobPromise {
  readonly glob: typeof glob
  readonly Glob: typeof glob.Glob
  readonly hasMagic: typeof glob.hasMagic
  readonly sync: typeof glob.sync
  readonly promise: GlobPromise
}
