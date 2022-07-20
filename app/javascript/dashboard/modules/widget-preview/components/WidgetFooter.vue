<template>
  <div class="footer-wrap">
    <custom-button
      v-if="config.isDefaultScreen"
      class="start-conversation"
      :style="{ background: config.color }"
    >
      Start Conversation
    </custom-button>
    <!-- <input v-else /> -->
  </div>
</template>

<script>
import CustomButton from '../../../../dashboard/components/buttons/Button';
export default {
  name: 'WidgetFooter',
  components: {
    CustomButton,
  },
  props: {
    config: {
      type: Object,
      default: () => {},
    },
  },
};
</script>

<style scoped lang="scss">
.footer-wrap {
  flex-shrink: 0;
  width: 100%;
  display: flex;
  flex-direction: column;
  position: relative;
  padding-left: var(--space-two);
  padding-right: var(--space-two);

  .start-conversation {
    justify-content: center;
    font-size: var(--font-size-small);
    border-radius: var(--border-radius-normal);
    padding-left: var(--space-two);
    padding-right: var(--space-two);
  }
}
</style>
