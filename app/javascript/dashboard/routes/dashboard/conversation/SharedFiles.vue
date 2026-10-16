<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useMapGetter } from 'dashboard/composables/store';
import {
  MEDIA_TYPES,
  NON_FILE_TYPES,
} from 'dashboard/components-next/message/constants';

import GalleryView from 'dashboard/components/widgets/conversation/components/GalleryView.vue';
import Media from 'dashboard/components-next/SharedAttachments/Media.vue';
import Files from 'dashboard/components-next/SharedAttachments/Files.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';

const MEDIA_PEEK_LIMIT = 6;
const FILES_PEEK_LIMIT = 3;

const allAttachments = useMapGetter('getSelectedChatAttachments');
const attachmentsLoaded = useMapGetter('getSelectedChatAttachmentsLoaded');
const { t } = useI18n();

const mediaAttachments = computed(() =>
  allAttachments.value
    .filter(a => MEDIA_TYPES.includes(a.file_type) && a.data_url)
    .sort((a, b) => (b.created_at || 0) - (a.created_at || 0))
);

const hasContent = computed(() =>
  allAttachments.value.some(
    a => a.data_url && !NON_FILE_TYPES.includes(a.file_type)
  )
);

const showGallery = ref(false);
const selectedAttachment = ref(null);

const onMediaSelect = attachment => {
  selectedAttachment.value = attachment;
  showGallery.value = true;
};

const onFileSelect = attachment => {
  if (attachment.data_url) {
    window.open(attachment.data_url, '_blank', 'noopener,noreferrer');
  }
};
</script>

<template>
  <div class="p-2">
    <div v-if="!attachmentsLoaded" class="flex justify-center p-3">
      <Spinner class="size-5" />
    </div>
    <p v-else-if="!hasContent" class="p-3 text-sm text-center text-n-slate-11">
      {{ t('CONVERSATION_SIDEBAR.SHARED_FILES.EMPTY') }}
    </p>
    <div v-else class="flex flex-col gap-5">
      <Media
        :attachments="allAttachments"
        :peek-limit="MEDIA_PEEK_LIMIT"
        @select="onMediaSelect"
      />
      <Files
        :attachments="allAttachments"
        :peek-limit="FILES_PEEK_LIMIT"
        @select="onFileSelect"
      />
    </div>
    <GalleryView
      v-if="showGallery && selectedAttachment"
      v-model:show="showGallery"
      :attachment="selectedAttachment"
      :all-attachments="mediaAttachments"
      auto-play
      @close="showGallery = false"
    />
  </div>
</template>
