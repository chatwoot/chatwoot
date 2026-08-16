import { ZodError } from 'zod'
import { QueueUnavailableError } from './controller.js'
import { SignatureError } from './signature.js'

export interface WebhookHttpError {
  status: number
  body: { error: string }
  log: boolean
}

export function webhookHttpError(error: unknown): WebhookHttpError {
  if (error instanceof SignatureError) {
    return { status: 401, body: { error: 'invalid signature' }, log: false }
  }
  if (error instanceof QueueUnavailableError) {
    // Chatwoot v4.16 retries AgentBot webhooks only for 429 and 500.
    return { status: 500, body: { error: 'queue unavailable' }, log: true }
  }
  if (error instanceof ZodError || error instanceof SyntaxError) {
    return { status: 400, body: { error: 'invalid payload' }, log: false }
  }
  if (error instanceof Error && error.message.startsWith('Unknown Chatwoot account ID')) {
    return { status: 403, body: { error: 'unknown account' }, log: false }
  }
  return { status: 400, body: { error: 'invalid request' }, log: true }
}
