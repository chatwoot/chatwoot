import { createHmac, timingSafeEqual } from 'node:crypto'

export class SignatureError extends Error {
  constructor(message: string) {
    super(message)
    this.name = 'SignatureError'
  }
}

export function verifyChatwootSignature(input: {
  rawBody: string
  secret: string
  timestamp: string
  signature: string
  nowMs: number
  replayWindowSeconds: number
}): void {
  if (!/^\d{10,13}$/.test(input.timestamp)) {
    throw new SignatureError('Invalid Chatwoot timestamp')
  }
  const timestampSeconds = Number(input.timestamp)
  const nowSeconds = Math.floor(input.nowMs / 1000)
  if (
    !Number.isSafeInteger(timestampSeconds) ||
    Math.abs(nowSeconds - timestampSeconds) > input.replayWindowSeconds
  ) {
    throw new SignatureError('Chatwoot timestamp is outside the replay window')
  }
  if (!input.signature.startsWith('sha256=')) {
    throw new SignatureError('Invalid Chatwoot signature format')
  }
  const providedHex = input.signature.slice('sha256='.length)
  if (!/^[a-f\d]{64}$/i.test(providedHex)) {
    throw new SignatureError('Invalid Chatwoot signature encoding')
  }
  const provided = Buffer.from(providedHex, 'hex')
  const expected = createHmac('sha256', input.secret)
    .update(`${input.timestamp}.${input.rawBody}`)
    .digest()
  if (provided.length !== expected.length || !timingSafeEqual(provided, expected)) {
    throw new SignatureError('Invalid Chatwoot signature')
  }
}
