import type { Plugin, PluginApiBase } from '@histoire/shared'
import { getInjectedImport } from '../util/vendors.js'
import { findUp } from '../util/find-up.js'
import { join } from 'pathe'

export interface PinceauTokensOptions {
  configOrPaths?: string | string[]
  configFileName?: string
}

export function pinceauTokens (options: PinceauTokensOptions = {}): Plugin {
  const themePath = join(process.cwd(), 'node_modules/.vite/pinceau/index.js')

  async function generate (api: PluginApiBase) {
    try {
      await api.fs.ensureDir(api.pluginTempDir)
      await api.fs.emptyDir(api.pluginTempDir)
      api.moduleLoader.clearCache()
      await api.fs.writeFile(api.path.resolve(api.pluginTempDir, 'style.css'), css)
      const theme = await api.moduleLoader.loadModule(themePath)
      const storyFile = api.path.resolve(api.pluginTempDir, 'Pinceau.story.js')
      await api.fs.writeFile(storyFile, storyTemplate(theme))
      api.addStoryFile(storyFile)
    } catch (e) {
      api.error(e.stack ?? e.message)
    }
  }

  return {
    name: 'builtin:pinceau-tokens',

    config (config) {
      // Add 'design-system' group
      if (!config.tree) {
        config.tree = {}
      }
      if (!config.tree.groups) {
        config.tree.groups = []
      }
      if (!config.tree.groups.some(g => g.id === 'design-system')) {
        let index = 0
        // After 'top' group
        const topIndex = config.tree.groups.findIndex(g => g.id === 'top')
        if (topIndex > -1) {
          index = topIndex + 1
        }
        // Insert group
        config.tree.groups.splice(index, 0, {
          id: 'design-system',
          title: 'Design System',
        })
      }
    },

    onDev (api, onCleanup) {
      const watcher = api.watcher.watch(themePath)
        .on('change', () => generate(api))
        .on('add', () => generate(api))

      onCleanup(() => {
        watcher.close()
      })
    },

    async onBuild (api) {
      await generate(api)
    },
  }
}

const storyTemplate = (pinceauConfig: any) => {
  pinceauConfig = pinceauConfig?.theme || pinceauConfig?.default?.theme || {}

  return `import 'histoire-style'
import './style.css'
import { createApp, h, markRaw, ref } from ${getInjectedImport('@histoire/vendors/vue')}
import {
  HstColorShades,
  HstTokenList,
  HstTokenGrid,
  HstText,
  HstTextarea,
  HstNumber,
} from ${getInjectedImport('@histoire/controls')}

const config = markRaw(${JSON.stringify(pinceauConfig, null, 2)})
const search = ref('')
const sampleText = ref('Cat sit like bread eat prawns daintily with a claw then lick paws clean wash down prawns with a lap of carnation milk then retire to the warmest spot on the couch to claw at the fabric before taking a catnap mrow cat cat moo moo lick ears lick paws')
const fontSize = ref(16)
const flattenTokens = (data, transformValue = (value) => (value?.value || value)) => {
  const output = {}
  function step(obj, prev) {
    Object.keys(obj).forEach((key) => {
      const value = obj[key]
      const isarray = Array.isArray(value)
      const type = Object.prototype.toString.call(value)
      const isobject
        = type === '[object Object]'
        || type === '[object Array]'

      const newKey = prev ? prev + '.' + key : key

      if (value.value && !output[newKey]) {
        output[newKey] = transformValue(value)
      }

      if (!isarray && isobject && Object.keys(value).length) { return step(value, newKey) }
    })
  }
  step(data)
  return output
}

function mountApp ({ el, state, onUnmount }, render) {
  Object.assign(state, {
    search,
    sampleText,
    fontSize,
  })

  const app = createApp({
    render,
  })
  app.mount(el)

  onUnmount(() => {
    app.unmount()
  })
}

/*
  media?: PinceauTokens
  colors?: ScaleTokens
  fonts?: PinceauTokens
  fontWeights?: FontWeightTokens
  fontSizes?: BreakpointsTokens
  size?: BreakpointsTokens
  space?: BreakpointsTokens
  radii?: BreakpointsTokens
  borders?: BreakpointsTokens
  borderWidths?: BreakpointsTokens
  borderStyles?: BreakpointsTokens
  shadows?: BreakpointsTokens
  opacity?: BreakpointsTokens
  leads?: BreakpointsTokens
  letterSpacings?: BreakpointsTokens
  transitions?: PinceauTokens
  zIndices?: PinceauTokens
*/

export default {
  id: 'pinceau',
  title: 'Pinceau',
  group: 'design-system',
  icon: 'noto:paintbrush',
  responsiveDisabled: true,
  layout: { type: 'single', iframe: false },
  variants: [
    {
      id: 'media-queries',
      title: 'Media Queries',
      icon: 'carbon:screen',
      onMount: (api) => mountApp(api, () => h(HstTokenGrid, {
        tokens: flattenTokens(config.media),
        getName: key => '@mq.' + key,
        colSize: 180,
      }, ({ token }) => h('div', {
        class: '__hst-drop-shadow',
      }))),
    },
    {
      id: 'colors',
      title: 'Colors',
      icon: 'carbon:color-palette',
      onMount: (api) => mountApp(api, () => Object.entries(config.colors).map(([key, shades]) => h(HstColorShades, {
        key,
        shades: shades.value ? { DEFAULT: shades.value } : flattenTokens(shades),
        getName: shade => '{colors.' + key + '.' + shade + '}',
        search: search.value,
      }, ({ color}) => h('div', {
        class: '__hst-shade',
        style: {
          backgroundColor: color,
        },
      })))),
      onMountControls: (api) => mountApp(api, () => [
        h(HstText, {
          title: 'Filter...',
          modelValue: search.value,
          'onUpdate:modelValue': value => { search.value = value },
        }),
      ]),
    },
    // SPACES
    {
      id: 'Spaces',
      title: 'Spaces',
      icon: 'carbon:area',
      onMount: (api) => mountApp(api, () => h(HstTokenList, {
        tokens: flattenTokens(config.space),
        getName: key => '{space.' + key + '}',
      }, ({ token }) => h('div', {
        class: '__hst-spaces',
        style: {
          padding: token.value,
        },
      }, [
        h('div', {
          class: '__hst-spaces-box',
        }),
      ]))),
    },
    // SIZES
    {
      id: 'sizes',
      title: 'Sizes',
      icon: 'carbon:pan-horizontal',
      onMount: (api) => mountApp(api, () => h(HstTokenList, {
        tokens: flattenTokens(config.size),
        getName: key => '{size.' + key + '}',
      }, ({ token }) => h('div', {
        class: '__hst-width',
      }, [
        h('div', {
          class: '__hst-width-box',
          style: {
            width: token.value,
          },
        }),
      ]))),
    },
    // FONTSIZES
    {
      id: 'font-size',
      title: 'Font Size',
      icon: 'carbon:text-font',
      onMount: (api) => mountApp(api, () => h(HstTokenList, {
        tokens: flattenTokens(config.fontSizes),
        getName: key => '{fontSizes.' + key + '}',
      }, ({ token }) => h('div', {
        class: '__hst-truncate',
        style: {
          fontSize: token.value,
        },
      }, sampleText.value))),
      onMountControls: (api) => mountApp(api, () => [
        h(HstTextarea, {
          title: 'Sample text',
          modelValue: sampleText.value,
          'onUpdate:modelValue': value => { sampleText.value = value },
          rows: 5,
        }),
      ]),
    },
    // FONTWEIGHTS
    {
      id: 'font-weight',
      title: 'Font Weight',
      icon: 'carbon:text-font',
      onMount: (api) => mountApp(api, () => h(HstTokenList, {
        tokens: flattenTokens(config.fontWeights),
        getName: key => '{fontWeights.' + key + '}',
      }, ({ token }) => h('div', {
        class: '__hst-truncate',
        style: {
          fontWeight: token.value,
          fontSize: \`\${fontSize.value}px\`,
        },
      }, sampleText.value))),
      onMountControls: (api) => mountApp(api, () => [
        h(HstTextarea, {
          title: 'Sample text',
          modelValue: sampleText.value,
          'onUpdate:modelValue': value => { sampleText.value = value },
          rows: 5,
        }),
        h(HstNumber, {
          title: 'Font size',
          modelValue: fontSize.value,
          'onUpdate:modelValue': value => { fontSize.value = value },
          min: 1,
        }),
      ]),
    },
    // FONTS
    {
      id: 'fonts',
      title: 'Fonts',
      icon: 'carbon:text-font',
      onMount: (api) => mountApp(api, () => h(HstTokenList, {
        tokens: flattenTokens(config.fonts),
        getName: key => '{fonts.' + key + '}',
      }, ({ token }) => h('div', {
        class: '__hst-truncate',
        style: {
          fontFamily: token.value,
          fontSize: \`\${fontSize.value}px\`,
        },
      }, sampleText.value))),
      onMountControls: (api) => mountApp(api, () => [
        h(HstTextarea, {
          title: 'Sample text',
          modelValue: sampleText.value,
          'onUpdate:modelValue': value => { sampleText.value = value },
          rows: 5,
        }),
        h(HstNumber, {
          title: 'Font size',
          modelValue: fontSize.value,
          'onUpdate:modelValue': value => { fontSize.value = value },
          min: 1,
        }),
      ]),
    },
    // LETTERSPACINGS
    {
      id: 'letter-spacing',
      title: 'Letter Spacing',
      icon: 'carbon:text-font',
      onMount: (api) => mountApp(api, () => h(HstTokenList, {
        tokens: flattenTokens(config.letterSpacings),
        getName: key => '{letterSpacings.' + key + '}',
      }, ({ token }) => h('div', {
        class: '__hst-truncate',
        style: {
          letterSpacing: token.value,
          fontSize: \`\${fontSize.value}px\`,
        },
      }, sampleText.value))),
      onMountControls: (api) => mountApp(api, () => [
        h(HstTextarea, {
          title: 'Sample text',
          modelValue: sampleText.value,
          'onUpdate:modelValue': value => { sampleText.value = value },
          rows: 5,
        }),
        h(HstNumber, {
          title: 'Font size',
          modelValue: fontSize.value,
          'onUpdate:modelValue': value => { fontSize.value = value },
          min: 1,
        }),
      ]),
    },
    // LEADS
    {
      id: 'leads',
      title: 'Leads',
      icon: 'carbon:text-font',
      onMount: (api) => mountApp(api, () => h(HstTokenList, {
        tokens: flattenTokens(config.leads),
        getName: key => '{leads.' + key + '}',
      }, ({ token }) => h('div', {
        style: {
          lineHeight: token.value,
        },
      }, sampleText.value))),
      onMountControls: (api) => mountApp(api, () => [
        h(HstTextarea, {
          title: 'Sample text',
          modelValue: sampleText.value,
          'onUpdate:modelValue': value => { sampleText.value = value },
          rows: 5,
        }),
        // @TODO select font size
      ]),
    },
    // SHADOWS
    {
      id: 'shadows',
      title: 'Shadows',
      icon: 'carbon:shape-except',
      onMount: (api) => mountApp(api, () => h(HstTokenGrid, {
        tokens: flattenTokens(config.shadows),
        getName: key => '{shadows.' + key + '}',
        colSize: 180,
      }, ({ token }) => h('div', {
        class: '__hst-drop-shadow',
        style: 'box-shadow:' + token.value,
      }))),
    },
    // OPACITIES
    {
      id: 'opacities',
      title: 'Opacities',
      icon: 'carbon:bring-forward',
      onMount: (api) => mountApp(api, () => h(HstTokenGrid, {
        tokens: flattenTokens(config.opacity),
        getName: key => '{opacity.' + key + '}',
        colSize: 180,
      }, ({ token }) => h('div', {
        class: '__hst-drop-shadow',
        style: 'opacity:' + token.value,
      }))),
    },
    // RADII
    {
      id: 'border-radius',
      title: 'Border Radius',
      icon: 'carbon:condition-wait-point',
      onMount: (api) => mountApp(api, () => h(HstTokenGrid, {
        tokens: flattenTokens(config.radii),
        getName: key => '{radii.' + key + '}',
        colSize: 180,
      }, ({ token }) => h('div', {
        class: '__hst-border-radius',
        style: {
          borderRadius: token.value,
        },
      }))),
    },
    // BORDERWIDTHS
    {
      id: 'border-width',
      title: 'Border Width',
      icon: 'carbon:checkbox',
      onMount: (api) => mountApp(api, () => h(HstTokenGrid, {
        tokens: flattenTokens(config.borderWidths),
        getName: key => '{borderWidths.' + key + '}',
        colSize: 180,
      }, ({ token }) => h('div', {
        class: '__hst-border-width',
        style: {
          borderWidth: token.value,
        },
      }))),
    },
    // FULL CONFIG
    {
      id: 'full-config',
      title: 'Full Config',
      icon: 'carbon:code',
      onMount: (api) => mountApp(api, () => h('pre', JSON.stringify(config, null, 2))),
    },
  ],
}`
}

const css = `.__hst-shade {
  height: 80px;
  border-radius: 4px;
}

.__hst-text {
  font-size: 4rem;
  display: flex;
  align-items: flex-end;
}

.__hst-border {
  border-style: solid;
  border-width: 2px;
}

.__hst-spaces {
  background-color: rgb(113 113 122 / 0.1);
  width: min-content;
}

.__hst-margin {
  border: dashed 1px rgb(113 113 122 / 0.5);
  width: min-content;
}

.__hst-spaces-box,
.__hst-margin-box {
  width: 5rem;
  height: 5rem;
  background-color: rgb(113 113 122 / 0.5);
}

.__hst-spaces,
.__hst-spaces-box,
.__hst-margin,
.__hst-margin-box,
.__hst-drop-shadow {
  border-radius: 4px;
}

.__hst-truncate {
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.__hst-drop-shadow {
  width: 8rem;
  height: 8rem;
  background: white;
  margin-bottom: 0.5rem;
}

.__hst-drop-shadow {
  background: #4e4e57;
}

.__hst-border-radius {
  width: 8rem;
  height: 8rem;
  background-color: rgb(113 113 122 / 0.5);
}

.__hst-border-width {
  width: 8rem;
  height: 8rem;
  border-color: rgb(113 113 122 / 0.5);
  background-color: rgb(113 113 122 / 0.1);
}

.__hst-width {
  background-color: rgb(113 113 122 / 0.1);
}

.__hst-width-box,
.__hst-height {
  background-color: rgb(113 113 122 / 0.5);
}

.__hst-width-box {
  height: 5rem;
}`
