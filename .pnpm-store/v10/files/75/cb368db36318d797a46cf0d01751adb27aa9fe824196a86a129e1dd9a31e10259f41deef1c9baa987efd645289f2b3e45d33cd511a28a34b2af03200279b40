import { SegmentEvent } from '../../core/events'
import { fetch } from '../../lib/fetch'
import { onPageLeave } from '../../lib/on-page-leave'

export type BatchingDispatchConfig = {
  size?: number
  timeout?: number
}

const MAX_PAYLOAD_SIZE = 500

function kilobytes(buffer: unknown): number {
  const size = encodeURI(JSON.stringify(buffer)).split(/%..|./).length - 1
  return size / 1024
}

/**
 * Checks if the payload is over or close to
 * the maximum payload size allowed by tracking
 * API.
 */
function approachingTrackingAPILimit(buffer: unknown): boolean {
  return kilobytes(buffer) >= MAX_PAYLOAD_SIZE - 50
}

function chunks(batch: object[]): Array<object[]> {
  const result: object[][] = []
  let index = 0

  batch.forEach((item) => {
    const size = kilobytes(result[index])
    if (size >= 64) {
      index++
    }

    if (result[index]) {
      result[index].push(item)
    } else {
      result[index] = [item]
    }
  })

  return result
}

export default function batch(
  apiHost: string,
  config?: BatchingDispatchConfig
) {
  let buffer: object[] = []
  let pageUnloaded = false

  const limit = config?.size ?? 10
  const timeout = config?.timeout ?? 5000

  function sendBatch(batch: object[]) {
    if (batch.length === 0) {
      return
    }

    const writeKey = (batch[0] as SegmentEvent)?.writeKey

    return fetch(`https://${apiHost}/b`, {
      keepalive: pageUnloaded,
      headers: {
        'Content-Type': 'application/json',
      },
      method: 'post',
      body: JSON.stringify({ batch, writeKey }),
    })
  }

  async function flush(): Promise<unknown> {
    if (buffer.length) {
      const batch = buffer
      buffer = []
      return sendBatch(batch)
    }
  }

  let schedule: NodeJS.Timeout | undefined

  function scheduleFlush(): void {
    if (schedule) {
      return
    }

    schedule = setTimeout(() => {
      schedule = undefined
      flush().catch(console.error)
    }, timeout)
  }

  onPageLeave(() => {
    pageUnloaded = true

    if (buffer.length) {
      const reqs = chunks(buffer).map(sendBatch)
      Promise.all(reqs).catch(console.error)
    }
  })

  async function dispatch(_url: string, body: object): Promise<unknown> {
    buffer.push(body)

    const bufferOverflow =
      buffer.length >= limit || approachingTrackingAPILimit(buffer)

    return bufferOverflow || pageUnloaded ? flush() : scheduleFlush()
  }

  return {
    dispatch,
  }
}
