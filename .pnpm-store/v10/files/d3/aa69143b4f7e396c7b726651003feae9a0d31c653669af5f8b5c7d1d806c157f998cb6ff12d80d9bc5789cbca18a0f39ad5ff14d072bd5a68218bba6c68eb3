import { MessageChannel } from 'node:worker_threads'
import type { ViteDevServer } from 'vite'
import { ViteNodeServer } from 'vite-node/server'
import type { FetchFunction, ResolveIdFunction } from 'vite-node'
import { relative } from 'pathe'
import pc from 'picocolors'
import Tinypool from '@akryum/tinypool'
import { createBirpc } from 'birpc'
import { cpus } from 'node:os'
import type { ServerStoryFile } from '@histoire/shared'
import { createPath } from '../tree.js'
import type { Context } from '../context.js'
import type { Payload, ReturnData } from './worker.js'
import { slash } from '../util/fs.js'

export interface UseCollectStoriesOptions {
  server: ViteDevServer
  mainServer?: ViteDevServer
  throws?: boolean
}

export function useCollectStories (options: UseCollectStoriesOptions, ctx: Context) {
  const { server, mainServer } = options

  const node = new ViteNodeServer(server, {
    deps: {
      inline: [
        /histoire\/dist/,
        /histoire\/client/,
        /@histoire\/[\w\d-]+\/dist/,
        /histoire-[\w\d-]+\/dist/,
        /@vue\/devtools-api/,
        /vuetify/,
        // @TODO temporary fix for https://github.com/histoire-dev/histoire/issues/409
        /vite\w*\/dist\/client\/(client|env).mjs/,
        ...ctx.config.viteNodeInlineDeps ?? [],
      ],
      fallbackCJS: true,
    },
    transformMode: ctx.config.viteNodeTransformMode,
  })

  const maxThreads = ctx.config.collectMaxThreads ?? cpus().length

  const threadsCount = ctx.mode === 'dev'
    ? Math.max(Math.min(maxThreads, Math.floor(cpus().length / 2)), 1)
    : Math.max(Math.min(maxThreads, cpus().length - 1), 1)
  console.log(pc.blue(`Using ${threadsCount} thread${threadsCount === 1 ? '' : 's'} for story collection`))

  const threadPool = new Tinypool({
    filename: new URL('./worker.js', import.meta.url).href,
    // WebContainer compatibility (Stackblitz)
    useAtomics: typeof process.versions.webcontainer !== 'string',
    minThreads: threadsCount,
    maxThreads: threadsCount,
  })

  function clearCache () {
    server.moduleGraph.invalidateAll()
    node.fetchCache.clear()
  }

  function createChannel () {
    const channel = new MessageChannel()
    const port = channel.port2
    const workerPort = channel.port1

    createBirpc<Record<string, never>, {
      fetchModule: FetchFunction
      resolveId: ResolveIdFunction
    }>({
      fetchModule: (id) => node.fetchModule(id),
      resolveId: (id, importer) => node.resolveId(id, importer),
    }, {
      post: data => port.postMessage(data),
      on: data => port.on('message', data),
    })

    return {
      port,
      workerPort,
    }
  }

  if (mainServer) {
    mainServer.watcher.on('change', (file) => {
      file = slash(file)
      threadPool.broadcastMessage({
        kind: 'hst:invalidate',
        file,
      })
    })
  }

  async function executeStoryFile (storyFile: ServerStoryFile) {
    try {
      const { workerPort } = createChannel()
      const payload: Payload = {
        root: server.config.root,
        base: server.config.base,
        storyFile,
        port: workerPort,
      }
      const { storyData } = await threadPool.run(payload, {
        transferList: [
          workerPort,
        ],
      }) as ReturnData
      if (storyData.length === 0) {
        console.warn(pc.yellow(`⚠️  No story found for ${storyFile.path}`))
        return
      } else if (storyData.length > 1) {
        console.warn(pc.yellow(`⚠️  Multiple stories not supported: ${storyFile.path}`))
      }

      const finalData = storyData[0]

      // Default props
      if (ctx.config.defaultStoryProps) {
        for (const key in ctx.config.defaultStoryProps) {
          if (finalData[key] == null) {
            finalData[key] = ctx.config.defaultStoryProps[key]
          }
        }
      }

      if (!finalData.layout) {
        finalData.layout = { type: 'single', iframe: true }
      }

      storyFile.id = finalData.id
      storyFile.story = finalData
      storyFile.treeFile = {
        title: finalData.title,
        path: relative(server.config.root, storyFile.path),
      }
      storyFile.treePath = createPath(ctx.config, storyFile.treeFile)
      storyFile.story.title = storyFile.treePath[storyFile.treePath.length - 1]
    } catch (e) {
      console.error(pc.red(`Error while collecting story ${storyFile.path}:\n${e.frame ? `${pc.bold(e.message)}\n${e.frame}` : e.stack}`))
      if (options.throws) {
        throw e
      }
    }
  }

  async function destroy () {
    await threadPool.destroy()
  }

  return {
    clearCache,
    executeStoryFile,
    destroy,
  }
}
