<script setup>
import { ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  properties: {
    type: Object,
    required: true,
  },
});

const emit = defineEmits(['update:properties']);

const { t } = useI18n();

const localProps = ref({
  type: props.properties.type || 'image',
  url: props.properties.url || '',
  thumbnailUrl: props.properties.thumbnailUrl || '',
  caption: props.properties.caption || '',
  altText: props.properties.altText || '',
});

const mediaTypes = [
  { value: 'image', label: 'Image' },
  { value: 'video', label: 'Video' },
  { value: 'audio', label: 'Audio' },
];

watch(
  localProps,
  newValue => {
    emit('update:properties', newValue);
  },
  { deep: true }
);

const handleFileUpload = () => {
  const input = document.createElement('input');
  input.type = 'file';

  // Set accept based on media type
  if (localProps.value.type === 'image') {
    input.accept = 'image/*';
  } else if (localProps.value.type === 'video') {
    input.accept = 'video/*';
  } else if (localProps.value.type === 'audio') {
    input.accept = 'audio/*';
  }

  input.onchange = e => {
    const file = e.target.files[0];
    if (file) {
      const reader = new FileReader();
      reader.onload = event => {
        localProps.value.url = event.target.result;
      };
      reader.readAsDataURL(file);
    }
  };
  input.click();
};
</script>

<template>
  <div class="space-y-4">
    <!-- Media Type -->
    <div>
      <label class="block text-sm font-medium text-n-slate-12 mb-2">
        {{ t('TEMPLATES.BUILDER.MEDIA_BLOCK.TYPE.LABEL') }}
      </label>
      <select
        v-model="localProps.type"
        class="w-full px-4 py-2 border border-n-slate-7 rounded-lg focus:outline-none focus:ring-2 focus:ring-n-blue-7"
      >
        <option v-for="type in mediaTypes" :key="type.value" :value="type.value">
          {{ type.label }}
        </option>
      </select>
    </div>

    <!-- URL -->
    <div>
      <label class="block text-sm font-medium text-n-slate-12 mb-2">
        {{ t('TEMPLATES.BUILDER.MEDIA_BLOCK.URL.LABEL') }}
      </label>
      <div class="flex gap-2">
        <input
          v-model="localProps.url"
          type="text"
          :placeholder="t('TEMPLATES.BUILDER.MEDIA_BLOCK.URL.PLACEHOLDER')"
          class="flex-1 px-4 py-2 border border-n-slate-7 rounded-lg focus:outline-none focus:ring-2 focus:ring-n-blue-7"
        />
        <Button icon="i-lucide-upload" @click="handleFileUpload">
          {{ t('TEMPLATES.BUILDER.MEDIA_BLOCK.UPLOAD') }}
        </Button>
      </div>
      <p class="text-xs text-n-slate-10 mt-1">
        {{ t('TEMPLATES.BUILDER.MEDIA_BLOCK.URL.HELP') }}
      </p>
    </div>

    <!-- Preview -->
    <div v-if="localProps.url" class="bg-n-slate-2 rounded-lg p-4">
      <div class="text-xs font-medium text-n-slate-11 mb-2">Preview:</div>
      <div class="bg-white rounded border border-n-weak p-2">
        <img
          v-if="localProps.type === 'image'"
          :src="localProps.url"
          :alt="localProps.altText || 'Preview'"
          class="max-w-full h-auto max-h-64 mx-auto"
        />
        <video
          v-else-if="localProps.type === 'video'"
          :src="localProps.url"
          controls
          class="max-w-full h-auto max-h-64 mx-auto"
        />
        <audio
          v-else-if="localProps.type === 'audio'"
          :src="localProps.url"
          controls
          class="w-full"
        />
      </div>
    </div>

    <!-- Thumbnail URL (for videos) -->
    <div v-if="localProps.type === 'video'">
      <label class="block text-sm font-medium text-n-slate-12 mb-2">
        {{ t('TEMPLATES.BUILDER.MEDIA_BLOCK.THUMBNAIL.LABEL') }}
      </label>
      <input
        v-model="localProps.thumbnailUrl"
        type="text"
        :placeholder="t('TEMPLATES.BUILDER.MEDIA_BLOCK.THUMBNAIL.PLACEHOLDER')"
        class="w-full px-4 py-2 border border-n-slate-7 rounded-lg focus:outline-none focus:ring-2 focus:ring-n-blue-7"
      />
      <p class="text-xs text-n-slate-10 mt-1">
        {{ t('TEMPLATES.BUILDER.MEDIA_BLOCK.THUMBNAIL.HELP') }}
      </p>
    </div>

    <!-- Caption -->
    <div>
      <label class="block text-sm font-medium text-n-slate-12 mb-2">
        {{ t('TEMPLATES.BUILDER.MEDIA_BLOCK.CAPTION.LABEL') }}
      </label>
      <textarea
        v-model="localProps.caption"
        rows="2"
        :placeholder="t('TEMPLATES.BUILDER.MEDIA_BLOCK.CAPTION.PLACEHOLDER')"
        class="w-full px-4 py-2 border border-n-slate-7 rounded-lg focus:outline-none focus:ring-2 focus:ring-n-blue-7"
      />
    </div>

    <!-- Alt Text -->
    <div>
      <label class="block text-sm font-medium text-n-slate-12 mb-2">
        {{ t('TEMPLATES.BUILDER.MEDIA_BLOCK.ALT_TEXT.LABEL') }}
      </label>
      <input
        v-model="localProps.altText"
        type="text"
        :placeholder="t('TEMPLATES.BUILDER.MEDIA_BLOCK.ALT_TEXT.PLACEHOLDER')"
        class="w-full px-4 py-2 border border-n-slate-7 rounded-lg focus:outline-none focus:ring-2 focus:ring-n-blue-7"
      />
      <p class="text-xs text-n-slate-10 mt-1">
        {{ t('TEMPLATES.BUILDER.MEDIA_BLOCK.ALT_TEXT.HELP') }}
      </p>
    </div>
  </div>
</template>
