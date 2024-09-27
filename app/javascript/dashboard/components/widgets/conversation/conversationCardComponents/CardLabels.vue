<script>
import { computed } from 'vue';
import { useMapGetter } from 'dashboard/composables/store';

export default {
  props: {
    conversationId: {
      type: [String, Number],
      required: true,
    },
    conversationLabels: {
      type: Array,
      required: true,
    },
  },
  setup(props) {
    const accountLabels = useMapGetter('labels/getLabels');

    const activeLabels = computed(() => {
      return accountLabels.value.filter(({ title }) =>
        props.conversationLabels.includes(title)
      );
    });

    return {
      activeLabels,
    };
  },
  data() {
    return {
      showAllLabels: false,
      showExpandLabelButton: false,
      labelPosition: -1,
    };
  },
  watch: {
    activeLabels: {
      handler() {
        this.$nextTick(() => {
          this.computeVisibleLabelPosition();
        });
      },
      deep: true,
    },
  },
  mounted() {
    // the problem here is that there is a certain amount of delay between the conversation
    // card being mounted and the resize event eventually being triggered
    // This means we need to run the function immediately after the component is mounted
    // Happens especially when used in a virtual list.
    // We can make the first trigger, a standard part of the directive, in case
    // we face this issue again
    this.$nextTick(() => this.computeVisibleLabelPosition());
  },
  methods: {
    onShowLabels(e) {
      e.stopPropagation();
      this.showAllLabels = !this.showAllLabels;
      this.$nextTick(() => this.computeVisibleLabelPosition());
    },
    getWidth(el) {
      let width = el.offsetWidth;
      if (width === 0) {
        // Sometimes the last label width is not calculated correctly
        // Despite trying to use multiple nextTicks, it still doesn't work
        // So we calculate the width based on the text length assuming each character is 6px
        // This is hacky, but it works
        // [TODO] Fix this later
        width = el.innerText.length * 6;
      }

      return width;
    },
    computeVisibleLabelPosition() {
      const beforeSlot = this.$slots.before ? 100 : 0;
      const labelContainer = this.$refs.labelContainer;
      if (!labelContainer) return;

      const labels = Array.from(labelContainer.querySelectorAll('.label'));
      let labelOffset = 0;
      this.showExpandLabelButton = false;
      labels.forEach((label, index) => {
        labelOffset += this.getWidth(label) + 8;
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

<template>
  <div>
    <div v-if="activeLabels.length || $slots.before">
      <div
        ref="labelContainer"
        v-resize="computeVisibleLabelPosition"
        class="flex items-end flex-shrink min-w-0 gap-y-1"
        :class="{ 'h-auto overflow-visible flex-row flex-wrap': showAllLabels }"
      >
        <slot name="before" />
        <woot-label
          v-for="(label, index) in activeLabels"
          :key="label ? label.id : index"
          :title="label.title"
          :description="label.description"
          :color="label.color"
          variant="smooth"
          :data-label-idx="index"
          :data-label-max="labelPosition"
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
  </div>
</template>

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
