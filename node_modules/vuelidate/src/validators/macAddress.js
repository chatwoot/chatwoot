import { req, withParams } from './common'

export default (separator = ':') =>
  withParams({ type: 'macAddress' }, (value) => {
    if (!req(value)) {
      return true
    }

    if (typeof value !== 'string') {
      return false
    }

    const parts =
      typeof separator === 'string' && separator !== ''
        ? value.split(separator)
        : value.length === 12 || value.length === 16
        ? value.match(/.{2}/g)
        : null

    return (
      parts !== null &&
      (parts.length === 6 || parts.length === 8) &&
      parts.every(hexValid)
    )
  })

const hexValid = (hex) => hex.toLowerCase().match(/^[0-9a-f]{2}$/)
