<template>
  <div class="dashboard-app--container">
    <div
      v-for="(configItem, index) in config"
      :key="index"
      class="dashboard-app--list"
    >
      <loading-state
        v-if="iframeLoading"
        :message="$t('DASHBOARD_APPS.LOADING_MESSAGE')"
        class="dashboard-app_loading-container"
      />
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
import LoadingState from 'dashboard/components/widgets/LoadingState';
export default {
  components: {
    LoadingState,
  },
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
  data() {
    return {
      iframeLoading: true,
    };
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

  mounted() {
    window.onmessage = e => {
      if (
        typeof e.data !== 'string' ||
        e.data !== 'chatwoot-dashboard-app:fetch-info'
      ) {
        return;
      }
      this.onIframeLoad(0);
    };
  },
  methods: {
    onIframeLoad(index) {
      const frameElement = document.getElementById(
        `dashboard-app--frame-${index}`
      );
      const eventData = { event: 'appContext', data: this.dashboardAppContext };
      frameElement.contentWindow.postMessage(JSON.stringify(eventData), '*');
      this.iframeLoading = false;
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
.dashboard-app_loading-container {
  display: flex;
  align-items: center;
  justify-content: center;
  height: 100%;
  width: 100%;
}
</style>
