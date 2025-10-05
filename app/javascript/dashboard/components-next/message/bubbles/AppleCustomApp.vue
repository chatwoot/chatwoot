<script setup>
import { computed, ref } from 'vue';
import { useMessageContext } from '../provider.js';
import BaseBubble from './Base.vue';

const { contentAttributes } = useMessageContext();

const appData = computed(() => contentAttributes.value || {});
const isLoading = ref(false);
const errorMessage = ref('');

// Extract app name from BID
function extractAppName() {
  const bid = appData.value.bid;
  if (!bid) return 'Custom App';

  // BID format: com.apple.messages.MSMessageExtensionBalloonPlugin:bundleId:extension
  const parts = bid.split(':');
  if (parts.length >= 2) {
    const bundleId = parts[1];
    // Extract app name from bundle ID (e.g., com.company.appname -> AppName)
    const appName = bundleId.split('.').pop();
    return (
      appName.charAt(0).toUpperCase() +
      appName.slice(1).replace(/([A-Z])/g, ' $1')
    );
  }

  return 'Custom App';
}

// Extract app configuration
const appConfig = computed(() => ({
  appId: appData.value.app_id,
  bid: appData.value.bid,
  version: appData.value.version || '1.0',
  url: appData.value.url,
  appName: extractAppName(),
  parameters: appData.value.parameters || {},
  receivedMessage: appData.value.received_message,
  replyMessage: appData.value.reply_message,
  images: appData.value.images || [],
  useLiveLayout: appData.value.use_live_layout !== false,
}));

// Check if app has preview image
const hasPreviewImage = computed(() => {
  return appConfig.value.images && appConfig.value.images.length > 0;
});

const previewImage = computed(() => {
  if (!hasPreviewImage.value) return null;
  return appConfig.value.images[0];
});

// Handle app invocation (this would trigger the backend service)
const invokeApp = () => {
  isLoading.value = true;
  errorMessage.value = '';

  // In a real implementation, this would trigger the AppInvocationService
  // For now, we'll simulate the app invocation
  setTimeout(() => {
    isLoading.value = false;
  }, 2000);
};

// Format app description
const appDescription = computed(() => {
  if (appData.value.description) {
    return appData.value.description;
  }

  return `Tap to launch ${appConfig.value.appName}`;
});

// Check if app is web-based (has URL)
const isWebBasedApp = computed(() => {
  return !!appConfig.value.url;
});

// Get app icon based on type
const getAppIcon = () => {
  if (isWebBasedApp.value) {
    return 'M21 12a9 9 0 11-18 0 9 9 0 0118 0z M15.91 11.672a.375.375 0 010 .656l-5.603 3.113a.375.375 0 01-.557-.328V8.887c0-.286.307-.466.557-.327l5.603 3.112z'; // Web/Globe icon
  }

  return 'M7 4V2C7 1.45 7.45 1 8 1H16C16.55 1 17 1.45 17 2V4H20C20.55 4 21 4.45 21 5S20.55 6 20 6H19V19C19 20.1 18.1 21 17 21H7C5.9 21 5 20.1 5 19V6H4C3.45 6 3 5.55 3 5S3.45 4 4 4H7ZM9 3V4H15V3H9ZM7 6V19H17V6H7Z'; // Native app icon
};
</script>

<template>
  <BaseBubble>
    <div
      class="apple-custom-app-bubble cursor-pointer hover:bg-slate-50 dark:hover:bg-slate-700 transition-colors"
      @click="invokeApp"
    >
      <!-- App Preview Image -->
      <div v-if="hasPreviewImage" class="app-preview-image">
        <img
          :src="previewImage.url || previewImage.data"
          :alt="appConfig.appName"
          class="w-full h-32 object-cover rounded-t-lg"
        />

        <!-- App overlay indicator -->
        <div
          class="absolute inset-0 flex items-center justify-center bg-black bg-opacity-20 rounded-t-lg"
        >
          <div
            class="w-12 h-12 bg-white bg-opacity-90 rounded-full flex items-center justify-center"
          >
            <svg
              class="w-6 h-6 text-slate-700"
              fill="currentColor"
              viewBox="0 0 24 24"
            >
              <path :d="getAppIcon()" />
            </svg>
          </div>
        </div>
      </div>

      <!-- App Icon Header (when no preview image) -->
      <div
        v-else
        class="app-header bg-gradient-to-br from-blue-500 to-purple-600 p-4 rounded-t-lg"
      >
        <div class="flex items-center space-x-3">
          <div
            class="w-12 h-12 bg-white bg-opacity-90 rounded-xl flex items-center justify-center"
          >
            <svg
              class="w-6 h-6 text-slate-700"
              fill="currentColor"
              viewBox="0 0 24 24"
            >
              <path :d="getAppIcon()" />
            </svg>
          </div>
          <div>
            <h3 class="text-white font-semibold text-lg">
              {{ appConfig.appName }}
            </h3>
            <p v-if="isWebBasedApp" class="text-blue-100 text-sm">Web App</p>
            <p v-else class="text-blue-100 text-sm">Native App</p>
          </div>
        </div>
      </div>

      <!-- App Content -->
      <div class="app-content p-4">
        <!-- App Name (if preview image is shown) -->
        <h3
          v-if="hasPreviewImage"
          class="text-lg font-semibold text-slate-900 dark:text-slate-100 mb-2"
        >
          {{ appConfig.appName }}
        </h3>

        <!-- App Description -->
        <p class="text-sm text-slate-600 dark:text-slate-400 mb-3">
          {{ appDescription }}
        </p>

        <!-- App Parameters (if any) -->
        <div
          v-if="Object.keys(appConfig.parameters).length > 0"
          class="app-parameters mb-3"
        >
          <div
            class="text-xs text-slate-500 dark:text-slate-400 uppercase tracking-wide mb-2"
          >
            Configuration
          </div>
          <div class="space-y-1">
            <div
              v-for="(value, key) in appConfig.parameters"
              :key="key"
              class="flex justify-between text-xs"
            >
              <span class="text-slate-600 dark:text-slate-400 capitalize">{{ key.replace(/_/g, ' ') }}:</span>
              <span class="text-slate-800 dark:text-slate-200 font-medium">{{
                value
              }}</span>
            </div>
          </div>
        </div>

        <!-- App Status -->
        <div class="app-status flex items-center justify-between">
          <!-- Loading State -->
          <div
            v-if="isLoading"
            class="flex items-center space-x-2 text-blue-600"
          >
            <div
              class="w-4 h-4 border-2 border-blue-600 border-t-transparent rounded-full animate-spin"
            />
            <span class="text-sm">Launching app...</span>
          </div>

          <!-- Error State -->
          <div
            v-else-if="errorMessage"
            class="flex items-center space-x-2 text-red-600"
          >
            <svg class="w-4 h-4" fill="currentColor" viewBox="0 0 24 24">
              <path
                d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"
              />
            </svg>
            <span class="text-sm">{{ errorMessage }}</span>
          </div>

          <!-- Ready State -->
          <div
            v-else
            class="flex items-center space-x-2 text-slate-600 dark:text-slate-400"
          >
            <span class="text-sm">Tap to launch</span>
            <svg class="w-4 h-4" fill="currentColor" viewBox="0 0 24 24">
              <path
                d="M8.59 16.59L13.17 12 8.59 7.41 10 6l6 6-6 6-1.41-1.41z"
              />
            </svg>
          </div>
        </div>

        <!-- App Version Info -->
        <div
          class="app-version mt-2 pt-2 border-t border-slate-200 dark:border-slate-600"
        >
          <div
            class="flex justify-between items-center text-xs text-slate-500 dark:text-slate-400"
          >
            <span>Version {{ appConfig.version }}</span>
            <span
              v-if="appConfig.bid"
              class="font-mono truncate max-w-32"
              :title="appConfig.bid"
            >
              {{ appConfig.bid.split(':').pop() }}
            </span>
          </div>
        </div>
      </div>

      <!-- App Launch Indicator -->
      <div class="app-launch-indicator">
        <svg
          class="w-4 h-4 text-slate-500"
          fill="currentColor"
          viewBox="0 0 24 24"
        >
          <path d="M8 5v14l11-7z" />
        </svg>
      </div>
    </div>
  </BaseBubble>
</template>

<style lang="scss" scoped>
.apple-custom-app-bubble {
  @apply max-w-sm bg-white dark:bg-slate-800 rounded-lg border border-slate-200 dark:border-slate-600 overflow-hidden relative;

  .app-preview-image {
    @apply relative;

    img {
      @apply block;
    }
  }

  .app-header {
    @apply relative;
  }

  .app-content {
    @apply relative;
  }

  .app-parameters {
    @apply bg-slate-50 dark:bg-slate-700 rounded-md p-3;
  }

  .app-status {
    @apply text-sm;
  }

  .app-version {
    @apply text-xs;
  }

  .app-launch-indicator {
    @apply absolute top-2 right-2 opacity-0 transition-opacity;
  }
}

.apple-custom-app-bubble:hover {
  @apply shadow-md;

  .app-launch-indicator {
    @apply opacity-100;
  }
}
</style>
