<template>
  <div class="dashboard-app--container">
    <div
      v-for="(configItem, index) in config"
      :key="index"
      class="dashboard-app--list"
    >
      <iframe
        v-if="configItem.type === 'frame' && configItem.url"
        :id="`dashboard-app--frame-${index}`"
        :src="configItem.url"
        @load="() => onIframeLoad(index)"
      />
    </div>
  </div>
</template>

<script>
export default {
  props: {
    config: {
      type: Array,
      default: () => [],
    },
    currentChat: {
      type: Object,
      default: () => ({}),
    },
  },
  computed: {
    dashboardAppContext() {
      return {
        conversation: this.currentChat,
        contact: this.$store.getters['contacts/getContact'](this.contactId),
      };
    },
    contactId() {
      return this.currentChat?.meta?.sender?.id;
    },
  },
  methods: {
    onIframeLoad(index) {
      const frameElement = document.getElementById(
        `dashboard-app--frame-${index}`
      );
      const eventData = { event: 'appContext', data: this.dashboardAppContext };
      frameElement.contentWindow.postMessage(JSON.stringify(eventData), '*');
    },
  },
};
</script>

<style scoped>
.dashboard-app--container,
.dashboard-app--list,
.dashboard-app--list iframe {
  height: 100%;
  width: 100%;
}

.dashboard-app--list iframe {
  border: 0;
}
</style>
