<script>
export default {
  props: {
    eventPayload: {
      type: Object,
      required: true,
    },
  },
  computed: {
    meetingConfirmationMessage() {
      const { event_scheduled_at, event_organizer } = this.eventPayload;

      return this.$t('CAL_EVENT_CONFIRMATION_RESPONSE', {
        organizer: event_organizer,
        time: event_scheduled_at.time,
        date: event_scheduled_at.date,
        timezone: event_scheduled_at.timezone,
      });
    },
  },
};
</script>

<template>
  <div>
    <p v-html="meetingConfirmationMessage" />
  </div>
</template>
