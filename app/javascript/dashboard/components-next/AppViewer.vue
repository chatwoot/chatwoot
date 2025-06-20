<script setup>
import { ref, computed, onMounted, onUnmounted, watch } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useStore } from 'vuex';
import { useMapGetter } from 'dashboard/composables/store';

const route = useRoute();
const router = useRouter();
const store = useStore();

const appFrame = ref(null);
const loading = ref(true);
const error = ref(null);
const isVisible = ref(true);

const applications = useMapGetter('applications/getApplications');

const app = computed(() => {
  const appId = parseInt(route.params.appId, 10);
  return applications.value.find(application => application.id === appId);
});

const appUrl = computed(() => {
  if (!app.value) return '';
  return app.value.url;
});

// Send app context to iframe (following Chatwoot pattern)
const sendAppContext = () => {
  if (!appFrame.value || !app.value) return;

  const context = {
    event: 'appContext',
    data: {
      app: app.value,
      // Add any other context you need
    },
  };

  appFrame.value.contentWindow?.postMessage(context, appUrl.value);
};

const onLoad = () => {
  setTimeout(() => {
    loading.value = false;
    error.value = null;

    if (app.value) {
      store.dispatch('applications/updateLastUsed', app.value.id);
    }

    // Send context to the iframe after load (similar to Chatwoot)
    sendAppContext();
  }, 1000);
};

const onError = () => {
  loading.value = false;
  error.value = 'Unable to load application';
};

const refreshApp = () => {
  if (!app.value) return;

  loading.value = true;
  error.value = null;

  if (appFrame.value) {
    appFrame.value.src = appUrl.value;
  }
};

const openExternal = () => {
  if (appUrl.value) {
    window.open(appUrl.value, '_blank');
  }
};

// Handle iframe messages (following Chatwoot pattern)
const handleIframeMessage = event => {
  // Only process messages from our app
  if (!appUrl.value || !event.origin.includes(new URL(appUrl.value).hostname)) {
    return;
  }

  // Handle fetch-info request (similar to Chatwoot)
  if (event.data === 'dashboard-app:fetch-info') {
    sendAppContext();
  }
};

onMounted(() => {
  if (!app.value) {
    loading.value = false;
    error.value = 'Application not found';
    return;
  }

  // Add event listener (Chatwoot uses addEventListener instead of onmessage)
  window.addEventListener('message', handleIframeMessage);

  // Fallback timeout
  setTimeout(() => {
    if (loading.value) {
      loading.value = false;
    }
  }, 5000);
});

onUnmounted(() => {
  window.removeEventListener('message', handleIframeMessage);
});

watch(
  () => route.params.appId,
  () => {
    loading.value = true;
    error.value = null;
    isVisible.value = true;
  },
  { immediate: true }
);
</script>

<template>
  <div class="dashboard-app-container">
    <header
      class="flex items-center gap-3 p-4 border-b border-slate-200 bg-white"
    >
      <button class="p-2 hover:bg-slate-100 rounded-lg" @click="router.go(-1)">
        <i class="i-lucide-arrow-left size-4" />
      </button>

      <div class="flex items-center gap-2">
        <img
          v-if="app?.thumbnail"
          :src="app.thumbnail"
          :alt="app?.name"
          class="size-6 rounded object-cover"
        />
        <div
          v-else
          class="size-6 bg-gradient-to-br from-woot-500 to-woot-600 rounded flex items-center justify-center"
        >
          <i class="i-lucide-grid-3x3 size-3 text-white" />
        </div>
        <h1 class="font-semibold text-slate-800">{{ app?.name }}</h1>
      </div>

      <div class="ml-auto flex items-center gap-2">
        <button
          class="p-2 hover:bg-slate-100 rounded-lg"
          :aria-label="$t('GENERAL_SETTINGS.INTEGRATIONS.REFRESH')"
          @click="refreshApp"
        >
          <i class="i-lucide-refresh-cw size-4" />
        </button>

        <button
          class="p-2 hover:bg-slate-100 rounded-lg"
          :aria-label="$t('GENERAL_SETTINGS.INTEGRATIONS.OPEN_EXTERNAL')"
          @click="openExternal"
        >
          <i class="i-lucide-external-link size-4" />
        </button>
      </div>
    </header>

    <div v-if="loading && !app" class="dashboard-app-loading">
      <div class="text-center">
        <i class="i-lucide-loader-2 size-8 animate-spin text-woot-500 mb-2" />
        <p class="text-slate-600">
          {{ $t('GENERAL_SETTINGS.INTEGRATIONS.LOADING') }}
        </p>
      </div>
    </div>

    <div v-else-if="error" class="dashboard-app-error">
      <div class="text-center max-w-md">
        <i class="i-lucide-alert-circle size-12 text-red-500 mb-4" />
        <h3 class="text-lg font-semibold mb-2">
          {{ $t('GENERAL_SETTINGS.INTEGRATIONS.LOAD_ERROR') }}
        </h3>
        <p class="text-slate-600 mb-4">{{ error }}</p>
        <button
          class="px-4 py-2 bg-blue-500 text-white rounded-lg hover:bg-blue-600"
          @click="refreshApp"
        >
          {{ $t('GENERAL_SETTINGS.INTEGRATIONS.TRY_AGAIN') }}
        </button>
      </div>
    </div>

    <div v-else class="dashboard-app-frame-container">
      <div v-if="loading" class="dashboard-app-frame-loading">
        <div class="text-center">
          <i class="i-lucide-loader-2 size-8 animate-spin text-woot-500 mb-2" />
          <p class="text-slate-600">
            {{ $t('GENERAL_SETTINGS.INTEGRATIONS.LOADING') }}
          </p>
        </div>
      </div>

      <iframe
        ref="appFrame"
        :src="appUrl"
        class="dashboard-app-frame"
        @load="onLoad"
        @error="onError"
      />
    </div>
  </div>
</template>

<style scoped>
/* Main container - following Chatwoot's approach */
.dashboard-app-container {
  height: 100%;
  width: 100%;
  max-width: 100%;
  display: flex;
  flex-direction: column;
  overflow: hidden;
  box-sizing: border-box;
}

/* Loading states */
.dashboard-app-loading,
.dashboard-app-error {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
}

/* Frame container - similar to Chatwoot's implementation */
.dashboard-app-frame-container {
  flex: 1;
  position: relative;
  overflow: hidden;
  width: 100%;
  max-width: 100%;
  min-height: 0;
}

/* Loading overlay */
.dashboard-app-frame-loading {
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(255, 255, 255, 0.9);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 10;
}

/* Main iframe - following Chatwoot's exact approach */
.dashboard-app-frame {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  max-width: 100%;
  border: none;
  background: white;
  overflow: hidden;
  box-sizing: border-box;
}

/* Prevent any scrollbars on the container */
.dashboard-app-frame-container::-webkit-scrollbar {
  display: none;
}

.dashboard-app-frame-container {
  -ms-overflow-style: none;
  scrollbar-width: none;
}
</style>
