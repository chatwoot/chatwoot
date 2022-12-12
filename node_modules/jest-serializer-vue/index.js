const beautify = require('pretty')

const isHtmlString = received => received && typeof received === 'string' && received[0] === '<'
const isVueWrapper = received => (
  received &&
  typeof received === 'object' &&
  typeof received.isVueInstance === 'function'
)

module.exports = {
  test (received) {
    return isHtmlString(received) || isVueWrapper(received)
  },
  print (received) {
    const html = (isVueWrapper(received) ? received.html() : received) || ''
    const removedServerRenderedText = html.replace(/ data-server-rendered="true"/, '')
    return beautify(removedServerRenderedText, { indent_size: 2 })
  }
}
