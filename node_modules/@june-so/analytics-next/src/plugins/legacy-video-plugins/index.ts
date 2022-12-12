import { Analytics } from '../../analytics'

export async function loadLegacyVideoPlugins(
  analytics: Analytics
): Promise<void> {
  const plugins = await import(
    // @ts-expect-error
    '@segment/analytics.js-video-plugins/dist/index.umd.js'
  )

  // This is super gross, but we need to support the `window.analytics.plugins` namespace
  // that is linked in the segment docs in order to be backwards compatible with ajs-classic

  // @ts-expect-error
  analytics._plugins = plugins
}
