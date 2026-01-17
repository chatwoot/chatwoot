import type { Context } from '../context.js'
import { ID_SEPARATOR } from './util.js'

export const resolvedGeneratedSetupCode = (ctx: Context, id: string) => {
  const [, index] = id.split(ID_SEPARATOR)
  return ctx.config.setupCode?.[index] ?? ''
}
