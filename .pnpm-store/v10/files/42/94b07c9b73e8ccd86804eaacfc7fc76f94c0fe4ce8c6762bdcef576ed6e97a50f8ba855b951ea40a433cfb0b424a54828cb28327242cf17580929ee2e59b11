import { dirname } from 'pathe'
import { fileURLToPath } from 'node:url'
import type { Plugin } from '@histoire/shared'

const __dirname = dirname(fileURLToPath(import.meta.url))

export function vanillaSupport (): Plugin {
  return {
    name: 'builtin:vanilla-support',

    defaultConfig () {
      return {
        supportMatch: [
          {
            id: 'vanilla',
            patterns: ['**/*.js'],
            pluginIds: ['vanilla'],
          },
        ],
      }
    },

    supportPlugin: {
      id: 'vanilla',
      moduleName: __dirname,
      setupFn: 'setupVanilla',
      importStoryComponent: (file, index) => `import Comp${index} from ${JSON.stringify(file.moduleId)}`, // @TODO code-splitting
    },

    // onDev (api) {
    //   // Test vanilla story
    //   api.addStoryFile(resolve(__dirname, './vanilla.story.js'))
    // },
  }
}
