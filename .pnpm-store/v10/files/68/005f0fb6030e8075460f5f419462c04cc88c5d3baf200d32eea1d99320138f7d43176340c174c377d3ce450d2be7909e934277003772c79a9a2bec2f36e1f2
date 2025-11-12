import { computed, defineComponent, provide, useAttrs, VNode, h, PropType, getCurrentInstance, reactive, cloneVNode } from 'vue'
import { Story, omitInheritStoryProps } from '@histoire/shared'
import Variant from './Variant'

export default defineComponent({
  // eslint-disable-next-line vue/multi-word-component-names
  name: 'Story',
  __histoireType: 'story',

  inheritAttrs: false,

  props: {
    initState: {
      type: Function as PropType<() => any | Promise<any>>,
      default: undefined,
    },

    meta: {
      type: Object as PropType<Story['meta']>,
      default: undefined,
    },
  },

  setup (props) {
    const vm = getCurrentInstance()

    const attrs = useAttrs() as {
      story: Story
    }

    const story = computed(() => attrs.story)
    provide('story', story)

    const storyComponent: any = vm.parent
    // Allows tracking reactivity with watchers to sync state
    const implicitState = {
      $data: storyComponent.data,
    }
    function addImplicitState (key, value) {
      if (typeof value === 'function' || (value?.__file) || typeof value?.render === 'function' || typeof value?.setup === 'function') {
        return
      }
      implicitState[key] = value
    }
    // From `<script setup>`'s `defineExpose`
    for (const key in storyComponent.exposed) {
      addImplicitState(key, storyComponent.exposed[key])
    }
    // We needs __VUE_PROD_DEVTOOLS__ flag set to `true` to enable `devtoolsRawSetupState`
    for (const key in storyComponent.devtoolsRawSetupState) {
      addImplicitState(key, storyComponent.devtoolsRawSetupState[key])
    }
    // Shallow copy to prevent sharing object with different variants
    // Wrap with reactive to unwrap refs
    provide('implicitState', () => reactive({ ...implicitState }))

    function updateStory () {
      Object.assign(attrs.story, {
        meta: props.meta,
        slots: () => vm.proxy.$slots,
      })
    }

    return {
      story,
      updateStory,
    }
  },

  render () {
    this.updateStory()

    const [firstVariant] = this.story.variants
    if (firstVariant.id === '_default') {
      return h(Variant, {
        variant: firstVariant,
        initState: this.initState,
        ...this.$attrs,
      }, this.$slots)
    }

    let index = 0
    const applyAttrs = (vnodes: VNode[]) => {
      const result: VNode[] = []
      for (const vnode of vnodes) {
        // @ts-expect-error custom option
        if (vnode.type?.__histoireType === 'variant') {
          const props: any = {}
          props.variant = this.story.variants[index]
          if (!props.variant) {
            continue
          }
          if (!vnode.props?.initState && !vnode.props?.['init-state']) {
            props.initState = this.initState
          }
          for (const attr in this.$attrs) {
            if (typeof vnode.props?.[attr] === 'undefined') {
              props[attr] = this.$attrs[attr]
            }
          }
          for (const attr in this.story) {
            if (!omitInheritStoryProps.includes(attr) && typeof vnode.props?.[attr] === 'undefined') {
              props[attr] = this.story[attr]
            }
          }
          index++
          result.push(cloneVNode(vnode, props))
        } else {
          if (vnode.children?.length) {
            vnode.children = applyAttrs(vnode.children as VNode[])
          }
          result.push(vnode)
        }
      }
      return result
    }

    // Apply variant as attribute to each child vnode (should be `<Variant>` components)
    let vnodes: VNode[] = this.$slots.default()
    vnodes = applyAttrs(vnodes)
    return vnodes
  },
})
