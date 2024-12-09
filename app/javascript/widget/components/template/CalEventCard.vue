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
      isLoading: false,
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
      this.isLoading = true;
      this.showModal = true;
    },
    closeModal() {
      this.showModal = false;
      this.removeEventListener();
    },
    handleOnLoad() {
      this.isLoading = false;
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
        <span v-if="isLoading" class="loader" />
        <button class="close-button" @click="closeModal">{{ 'X' }}</button>
        <iframe
          :src="getEventUrl"
          width="100%"
          height="100%"
          frameborder="0"
          class="iframe"
          @load="handleOnLoad"
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
  width: 30px;
  height: 30px;
  cursor: pointer;
  font-size: 16px;
}
.loader {
  display: block;
  position: absolute;
  top: 50%;
  left: 48%;
  transform: translate(-50%, -50%);
  width: 30px;
  height: 30px;
  border-width: 4px;
  border-style: solid;
  animation: loader 2s infinite ease;
}
@keyframes loader {
  0% {
    transform: rotate(0deg);
  }

  25% {
    transform: rotate(180deg);
  }

  50% {
    transform: rotate(180deg);
  }

  75% {
    transform: rotate(360deg);
  }

  100% {
    transform: rotate(360deg);
  }
}
</style>
