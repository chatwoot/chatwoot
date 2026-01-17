import { defineComponent, getCurrentInstance, inject, PropType, useAttrs } from 'vue'
import type { Variant } from '@histoire/shared'
import { applyState } from '@histoire/shared'
import { syncStateBundledAndExternal, toRawDeep } from './util.js'

// const logLocation = location.href.includes('__sandbox') ? '[Sandbox]' : '[Host]'

export default defineComponent({
  // eslint-disable-next-line vue/multi-word-component-names
  name: 'Variant',
  __histoireType: 'variant',

  props: {
    initState: {
      type: Function as PropType<() => any | Promise<any>>,
      default: undefined,
    },

    source: {
      type: String,
      default: undefined,
    },

    responsiveDisabled: {
      type: Boolean,
      default: false,
    },

    autoPropsDisabled: {
      type: Boolean,
      default: false,
    },

    setupApp: {
      type: Function,
      default: undefined,
    },

    meta: {
      type: Object as PropType<Variant['meta']>,
      default: undefined,
    },
  },

  async setup (props) {
    const attrs = useAttrs() as {
      variant: Variant
    }

    const vm = getCurrentInstance()

    const implicitState = inject<() => any>('implicitState')

    if (typeof props.initState === 'function') {
      const state = await props.initState()
      applyState(attrs.variant.state, toRawDeep(state))
    }

    syncStateBundledAndExternal(attrs.variant.state, implicitState())

    function updateVariant () {
      Object.assign(attrs.variant, {
        slots: () => vm.proxy.$slots,
        source: props.source,
        responsiveDisabled: props.responsiveDisabled,
        autoPropsDisabled: props.autoPropsDisabled,
        setupApp: props.setupApp,
        meta: props.meta,
        configReady: true,
      })
    }
    updateVariant()

    return {
      updateVariant,
    }
  },

  render () {
    // Trigger variant updates to (re-)render slots
    this.updateVariant()
    return null
  },
})
