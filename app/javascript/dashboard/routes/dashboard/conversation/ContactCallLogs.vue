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
          <woot-button
            variant="smooth"
            class="label--add"
            icon="add"
            size="tiny"
            @click="toggleAddCallLogModal"
          >
            {{ 'Add Call log' }}
          </woot-button>
        </div>
      </h4>
    </div>
    <div v-if="!uiFlags.isFetching">
      <div v-if="callLogs && callLogs.length" class="flex flex-col gap-2 mt-2">
        <call-log-card
          v-for="(log, index) in callLogs"
          :key="log.callId"
          :call-log="log"
          :index="index"
          :phone-number="phoneNumber"
        />
      </div>
      <div v-else class="no-label-message">
        <span>
          {{ 'There are no call logs associated to this contact.' }}
        </span>
      </div>
    </div>
    <add-call-log :show="showAddCallLogModal" @cancel="toggleAddCallLogModal" />
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import HelperTextPopup from 'dashboard/components/ui/HelperTextPopup.vue';
import CallLogCard from '../../../components/widgets/conversation/CallLogCard.vue';
import AddCallLog from '../../../components/widgets/conversation/AddCallLog.vue';

export default {
  components: {
    HelperTextPopup,
    CallLogCard,
    AddCallLog,
  },
  props: {
    phoneNumber: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      showAddCallLogModal: false,
    };
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
  methods: {
    toggleAddCallLogModal() {
      this.showAddCallLogModal = !this.showAddCallLogModal;
    },
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
