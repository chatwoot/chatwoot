import { join } from 'pathe'
import {
  build as viteBuild,
  createServer as createViteServer,
  InlineConfig as ViteInlineConfig,
  mergeConfig as mergeViteConfig,
  Plugin as VitePlugin,
} from 'vite'
import fs from 'fs-extra'
import { lookup as lookupMime } from 'mrmime'
import pc from 'picocolors'
import { performance } from 'node:perf_hooks'
import type {
  ChangeViteConfigCallback,
  BuildEndCallback,
  PreviewStoryCallback,
} from '@histoire/shared'
import type { RollupOutput } from 'rollup'
import { APP_PATH } from './alias.js'
import { Context } from './context.js'
import { getViteConfigWithPlugins } from './vite.js'
import { findAllStories } from './stories.js'
import { useCollectStories } from './collect/index.js'
import { BuildPluginApi } from './plugin.js'
import { useModuleLoader } from './load.js'
import { startPreview } from './preview.js'
import { createMarkdownFilesWatcher } from './markdown.js'
import { getSerializedStoryData } from './build-serialize.js'

const PRELOAD_MODULES = [
  'vendor',
]

const PREFETCHED_MODULES = [
  'StoryView',
  'reactivity',
  'global-components',
]

export async function build (ctx: Context) {
  const startTime = performance.now()
  await findAllStories(ctx)

  // Scan for markdown files
  {
    const { stop } = await createMarkdownFilesWatcher(ctx)
    await stop()
  }

  const { viteConfig } = await getViteConfigWithPlugins(true, ctx)
  const server = await createViteServer(viteConfig)
  await server.pluginContainer.buildStart({})

  const moduleLoader = useModuleLoader({
    server,
    throws: true,
  })
  const changeViteConfigCallbacks: ChangeViteConfigCallback[] = []
  const buildEndCallbacks: BuildEndCallback[] = []
  const previewStoryCallbacks: PreviewStoryCallback[] = []
  for (const plugin of ctx.config.plugins) {
    if (plugin.onBuild) {
      const api = new BuildPluginApi(ctx, plugin, moduleLoader)
      await plugin.onBuild(api)
      changeViteConfigCallbacks.push(...api.changeViteConfigCallbacks)
      buildEndCallbacks.push(...api.buildEndCallbacks)
      previewStoryCallbacks.push(...api.previewStoryCallbacks)
    }
  }

  // Collect story data
  const { executeStoryFile, destroy: destroyCollectStories } = useCollectStories({
    server,
    throws: true,
  }, ctx)
  await Promise.all(ctx.storyFiles.map(storyFile => executeStoryFile(storyFile)))
  await destroyCollectStories()

  const storyCount = ctx.storyFiles.reduce((sum, file) => sum + (file.story?.variants.length ? 1 : 0), 0)
  const variantCount = ctx.storyFiles.reduce((sum, file) => sum + (file.story?.variants.length ?? 0), 0)
  const emptyStoryCount = ctx.storyFiles.length - storyCount

  const { viteConfig: buildViteConfigRaw } = await getViteConfigWithPlugins(false, ctx)
  const buildViteConfig: ViteInlineConfig = mergeViteConfig(buildViteConfigRaw, {
    mode: 'development',
    build: {
      lib: false,
      rollupOptions: {
        input: [
          join(APP_PATH, 'bundle-main.js'),
          join(APP_PATH, 'bundle-sandbox.js'),
        ],
        plugins: [
          {
            name: 'histoire-build-rollup-options-override',
            enforce: 'post',
            options (options) {
              // Don't externalize
              options.external = []
            },
          },
        ],
      },
    },
  })

  // For @vite/plugin-vue: Always put our vite server
  // Disable template inlining
  // (so that we no longer need defineExpose)
  // Nuxt: replaces the Nuxt vite dev server
  buildViteConfig.plugins.push({
    name: 'histoire-vue-plugin-override',
    config (config) {
      const vuePlugin = config.plugins.find((p: any) => p.name === 'vite:vue') as VitePlugin
      if (vuePlugin) {
        // @ts-expect-error vue plugin use function form
        const original = vuePlugin.configureServer.bind(vuePlugin)
        vuePlugin.configureServer = () => {
          original({
            ...server,
            config: {
              ...server.config,
              server: {
                ...server.config.server,
                hmr: false,
              },
            },
          })
        }
        vuePlugin.configureServer(server)
      }
    },
  })

  buildViteConfig.plugins.push({
    name: 'histoire-build-config-override',
    enforce: 'post',
    config (config) {
      // Don't externalize
      config.build.rollupOptions.external = []

      // Force chunk strategy
      config.build.rollupOptions.output = {
        manualChunks (id) {
          if (!id.includes('@histoire/app') && id.includes('node_modules')) {
            for (const test of ctx.config.build?.excludeFromVendorsChunk ?? []) {
              if ((
                typeof test === 'string' && id.includes(test)
              ) || (
                test instanceof RegExp && test.test(id)
              )) {
                // Excluded from vendor chunk
                return
              }
            }
            return 'vendor'
          }
        },
      }

      // Force vite build options
      Object.assign(config.build, {
        outDir: ctx.config.outDir,
        emptyOutDir: true,
        cssCodeSplit: false,
        minify: false,
        // Don't build in SSR mode
        ssr: false,
      })

      config.define.__HST_COLLECT__ = false
    },
  })

  for (const cb of changeViteConfigCallbacks) {
    console.log('vite config hook', cb)
    await cb(buildViteConfig)
  }

  const results = await viteBuild(buildViteConfig)
  const result = Array.isArray(results) ? results[0] : results as RollupOutput

  const styleOutput = result.output.find(o => o.name === 'style.css' && o.type === 'asset')

  // Preload
  const preloadOutputs = result.output.filter(o => PRELOAD_MODULES.includes(o.name) && o.type === 'chunk')
  const preloadHtml = generateScriptLinks(preloadOutputs.map(o => o.fileName), 'preload', ctx)

  // Prefetch
  const prefetchOutputs = result.output.filter(o => PREFETCHED_MODULES.includes(o.name) && o.type === 'chunk')
  const prefetchHtml = generateScriptLinks(prefetchOutputs.map(o => o.fileName), 'prefetch', ctx)

  // Index
  const indexOutput = result.output.find(o => o.name === 'bundle-main' && o.type === 'chunk')
  const indexHtml = generateEntryHtml(indexOutput.fileName, styleOutput.fileName, {
    HEAD: `${preloadHtml}${prefetchHtml}`,
  }, ctx)
  await writeFile('index.html', indexHtml, ctx)

  // Sandbox
  const sandboxOutput = result.output.find(o => o.name === 'bundle-sandbox' && o.type === 'chunk')
  const sandboxHtml = generateEntryHtml(sandboxOutput.fileName, styleOutput.fileName, {}, ctx)
  await writeFile('__sandbox.html', sandboxHtml, ctx)

  await writeFile('histoire.json', JSON.stringify(getSerializedStoryData(ctx), null, 2), ctx)

  const duration = performance.now() - startTime
  if (emptyStoryCount) {
    console.warn(pc.yellow(`⚠️  ${emptyStoryCount} empty story file${emptyStoryCount === 1 ? '' : 's'}`))
  }
  console.log(pc.green(`✅ Built ${storyCount} stor${storyCount === 1 ? 'y' : 'ies'} (${variantCount} variant${variantCount === 1 ? '' : 's'}) in ${Math.round(duration / 1000 * 100) / 100}s`))

  // Render
  if (previewStoryCallbacks.length) {
    const { baseUrl, close } = await startPreview(null, ctx)
    for (const storyFile of ctx.storyFiles) {
      const story = storyFile.story
      for (const variant of story.variants) {
        const query = new URLSearchParams()
        query.append('storyId', story.id)
        query.append('variantId', variant.id)
        const url = `${baseUrl}__sandbox.html?${query.toString()}`
        for (const fn of previewStoryCallbacks) {
          await fn({
            file: storyFile.path,
            story,
            variant,
            url,
          })
        }
      }
    }
    await close()
  }

  await server.close()

  for (const fn of buildEndCallbacks) {
    await fn()
  }
}

function generateBaseHtml (head: string, body: string, ctx: Context) {
  return `<!DOCTYPE html>
<html>
<head>
  <title>${ctx.config.theme.title}</title>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <meta name="description" content="">
  ${head}
</head>
<body>
  ${body}
</body>
</html>`
}

function generateEntryHtml (jsEntryFile: string, cssEntryFile: string, variables: { HEAD?: string }, ctx: Context) {
  return generateBaseHtml(
    `<link rel="stylesheet" href="${ctx.resolvedViteConfig.base}${cssEntryFile}">
    ${ctx.config.theme?.favicon ? `<link rel="icon" type="${lookupMime(ctx.config.theme.favicon)}" href="${ctx.resolvedViteConfig.base}${ctx.config.theme.favicon}"/>` : ''}
    ${variables.HEAD ?? ''}`,
    `<div id="app"></div>
    <script type="module" src="${ctx.resolvedViteConfig.base}${jsEntryFile}"></script>`,
    ctx,
  )
}

async function writeFile (fileName: string, content: string, ctx: Context) {
  await fs.writeFile(join(ctx.config.outDir, fileName), content, 'utf8')
}

function generateScriptLinks (prefetchScripts: string[], rel: string, ctx: Context) {
  return prefetchScripts.map(s => `<link rel="${rel}" href="${ctx.resolvedViteConfig.base}${s}" as="script" crossOrigin="anonymous">`).join('')
}
