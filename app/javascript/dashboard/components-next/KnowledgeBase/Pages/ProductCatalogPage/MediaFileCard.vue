<template>
  <button
    class="flex items-center gap-4 p-4 bg-n-alpha-3 backdrop-blur-[100px] border border-n-weak rounded-xl hover:bg-n-slate-2 transition-colors w-full text-left"
    :class="{ 'ring-2 ring-n-blue-9 bg-n-blue-2': isSelected }"
    @click="emit('click')"
  >
    <!-- Icon/Thumbnail -->
    <div class="flex-shrink-0">
      <!-- Image thumbnail with lazy loading -->
      <div
        v-if="media.file_type === 'image' && media.file_url && !hasError"
        class="w-16 h-16 rounded-lg overflow-hidden bg-n-slate-3 relative"
      >
        <!-- Loading placeholder -->
        <div
          v-if="isLoading"
          class="absolute inset-0 bg-n-slate-3 animate-pulse"
        />
        <img
          :src="media.file_url"
          :alt="media.file_name"
          loading="lazy"
          class="w-full h-full object-cover"
          @load="isLoading = false"
          @error="handleImageError"
        />
      </div>
      <!-- Video thumbnail with preview -->
      <div
        v-else-if="media.file_type === 'video' && media.file_url && !hasError"
        class="w-16 h-16 rounded-lg overflow-hidden bg-n-slate-3 relative"
      >
        <!-- Loading placeholder -->
        <div
          v-if="isLoading"
          class="absolute inset-0 bg-n-slate-3 animate-pulse"
        />
        <video
          :src="media.file_url"
          preload="metadata"
          muted
          class="w-full h-full object-cover"
          @loadedmetadata="handleVideoLoaded"
          @error="handleVideoError"
        />
        <!-- Play icon overlay -->
        <div class="absolute inset-0 flex items-center justify-center bg-black/20">
          <i class="i-lucide-play w-6 h-6 text-white" />
        </div>
      </div>
      <!-- Fallback icon for documents or failed loads -->
      <div
        v-else
        class="w-16 h-16 rounded-lg flex items-center justify-center"
        :class="{
          'bg-n-blue-3': media.file_type === 'image',
          'bg-n-purple-3': media.file_type === 'video',
          'bg-n-orange-3': media.file_type === 'document'
        }"
      >
        <i
          class="w-8 h-8"
          :class="{
            'i-lucide-image text-n-blue-11': media.file_type === 'image',
            'i-lucide-video text-n-purple-11': media.file_type === 'video',
            'i-lucide-file-text text-n-orange-11': media.file_type === 'document'
          }"
        />
      </div>
    </div>

    <!-- File Info -->
    <div class="flex-1 min-w-0">
      <div class="flex items-center gap-2 mb-1">
        <p class="text-sm font-medium text-n-slate-12 truncate">
          {{ media.file_name }}
        </p>
        <span
          v-if="media.is_primary"
          class="flex-shrink-0 px-2 py-0.5 text-xs font-medium bg-n-green-3 text-n-green-11 rounded"
        >
          {{ $t('KNOWLEDGE_BASE.PRODUCT_CATALOG.MEDIA_DRAWER.PRIMARY') }}
        </span>
      </div>
      <div class="flex items-center gap-3 text-xs text-n-slate-11">
        <span v-if="media.mime_type">{{ media.mime_type }}</span>
        <span v-if="media.file_size">{{ formatFileSize(media.file_size) }}</span>
        <span v-if="mostRecentDate" class="flex items-center gap-1">
          <i class="i-lucide-clock w-3 h-3" />
          {{ formatDate(mostRecentDate) }}
        </span>
      </div>
    </div>

    <!-- Actions -->
    <div class="flex-shrink-0 flex items-center gap-2">
      <button
        v-if="!media.is_primary"
        class="px-3 py-1.5 text-xs font-medium bg-n-slate-3 hover:bg-n-green-3 text-n-slate-11 hover:text-n-green-11 rounded-lg transition-colors"
        @click.stop="emit('set-primary', media)"
        title="Set as primary"
      >
        Set Primary
      </button>
      <i class="i-lucide-eye w-5 h-5 text-n-slate-11" />
    </div>
  </button>
</template>

<script setup>
import { computed, ref } from 'vue';

const props = defineProps({
  media: {
    type: Object,
    required: true
  },
  isSelected: {
    type: Boolean,
    default: false
  }
});

const emit = defineEmits(['click', 'set-primary']);

// Loading state for thumbnails
const isLoading = ref(true);
const hasError = ref(false);

// Handle image load error - fall back to icon
const handleImageError = () => {
  isLoading.value = false;
  hasError.value = true;
};

// Handle video metadata loaded - seek to 1 second for better preview
const handleVideoLoaded = (event) => {
  isLoading.value = false;
  // Seek to 1 second for a better preview frame (avoids black frames)
  if (event.target.duration > 1) {
    event.target.currentTime = 1;
  }
};

// Handle video error - fall back to icon
const handleVideoError = () => {
  isLoading.value = false;
  hasError.value = true;
};

// Show the most recent date (updated_at if exists and different from created_at, otherwise created_at)
const mostRecentDate = computed(() => {
  const updated = props.media.updated_at;
  const created = props.media.created_at;
  if (updated && updated !== created) {
    return updated;
  }
  return created;
});

const formatFileSize = (bytes) => {
  if (!bytes) return '-';
  if (bytes === 0) return '0 Bytes';
  const k = 1024;
  const sizes = ['Bytes', 'KB', 'MB', 'GB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return `${Math.round(bytes / Math.pow(k, i) * 100) / 100} ${sizes[i]}`;
};

const formatDate = (dateString) => {
  if (!dateString) return '-';
  const date = new Date(dateString);
  return new Intl.DateTimeFormat('en-US', {
    month: 'short',
    day: 'numeric',
    year: 'numeric'
  }).format(date);
};
</script>
