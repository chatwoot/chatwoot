<script>
import DatePicker from 'vue2-datepicker';

export default {
  components: {
    DatePicker,
  },

  data() {
    return {
      snoozeTime: null,
      lang: {
        days: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'],
        yearFormat: 'YYYY',
        monthFormat: 'MMMM',
      },
    };
  },

  methods: {
    onClose() {
      this.$emit('close');
    },
    chooseTime() {
      this.$emit('chooseTime', this.snoozeTime);
    },
    disabledDate(date) {
      // Disable all the previous dates
      const yesterday = new Date();
      yesterday.setDate(yesterday.getDate() - 1);
      return date < yesterday;
    },
    disabledTime(date) {
      // Allow only time after 1 hour
      const now = new Date();
      now.setHours(now.getHours() + 1);
      return date < now;
    },
  },
};
</script>

<template>
  <div class="flex flex-col">
    <woot-modal-header :header-title="$t('CONVERSATION.CUSTOM_SNOOZE.TITLE')" />
    <form class="modal-content" @submit.prevent="chooseTime">
      <DatePicker
        v-model="snoozeTime"
        type="datetime"
        inline
        :lang="lang"
        :disabled-date="disabledDate"
        :disabled-time="disabledTime"
        :popup-style="{ width: '100%' }"
      />
      <div class="flex flex-row justify-end w-full gap-2 px-0 py-2">
        <woot-button variant="clear" @click.prevent="onClose">
          {{ $t('CONVERSATION.CUSTOM_SNOOZE.CANCEL') }}
        </woot-button>
        <woot-button>
          {{ $t('CONVERSATION.CUSTOM_SNOOZE.APPLY') }}
        </woot-button>
      </div>
    </form>
  </div>
</template>

<style lang="scss" scoped>
.modal-content {
  @apply pt-2 px-5 pb-6;
}
</style>
