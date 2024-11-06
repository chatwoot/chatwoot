<script>
export default {
  props: {
    eventUrl: {
      type: String,
      required: true,
    },
    messageId: {
      type: Number,
      required: true,
    },
  },
  data() {
    return {
      buttonText: 'Find a time',
      showModal: false,
    };
  },
  computed: {
    getEventUrl() {
      const url = new URL(this.eventUrl);
      url.searchParams.set('widget_view', 'true');
      return url.toString();
    },
  },
  methods: {
    openModal() {
      this.showModal = true;
    },
    closeModal() {
      this.showModal = false;
      this.removeEventListener();
    },
    setupMessageListener() {
      window.addEventListener('message', this.handleMessage);
    },
    removeEventListener() {
      window.removeEventListener('message', this.handleMessage);
    },
    handleMessage(event) {
      const { payload } = event.data;
      if (payload) {
        this.$store.dispatch('conversation/sendCalConfirmationEvent', {
          message_id: this.messageId,
          event_payload: payload,
        });
        this.closeModal();
      }
    },
  },
};
</script>

<template>
  <div class="flex flex-col items-center">
    <button
      class="mt-4 w-full bg-woot-500 text-white rounded py-2 hover:bg-blue-600 disabled:opacity-50"
      @click="openModal"
    >
      {{ buttonText }}
    </button>

    <div v-if="showModal" class="modal-overlay" @click.self="closeModal">
      <div class="modal-content">
        <button class="close-button" @click="closeModal">{{ 'X' }}</button>
        <iframe
          :src="getEventUrl"
          width="100%"
          height="100%"
          frameborder="0"
          class="iframe"
          @load="setupMessageListener"
        />
      </div>
    </div>
  </div>
</template>

<style scoped>
.modal-overlay {
  position: absolute;
  top: 70px; /* Adjust based on your header height */
  left: 0;
  right: 0;
  background: rgba(0, 0, 0, 0.7);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
}

.modal-content {
  width: 100%;
  height: calc(100vh - 70px);
  background: white;
  border-top: 2px solid gray;
  overflow: hidden;
  position: relative;
}
.iframe {
  width: 100%;
  height: 100%;
}

.close-button {
  position: absolute;
  top: 24px;
  right: 20px;
  color: black;
  width: 30px; /* Button width */
  height: 30px; /* Button height */
  cursor: pointer; /* Cursor style */
  font-size: 16px; /* Text size */
}
</style>
