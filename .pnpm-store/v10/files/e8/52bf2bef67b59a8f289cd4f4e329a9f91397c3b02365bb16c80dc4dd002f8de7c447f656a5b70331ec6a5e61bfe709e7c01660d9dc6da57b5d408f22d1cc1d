import { createRequire } from 'node:module'
import { relative, join, dirname } from 'pathe'
import {
  Plugin as VitePlugin,
  UserConfig as ViteConfig,
  InlineConfig,
  mergeConfig as mergeViteConfig,
  loadConfigFromFile as loadViteConfigFromFile,
} from 'vite'
import { lookup as lookupMime } from 'mrmime'
import { APP_PATH, TEMP_PATH } from './alias.js'
import { Context } from './context.js'
import { notifyStoryChange } from './stories.js'
import { createMarkdownPlugins } from './markdown.js'
import { createVirtualFilesPlugin } from './virtual/vite-plugin.js'

const require = createRequire(import.meta.url)

export async function mergeHistoireViteConfig (viteConfig: InlineConfig, ctx: Context) {
  if (ctx.config.vite) {
    const command = ctx.mode === 'dev' ? 'serve' : 'build'
    const overrides = typeof ctx.config.vite === 'function'
      ? await ctx.config.vite(viteConfig as ViteConfig, {
        mode: ctx.mode,
        command,
      })
      : ctx.config.vite
    if (overrides) {
      viteConfig = mergeViteConfig(viteConfig, overrides)
    }
  }

  let flatPlugins = []
  if (viteConfig.plugins) {
    for (const pluginOption of viteConfig.plugins) {
      const resolvedPluginOption = await pluginOption
      if (Array.isArray(resolvedPluginOption)) {
        flatPlugins.push(...await Promise.all(resolvedPluginOption))
      } else {
        flatPlugins.push(resolvedPluginOption)
      }
    }
    flatPlugins = flatPlugins.filter(Boolean)
  }

  if (ctx.config.viteIgnorePlugins) {
    flatPlugins = flatPlugins.filter(plugin => !ctx.config.viteIgnorePlugins.includes(plugin.name))
  }

  viteConfig.plugins = flatPlugins

  return viteConfig
}

export interface ViteConfigWithPlugins {
  viteConfig: InlineConfig
  viteConfigFile: string | null
}

export async function getViteConfigWithPlugins (isServer: boolean, ctx: Context): Promise<ViteConfigWithPlugins> {
  const userViteConfigFile = await loadViteConfigFromFile({ command: ctx.mode === 'dev' ? 'serve' : 'build', mode: ctx.mode })
  const userViteConfig = mergeViteConfig(userViteConfigFile?.config ?? {}, { server: { port: 6006 } })

  const inlineConfig = await mergeHistoireViteConfig(userViteConfig, ctx)
  const plugins: VitePlugin[] = []

  function optimizeDeps (deps: string[]): string[] {
    const result = []
    for (const dep of deps) {
      result.push(dep)
      try {
        result.push(dirname(require.resolve(`${dep}/package.json`)))
      } catch (e) {
        // Noop
      }
    }
    return result
  }

  plugins.push({
    name: 'histoire-vite-plugin',

    config (_, { command }) {
      return {
        resolve: {
          dedupe: [
            'vue',
          ],
          alias: {
            'histoire-style': join(APP_PATH, process.env.HISTOIRE_DEV ? 'app/style/main.pcss' : 'style.css'),
          },

          ...(isServer
            ? {
              // Force resolving deps like Node.JS resolution algorithm (in case some modules are not loaded with ssr: true e.g. .vue files)
              conditions: ['node'],
            }
            : {}),
        },
        optimizeDeps: {
          entries: [
            `${APP_PATH}/bundle-main.js`,
            `${APP_PATH}/bundle-sandbox.js`,
          ],
          include: optimizeDeps([
            'flexsearch',
            'shiki-es',
            // Shiki dependencies
            'vscode-oniguruma',
            'vscode-textmate',
          ]),
          exclude: [
            'histoire',
            '@histoire/vendors',
          ],
        },
        server: {
          fs: {
            allow: [
              APP_PATH,
              TEMP_PATH,
              ctx.resolvedViteConfig.root,
              process.cwd(),
              ...process.env.HISTOIRE_DEV
                ? [
                  '../../packages/histoire-vendors',
                ]
                : [],
            ],
          },
          watch: {
            ignored: [`!**/node_modules/.histoire/**`, '**/vite.config.*'],
          },
          hmr: command === 'build' ? false : !isServer,
        },
        define: {
          // We need to force this to be able to use `devtoolsRawSetupState`
          __VUE_PROD_DEVTOOLS__: 'true',
          // Disable warnings
          'process.env.NODE_ENV': JSON.stringify(isServer ? 'production' : process.env.NODE_ENV ?? 'development'),
          ...!isServer
            ? {
              // Collect flag
              'process.env.HST_COLLECT': 'false',
            }
            : {},
          __HST_COLLECT__: isServer,
        },
        cacheDir: isServer ? 'node_modules/.hst-vite-server' : 'node_modules/.hst-vite',
      }
    },

    options () {
      // @ts-ignore
      this.meta.histoire = {
        isCollecting: isServer,
      }
    },

    handleHotUpdate (updateContext) {
      const story = ctx.storyFiles.find(file => file.path === updateContext.file)
      if (story) {
        notifyStoryChange(story)
      }
    },

    configureServer (server) {
      let firstMount = true
      server.ws.on('histoire:mount', () => {
        if (!firstMount) {
          notifyStoryChange()
        }
        firstMount = false
      })

      server.middlewares.use(async (req, res, next) => {
        if (req.url!.startsWith(`${server.config.base}__sandbox`)) {
          res.statusCode = 200
          let html = `
<!DOCTYPE html>
<html>
<head>
  <title></title>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <meta name="description" content="">
</head>
<body>
  <div id="app"></div>
  <script>
  // Hide spammy vite messages
  const origConsoleLog = console.log
  console.log = (...args) => {
    if (typeof args[0] !== 'string' || !args[0].startsWith('[vite] connect')) {
      origConsoleLog(...args)
    }
  }
  </script>
  <script type="module" src="/@fs/${APP_PATH}/bundle-sandbox${process.env.HISTOIRE_DEV ? '-dev' : ''}.js"></script>
</body>
</html>`
          // Apply Vite HTML transforms. This injects the Vite HMR client, and
          // also applies HTML transforms from Vite plugins
          html = await server.transformIndexHtml(req.url, html)
          res.setHeader('content-type', 'text/html; charset=UTF-8')
          res.end(html)
          return
        }
        next()
      })

      // serve our index.html after vite history fallback
      return () => {
        server.middlewares.use(async (req, res, next) => {
          if (req.url!.endsWith('.html')) {
            res.statusCode = 200

            let html = `
<!DOCTYPE html>
<html>
  <head>
    <title></title>
    <link rel="icon" href=""/>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <meta name="description" content="">
    ${ctx.config.theme?.favicon ? `<link rel="icon" type="${lookupMime(ctx.config.theme.favicon)}" href="${server.config.base}${ctx.config.theme.favicon}"/>` : ''}
  </head>
  <body>
    <div id="app"></div>
    <script type="module" src="/@fs/${APP_PATH}/bundle-main${process.env.HISTOIRE_DEV ? '-dev' : ''}.js"></script>
  </body>
</html>`
            // Apply Vite HTML transforms. This injects the Vite HMR client, and
            // also applies HTML transforms from Vite plugins
            html = await server.transformIndexHtml(req.url, html)
            res.setHeader('content-type', 'text/html; charset=UTF-8')
            res.end(html)
            return
          }
          next()
        })
      }
    },
  })

  plugins.push(createVirtualFilesPlugin(ctx, isServer))

  // Replace dev flag
  const flags = {
    '_ctx.__HISTOIRE_DEV__': JSON.stringify(ctx.mode === 'dev'),
    __HISTOIRE_DEV__: JSON.stringify(ctx.mode === 'dev'),
  }
  plugins.push({
    name: 'histoire:flags',
    enforce: 'pre',
    transform (code, id) {
      if (id.match(/\.(vue|js)($|\?)/)) {
        const original = code
        for (const flag in flags) {
          code = code.replace(new RegExp(flag, 'g'), flags[flag])
        }
        if (original !== code) { return code }
      }
    },
  })

  if (ctx.mode === 'dev') {
    // Dev commands
    plugins.push({
      name: 'histoire:dev-commands',
      configureServer (server) {
        server.ws.on('histoire:dev-command', ({ id, params }) => {
          const command = ctx.registeredCommands.find(c => c.id === id)
          if (command?.serverAction) {
            command.serverAction(params)
          }
        })
      },
    })
  }

  // Markdown
  plugins.push(...await createMarkdownPlugins(ctx))

  if (ctx.mode === 'build') {
    // Add file name in build mode to have components names instead of <Anonymous>
    const include = [/\.vue$/]
    const exclude = [/[\\/]node_modules[\\/]/, /[\\/]\.git[\\/]/, /[\\/]\.nuxt[\\/]/]
    plugins.push({
      name: 'histoire-file-name-plugin',
      enforce: 'post',

      transform (code, id) {
        if (exclude.some(r => r.test(id))) return
        if (include.some(r => r.test(id))) {
          const file = relative(ctx.resolvedViteConfig.root, id)
          const index = code.indexOf('export default')
          const result = `${code.substring(0, index)}_sfc_main.__file = '${file}'\n${code.substring(index)}`
          return result
        }
      },
    })
  }

  if (process.env.HISTOIRE_DEV && !isServer) {
    plugins.push({
      name: 'histoire-dev-plugin',
      config () {
        // Examples context
        return {
          resolve: {
            alias: [
              ...[
                ['floating-vue/dist/style.css', 'node_modules/floating-vue/dist/style.css'],
                ['floating-vue', 'floating-vue'],
                ['@iconify/vue', 'iconify'],
                ['pinia', 'pinia'],
                ['scroll-into-view-if-needed', 'scroll'],
                ['vue-router', 'vue-router'],
                ['@vueuse/core', 'vue-use'],
                ['vue', 'vue'],
              ].reduce((acc, [name, entry]) => {
                acc.push({
                  find: new RegExp(`^${name.replace(/\//g, '\\/')}$`),
                  replacement: `@histoire/vendors/${entry}`,
                })
                acc.push({
                  find: new RegExp(`^${name.replace(/\//g, '\\/')}\\/`),
                  replacement: `@histoire/vendors/${entry}/`,
                })
                return acc
              }, [] as any[]),

              { find: /@histoire\/controls$/, replacement: '@histoire/controls/src/index.ts' },
            ],
          },
        }
      },
    })
  }

  const viteConfig = mergeViteConfig(inlineConfig, {
    configFile: false,
    plugins,
  }) as InlineConfig

  return {
    viteConfig,
    viteConfigFile: userViteConfigFile?.path ?? null,
  }
}
