import { defineComponent, inject, type PropType } from 'vue'
import type { ServerStory, ServerVariant } from '@histoire/shared'

export default defineComponent({
  name: 'HistoireVariant',

  props: {
    title: {
      type: String,
      default: 'untitled',
    },

    id: {
      type: String,
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

    meta: {
      type: Object as PropType<ServerVariant['meta']>,
      default: undefined,
    },
  },

  setup (props) {
    const story = inject<ServerStory>('story')

    function generateId () {
      return `${story.id}-${story.variants.length}`
    }

    const variant: ServerVariant = {
      id: props.id ?? generateId(),
      title: props.title,
      icon: props.icon,
      iconColor: props.iconColor,
      meta: props.meta,
    }

    const addVariant = inject('addVariant') as (variant: ServerVariant) => void
    addVariant(variant)
  },

  render () {
    return null
  },
})
