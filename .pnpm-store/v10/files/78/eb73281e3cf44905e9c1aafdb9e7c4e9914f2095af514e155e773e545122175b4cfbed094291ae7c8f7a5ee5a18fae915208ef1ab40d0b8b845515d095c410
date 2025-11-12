import { getInjectedImport } from '../util/vendors.js';
import { findUp } from '../util/find-up.js';
export function tailwindTokens(options = {}) {
    const tailwindConfigFile = options.configFile ?? findUp(process.cwd(), [
        'tailwind.config.js',
        'tailwind.config.cjs',
        'tailwind.config.mjs',
        'tailwind.config.ts',
        'tailwind-config.js',
        'tailwind-config.cjs',
        'tailwind-config.mjs',
        'tailwind-config.ts',
    ]);
    async function generate(api) {
        try {
            await api.fs.ensureDir(api.pluginTempDir);
            await api.fs.emptyDir(api.pluginTempDir);
            api.moduleLoader.clearCache();
            await api.fs.writeFile(api.path.resolve(api.pluginTempDir, 'style.css'), css);
            const tailwindConfig = await api.moduleLoader.loadModule(tailwindConfigFile);
            const { default: resolveConfig } = await import('tailwindcss/resolveConfig.js');
            const resolvedTailwindConfig = resolveConfig(tailwindConfig);
            const storyFile = api.path.resolve(api.pluginTempDir, 'Tailwind.story.js');
            await api.fs.writeFile(storyFile, storyTemplate(resolvedTailwindConfig));
            api.addStoryFile(storyFile);
        }
        catch (e) {
            api.error(e.stack ?? e.message);
        }
    }
    return {
        name: 'builtin:tailwind-tokens',
        config(config) {
            if (tailwindConfigFile) {
                // Add 'design-system' group
                if (!config.tree) {
                    config.tree = {};
                }
                if (!config.tree.groups) {
                    config.tree.groups = [];
                }
                if (!config.tree.groups.some(g => g.id === 'design-system')) {
                    let index = 0;
                    // After 'top' group
                    const topIndex = config.tree.groups.findIndex(g => g.id === 'top');
                    if (topIndex > -1) {
                        index = topIndex + 1;
                    }
                    // Insert group
                    config.tree.groups.splice(index, 0, {
                        id: 'design-system',
                        title: 'Design System',
                    });
                }
            }
        },
        onDev(api, onCleanup) {
            if (tailwindConfigFile) {
                const watcher = api.watcher.watch(tailwindConfigFile)
                    .on('change', () => generate(api))
                    .on('add', () => generate(api));
                onCleanup(() => {
                    watcher.close();
                });
            }
        },
        async onBuild(api) {
            if (tailwindConfigFile) {
                await generate(api);
            }
        },
    };
}
const storyTemplate = (tailwindConfig) => `import 'histoire-style'
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

const config = markRaw(${JSON.stringify(tailwindConfig, null, 2)})
const search = ref('')
const sampleText = ref('Cat sit like bread eat prawns daintily with a claw then lick paws clean wash down prawns with a lap of carnation milk then retire to the warmest spot on the couch to claw at the fabric before taking a catnap mrow cat cat moo moo lick ears lick paws')
const fontSize = ref(16)

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

export default {
  id: 'tailwind',
  title: 'Tailwind',
  group: 'design-system',
  icon: 'mdi:tailwind',
  responsiveDisabled: true,
  layout: { type: 'single', iframe: false },
  variants: [
    {
      id: 'background-color',
      title: 'Background Color',
      icon: 'carbon:color-palette',
      onMount: (api) => mountApp(api, () => Object.entries(config.theme.backgroundColor).map(([key, shades]) => h(HstColorShades, {
        key,
        shades: typeof shades === 'object' ? shades : { DEFAULT: shades },
        getName: shade => (config.prefix ?? '') + (shade === 'DEFAULT' ? \`bg-\${key}\` : \`bg-\${key}-\${shade}\`),
        search: search.value,
      }, ({ color}) => h('div', {
        class: '__hst-shade',
        style: {
          backgroundColor: color.replace('<alpha-value>', 1),
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
    {
      id: 'text-color',
      title: 'Text Color',
      icon: 'carbon:text-color',
      onMount: (api) => mountApp(api, () => Object.entries(config.theme.textColor).map(([key, shades]) => h(HstColorShades, {
        key,
        shades: typeof shades === 'object' ? shades : { DEFAULT: shades },
        getName: shade => (config.prefix ?? '') + (shade === 'DEFAULT' ? \`text-\${key}\` : \`text-\${key}-\${shade}\`),
        search: search.value,
      }, ({ color}) => h('div', {
        class: '__hst-shade __hst-text',
        style: {
          color: color.replace('<alpha-value>', 1),
        },
      }, 'Aa')))),
      onMountControls: (api) => mountApp(api, () => [
        h(HstText, {
          title: 'Filter...',
          modelValue: search.value,
          'onUpdate:modelValue': value => { search.value = value },
        }),
      ]),
    },
    {
      id: 'border-color',
      title: 'Border Color',
      icon: 'carbon:color-palette',
      onMount: (api) => mountApp(api, () => Object.entries(config.theme.borderColor).map(([key, shades]) => h(HstColorShades, {
        key,
        shades: typeof shades === 'object' ? shades : { DEFAULT: shades },
        getName: shade => (config.prefix ?? '') + (shade === 'DEFAULT' ? \`border-\${key}\` : \`border-\${key}-\${shade}\`),
        search: search.value,
      }, ({ color}) => h('div', {
        class: '__hst-shade __hst-border',
        style: {
          borderColor: color.replace('<alpha-value>', 1),
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
    {
      id: 'padding',
      title: 'Padding',
      icon: 'carbon:area',
      onMount: (api) => mountApp(api, () => h(HstTokenList, {
        tokens: config.theme.padding,
        getName: key => \`\${config.prefix ?? ''}p-\${key}\`,
      }, ({ token }) => h('div', {
        class: '__hst-padding',
        style: {
          padding: token.value,
        },
      }, [
        h('div', {
          class: '__hst-padding-box',
        }),
      ]))),
    },
    {
      id: 'margin',
      title: 'Margin',
      icon: 'carbon:area',
      onMount: (api) => mountApp(api, () => h(HstTokenList, {
        tokens: config.theme.margin,
        getName: key => \`\${config.prefix ?? ''}m-\${key}\`,
      }, ({ token }) => h('div', {
        class: '__hst-margin',
      }, [
        h('div', {
          class: '__hst-margin-box',
          style: {
            margin: token.value,
          },
        }),
      ]))),
    },
    {
      id: 'font-size',
      title: 'Font Size',
      icon: 'carbon:text-font',
      onMount: (api) => mountApp(api, () => h(HstTokenList, {
        tokens: config.theme.fontSize,
        getName: key => \`\${config.prefix ?? ''}text-\${key}\`,
      }, ({ token }) => h('div', {
        class: '__hst-truncate',
        style: {
          fontSize: Array.isArray(token.value) ? token.value[0] : token.value,
          ...(Array.isArray(token.value) && typeof token.value[1] === "object" ? token.value[1] : { lineHeight: token.value[1] })
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
    {
      id: 'font-weight',
      title: 'Font Weight',
      icon: 'carbon:text-font',
      onMount: (api) => mountApp(api, () => h(HstTokenList, {
        tokens: config.theme.fontWeight,
        getName: key => \`\${config.prefix ?? ''}font-\${key}\`,
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
    {
      id: 'font-family',
      title: 'Font Family',
      icon: 'carbon:text-font',
      onMount: (api) => mountApp(api, () => h(HstTokenList, {
        tokens: config.theme.fontFamily,
        getName: key => \`\${config.prefix ?? ''}font-\${key}\`,
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
    {
      id: 'letter-spacing',
      title: 'Letter Spacing',
      icon: 'carbon:text-font',
      onMount: (api) => mountApp(api, () => h(HstTokenList, {
        tokens: config.theme.letterSpacing,
        getName: key => \`\${config.prefix ?? ''}tracking-\${key}\`,
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
    {
      id: 'line-height',
      title: 'Line Height',
      icon: 'carbon:text-font',
      onMount: (api) => mountApp(api, () => h(HstTokenList, {
        tokens: config.theme.lineHeight,
        getName: key => \`\${config.prefix ?? ''}leading-\${key}\`,
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
    {
      id: 'drop-shadow',
      title: 'Drop Shadow',
      icon: 'carbon:shape-except',
      onMount: (api) => mountApp(api, () => h(HstTokenGrid, {
        tokens: config.theme.dropShadow,
        getName: key => (config.prefix ?? '') + (key === 'DEFAULT' ? 'drop-shadow' : \`drop-shadow-\${key}\`),
        colSize: 180,
      }, ({ token }) => h('div', {
        class: '__hst-drop-shadow',
        style: {
          filter: \`\${(Array.isArray(token.value) ? token.value : [token.value]).map(v => \`drop-shadow(\${v})\`).join(' ')}\`,
        },
      }))),
    },
    {
      id: 'border-radius',
      title: 'Border Radius',
      icon: 'carbon:condition-wait-point',
      onMount: (api) => mountApp(api, () => h(HstTokenGrid, {
        tokens: config.theme.borderRadius,
        getName: key => (config.prefix ?? '') + (key === 'DEFAULT' ? 'rounded' : \`rounded-\${key}\`),
        colSize: 180,
      }, ({ token }) => h('div', {
        class: '__hst-border-radius',
        style: {
          borderRadius: token.value,
        },
      }))),
    },
    {
      id: 'border-width',
      title: 'Border Width',
      icon: 'carbon:checkbox',
      onMount: (api) => mountApp(api, () => h(HstTokenGrid, {
        tokens: config.theme.borderWidth,
        getName: key => (config.prefix ?? '') + (key === 'DEFAULT' ? 'border' : \`border-\${key}\`),
        colSize: 180,
      }, ({ token }) => h('div', {
        class: '__hst-border-width',
        style: {
          borderWidth: token.value,
        },
      }))),
    },
    {
      id: 'width',
      title: 'Width',
      icon: 'carbon:pan-horizontal',
      onMount: (api) => mountApp(api, () => h(HstTokenList, {
        tokens: config.theme.width,
        getName: key => (config.prefix ?? '') + (key === 'DEFAULT' ? 'w' : \`w-\${key}\`),
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
    {
      id: 'height',
      title: 'Height',
      icon: 'carbon:pan-vertical',
      onMount: (api) => mountApp(api, () => h(HstTokenList, {
        tokens: config.theme.height,
        getName: key => (config.prefix ?? '') + (key === 'DEFAULT' ? 'h' : \`h-\${key}\`),
      }, ({ token }) => h('div', {
        class: '__hst-height',
        style: {
          height: token.value,
        },
      }))),
    },
    {
      id: 'full-config',
      title: 'Full Config',
      icon: 'carbon:code',
      onMount: (api) => mountApp(api, () => h('pre', JSON.stringify(config, null, 2))),
    },
  ],
}`;
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

.__hst-padding {
  background-color: rgb(113 113 122 / 0.1);
  width: min-content;
}

.__hst-margin {
  border: dashed 1px rgb(113 113 122 / 0.5);
  width: min-content;
}

.__hst-padding-box,
.__hst-margin-box {
  width: 5rem;
  height: 5rem;
  background-color: rgb(113 113 122 / 0.5);
}

.__hst-padding,
.__hst-padding-box,
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
}`;
