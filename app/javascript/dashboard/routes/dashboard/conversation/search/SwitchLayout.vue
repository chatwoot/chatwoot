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
    icon="i-woot-expand-list"
    slate
    sm
    ghost
    class="flex-shrink-0 md:inline-flex hidden"
    :class="{
      'ltr:!rotate-180 rtl:!rotate-0': isOnExpandedLayout,
      'ltr:!rotate-0 rtl:!rotate-180': !isOnExpandedLayout,
    }"
    @click="toggle"
  />
</template>
