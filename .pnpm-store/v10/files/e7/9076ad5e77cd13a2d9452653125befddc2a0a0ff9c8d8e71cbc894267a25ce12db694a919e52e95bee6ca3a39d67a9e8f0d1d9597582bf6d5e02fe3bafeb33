import type { Context } from '../context.js'
import { GENERATED_SETUP_CODE } from './index.js'
import { ID_SEPARATOR } from './util.js'

export const resolvedGeneratedGlobalSetup = (ctx: Context) => {
  if (ctx.config.setupCode) {
    return [
      // Import
      `${ctx.config.setupCode.map((c, index) => `import * as setup_${index} from '${GENERATED_SETUP_CODE}${ID_SEPARATOR}${index}'`).join('\n')}`,
      // List
      `const setupList = [${ctx.config.setupCode.map((c, index) => `setup_${index}`).join(', ')}]`,
      // Setups
      ...ctx.supportPlugins.map(p => p.setupFn).flat().map(fnName => `export async function ${fnName} (payload) {
        for (const setup of setupList) {
          if (setup?.${fnName}) {
            await setup.${fnName}(payload)
          }
        }
      }`),
    ].join('\n')
  } else {
    return ''
  }
}
