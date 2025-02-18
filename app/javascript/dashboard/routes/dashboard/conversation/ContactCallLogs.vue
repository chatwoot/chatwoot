<template>
  <div class="py-3 px-4">
    <div class="flex items-center mb-1">
      <h4 class="text-sm flex items-center m-0 w-full error">
        <div class="flex items-center justify-between w-full">
          <span
            class="w-full inline-flex gap-1.5 items-start font-medium whitespace-nowrap text-sm mb-0"
            :class="'text-slate-800 dark:text-slate-100'"
          >
            {{ 'Call Logs' }}
            <helper-text-popup
              name="contactCallLogs"
              :message="'Call logs for contacts'"
              class="mt-0.5"
            />
          </span>
        </div>
      </h4>
    </div>
    <div v-if="!uiFlags.isFetching">
      <div v-if="callLogs && callLogs.length" class="flex flex-col gap-2 mt-2">
        <call-log-card
          v-for="log in callLogs"
          :key="log.callId"
          :call-log="log"
        />
      </div>
      <div v-else class="no-label-message">
        <span>
          {{ 'There are no call logs associated to this contact.' }}
        </span>
      </div>
    </div>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import HelperTextPopup from 'dashboard/components/ui/HelperTextPopup.vue';
import CallLogCard from '../../../components/widgets/conversation/CallLogCard.vue';

export default {
  components: {
    HelperTextPopup,
    CallLogCard,
  },
  props: {
    phoneNumber: {
      type: String,
      required: true,
    },
  },
  computed: {
    ...mapGetters({
      uiFlags: 'contactCallLogs/getUIFlags',
    }),
    callLogs() {
      return this.$store.getters['contactCallLogs/getContactCallLogs'](
        this.phoneNumber
      );
    },
  },
  watch: {
    phoneNumber(newPhoneNumber, prevPhoneNumber) {
      if (newPhoneNumber && newPhoneNumber !== prevPhoneNumber) {
        this.$store.dispatch('contactCallLogs/get', newPhoneNumber);
      }
    },
  },
  mounted() {
    this.$store.dispatch('contactCallLogs/get', this.phoneNumber);
  },
};
</script>

<style lang="scss" scoped>
.no-label-message {
  @apply text-slate-500 dark:text-slate-400 mb-4;
}
.close-caption svg {
  @apply w-10 h-10;
}
</style>
