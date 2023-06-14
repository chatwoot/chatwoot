<template>
  <div class="column">
    <woot-modal-header :header-title="$t('CONVERSATION.CUSTOM_SNOOZE.TITLE')" />
    <form class="row modal-content" @submit.prevent="chooseTime">
      <div class="medium-12 columns">
        <date-picker
          v-model="snoozeTime"
          type="datetime"
          inline
          :lang="lang"
          :disabled-date="disabledDate"
          :disabled-time="disabledTime"
          :popup-style="{ width: '100%' }"
        />
      </div>
      <div class="modal-footer justify-content-end w-full">
        <woot-button variant="clear" @click.prevent="onClose">
          {{ this.$t('CONVERSATION.CUSTOM_SNOOZE.CANCEL') }}
        </woot-button>
        <woot-button>
          {{ this.$t('CONVERSATION.CUSTOM_SNOOZE.APPLY') }}
        </woot-button>
      </div>
    </form>
  </div>
</template>

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
      this.$emit('on-close');
    },
    chooseTime() {
      this.$emit('choose-time', this.snoozeTime);
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

<style lang="scss" scoped>
.modal-footer {
  padding-top: var(--font-size-mega);
}
</style>
