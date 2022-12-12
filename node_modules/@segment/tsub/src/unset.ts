import get from 'dlv'

export function unset(obj, prop) {
  if (get(obj, prop)) {
    var segs = prop.split('.')
    var last = segs.pop()
    while (segs.length && segs[segs.length - 1].slice(-1) === '\\') {
      last = segs.pop().slice(0, -1) + '.' + last
    }
    while (segs.length) obj = obj[(prop = segs.shift())]
    return delete obj[last]
  }
  return true
}
