<template>
  <div
    v-if="activeLabels.length || $slots.before"
    ref="labelContainer"
    v-resize="computeVisibleLabelPosition"
  >
    <div
      class="flex items-end flex-shrink min-w-0 gap-y-1"
      :class="{ 'h-auto overflow-visible flex-row flex-wrap': showAllLabels }"
    >
      <slot name="before" />
      <woot-label
        v-for="(label, index) in activeLabels"
        :key="label.id"
        :title="label.title"
        :description="label.description"
        :color="label.color"
        variant="smooth"
        class="!mb-0 max-w-[calc(100%-0.5rem)]"
        small
        :class="{ hidden: !showAllLabels && index > labelPosition }"
      />
      <woot-button
        v-if="showExpandLabelButton"
        :title="
          showAllLabels
            ? $t('CONVERSATION.CARD.HIDE_LABELS')
            : $t('CONVERSATION.CARD.SHOW_LABELS')
        "
        class="sticky right-0 flex-shrink-0 mr-6 show-more--button rtl:rotate-180"
        color-scheme="secondary"
        variant="hollow"
        :icon="showAllLabels ? 'chevron-left' : 'chevron-right'"
        size="tiny"
        @click="onShowLabels"
      />
    </div>
  </div>
</template>
<script>
import conversationLabelMixin from 'dashboard/mixins/conversation/labelMixin';
export default {
  mixins: [conversationLabelMixin],
  props: {
    conversationId: {
      type: Number,
      required: true,
    },
    conversationLabels: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      showAllLabels: false,
      showExpandLabelButton: false,
      labelPosition: -1,
    };
  },
  watch: {
    activeLabels() {
      this.$nextTick(() => this.computeVisibleLabelPosition());
    },
  },
  mounted() {
    // the problem here is that there is a certain amount of delay between the conversation
    // card being mounted and the resize event eventually being triggered
    // This means we need to run the function immediately after the component is mounted
    // Happens especially when used in a virtual list.
    // We can make the first trigger, a standard part of the directive, in case
    // we face this issue again
    this.computeVisibleLabelPosition();
  },
  methods: {
    onShowLabels(e) {
      e.stopPropagation();
      this.showAllLabels = !this.showAllLabels;
      this.$nextTick(() => this.computeVisibleLabelPosition());
    },
    computeVisibleLabelPosition() {
      const beforeSlot = this.$slots.before ? 100 : 0;
      const labelContainer = this.$refs.labelContainer;
      if (!labelContainer) return;

      const labels = Array.from(labelContainer.querySelectorAll('.label'));
      let labelOffset = 0;
      this.showExpandLabelButton = false;
      labels.forEach((label, index) => {
        labelOffset += label.offsetWidth + 8;
        if (labelOffset < labelContainer.clientWidth - 16 - beforeSlot) {
          this.labelPosition = index;
        } else {
          this.showExpandLabelButton = labels.length > 1;
        }
      });
    },
  },
};
</script>

<style lang="scss" scoped>
.show-more--button {
  @apply h-5;
  &.secondary:focus {
    @apply text-slate-700 dark:text-slate-200 border-slate-300 dark:border-slate-700;
  }
}

.labels-wrap {
  .secondary {
    @apply border border-solid border-slate-100 dark:border-slate-700;
  }
}

.hidden {
  @apply invisible absolute;
}
</style>
