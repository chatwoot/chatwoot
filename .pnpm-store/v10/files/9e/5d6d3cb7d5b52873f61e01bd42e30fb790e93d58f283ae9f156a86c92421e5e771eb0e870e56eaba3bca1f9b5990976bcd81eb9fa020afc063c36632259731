/* eslint-disable vue/one-component-per-file */

import { App, createApp, h, Suspense, Component, VNode } from 'vue'
import {
  defineComponent as _defineComponent,
  PropType as _PropType,
  onMounted as _onMounted,
  onUnmounted as _onUnmounted,
  ref as _ref,
  watch as _watch,
  h as _h,
} from '@histoire/vendors/vue'
import type { Story } from '@histoire/shared'
// @ts-expect-error virtual module id
import * as setup from 'virtual:$histoire-setup'
// @ts-expect-error virtual module id
import * as generatedSetup from 'virtual:$histoire-generated-global-setup'
import { registerGlobalComponents } from './global-components.js'
import { RouterLinkStub } from './RouterLinkStub'
import type { Vue3StorySetupHandler, Vue3StorySetupApi } from '../../helpers.js'

export default _defineComponent({
  name: 'MountStory',

  props: {
    story: {
      type: Object as _PropType<Story>,
      required: true,
    },
  },

  setup (props) {
    const el = _ref<HTMLDivElement>()
    let app: App

    async function mountStory () {
      const wrappers: Component[] = []

      app = createApp({
        name: 'MountStorySubApp',

        render: () => {
          const vnode = h(props.story.file.component, {
            story: props.story,
          })

          const children: VNode[] = []
          children.push(vnode)

          for (const [index, wrapper] of wrappers.entries()) {
            children.push(
              h(wrapper, {
                story: props.story,
                variant: null,
              },
              () => children[index]),
            )
          }

          return h(Suspense, undefined,
            children.at(-1),
          )
        },
      })

      registerGlobalComponents(app)

      // Stubs
      app.component('RouterLink', RouterLinkStub)

      // Force update (story is not reactive for user's vue)
      _watch(() => props.story.variants, () => {
        app._instance.proxy.$forceUpdate()
      })

      // Call app setups to resolve global assets such as components

      const setupApi: Vue3StorySetupApi = {
        app,
        story: props.story,
        variant: null,
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

      wrappers.reverse()

      const target = document.createElement('div')
      el.value.appendChild(target)
      app.mount(target)
    }

    function unmountStory () {
      app?.unmount()
    }

    _watch(() => props.story.id, async () => {
      unmountStory()
      await mountStory()
    })

    _onMounted(async () => {
      await mountStory()
    })

    _onUnmounted(() => {
      unmountStory()
    })

    return {
      el,
    }
  },

  render () {
    return _h('div', {
      ref: 'el',
    })
  },
})
