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

const applications = useMapGetter('applications/getApplications');

const app = computed(() => {
  const appId = parseInt(route.params.appId, 10);
  return applications.value.find(application => application.id === appId);
});

const appUrl = computed(() => {
  if (!app.value) return '';
  return app.value.url;
});

const onLoad = () => {
  setTimeout(() => {
    loading.value = false;
    error.value = null;

    if (app.value) {
      store.dispatch('applications/updateLastUsed', app.value.id);
    }
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

const handleIframeMessage = () => {
  // Handle iframe messages if needed
};

onMounted(() => {
  if (!app.value) {
    loading.value = false;
    error.value = 'Application not found';
  } else {
    setTimeout(() => {
      if (loading.value) {
        loading.value = false;
      }
    }, 5000);
  }

  window.addEventListener('message', handleIframeMessage);
});

onUnmounted(() => {
  window.removeEventListener('message', handleIframeMessage);
});

watch(
  () => route.params.appId,
  () => {
    loading.value = true;
    error.value = null;
  },
  { immediate: true }
);
</script>

<template>
  <div class="h-full flex flex-col">
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
          :aria-label="$t('GENERAL_SETTINGS.FORM.REFRESH')"
          @click="refreshApp"
        >
          <i class="i-lucide-refresh-cw size-4" />
        </button>

        <button
          class="p-2 hover:bg-slate-100 rounded-lg"
          :aria-label="$t('GENERAL_SETTINGS.FORM.OPEN_EXTERNAL')"
          @click="openExternal"
        >
          <i class="i-lucide-external-link size-4" />
        </button>
      </div>
    </header>

    <div v-if="loading && !app" class="flex-1 flex items-center justify-center">
      <div class="text-center">
        <i class="i-lucide-loader-2 size-8 animate-spin text-woot-500 mb-2" />
        <p class="text-slate-600">{{ $t('GENERAL_SETTINGS.FORM.LOADING') }}</p>
      </div>
    </div>

    <div v-else-if="error" class="flex-1 flex items-center justify-center">
      <div class="text-center max-w-md">
        <i class="i-lucide-alert-circle size-12 text-red-500 mb-4" />
        <h3 class="text-lg font-semibold mb-2">
          {{ $t('GENERAL_SETTINGS.FORM.FAILED_TO_LOAD') }}
        </h3>
        <p class="text-slate-600 mb-4">{{ error }}</p>
        <button
          class="px-4 py-2 bg-blue-500 text-white rounded-lg hover:bg-blue-600"
          @click="refreshApp"
        >
          {{ $t('GENERAL_SETTINGS.FORM.TRY_AGAIN') }}
        </button>
      </div>
    </div>

    <div v-else class="flex-1 overflow-auto relative">
      <div class="w-full h-full desktop-container">
        <div
          v-if="loading"
          class="absolute inset-0 bg-white bg-opacity-90 flex items-center justify-center z-10"
        >
          <div class="text-center">
            <i
              class="i-lucide-loader-2 size-8 animate-spin text-woot-500 mb-2"
            />
            <p class="text-slate-600">
              {{ $t('GENERAL_SETTINGS.FORM.LOADING') }}
            </p>
          </div>
        </div>

        <iframe
          ref="appFrame"
          :src="appUrl"
          class="w-full h-full border-0 desktop-iframe"
          @load="onLoad"
          @error="onError"
        />
      </div>
    </div>
  </div>
</template>

<style scoped>
.desktop-container {
  min-width: 1200px;
}

.desktop-iframe {
  min-width: 1200px;
  opacity: 1;
}

.overflow-auto::-webkit-scrollbar {
  width: 8px;
  height: 8px;
}

.overflow-auto::-webkit-scrollbar-track {
  background: #f1f5f9;
}

.overflow-auto::-webkit-scrollbar-thumb {
  background: #cbd5e1;
  border-radius: 4px;
}

.overflow-auto::-webkit-scrollbar-thumb:hover {
  background: #94a3b8;
}
</style>
