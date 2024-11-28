<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';

import FileIcon from 'next/icon/FileIcon.vue';
import Icon from 'next/icon/Icon.vue';

const { attachment } = defineProps({
  attachment: {
    type: Object,
    required: true,
  },
});

const { t } = useI18n();

const fileName = computed(() => {
  const url = attachment.dataUrl;
  if (url) {
    const filename = url.substring(url.lastIndexOf('/') + 1);
    return filename || t('CONVERSATION.UNKNOWN_FILE_TYPE');
  }
  return t('CONVERSATION.UNKNOWN_FILE_TYPE');
});

const fileType = computed(() => {
  return fileName.value.split('.').pop();
});
</script>

<template>
  <div
    class="h-9 bg-n-solid-3 gap-2 items-center flex px-2 rounded-lg border border-n-strong"
  >
    <FileIcon class="flex-shrink-0" :file-type="fileType" />
    <span class="mr-1 max-w-32 truncate">{{ fileName }}</span>
    <a
      v-tooltip="t('CONVERSATION.DOWNLOAD')"
      class="flex-shrink-0 h-9 grid place-content-center cursor-pointer"
      :href="url"
      rel="noreferrer noopener nofollow"
      target="_blank"
    >
      <Icon icon="i-lucide-download" />
    </a>
  </div>
</template>
