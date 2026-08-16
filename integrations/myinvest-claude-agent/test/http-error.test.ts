import { describe, expect, it } from 'vitest'
import { QueueUnavailableError } from '../src/webhook/controller.js'
import { webhookHttpError } from '../src/webhook/http-error.js'
import { SignatureError } from '../src/webhook/signature.js'

describe('webhookHttpError', () => {
  it('uses Chatwoot retryable status 500 for queue failures', () => {
    expect(webhookHttpError(new QueueUnavailableError())).toEqual({
      status: 500,
      body: { error: 'queue unavailable' },
      log: true,
    })
  })

  it('keeps signature failures non-retryable and private', () => {
    expect(webhookHttpError(new SignatureError('secret detail'))).toEqual({
      status: 401,
      body: { error: 'invalid signature' },
      log: false,
    })
  })
})
