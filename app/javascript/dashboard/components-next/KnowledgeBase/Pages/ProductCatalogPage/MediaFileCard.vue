<template>
  <button
    class="flex items-center gap-4 p-4 bg-n-alpha-3 backdrop-blur-[100px] border border-n-weak rounded-xl hover:bg-n-slate-2 transition-colors w-full text-left"
    :class="{ 'ring-2 ring-n-blue-9 bg-n-blue-2': isSelected }"
    @click="emit('click')"
  >
    <!-- Icon/Thumbnail -->
    <div class="flex-shrink-0">
      <div
        v-if="media.file_type === 'IMAGE' && media.thumbnail_url"
        class="w-16 h-16 rounded-lg overflow-hidden bg-n-slate-3"
      >
        <img
          :src="media.thumbnail_url"
          :alt="media.file_name"
          class="w-full h-full object-cover"
        />
      </div>
      <div
        v-else
        class="w-16 h-16 rounded-lg flex items-center justify-center"
        :class="{
          'bg-n-blue-3': media.file_type === 'IMAGE',
          'bg-n-purple-3': media.file_type === 'VIDEO',
          'bg-n-orange-3': media.file_type === 'DOCUMENT'
        }"
      >
        <i
          class="w-8 h-8"
          :class="{
            'i-lucide-image text-n-blue-11': media.file_type === 'IMAGE',
            'i-lucide-video text-n-purple-11': media.file_type === 'VIDEO',
            'i-lucide-file-text text-n-orange-11': media.file_type === 'DOCUMENT'
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
        <span v-if="media.created_at">{{ formatDate(media.created_at) }}</span>
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
defineProps({
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
