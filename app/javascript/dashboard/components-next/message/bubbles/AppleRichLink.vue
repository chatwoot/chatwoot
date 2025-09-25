<script setup>
import { computed, ref, onMounted } from 'vue';
import { useMessageContext } from '../provider.js';
import BaseBubble from './Base.vue';

const { contentAttributes } = useMessageContext();

const richLinkData = computed(() => contentAttributes.value || {});
const hasImage = computed(
  () =>
    richLinkData.value.image_data ||
    richLinkData.value.imageData ||
    richLinkData.value.image_url
);
const hasFavicon = computed(() => richLinkData.value.favicon_url);
const hasVideo = computed(
  () => richLinkData.value.video_url || richLinkData.value.videoUrl
);

// Track image loading state
const imageLoaded = ref(false);
const imageError = ref(false);
const faviconLoaded = ref(false);
const faviconError = ref(false);

// Debug logging
onMounted(() => {
  console.log('🔗 AppleRichLink component mounted');
  console.log('📊 Rich Link Data:', richLinkData.value);
  console.log('🖼️ Has Image:', hasImage.value);
  console.log('🎥 Has Video:', hasVideo.value);
});

// Check if image_data is a URL or base64 data
const isImageDataUrl = computed(() => {
  const imageData =
    richLinkData.value.image_data || richLinkData.value.imageData;
  const isUrl =
    imageData &&
    (imageData.startsWith('http://') || imageData.startsWith('https://'));
  console.log(
    '🔍 Is Image Data URL:',
    isUrl,
    'for:',
    imageData?.substring(0, 50)
  );
  return isUrl;
});

const isImageDataBase64 = computed(() => {
  const imageData =
    richLinkData.value.image_data || richLinkData.value.imageData;
  const isBase64 = imageData && !isImageDataUrl.value;
  console.log('🔍 Is Image Data Base64:', isBase64);
  return isBase64;
});

// Get the image source URL
const imageSource = computed(() => {
  let source = null;
  const imageData =
    richLinkData.value.image_data || richLinkData.value.imageData;
  const imageMimeType =
    richLinkData.value.image_mime_type || richLinkData.value.imageMimeType;

  if (isImageDataBase64.value) {
    source = `data:${imageMimeType || 'image/jpeg'};base64,${imageData}`;
  } else if (isImageDataUrl.value) {
    source = imageData;
  } else if (richLinkData.value.image_url) {
    source = richLinkData.value.image_url;
  }
  console.log('🖼️ Image Source:', source?.substring(0, 100));
  return source;
});

const onImageLoad = () => {
  imageLoaded.value = true;
  imageError.value = false;
  console.log('✅ Image loaded successfully');
};

const onImageError = event => {
  imageError.value = true;
  imageLoaded.value = false;
  console.error('❌ Rich Link image failed to load:', imageSource.value);
  // Hide the image element
  event.target.style.display = 'none';
};

const onFaviconLoad = () => {
  faviconLoaded.value = true;
  faviconError.value = false;
  console.log('✅ Favicon loaded successfully');
};

const onFaviconError = event => {
  faviconError.value = true;
  faviconLoaded.value = false;
  console.error('❌ Favicon failed to load:', richLinkData.value.favicon_url);
  // Hide the favicon element
  event.target.style.display = 'none';
};

const openLink = () => {
  if (richLinkData.value.url) {
    console.log('🔗 Opening link:', richLinkData.value.url);
    window.open(richLinkData.value.url, '_blank', 'noopener,noreferrer');
  }
};
</script>

<template>
  <BaseBubble>
    <div
      class="apple-rich-link-bubble cursor-pointer hover:bg-slate-50 dark:hover:bg-slate-700 transition-colors"
      @click="openLink"
    >
      <!-- Image/Video Section -->
      <div v-if="hasImage || hasVideo" class="rich-link-media">
        <!-- Loading placeholder -->
        <div
          v-if="imageSource && !imageLoaded && !imageError"
          class="w-full h-32 bg-slate-200 dark:bg-slate-600 rounded-t-lg flex items-center justify-center"
        >
          <div class="animate-pulse text-slate-500 dark:text-slate-400">
            <svg class="w-6 h-6" fill="currentColor" viewBox="0 0 24 24">
              <path
                d="M21 19V5c0-1.1-.9-2-2-2H5c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2zM8.5 13.5l2.5 3.01L14.5 12l4.5 6H5l3.5-4.5z"
              />
            </svg>
          </div>
        </div>

        <!-- Video with play button overlay -->
        <div v-if="hasVideo && imageSource" class="relative">
          <img
            :src="imageSource"
            :alt="richLinkData.title || 'Rich Link'"
            class="w-full h-32 object-cover rounded-t-lg"
            @load="onImageLoad"
            @error="onImageError"
          />
          <div
            class="absolute inset-0 flex items-center justify-center bg-black bg-opacity-30 rounded-t-lg"
          >
            <div
              class="w-12 h-12 bg-white bg-opacity-90 rounded-full flex items-center justify-center"
            >
              <svg
                class="w-6 h-6 text-slate-700 ml-1"
                fill="currentColor"
                viewBox="0 0 24 24"
              >
                <path d="M8 5v14l11-7z" />
              </svg>
            </div>
          </div>
        </div>

        <!-- Image only -->
        <img
          v-else-if="imageSource"
          :src="imageSource"
          :alt="richLinkData.title || 'Rich Link'"
          class="w-full h-32 object-cover rounded-t-lg"
          @load="onImageLoad"
          @error="onImageError"
        />

        <!-- Fallback when no image or image failed to load - try favicon -->
        <div
          v-else-if="(!imageSource || imageError) && hasFavicon"
          class="w-full h-32 bg-gradient-to-br from-slate-100 to-slate-200 dark:from-slate-700 dark:to-slate-800 rounded-t-lg flex items-center justify-center"
        >
          <img
            :src="richLinkData.favicon_url"
            :alt="richLinkData.title || 'Rich Link'"
            class="w-8 h-8 object-contain"
            @load="onFaviconLoad"
            @error="onFaviconError"
          />
        </div>

        <!-- Final fallback when both image and favicon fail -->
        <div
          v-else-if="!imageSource || imageError || !hasFavicon || faviconError"
          class="w-full h-32 bg-gradient-to-br from-slate-100 to-slate-200 dark:from-slate-700 dark:to-slate-800 rounded-t-lg flex items-center justify-center"
        >
          <div class="text-slate-400 dark:text-slate-500 text-center">
            <svg
              class="w-8 h-8 mx-auto mb-2"
              fill="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                d="M21 19V5c0-1.1-.9-2-2-2H5c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2zM8.5 13.5l2.5 3.01L14.5 12l4.5 6H5l3.5-4.5z"
              />
            </svg>
            <div class="text-xs">{{ richLinkData.site_name || 'Website' }}</div>
          </div>
        </div>
      </div>

      <!-- Content Section -->
      <div class="rich-link-content p-4">
        <!-- Site Name -->
        <div
          v-if="richLinkData.site_name"
          class="text-xs text-slate-500 dark:text-slate-400 uppercase tracking-wide mb-1"
        >
          {{ richLinkData.site_name }}
        </div>

        <!-- Title -->
        <h3
          class="text-lg font-semibold text-slate-900 dark:text-slate-100 mb-2 line-clamp-2"
        >
          {{ richLinkData.title || 'Rich Link' }}
        </h3>

        <!-- Description -->
        <p
          v-if="richLinkData.description"
          class="text-sm text-slate-600 dark:text-slate-400 line-clamp-3 mb-3"
        >
          {{ richLinkData.description }}
        </p>

        <!-- URL Display -->
        <div class="text-xs text-slate-500 dark:text-slate-400 truncate">
          {{ richLinkData.url }}
        </div>
      </div>

      <!-- External Link Indicator -->
      <div class="external-link-indicator">
        <svg
          class="w-4 h-4 text-slate-500"
          fill="none"
          stroke="currentColor"
          viewBox="0 0 24 24"
        >
          <path
            stroke-linecap="round"
            stroke-linejoin="round"
            stroke-width="2"
            d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14"
          />
        </svg>
      </div>
    </div>
  </BaseBubble>
</template>

<style lang="scss" scoped>
.apple-rich-link-bubble {
  @apply max-w-sm bg-white dark:bg-slate-800 rounded-lg border border-slate-200 dark:border-slate-600 overflow-hidden relative;

  .rich-link-media {
    @apply relative;

    img {
      @apply block;
    }
  }

  .rich-link-content {
    @apply relative;
  }

  .line-clamp-2 {
    display: -webkit-box;
    -webkit-line-clamp: 2;
    -webkit-box-orient: vertical;
    overflow: hidden;
  }

  .line-clamp-3 {
    display: -webkit-box;
    -webkit-line-clamp: 3;
    -webkit-box-orient: vertical;
    overflow: hidden;
  }

  .external-link-indicator {
    @apply absolute top-2 right-2 opacity-0 transition-opacity;
  }
}

.apple-rich-link-bubble:hover {
  @apply shadow-md;

  .external-link-indicator {
    @apply opacity-100;
  }
}
</style>
