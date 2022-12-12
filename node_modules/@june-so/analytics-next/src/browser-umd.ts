import { getCDN } from './lib/parse-cdn'
import { setVersionType } from './plugins/segmentio/normalize'

if (process.env.ASSET_PATH) {
  if (process.env.ASSET_PATH === '/dist/umd/') {
    // @ts-ignore
    // eslint-disable-next-line @typescript-eslint/camelcase
    __webpack_public_path__ = '/dist/umd/'
  } else {
    const cdn = window.analytics?._cdn ?? getCDN()
    if (window.analytics) window.analytics._cdn = cdn

    // @ts-ignore
    // eslint-disable-next-line @typescript-eslint/camelcase
    __webpack_public_path__ = cdn + '/analytics-next/bundles/'
  }
}

setVersionType('web')

export * from './browser'
