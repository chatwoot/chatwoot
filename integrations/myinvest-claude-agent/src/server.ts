import express from 'express'
import { Queue, Worker } from 'bullmq'
import { Redis } from 'ioredis'
import pg from 'pg'
import { ChatwootClient } from './chatwoot-client.js'
import { createClaudeClient } from './claude.js'
import { loadConfig } from './config.js'
import { PostgresKnowledgeRepository } from './knowledge/repository.js'
import { MessageProcessor } from './processor.js'
import { DeliveryQueue, QUEUE_NAME, type DeliveryJob } from './queue.js'
import { PostgresAgentState } from './state.js'
import { WebhookController } from './webhook/controller.js'
import { webhookHttpError } from './webhook/http-error.js'

const config = loadConfig()
const redis = new Redis(config.REDIS_URL, { maxRetriesPerRequest: null })
const pool = new pg.Pool({ connectionString: config.DATABASE_URL, max: 10 })
const queue = new Queue<DeliveryJob>(QUEUE_NAME, { connection: redis })
const deliveryQueue = new DeliveryQueue(queue, {
  retentionSeconds: config.DELIVERY_RETENTION_SECONDS,
})
const processor = new MessageProcessor({
  knowledge: new PostgresKnowledgeRepository(pool),
  claude: createClaudeClient(config),
  chatwoot: new ChatwootClient(config.CHATWOOT_BASE_URL),
  state: new PostgresAgentState(pool),
  minRetrievalScore: config.KNOWLEDGE_MIN_SCORE,
  maxSources: config.KNOWLEDGE_MAX_SOURCES,
})
const controller = new WebhookController({
  tenants: config.tenants,
  queue: deliveryQueue,
  replayWindowSeconds: config.WEBHOOK_REPLAY_WINDOW_SECONDS,
})

const worker =
  config.RUN_MODE === 'web'
    ? undefined
    : new Worker<DeliveryJob>(
        QUEUE_NAME,
        async (job) => {
          const tenant = config.tenants.requireByKey(job.data.tenantKey)
          await processor.process({ tenant, payload: job.data.payload })
        },
        { connection: redis.duplicate(), concurrency: 4 },
      )

worker?.on('failed', (job, error) =>
  console.error('Agent job failed', job?.id, error.message),
)

const app = express()
app.get('/health', async (_request, response) => {
  try {
    await Promise.all([pool.query('SELECT 1'), redis.ping()])
    response.json({ status: 'ok' })
  } catch {
    response.status(503).json({ status: 'unavailable' })
  }
})

app.post(
  '/webhooks/chatwoot',
  express.raw({ type: 'application/json', limit: config.MAX_BODY_BYTES }),
  async (request, response) => {
    if (!Buffer.isBuffer(request.body)) {
      return response.status(415).json({ error: 'application/json required' })
    }
    try {
      const result = await controller.handle(request.body.toString('utf8'), request.headers)
      return response.status(result.status).json(result.body)
    } catch (error) {
      const rejection = webhookHttpError(error)
      if (rejection.log) {
        console.error('Webhook rejected', error instanceof Error ? error.message : 'unknown error')
      }
      return response.status(rejection.status).json(rejection.body)
    }
  },
)

const server =
  config.RUN_MODE === 'worker'
    ? undefined
    : app.listen(config.PORT, '0.0.0.0', () =>
        console.log(`Claude agent listening on ${config.PORT}`),
      )

async function shutdown(signal: string) {
  console.log(`Received ${signal}; shutting down`)
  server?.close()
  await worker?.close()
  await queue.close()
  await redis.quit()
  await pool.end()
  process.exit(0)
}

process.on('SIGTERM', () => void shutdown('SIGTERM'))
process.on('SIGINT', () => void shutdown('SIGINT'))
