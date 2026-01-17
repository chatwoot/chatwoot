import http from 'node:http'
import connect from 'connect'
import sirv from 'sirv'
import type { Context } from './context.js'

interface ReturnPayload {
  baseUrl: string
  close: () => Promise<void>
}

export async function startPreview (port: number | null, ctx: Context): Promise<ReturnPayload> {
  const app = connect()

  app.use(
    ctx.resolvedViteConfig.base,
    sirv(ctx.config.outDir, {
      dev: true,
      etag: true,
      single: true,
    }),
  )

  let finalPort = port ?? 6006

  const httpServer = http.createServer(app)

  return new Promise((resolve, reject) => {
    function onError (e: Error & { code?: string }) {
      if (e.code === 'EADDRINUSE') {
        httpServer.listen(++finalPort)
      } else {
        reject(e)
      }
    }

    httpServer.on('error', onError)

    httpServer.listen(finalPort, () => {
      httpServer.off('error', onError)
      const baseUrl = `http://localhost:${finalPort}${ctx.resolvedViteConfig.base}`
      resolve({
        baseUrl,
        close: () => new Promise((resolve, reject) => {
          httpServer.close((err) => {
            if (err) {
              reject(err)
            } else {
              resolve()
            }
          })
        }),
      })
    })
  })
}
