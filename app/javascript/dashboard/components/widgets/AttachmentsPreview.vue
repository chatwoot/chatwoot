<script setup>
import { computed, ref } from 'vue';
import { formatBytes } from 'shared/helpers/FileHelper';

import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  attachments: {
    type: Array,
    default: () => [],
  },
});

const emit = defineEmits(['removeAttachment']);

const nonRecordedAudioAttachments = computed(() => {
  return props.attachments.filter(attachment => !attachment?.isVoiceMessage);
});

const recordedAudioAttachments = computed(() =>
  props.attachments.filter(attachment => attachment.isVoiceMessage)
);

const onRemoveAttachment = itemIndex => {
  emit(
    'removeAttachment',
    nonRecordedAudioAttachments.value
      .filter((_, index) => index !== itemIndex)
      .concat(recordedAudioAttachments.value)
  );
};

const formatFileSize = file => {
  const size = file.byte_size || file.size;
  return formatBytes(size, 0);
};

const isTypeImage = file => {
  const type = file.content_type || file.type;
  return type.includes('image');
};

const fileName = file => {
  return file.filename || file.name;
};

// preview ไฟล์แนบเป็น modal ในหน้าเดิม — ไม่ใช้ window.open เพราะโดนได้ทั้ง
// popup blocker และ quirk ของ blob URL (เปิดแล้วได้แท็บว่าง)
const preview = ref(null);

const previewKind = type => {
  if (/^image\/(?!svg)/.test(type)) return 'image';
  if (/^video\//.test(type)) return 'video';
  if (/^audio\//.test(type)) return 'audio';
  if (type === 'application/pdf') return 'pdf';
  return null;
};

const closePreview = () => {
  if (preview.value) URL.revokeObjectURL(preview.value.url);
  preview.value = null;
};

// แหล่งข้อมูลไฟล์ต่างกันตามโหมด:
// - direct uploads เปิด → resource = ActiveStorage blob (ไม่มีตัวไฟล์) แต่ thumb เก็บทั้งไฟล์เป็น data URL
// - direct uploads ปิด → resource = upload item ที่มี File จริงใน resource.file
const previewUrl = attachment => {
  const res = attachment.resource;
  if (res?.file instanceof Blob) return URL.createObjectURL(res.file);
  return attachment.thumb || res?.data_url || res?.file_url;
};

const openPreview = async attachment => {
  const res = attachment.resource;
  let url = previewUrl(attachment);
  if (!url) return;
  const kind = previewKind(res?.content_type || res?.type || '');
  if (kind) {
    // PDF เป็น data: URL ตรงๆ ใน iframe แสดงไม่ขึ้นใน Chrome บางรุ่น → แปลงเป็น blob URL
    if (kind === 'pdf' && url.startsWith('data:')) {
      url = URL.createObjectURL(await (await fetch(url)).blob());
    }
    preview.value = { url, kind, name: fileName(res) };
  } else {
    // ชนิดที่ browser แสดงเองไม่ได้ (docx/xlsx ฯลฯ) → ดาวน์โหลดพร้อมชื่อไฟล์เดิม
    const link = document.createElement('a');
    link.href = url;
    link.download = fileName(res);
    link.click();
  }
};
</script>

<template>
  <div class="flex flex-wrap gap-y-1 gap-x-2 overflow-auto max-h-[12.5rem]">
    <div
      v-for="(attachment, index) in nonRecordedAudioAttachments"
      :key="attachment.id"
      class="flex items-center p-1 bg-n-slate-3 gap-1 rounded-md w-[15rem]"
    >
      <div
        class="flex items-center flex-1 min-w-0 gap-1 cursor-pointer"
        :title="$t('CONVERSATION.ATTACHMENT_PREVIEW.OPEN')"
        @click="openPreview(attachment)"
      >
        <div class="max-w-[4rem] flex-shrink-0 w-6 flex items-center">
          <img
            v-if="isTypeImage(attachment.resource)"
            class="object-cover w-6 h-6 rounded-sm"
            :src="attachment.thumb"
          />
          <span v-else class="relative w-6 h-6 text-lg text-left -top-px">
            📄
          </span>
        </div>
        <div class="max-w-3/5 min-w-[50%] overflow-hidden text-ellipsis">
          <span
            class="h-4 overflow-hidden text-sm font-medium text-ellipsis whitespace-nowrap"
          >
            {{ fileName(attachment.resource) }}
          </span>
        </div>
      </div>
      <div class="w-[30%] justify-center">
        <span class="overflow-hidden text-xs text-ellipsis whitespace-nowrap">
          {{ formatFileSize(attachment.resource) }}
        </span>
      </div>
      <div class="flex items-center justify-center">
        <Button
          ghost
          slate
          xs
          icon="i-lucide-eye"
          :title="$t('CONVERSATION.ATTACHMENT_PREVIEW.BUTTON')"
          @click="openPreview(attachment)"
        />
        <Button
          ghost
          slate
          xs
          icon="i-lucide-x"
          @click="onRemoveAttachment(index)"
        />
      </div>
    </div>
  </div>
  <Teleport to="body">
    <div
      v-if="preview"
      class="fixed inset-0 z-[9999] flex items-center justify-center bg-black/60 p-6"
      @click.self="closePreview"
    >
      <div
        class="flex flex-col max-w-[92vw] max-h-[92vh] overflow-hidden shadow-xl rounded-xl bg-n-solid-1 border border-n-weak"
      >
        <div
          class="flex items-center justify-between gap-4 px-4 py-2 border-b border-n-weak"
        >
          <span
            class="text-sm font-medium truncate text-n-slate-12"
            :title="preview.name"
          >
            {{ preview.name }}
          </span>
          <Button ghost slate xs icon="i-lucide-x" @click="closePreview" />
        </div>
        <div class="flex items-center justify-center p-3 overflow-auto">
          <img
            v-if="preview.kind === 'image'"
            :src="preview.url"
            :alt="preview.name"
            class="max-w-full max-h-[78vh] object-contain rounded-md"
          />
          <video
            v-else-if="preview.kind === 'video'"
            :src="preview.url"
            controls
            autoplay
            class="max-w-full max-h-[78vh] rounded-md"
          />
          <audio
            v-else-if="preview.kind === 'audio'"
            :src="preview.url"
            controls
            class="my-6 w-96 max-w-full"
          />
          <iframe
            v-else
            :src="preview.url"
            :title="preview.name"
            class="w-[85vw] h-[80vh] bg-white rounded-md"
          />
        </div>
      </div>
    </div>
  </Teleport>
</template>
