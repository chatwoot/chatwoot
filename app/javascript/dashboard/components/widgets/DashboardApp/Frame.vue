<script setup>
import { computed, onMounted, onUnmounted, ref, watch } from 'vue';
import { useStore } from 'vuex';
import LoadingState from 'dashboard/components/widgets/LoadingState.vue';

const props = defineProps({
  config: {
    type: Array,
    default: () => [],
  },
  currentChat: {
    type: Object,
    default: () => ({}),
  },
  isVisible: {
    type: Boolean,
    default: false,
  },
  position: {
    type: Number,
    required: true,
  },
});

const FETCH_INFO_MESSAGE = 'chatwoot-dashboard-app:fetch-info';
const APP_CONTEXT_EVENT = 'appContext';
const DARK_THEME = 'dark';
const LIGHT_THEME = 'light';

const getCurrentTheme = () =>
  document.body.classList.contains(DARK_THEME) ? DARK_THEME : LIGHT_THEME;

const store = useStore();
const hasOpenedAtLeastOnce = ref(false);
const iframeLoading = ref(true);
const currentTheme = ref(getCurrentTheme());
const hasPendingContextUpdate = ref(false);
let themeObserver;

const customAttributes = computed(
  () => store.getters['attributes/getAttributes']
);
const contactId = computed(() => props.currentChat?.meta?.sender?.id);
const currentAgent = computed(() => {
  const { id, name, email } = store.getters.getCurrentUser;
  return { id, name, email };
});
const dashboardAppContext = computed(() => ({
  conversation: props.currentChat,
  contact: store.getters['contacts/getContact'](contactId.value),
  currentAgent: currentAgent.value,
  customAttributes: customAttributes.value,
  theme: currentTheme.value,
}));

const getFrameId = index => `dashboard-app--frame-${props.position}-${index}`;

const sendContext = index => {
  // A possible alternative is to use ref instead of document.getElementById.
  // A ref used with v-for returns an array mirroring the data source.
  const frameElement = document.getElementById(getFrameId(index));
  const eventData = {
    event: APP_CONTEXT_EVENT,
    data: dashboardAppContext.value,
  };
  frameElement.contentWindow.postMessage(JSON.stringify(eventData), '*');
  iframeLoading.value = false;
  hasPendingContextUpdate.value = false;
};

const sendContextToFrames = () => {
  if (!props.isVisible || iframeLoading.value) return;
  props.config.forEach((_, index) => sendContext(index));
};

const syncContext = () => {
  if (!props.isVisible) {
    hasPendingContextUpdate.value = true;
    return;
  }
  sendContextToFrames();
};

const triggerEvent = event => {
  if (!props.isVisible || event.data !== FETCH_INFO_MESSAGE) return;

  const frameIndex = props.config.findIndex((_, index) => {
    const frameElement = document.getElementById(getFrameId(index));
    return frameElement?.contentWindow === event.source;
  });
  if (frameIndex >= 0) sendContext(frameIndex);
};

const onThemeChange = () => {
  const theme = getCurrentTheme();
  if (theme === currentTheme.value) return;

  currentTheme.value = theme;
  syncContext();
};

watch(
  () => props.isVisible,
  isVisible => {
    if (!isVisible) return;

    const hasOpened = hasOpenedAtLeastOnce.value;
    hasOpenedAtLeastOnce.value = true;
    if (hasOpened && hasPendingContextUpdate.value) sendContextToFrames();
  }
);
watch(customAttributes, syncContext);

onMounted(() => {
  window.addEventListener('message', triggerEvent);
  themeObserver = new MutationObserver(onThemeChange);
  themeObserver.observe(document.body, {
    attributes: true,
    attributeFilter: ['class'],
  });
});

onUnmounted(() => {
  window.removeEventListener('message', triggerEvent);
  themeObserver.disconnect();
});

defineExpose({ triggerEvent });
</script>

<!-- eslint-disable-next-line vue/no-root-v-if -->
<template>
  <div v-if="hasOpenedAtLeastOnce" class="dashboard-app--container">
    <div
      v-for="(configItem, index) in config"
      :key="index"
      class="dashboard-app--list"
    >
      <LoadingState
        v-if="iframeLoading"
        :message="$t('DASHBOARD_APPS.LOADING_MESSAGE')"
        class="dashboard-app_loading-container"
      />
      <iframe
        v-if="configItem.type === 'frame' && configItem.url"
        :id="getFrameId(index)"
        :src="configItem.url"
        @load="() => sendContext(index)"
      />
    </div>
  </div>
</template>

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
