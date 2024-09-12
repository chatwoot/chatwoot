<template>
  <div class="relative items-center w-full p-4 bg-white dark:bg-slate-900">
    <div class="flex flex-col w-full gap-2 text-left rtl:text-right">
      <div class="flex flex-row justify-between items-center mb-4">
        <h2 class="text-xl">{{ $t('ORDER_PANEL.LABELS.GERAL.TITLE') }}</h2>
        <woot-button
          v-if="showCloseButton"
          :icon="closeIconName"
          class="clear secondary rtl:rotate-180"
          @click="onPanelToggle"
        />
      </div>
      <div class="flex flex-col items-start gap-2 min-w-0 w-full">
        <div class="flex items-start w-full min-w-0 gap-2">
          <h3
            class="flex-shrink max-w-full min-w-0 my-0 text-base capitalize break-words text-slate-800 dark:text-slate-100"
          >
            Nº {{ order.order_number }}
          </h3>
          <div class="flex flex-row items-center gap-1">
            <fluent-icon
              v-if="order.date_created"
              v-tooltip.left="
                `${$t('ORDER_PANEL.CREATED_AT_LABEL')} ${order.date_created}`
              "
              icon="info"
              size="14"
              class="mt-0.5"
            />
          </div>
        </div>

        <div class="flex flex-col items-start w-full gap-2">
          <div>
            <label>{{ $t('ORDER_PANEL.LABELS.GERAL.STATUS') }}</label>
            <p>{{ order.status || '---' }}</p>
          </div>
          <div>
            <label>{{ $t('ORDER_PANEL.LABELS.GERAL.CREATED') }}</label>
            <p>{{ getDateMessage(order.date_created) || '---' }}</p>
          </div>
          <div>
            <label>{{ $t('ORDER_PANEL.LABELS.GERAL.MODIFIED') }}</label>
            <p>{{ getDateMessage(order.date_modified) || '---' }}</p>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
<script>
import { messageTimestamp } from 'shared/helpers/timeHelper';
export default {
  components: {},
  props: {
    order: {
      type: Object,
      default: () => ({}),
    },

    showCloseButton: {
      type: Boolean,
      default: true,
    },
    closeIconName: {
      type: String,
      default: 'chevron-right',
    },
  },

  computed: {},

  methods: {
    onPanelToggle() {
      this.$emit('toggle-panel');
    },

    getDateMessage(date) {
      const timestampDate = new Date(date);
      const timestamp = Math.floor(timestampDate.getTime() / 1000);

      return messageTimestamp(timestamp);
    },
  },
};
</script>
