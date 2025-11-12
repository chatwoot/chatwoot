/* eslint-disable vue/one-component-per-file */

import { App, createApp, onMounted, reactive, Component, h, VNode, Suspense } from 'vue'
import {
  defineComponent as _defineComponent,
  onBeforeUnmount as _onBeforeUnmount,
  onMounted as _onMounted,
  PropType as _PropType,
  ref as _ref,
  watch as _watch,
  h as _h,
} from '@histoire/vendors/vue'
import { applyState } from '@histoire/shared'
import type { Story, Variant, PropDefinition, AutoPropComponentDefinition } from '@histoire/shared'
import { getTagName } from '../codegen'
import { registerGlobalComponents } from './global-components.js'
import { RouterLinkStub } from './RouterLinkStub'
// @ts-expect-error virtual module id
import * as setup from 'virtual:$histoire-setup'
// @ts-expect-error virtual module id
import * as generatedSetup from 'virtual:$histoire-generated-global-setup'
import { syncStateBundledAndExternal } from './util.js'
import type { Vue3StorySetupApi, Vue3StorySetupHandler } from '../../helpers.js'

export default _defineComponent({
  name: 'RenderStory',

  props: {
    variant: {
      type: Object as _PropType<Variant>,
      required: true,
    },

    story: {
      type: Object as _PropType<Story>,
      required: true,
    },

    slotName: {
      type: String,
      default: 'default',
    },
  },

  emits: {
    ready: () => true,
  },

  setup (props, { emit }) {
    const sandbox = _ref<HTMLDivElement>()
    let app: App
    let mounting = false

    const externalState = reactive<Variant['state']>({})

    syncStateBundledAndExternal(props.variant.state, externalState)

    function unmountVariant () {
      if (app) {
        app.unmount()
        app = null
      }
    }

    async function mountVariant () {
      if (mounting) return
      mounting = true

      unmountVariant()

      let lastPropsTypesSnapshot: string

      const wrappers: Component[] = []

      app = createApp({
        name: 'RenderStorySubApp',

        setup () {
          onMounted(() => {
            mounting = false
          })
        },

        render: () => {
          const vnodes = props.variant.slots()?.[props.slotName]?.({
            state: externalState,
          }) ?? props.story.slots()?.[props.slotName]?.({
            state: externalState,
          })

          // Auto detect props
          if (props.slotName === 'default' && !props.variant.autoPropsDisabled) {
            const propsTypes: AutoPropComponentDefinition[] = scanForAutoProps(vnodes)

            const snapshot = JSON.stringify(propsTypes)
            if (!lastPropsTypesSnapshot || lastPropsTypesSnapshot !== snapshot) {
              applyState(props.variant.state, {
                _hPropDefs: propsTypes,
              })
              if (!props.variant.state._hPropState) {
                applyState(props.variant.state, {
                  _hPropState: {},
                })
              }
              lastPropsTypesSnapshot = snapshot
            }
          }

          const children: VNode[] = []
          children.push(vnodes)

          for (const [index, wrapper] of wrappers.entries()) {
            children.push(
              h(wrapper, {
                story: props.story,
                variant: props.variant,
              }, () => children[index]),
            )
          }

          // Wrap in div to ensure only one root element
          children.push(h('div', children.at(-1)))
          // Wrap in Suspense to render async components
          children.push(h(Suspense, {}, children.at(-1)))

          return children.at(-1)
        },
      })

      registerGlobalComponents(app)

      // Stubs
      app.component('RouterLink', RouterLinkStub)

      const setupApi: Vue3StorySetupApi = {
        app,
        story: props.story,
        variant: props.variant,
        addWrapper: (wrapper) => {
          wrappers.push(wrapper)
        },
      }

      if (typeof generatedSetup?.setupVue3 === 'function') {
        const setupFn = generatedSetup.setupVue3 as Vue3StorySetupHandler
        await setupFn(setupApi)
      }

      if (typeof setup?.setupVue3 === 'function') {
        const setupFn = setup.setupVue3 as Vue3StorySetupHandler
        await setupFn(setupApi)
      }

      if (typeof props.variant.setupApp === 'function') {
        const setupFn = props.variant.setupApp as Vue3StorySetupHandler
        await setupFn(setupApi)
      }

      wrappers.reverse()

      const target = document.createElement('div')
      sandbox.value.appendChild(target)
      app.mount(target)

      emit('ready')
    }

    function scanForAutoProps (vnodes: any[]) {
      const result: AutoPropComponentDefinition[] = []
      let index = 0
      for (const vnode of vnodes) {
        if (typeof vnode.type === 'object') {
          const propDefs: PropDefinition[] = []
          for (const key in vnode.type.props) {
            const prop = vnode.type.props[key]
            let types
            let defaultValue
            if (prop) {
              const rawTypes = Array.isArray(prop.type) ? prop.type : typeof prop === 'function' ? [prop] : [prop.type]
              types = rawTypes.map(t => {
                switch (t) {
                  case String:
                    return 'string'
                  case Number:
                    return 'number'
                  case Boolean:
                    return 'boolean'
                  case Object:
                    return 'object'
                  case Array:
                    return 'array'
                  default:
                    return 'unknown'
                }
              })
              defaultValue = typeof prop.default === 'function' ? prop.default.toString() : prop.default
            }
            propDefs.push({
              name: key,
              types,
              required: prop?.required,
              default: defaultValue,
            })

            // Props overrides
            if (externalState?._hPropState?.[index]?.[key] != null) {
              if (!vnode.props) {
                vnode.props = {}
              }
              vnode.props[key] = externalState._hPropState[index][key]
              if (!vnode.dynamicProps) {
                vnode.dynamicProps = []
              }
              if (!vnode.dynamicProps.includes(key)) {
                vnode.dynamicProps.push(key)
              }
            }
          }

          result.push({
            name: getTagName(vnode),
            index,
            props: propDefs,
          } as AutoPropComponentDefinition)
          index++
        }

        if (Array.isArray(vnode.children)) {
          result.push(...scanForAutoProps(vnode.children))
        }
      }
      return result.filter(def => def.props.length)
    }

    _onMounted(async () => {
      if (props.variant.configReady) {
        await mountVariant()
      }
    })

    _watch(() => props.variant, async value => {
      if (value.configReady && !mounting) {
        if (!app) {
          await mountVariant()
        } else {
          app._instance.proxy.$forceUpdate()
        }
      }
    }, {
      deep: true,
    })

    _onBeforeUnmount(() => {
      unmountVariant()
    })

    return {
      sandbox,
    }
  },

  render () {
    return _h('div', {
      ref: 'sandbox',
    })
  },
})
