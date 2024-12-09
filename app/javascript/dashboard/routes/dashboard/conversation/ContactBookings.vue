<script>
import { mapGetters } from 'vuex';
import Spinner from 'shared/components/Spinner.vue';

export default {
  components: {
    Spinner,
  },
  props: {
    contactId: {
      type: [String, Number],
      required: true,
    },
  },
  computed: {
    bookings() {
      return this.$store.getters['contactBookings/getContactBookings'](
        this.contactId
      );
    },
    previousBookings() {
      const currentTime = new Date();
      const filteredBookings = this.bookings
        .filter(booking => new Date(booking.booking_endTime) < currentTime)
        .sort((a, b) => new Date(b.endTime) - new Date(a.endTime));
      return filteredBookings;
    },
    ...mapGetters({
      uiFlags: 'contactBookings/getUIFlags',
    }),
  },
  mounted() {
    this.$store.dispatch('contactBookings/get', this.contactId);
  },
  methods: {
    formatDate(dateString) {
      const date = new Date(dateString);
      return date.toLocaleString().split(',');
    },
  },
};
</script>

<template>
  <div class="contact-conversation--panel">
    <div v-if="!uiFlags.isFetching" class="contact-conversation__wrap">
      <div v-if="!previousBookings.length" class="no-label-message">
        <span>
          {{ $t('CONTACT_PANEL.BOOKING.NO_BOOKINGS_FOUND') }}
        </span>
      </div>
      <div v-else class="contact-conversation--list px-6 py-4">
        <div
          v-for="(booking, index) in previousBookings"
          :key="index"
          class="flex items-center justify-between py-4 border-b border-slate-50 dark:border-slate-800/75"
        >
          <div class="flex flex-col">
            <p class="text-sm">
              {{ $t('CONTACT_PANEL.BOOKING.EVENT') }}
              {{ booking.booking_eventtype }}
            </p>
            <p class="text-sm">
              {{ $t('CONTACT_PANEL.BOOKING.HOST') }}
              {{
                booking.host_name.charAt(0).toUpperCase() +
                booking.host_name.slice(1)
              }}
            </p>
          </div>

          <!-- Right side: Formatted Date -->
          <div class="text-center">
            <p class="text-xs">
              {{ formatDate(booking.booking_startTime)[0] }}
            </p>
            <p class="text-xs">
              {{ formatDate(booking.booking_startTime)[1] }}
            </p>
          </div>
        </div>
      </div>
    </div>
    <Spinner v-else />
  </div>
</template>

<style lang="scss" scoped>
.no-label-message {
  @apply text-slate-500 dark:text-slate-400 mb-4;
}

::v-deep .conversation {
  @apply pr-0;
  .conversation--details {
    @apply pl-2;
  }
}
</style>
