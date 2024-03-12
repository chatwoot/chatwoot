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
          class="text-slate-700 dark:text-slate-200 flex-shrink-0"
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
        class="w-full flex flex-row divide-x divide-slate-100 dark:divide-slate-700/50"
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
            class="w-2 h-2 rounded-sm flex-shrink-0"
          />
          <span
            class="font-medium truncate text-slate-700 dark:text-slate-200 text-xs"
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
  // mounted() {
  //   this.$nextTick(() => {
  //     this.updateLabelWidths();
  //   });
  // },
  // methods: {
  //   updateLabelWidths() {
  //     this.$nextTick(() => {
  //       const containerWidth = this.$refs.container.clientWidth;
  //       const inboxIconWidth = this.$refs.inboxIcon?.clientWidth || 0;
  //       const conversationIdWidth = this.$refs.conversationId?.clientWidth || 0;
  //       // Assuming there are no other elements affecting the width calculation
  //       // And after the label container, there is one more element
  //       // So, subtracting the width of that element from the container width

  //       const labelContainerWidth =
  //         containerWidth - inboxIconWidth - conversationIdWidth - 8;
  //       const labelWidth = this.$refs.labelContainer?.clientWidth || 0;
  //       const visibleLabels = Math.floor(labelContainerWidth / labelWidth);
  //       // should be at least 1 label visible
  //       this.visibleLabels = Math.max(visibleLabels, 1);
  //     });
  //   },
  // },
};
</script>
