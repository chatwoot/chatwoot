<script>
export default {
  components: {},
  props: {
    calendarEvents: {
      type: Array,
      default: () => [],
    },
    show: {
      type: Boolean,
      default: true,
    },
  },
  data() {
    return {
      selectedEvent: null,
    };
  },
  methods: {
    onClose() {
      this.$emit('close');
    },
    selectEvent(event) {
      if (this.selectedEvent && this.selectedEvent.uid === event.uid) {
        this.selectedEvent = null;
      } else {
        this.selectedEvent = event;
      }
    },
    sendSelectedEvent() {
      this.$emit('onSelect', this.selectedEvent);
    },
    isSelected(event) {
      return this.selectedEvent && this.selectedEvent.uid === event.uid;
    },
  },
};
</script>

<template>
  <woot-modal :show="show" :on-close="onClose" size="modal-big">
    <woot-modal-header
      :header-title="$t('SELECT_CALENDAR_EVENT.MODAL.TITLE')"
      :header-content="$t('SELECT_CALENDAR_EVENT.MODAL.DESC')"
    />
    <div class="row modal-content">
      <ul class="space-y-2">
        <div
          v-for="event in calendarEvents"
          :key="event.uid"
          class="cursor-pointer p-2 rounded border flex justify-between"
          @click="selectEvent(event)"
        >
          <h3 class="font-semibold">{{ event.title }}</h3>
          <fluent-icon v-if="isSelected(event)" icon="checkmark" size="24" />
        </div>
      </ul>
      <button
        :disabled="!selectedEvent"
        class="mt-4 w-full bg-woot-500 text-white rounded py-2 hover:bg-blue-600 disabled:opacity-50"
        @click="sendSelectedEvent"
      >
        {{ $t('SELECT_CALENDAR_EVENT.MODAL.SEND_EVENT') }}
      </button>
    </div>
  </woot-modal>
</template>

<style scoped>
.modal-content {
  padding: 1.5625rem 2rem;
}
</style>
