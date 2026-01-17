import { build } from '../build.js'
import { createContext } from '../context.js'

export interface BuildOptions {
  config?: string
}

export async function buildCommand (options: BuildOptions) {
  const ctx = await createContext({
    configFile: options.config,
    mode: 'build',
  })
  await build(ctx)

  // @TODO remove when https://github.com/vitejs/vite/issues/6815 is fixed
  process.exit(0)
}
