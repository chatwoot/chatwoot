<template>
  <div
    class="flex items-center w-auto justify-start rounded-[4px] border border-slate-75 dark:border-slate-700/50 divide-x divide-slate-75 dark:divide-slate-700/50 bg-none overflow-hidden"
  >
    <!-- Inbox icon -->
    <div
      v-if="inbox"
      ref="inboxIcon"
      v-tooltip.right="inbox.name"
      class="flex items-center gap-0.5 py-0.5 px-1.5"
    >
      <fluent-icon
        class="flex-shrink-0 text-slate-700 dark:text-slate-200"
        :icon="inboxIcon"
        type="outline"
        size="14"
      />
    </div>

    <!-- Conversation ID -->
    <span
      class="flex items-center py-0.5 px-1.5 font-medium text-slate-700 dark:text-slate-200 text-xs"
    >
      {{ conversationId }}
    </span>

    <!-- Labels display logic -->
    <div
      v-for="(label, index) in activeLabels"
      v-show="index < visibleLabels"
      :key="label.id"
      class="flex items-center truncate justify-start gap-1 py-0.5 px-1.5"
    >
      <span
        v-if="label.title"
        :style="{ background: label.color }"
        class="flex-shrink-0 w-2 h-2 rounded-sm"
      />
      <span
        :title="label.title"
        class="text-xs font-medium truncate text-slate-700 dark:text-slate-200"
      >
        {{ label.title }}
      </span>
    </div>

    <!-- Label count display logic -->
    <span
      v-if="activeLabels.length > visibleLabels"
      :title="hiddenLabelsTitle"
      class="flex items-center py-0.5 px-1.5 font-medium text-slate-700 dark:text-slate-200 text-xs"
    >
      +{{ activeLabels.length - visibleLabels }}
    </span>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import { getInboxClassByType } from 'dashboard/helper/inbox';

const MAX_LABELS = 6;
const MIN_LABELS = 1;

const BASE_WIDTH = 360;
const TOTAL_PADDING = 36;
const EFFECTIVE_WIDTH = BASE_WIDTH - TOTAL_PADDING;

// 24 is the padding + gap + label color width
const LABEL_ITEM_PADDING = 24;
const AVG_CHAR_WIDTH = 5.2;

// Clamp function to limit the number of labels to be displayed
const clamp = (value, min, max) => Math.min(Math.max(min, value), max);

export default {
  props: {
    inbox: {
      type: Object,
      default: () => {},
    },
    conversationId: {
      type: Number,
      default: 0,
    },
    conversationLabels: {
      type: Array,
      default: () => [],
    },
    parentElementWidth: {
      type: Number,
      default: 0,
    },
  },
  data() {
    return {
      visibleLabels: 1,
    };
  },
  computed: {
    ...mapGetters({ accountLabels: 'labels/getLabels' }),
    inboxIcon() {
      const { phone_number: phoneNumber, channel_type: type } = this.inbox;
      return getInboxClassByType(type, phoneNumber);
    },
    activeLabels() {
      return this.accountLabels?.filter(({ title }) =>
        this.conversationLabels?.includes(title)
      );
    },
    hiddenLabelsTitle() {
      if (this.activeLabels?.length <= this.visibleLabels) {
        return '';
      }
      return (
        this.activeLabels
          .slice(this.visibleLabels)
          .map(label => label.title)
          .join(', ') || ''
      );
    },
  },
  watch: {
    parentElementWidth() {
      if (this.activeLabels.length > 1) {
        this.updateLabelWidths();
      }
    },
  },
  methods: {
    updateLabelWidths() {
      this.$nextTick(() => {
        const containerWidth = this.parentElementWidth || EFFECTIVE_WIDTH;
        if (containerWidth <= EFFECTIVE_WIDTH) {
          this.visibleLabels = 1;
          return;
        }

        let widthAvailable = containerWidth - EFFECTIVE_WIDTH;

        // go through each label and calculate the width required
        let numberOfLabels = this.activeLabels.reduce(
          (acc, label) => {
            const widthRequired =
              label.title.length * AVG_CHAR_WIDTH + LABEL_ITEM_PADDING;
            if (acc.widthAvailable >= widthRequired) {
              acc.widthAvailable -= widthRequired;
              acc.count += 1;
            }
            return acc;
          },
          { count: 0, widthAvailable }
        ).count;

        this.visibleLabels = clamp(numberOfLabels, MIN_LABELS, MAX_LABELS);
      });
    },
  },
};
</script>
