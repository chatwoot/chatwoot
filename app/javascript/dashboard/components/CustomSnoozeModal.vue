<template>
  <div class="column">
    <woot-modal-header :header-title="$t('CONVERSATION.CUSTOM_SNOOZE.TITLE')" />
    <form class="row modal-content" @submit.prevent="chooseTime">
      <div class="medium-12 columns">
        <date-picker
          v-model="customSnoozeTime"
          type="datetime"
          inline
          :disabled-date="disableBeforeToday"
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
import addDays from 'date-fns/addDays';

export default {
  components: {
    DatePicker,
  },

  data() {
    return {
      customSnoozeTime: null,
    };
  },

  methods: {
    onClose() {
      this.$emit('on-close');
    },
    chooseTime() {
      this.$emit('choose-time', this.customSnoozeTime);
    },
    disableBeforeToday(date) {
      const yesterdayDate = addDays(new Date(), -1);
      return date < yesterdayDate;
    },
  },
};
</script>
