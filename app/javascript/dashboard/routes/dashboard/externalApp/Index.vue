<script setup>
import { computed, onMounted, onUnmounted, ref, watch } from 'vue';
import { useRoute } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useMapGetter } from 'dashboard/composables/store';
import ExternalAppContextAPI from 'dashboard/api/externalAppContext';
import LoadingState from 'dashboard/components/widgets/LoadingState.vue';

const globalConfig = useMapGetter('globalConfig/get');
const selectedChat = useMapGetter('getSelectedChat');
const route = useRoute();
const { t } = useI18n();

const externalAppName = computed(
  () => globalConfig.value.externalAppName || 'External App'
);
const externalAppUrl = computed(() => globalConfig.value.externalAppUrl || '');
const missingConfigMessage = 'Configure EXTERNAL_APP_URL to enable this page.';
const invalidConfigMessage =
  'EXTERNAL_APP_URL must be a valid http(s) URL to enable this page.';
const HANDSHAKE_REQUEST_EVENT = 'chatwoot-external-app:fetch-info';

const iframeRef = ref(null);
const isLoading = ref(true);
const externalAppContext = ref(null);
const hasIframeHandshake = ref(false);
let contextRequestId = 0;

const iframeOrigin = computed(() => {
  if (!externalAppUrl.value) return '';
  try {
    const url = new URL(externalAppUrl.value);
    if (!['http:', 'https:'].includes(url.protocol)) return '';
    return url.origin;
  } catch {
    return '';
  }
});

const routeConversationId = computed(
  () =>
    route.params.conversation_id ||
    route.params.conversationId ||
    route.query.conversation_id ||
    route.query.conversationId
);

const routeInboxId = computed(
  () =>
    route.params.inbox_id ||
    route.params.inboxId ||
    route.query.inbox_id ||
    route.query.inboxId
);

const selectedConversationId = computed(
  () => selectedChat.value?.id || routeConversationId.value
);
const selectedInboxId = computed(
  () => selectedChat.value?.inbox_id || routeInboxId.value
);

const postContextToIframe = () => {
  if (!iframeOrigin.value || !iframeRef.value?.contentWindow) return;
  if (!externalAppContext.value) return;
  if (!hasIframeHandshake.value) return;

  try {
    iframeRef.value.contentWindow.postMessage(
      JSON.stringify(externalAppContext.value),
      iframeOrigin.value
    );
  } catch {
    // Iframe may still be on about:blank or a stale origin during navigation.
  }
};

const fetchExternalAppContext = async () => {
  if (!iframeOrigin.value) {
    externalAppContext.value = null;
    return;
  }

  const requestId = contextRequestId + 1;
  contextRequestId = requestId;

  const params = {
    ...(selectedConversationId.value
      ? { conversation_id: selectedConversationId.value }
      : {}),
    ...(selectedInboxId.value ? { inbox_id: selectedInboxId.value } : {}),
    ...(route.name ? { route_name: String(route.name) } : {}),
    ...(route.fullPath ? { route_full_path: route.fullPath } : {}),
  };

  try {
    const { data } = await ExternalAppContextAPI.fetch(params);
    if (contextRequestId !== requestId) return;

    externalAppContext.value = data;
    postContextToIframe();
  } catch {
    if (contextRequestId !== requestId) return;
    externalAppContext.value = null;
  }
};

const onIframeLoad = () => {
  isLoading.value = false;
};

const onIframeError = () => {
  isLoading.value = false;
};

const onWindowMessage = event => {
  if (!iframeRef.value?.contentWindow) return;
  if (event.source !== iframeRef.value.contentWindow) return;
  if (!iframeOrigin.value || event.origin !== iframeOrigin.value) return;
  if (event.data !== HANDSHAKE_REQUEST_EVENT) return;
  hasIframeHandshake.value = true;

  if (!externalAppContext.value) {
    fetchExternalAppContext();
    return;
  }

  postContextToIframe();
};

watch(externalAppContext, () => {
  postContextToIframe();
});

watch(iframeOrigin, origin => {
  isLoading.value = Boolean(origin);
  hasIframeHandshake.value = false;
});

watch(
  [
    selectedConversationId,
    selectedInboxId,
    () => route.name,
    () => route.fullPath,
    iframeOrigin,
  ],
  () => {
    fetchExternalAppContext();
  },
  { immediate: true }
);

onMounted(() => {
  window.addEventListener('message', onWindowMessage);
});

onUnmounted(() => {
  window.removeEventListener('message', onWindowMessage);
});
</script>

<template>
  <section class="flex flex-col h-full w-full min-w-0 bg-n-surface-1">
    <div class="flex-1 min-h-0">
      <div v-if="externalAppUrl && iframeOrigin" class="relative h-full w-full">
        <iframe
          ref="iframeRef"
          :src="externalAppUrl"
          class="h-full w-full border-0"
          @load="onIframeLoad"
          @error="onIframeError"
        />
        <LoadingState
          v-if="isLoading"
          class="absolute inset-0 flex items-center justify-center"
          :message="t('DASHBOARD_APPS.LOADING_MESSAGE')"
        />
      </div>
      <div
        v-else-if="externalAppUrl"
        class="h-full flex items-center justify-center px-6 text-sm text-center text-n-slate-11"
      >
        {{ invalidConfigMessage }}
      </div>
      <div
        v-else
        class="h-full flex items-center justify-center px-6 text-sm text-center text-n-slate-11"
      >
        {{ missingConfigMessage }}
      </div>
    </div>
  </section>
</template>
