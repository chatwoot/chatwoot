import chokidar from 'chokidar'
import pc from 'picocolors'
import { resolveConfigFile } from '../config.js'
import { createContext } from '../context.js'
import { createServer } from '../server.js'

export interface DevOptions {
  port: number
  open?: boolean
  config?: string
}

export async function devCommand (options: DevOptions) {
  let stop: () => Promise<void>

  async function start () {
    const ctx = await createContext({
      configFile: options.config,
      mode: 'dev',
    })
    const { server, viteConfigFile, close } = await createServer(ctx, {
      port: options.port,
      open: options.open,
    })
    server.printUrls()

    // Histoire config watcher
    let watcher: chokidar.FSWatcher
    if (viteConfigFile) {
      watcher = chokidar.watch(viteConfigFile, {
        ignoreInitial: true,
      })
      watcher.on('change', () => {
        restart('Vite')
      })
    }

    return async () => {
      await watcher?.close()
      await close()
    }
  }

  async function restart (source: string) {
    if (stop) {
      console.log(pc.blue(`${source} config changed, restarting...`))
      await stop()
      stop = null // Don't call stop again until new start() is done
      stop = await start()
    }
  }

  stop = await start()

  const configFile = await resolveConfigFile(undefined, options.config)
  if (configFile) {
    const watcher = chokidar.watch(configFile, {
      ignoreInitial: true,
    })
    watcher.on('change', () => {
      restart('Histoire')
    })
  }
}
