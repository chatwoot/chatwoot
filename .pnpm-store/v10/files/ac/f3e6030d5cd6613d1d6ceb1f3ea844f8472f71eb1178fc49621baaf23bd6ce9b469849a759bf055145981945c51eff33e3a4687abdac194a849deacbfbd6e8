import {
  defineComponent as _defineComponent,
  PropType as _PropType,
} from '@histoire/vendors/vue'
import type { Story } from '@histoire/shared'
import type { StoryOptions, VariantOptions } from './types'

export default _defineComponent({
  name: 'MountStory',

  props: {
    story: {
      type: Object as _PropType<Story>,
      required: true,
    },
  },

  setup (props) {
    const options = props.story.file.component as StoryOptions

    let rawVariants: VariantOptions[] = []

    if (options.onMount) {
      rawVariants = [{
        id: '_default',
        title: 'default',
        onMount: options.onMount,
        onMountControls: options.onMountControls,
      }]
    } else {
      rawVariants = options.variants
    }

    for (const index in props.story.variants) {
      const rawVariant = rawVariants[index]
      Object.assign(props.story.variants[index], {
        slots: () => ({ default: rawVariant.onMount, controls: rawVariant.onMountControls }),
        source: rawVariant.source ?? options.source,
        responsiveDisabled: rawVariant.responsiveDisabled ?? options.responsiveDisabled,
        autoPropsDisabled: rawVariant.autoPropsDisabled ?? options.autoPropsDisabled,
        setupApp: rawVariant.setupApp ?? options.setupApp,
        configReady: true,
      })
    }
  },

  render () {
    return null
  },
})
