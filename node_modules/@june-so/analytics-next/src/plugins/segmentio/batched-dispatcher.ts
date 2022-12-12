import unfetch from 'unfetch'
import { SegmentEvent } from '../../core/events'

let fetch = unfetch
if (typeof window !== 'undefined') {
  // @ts-ignore
  fetch = window.fetch || unfetch
}

type BatchingConfig = {
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

export default function batch(apiHost: string, config?: BatchingConfig) {
  let buffer: Array<[string, object]> = []
  let flushing = false

  const limit = config?.size ?? 10
  const timeout = config?.timeout ?? 5000

  function flush(): unknown {
    if (flushing) {
      return
    }

    flushing = true

    const batch = buffer.map(([_url, blob]) => {
      return blob
    })

    buffer = []
    flushing = false

    const writeKey = (batch[0] as SegmentEvent)?.writeKey

    return fetch(`https://${apiHost}/b`, {
      // @ts-ignore
      headers: {
        'Content-Type': 'application/json',
      },
      method: 'post',
      body: JSON.stringify({ batch, writeKey }),
    })
  }

  // eslint-disable-next-line @typescript-eslint/no-use-before-define
  let schedule: NodeJS.Timeout | undefined = scheduleFlush()

  function scheduleFlush(): NodeJS.Timeout {
    return setTimeout(() => {
      schedule = undefined
      if (buffer.length && !flushing) {
        flush()
      }
    }, timeout)
  }

  window.addEventListener('beforeunload', () => {
    if (buffer.length === 0) {
      return
    }

    const batch = buffer.map(([_url, blob]) => {
      return blob
    })

    const chunked = chunks(batch)

    const reqs = chunked.map(async (chunk) => {
      if (chunk.length === 0) {
        return
      }

      const remote = `https://${apiHost}/b`
      const writeKey = (chunk[0] as SegmentEvent)?.writeKey

      return fetch(remote, {
        // @ts-expect-error
        keepalive: true,
        headers: {
          'Content-Type': 'application/json',
        },
        method: 'post',
        body: JSON.stringify({ batch: chunk, writeKey }),
      })
    })

    Promise.all(reqs).catch(console.error)
  })

  async function dispatch(url: string, body: object): Promise<unknown> {
    buffer.push([url, body])

    const bufferOverflow =
      buffer.length >= limit || approachingTrackingAPILimit(buffer)

    if (bufferOverflow && !flushing) {
      flush()
    } else {
      if (!schedule) {
        schedule = scheduleFlush()
      }
    }

    return true
  }

  return {
    dispatch,
  }
}
