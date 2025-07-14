import { defineComponent, inject, onMounted, PropType, provide, useAttrs } from 'vue'
import type { ServerStoryFile, ServerStory, ServerVariant } from '@histoire/shared'
import { autoStubComponents } from './stub'

export default defineComponent({
  name: 'HistoireStory',

  inheritAttrs: false,

  props: {
    title: {
      type: String,
      default: undefined,
    },

    id: {
      type: String,
      default: undefined,
    },

    group: {
      type: String,
      default: undefined,
    },

    layout: {
      type: Object as PropType<ServerStory['layout']>,
      default: undefined,
    },

    icon: {
      type: String,
      default: undefined,
    },

    iconColor: {
      type: String,
      default: undefined,
    },

    docsOnly: {
      type: Boolean,
      default: false,
    },

    meta: {
      type: Object as PropType<ServerStory['meta']>,
      default: undefined,
    },
  },

  setup (props) {
    const attrs = useAttrs() as {
      data: ServerStoryFile
    }

    // Story

    const story: ServerStory = {
      id: props.id ?? attrs.data.id,
      title: props.title ?? attrs.data.fileName,
      group: props.group,
      layout: props.layout,
      icon: props.icon,
      iconColor: props.iconColor,
      docsOnly: props.docsOnly,
      meta: props.meta,
      variants: [],
    }
    const addStory = inject('addStory', null)
    addStory?.(story)

    // Variants

    provide('story', story)

    provide('addVariant', (variant: ServerVariant) => {
      story.variants.push(variant)
    })

    onMounted(() => {
      if (!story.variants.length) {
        story.variants.push({
          id: '_default',
          title: 'default',
        })
      }
    })

    return {
      story,
    }
  },

  render () {
    let suppressError = false
    try {
      const vnodes = this.$slots.default?.({
        get state () {
          // No variant tags
          suppressError = true
          return {}
        },
      })

      // Auto stub components
      if (Array.isArray(vnodes)) {
        autoStubComponents(vnodes)
      }

      return vnodes
    } catch (e) {
      if (!suppressError) {
        console.error(e)
      }
      return null
    }
  },
})
