<script setup>
import { ref, computed, watch, nextTick } from 'vue';
import { useI18n } from 'vue-i18n';
import { DirectUpload } from 'activestorage';
import { useAlert } from 'dashboard/composables';
import Button from 'dashboard/components-next/button/Button.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import whatsappStickersApi from 'dashboard/api/whatsappStickers';

const props = defineProps({
  show: {
    type: Boolean,
    default: false,
  },
  inboxId: {
    type: Number,
    required: true,
  },
});

const emit = defineEmits(['close', 'send']);

const { t } = useI18n();

const dialogRef = ref(null);
const fileInputRef = ref(null);
const isLoading = ref(false);
const isUploading = ref(false);
const isDeleting = ref(false);
const selectionMode = ref(false);
const selectedIds = ref(new Set());
const stickers = ref({ recent: [], all: [] });

const hasSelection = computed(() => selectedIds.value.size > 0);

const loadStickers = async () => {
  if (!props.inboxId) return;
  isLoading.value = true;
  try {
    const { data } = await whatsappStickersApi.getStickers(props.inboxId);
    stickers.value = data;
    // eslint-disable-next-line no-console
    console.info('[StickerPicker] loaded', {
      inboxId: props.inboxId,
      recent: data?.recent?.length || 0,
      all: data?.all?.length || 0,
    });
  } catch (error) {
    useAlert(t('CONVERSATION.REPLYBOX.STICKERS.LOAD_ERROR'));
  } finally {
    isLoading.value = false;
  }
};

const handleOpen = async () => {
  await nextTick();
  dialogRef.value?.open();
  await loadStickers();
};

const resetSelectionState = () => {
  selectionMode.value = false;
  selectedIds.value = new Set();
};

const handleClose = () => {
  resetSelectionState();
  emit('close');
};

const toggleSelectionMode = () => {
  selectionMode.value = !selectionMode.value;
  if (!selectionMode.value) {
    selectedIds.value = new Set();
  }
};

const toggleStickerSelection = stickerId => {
  const next = new Set(selectedIds.value);
  if (next.has(stickerId)) {
    next.delete(stickerId);
  } else {
    next.add(stickerId);
  }
  selectedIds.value = next;
};

const getStickerPreviewUrl = sticker => {
  const fileUrl = sticker?.file_url;
  const thumbUrl = sticker?.thumb_url;
  if (!fileUrl) return thumbUrl;
  const isAnimated = /\.(gif|webp)(\?|$)/i.test(fileUrl);
  return isAnimated ? fileUrl : thumbUrl || fileUrl;
};

const handleStickerClick = sticker => {
  if (selectionMode.value) {
    toggleStickerSelection(sticker.id);
    return;
  }

  // eslint-disable-next-line no-console
  console.info('[StickerPicker] send', { stickerId: sticker.id });
  emit('send', sticker);
  handleClose();
};

const handleDeleteSelected = async () => {
  if (!hasSelection.value) return;
  isDeleting.value = true;
  try {
    await whatsappStickersApi.bulkDelete(Array.from(selectedIds.value));
    // eslint-disable-next-line no-console
    console.info('[StickerPicker] deleted', {
      ids: Array.from(selectedIds.value),
    });
    selectionMode.value = false;
    selectedIds.value = new Set();
    await loadStickers();
  } catch (error) {
    useAlert(t('CONVERSATION.REPLYBOX.STICKERS.DELETE_ERROR'));
  } finally {
    isDeleting.value = false;
  }
};

const handleAddSticker = () => {
  fileInputRef.value?.click();
};

const handleFileChange = async event => {
  const file = event.target.files?.[0];
  if (!file) return;

  isUploading.value = true;
  const upload = new DirectUpload(file, '/rails/active_storage/direct_uploads');

  upload.create(async (error, blob) => {
    if (error) {
      useAlert(t('CONVERSATION.REPLYBOX.STICKERS.UPLOAD_ERROR'));
      isUploading.value = false;
      return;
    }

    try {
      // eslint-disable-next-line no-console
      console.info('[StickerPicker] upload complete', { blobId: blob.id });
      await whatsappStickersApi.createSticker(props.inboxId, blob.signed_id);
      // eslint-disable-next-line no-console
      console.info('[StickerPicker] saved', { inboxId: props.inboxId });
      await loadStickers();
    } catch (createError) {
      useAlert(t('CONVERSATION.REPLYBOX.STICKERS.UPLOAD_ERROR'));
    } finally {
      isUploading.value = false;
      event.target.value = '';
    }
  });
};

watch(
  () => props.show,
  show => {
    if (show) {
      handleOpen();
    } else {
      resetSelectionState();
    }
  },
  { immediate: true }
);
</script>

<template>
  <Dialog
    ref="dialogRef"
    :title="t('CONVERSATION.REPLYBOX.STICKERS.TITLE')"
    :show-cancel-button="false"
    :show-confirm-button="false"
    width="3xl"
    @close="handleClose"
  >
    <div class="flex items-center justify-between gap-3">
      <div class="text-sm text-n-slate-11">
        {{ t('CONVERSATION.REPLYBOX.STICKERS.SUBTITLE') }}
      </div>
      <div class="flex items-center gap-2">
        <Button
          variant="faded"
          color="slate"
          :label="
            selectionMode
              ? t('CONVERSATION.REPLYBOX.STICKERS.CANCEL_SELECTION')
              : t('CONVERSATION.REPLYBOX.STICKERS.SELECT')
          "
          @click="toggleSelectionMode"
        />
        <Button
          v-if="selectionMode"
          color="ruby"
          :label="t('CONVERSATION.REPLYBOX.STICKERS.DELETE')"
          :disabled="!hasSelection || isDeleting"
          :is-loading="isDeleting"
          @click="handleDeleteSelected"
        />
        <Button
          color="blue"
          :label="t('CONVERSATION.REPLYBOX.STICKERS.ADD')"
          :is-loading="isUploading"
          :disabled="isUploading"
          @click="handleAddSticker"
        />
      </div>
    </div>

    <input
      ref="fileInputRef"
      type="file"
      accept="image/png,image/jpeg,image/gif,image/webp"
      class="hidden"
      @change="handleFileChange"
    />

    <div v-if="isLoading" class="text-sm text-n-slate-11">
      {{ t('CONVERSATION.REPLYBOX.STICKERS.LOADING') }}
    </div>

    <template v-else>
      <div class="max-h-[60vh] overflow-y-auto pr-1 flex flex-col gap-4">
        <div v-if="stickers.recent?.length" class="flex flex-col gap-3">
        <div class="text-xs font-medium text-n-slate-11 uppercase">
          {{ t('CONVERSATION.REPLYBOX.STICKERS.RECENT') }}
        </div>
        <div class="grid grid-cols-4 sm:grid-cols-5 gap-3">
          <button
            v-for="sticker in stickers.recent"
            :key="`recent-${sticker.id}`"
            type="button"
            class="rounded-lg border border-n-weak overflow-hidden p-1 transition"
            :class="{
              'ring-2 ring-n-brand': selectedIds.has(sticker.id),
              'hover:border-n-slate-6': !selectionMode,
            }"
            @click="handleStickerClick(sticker)"
          >
            <img
              :src="getStickerPreviewUrl(sticker)"
              :alt="t('CONVERSATION.REPLYBOX.STICKERS.ALT')"
              class="w-full h-20 object-contain"
            />
          </button>
        </div>
      </div>

      <div class="flex flex-col gap-3">
        <div class="text-xs font-medium text-n-slate-11 uppercase">
          {{ t('CONVERSATION.REPLYBOX.STICKERS.ALL') }}
        </div>
        <div v-if="!stickers.all?.length" class="text-sm text-n-slate-11">
          {{ t('CONVERSATION.REPLYBOX.STICKERS.EMPTY') }}
        </div>
        <div v-else class="grid grid-cols-4 sm:grid-cols-5 gap-3">
          <button
            v-for="sticker in stickers.all"
            :key="sticker.id"
            type="button"
            class="rounded-lg border border-n-weak overflow-hidden p-1 transition"
            :class="{
              'ring-2 ring-n-brand': selectedIds.has(sticker.id),
              'hover:border-n-slate-6': !selectionMode,
            }"
            @click="handleStickerClick(sticker)"
          >
            <img
              :src="getStickerPreviewUrl(sticker)"
              :alt="t('CONVERSATION.REPLYBOX.STICKERS.ALT')"
              class="w-full h-20 object-contain"
            />
          </button>
        </div>
      </div>
      </div>
    </template>
  </Dialog>
</template>
