/* eslint-disable @typescript-eslint/no-var-requires */
/**
 * This is a classic destination, such as:
 * https://github.com/segmentio/analytics.js-integrations/blob/master/integrations/appcues/lib/index.js
 */

const integration = require('@segment/analytics.js-integration')

export const mockIntegrationName = 'Fake'
export const Fake = integration(mockIntegrationName)

Fake.prototype.initialize = function () {
  this.load(this.ready)
}

Fake.prototype.loaded = function () {
  return true
}

Fake.prototype.track = function () {}

Fake.prototype.load = function (callback: Function) {
  // this callback is important to actually initialize.
  callback()
}
