<script>
import NextButton from 'dashboard/components-next/button/Button.vue';

export default {
  components: {
    NextButton,
  },
  props: {
    isOnExpandedLayout: {
      type: Boolean,
      default: false,
    },
  },
  emits: ['toggle'],
  methods: {
    toggle() {
      this.$emit('toggle');
    },
  },
};
</script>

<template>
  <NextButton
    v-tooltip.left="$t('CONVERSATION.SWITCH_VIEW_LAYOUT')"
    :icon="
      isOnExpandedLayout
        ? 'i-lucide-arrow-left-to-line'
        : 'i-lucide-arrow-right-to-line'
    "
    slate
    xs
    faded
    class="flex-shrink-0 rtl:rotate-180 ltr:rotate-0"
    @click="toggle"
  />
</template>
