<template>
  <div ref="container" class="w-auto bg-none">
    <div
      class="flex items-center w-full justify-start rounded-[4px] border border-slate-100 dark:border-slate-700/50 divide-x divide-slate-100 dark:divide-slate-700/50 bg-none"
    >
      <!-- Inbox icon and conversation ID -->
      <div
        v-if="inbox"
        ref="inboxIcon"
        v-tooltip.right="inbox.name"
        class="flex items-center gap-0.5 py-0.5 px-1.5"
      >
        <fluent-icon
          class="flex-shrink-0 text-slate-700 dark:text-slate-200"
          :icon="inboxIcon"
          size="14"
        />
      </div>
      <span
        ref="conversationId"
        class="flex items-center py-0.5 px-1.5 font-medium text-slate-600 dark:text-slate-200 text-xs"
      >
        {{ conversationId }}
      </span>
      <!-- Labels display logic -->
      <div
        ref="labelContainer"
        class="flex flex-row w-full divide-x divide-slate-100 dark:divide-slate-700/50"
      >
        <div
          v-for="(label, index) in activeLabels"
          v-show="index < visibleLabels"
          :key="label.id"
          class="label flex items-center justify-start gap-1 w-full py-0.5 px-1.5"
        >
          <span
            v-if="label.title"
            :style="{ background: label.color }"
            class="flex-shrink-0 w-2 h-2 rounded-sm"
          />
          <span
            class="text-xs font-medium truncate text-slate-700 dark:text-slate-200"
          >
            {{ label.title }}
          </span>
        </div>
        <span
          v-if="activeLabels.length > visibleLabels"
          class="flex items-center py-0.5 px-1.5 font-medium text-slate-700 dark:text-slate-200 text-xs"
        >
          +{{ activeLabels.length - visibleLabels }}
        </span>
      </div>
    </div>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import { getInboxClassByType } from 'dashboard/helper/inbox';

const MAX_LABELS = 5;
const MIN_LABELS = 1;

const BASE_WIDTH = 380;
const TOTAL_PADDING = 32;
const EFFECTIVE_WIDTH = BASE_WIDTH - TOTAL_PADDING;

const LABEL_ITEM_PADDING = 24;
const CHAR_WIDTH = 5.2;

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
      return this.accountLabels.filter(({ title }) =>
        this.conversationLabels.includes(title)
      );
    },
  },
  mounted() {
    this.$nextTick(() => {
      this.updateLabelWidths();
    });
  },
  methods: {
    updateLabelWidths() {
      this.$nextTick(() => {
        const currentInfoEl = this.$refs.container;
        // this is a hack, get the parent width as a prop, and on resize of the parent width
        // update the prop value, that will cause a reactive change and the number of labels will fix
        // itself
        const parent = currentInfoEl.parentElement.parentElement;
        const containerWidth = parent.clientWidth;
        if (containerWidth <= EFFECTIVE_WIDTH) {
          this.visibleLabels = 1;
          return;
        }

        let widthAvailable = containerWidth - EFFECTIVE_WIDTH;

        // go through each label that is availble and calculate estimated width
        let numberOfLabels = 0;
        this.activeLabels.forEach(label => {
          const numberOfChars = label.title.length;
          const widthRequired = numberOfChars * CHAR_WIDTH + LABEL_ITEM_PADDING;
          widthAvailable -= widthRequired;

          if (widthAvailable > 0) {
            numberOfLabels += 1;
          }
        });

        this.visibleLabels = clamp(numberOfLabels, MIN_LABELS, MAX_LABELS);
      });
    },
  },
};
</script>
