/* eslint-disable vue/one-component-per-file */

import {
  App,
  defineComponent,
  ref,
  h,
  onMounted,
  onBeforeUpdate,
  onBeforeUnmount,
  onUpdated,
} from 'vue'
import {
  createApp as _createApp,
  h as _h,
  App as _App,
  reactive as _reactive,
} from '@histoire/vendors/vue'
import { components } from '@histoire/controls'
import Story from './Story'
import Variant from './Variant'

export function registerGlobalComponents (app: App) {
  // eslint-disable-next-line vue/multi-word-component-names
  app.component('Story', Story)
  // eslint-disable-next-line vue/multi-word-component-names
  app.component('Variant', Variant)

  for (const key in components) {
    app.component(key, wrapControlComponent(components[key]))
  }
}

function wrapControlComponent (controlComponent) {
  return defineComponent({
    name: controlComponent.name,
    inheritAttrs: false,
    setup (props, { attrs }) {
      const el = ref<HTMLDivElement>()
      const slotEl = ref<HTMLDivElement>()

      // Attrs

      const state = _reactive({})

      function applyState (data) {
        Object.assign(state, data)
      }

      applyState(attrs)
      onBeforeUpdate(() => {
        applyState(attrs)
      })

      // Slots

      let newSlotCalls = []
      const slotCalls = ref([])

      function moveSlotContent () {
        slotCalls.value.forEach((props, index) => {
          const renderedEl = slotEl.value.querySelector(`[renderslotid="${index}"]`)
          if (!renderedEl) return
          const targetEl = el.value.querySelector(`[slotid="${index}"]`)
          while (targetEl.firstChild) {
            targetEl.removeChild(targetEl.lastChild)
          }
          targetEl.appendChild(renderedEl)
        })
      }

      // App

      let app: _App

      onMounted(() => {
        app = _createApp({
          mounted () {
            slotCalls.value = newSlotCalls
            newSlotCalls = []
          },
          updated () {
            slotCalls.value = newSlotCalls
            newSlotCalls = []
          },
          render () {
            return _h(controlComponent, {
              ...state,
              key: 'component',
            }, {
              default: props => {
                newSlotCalls.push(props)
                return _h('div', {
                  slotId: newSlotCalls.length - 1,
                })
              },
            })
          },
        })
        app.mount(el.value)
      })

      onUpdated(() => {
        moveSlotContent()
      })

      onBeforeUnmount(() => {
        app.unmount()
      })

      return {
        el,
        slotEl,
        slotCalls,
      }
    },
    render () {
      return [
        h('div', {
          ref: 'el',
        }),
        h('div', {
          ref: 'slotEl',
        }, this.slotCalls.map((props, index) => h('div', {
          renderSlotId: index,
        }, this.$slots.default(props)))),
      ]
    },
  })
}
