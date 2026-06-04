<script setup>
import { computed, nextTick, ref, watch } from 'vue';
import { useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useStore } from 'vuex';
import { useAlert } from 'dashboard/composables';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import GalleryView from './components/GalleryView.vue';
import ForwardMessagesModal from './ForwardMessagesModal.vue';
import { downloadFile } from '@chatwoot/utils';

const props = defineProps({
  show: {
    type: Boolean,
    default: false,
  },
  attachments: {
    type: Array,
    default: () => [],
  },
  messages: {
    type: Array,
    default: () => [],
  },
  conversationId: {
    type: [Number, String],
    default: null,
  },
  isLoading: {
    type: Boolean,
    default: false,
  },
  attachmentsMeta: {
    type: Object,
    default: () => ({}),
  },
  isLoadingMore: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['close', 'load-more']);

const dialogRef = ref(null);
const deleteConfirmRef = ref(null);
const deleteInfoRef = ref(null);
const activeTab = ref('media');
const mediaFilter = ref('all');
const previewAttachment = ref(null);
const showGallery = ref(false);
const showForwardModal = ref(false);
const isForwardSelectionActive = ref(false);
const isDeleteSelectionActive = ref(false);
const showDeleteConfirm = ref(false);
const showDeleteInfo = ref(false);
const deleteTarget = ref('selected');
const deleteInfoCount = ref(0);
const isDeleting = ref(false);
const selectedAttachmentIds = ref([]);
const selectedLinkMessageIds = ref([]);
const isSelectionActive = computed(
  () => isForwardSelectionActive.value || isDeleteSelectionActive.value
);
const getAttachmentSelectionKey = attachment => {
  const messageId =
    attachment?.message_id ||
    attachment?.messageId ||
    attachment?.message?.id ||
    null;
  const url = getAttachmentUrl(attachment);
  const name =
    attachment?.file_name ||
    attachment?.filename ||
    attachment?.name ||
    attachment?.title ||
    '';
  const rawId =
    attachment?.id ||
    attachment?.attachment_id ||
    attachment?.attachmentId ||
    messageId ||
    url ||
    name;
  return rawId ? String(rawId) : '';
};

const getAttachmentSelectionKeys = attachment => {
  const messageId =
    attachment?.message_id ||
    attachment?.messageId ||
    attachment?.message?.id ||
    null;
  const url = getAttachmentUrl(attachment);
  const name =
    attachment?.file_name ||
    attachment?.filename ||
    attachment?.name ||
    attachment?.title ||
    '';
  const candidates = [
    attachment?.id,
    attachment?.attachment_id,
    attachment?.attachmentId,
    messageId,
    url,
    name,
  ];

  return candidates
    .map(value => (value ? String(value) : ''))
    .filter(Boolean);
};
const { t } = useI18n();
const router = useRouter();
const store = useStore();

const showDialog = computed(
  () => props.show && !showGallery.value && !showForwardModal.value
);

const getAttachmentUrl = attachment =>
  attachment?.data_url ||
  attachment?.dataUrl ||
  attachment?.thumb_url ||
  attachment?.thumbUrl ||
  attachment?.file_url ||
  attachment?.fileUrl ||
  attachment?.download_url ||
  attachment?.downloadUrl ||
  attachment?.external_url ||
  attachment?.externalUrl ||
  attachment?.url ||
  '';

const getExtension = attachment => {
  const type = (
    attachment?.file_type ||
    attachment?.fileType ||
    attachment?.content_type ||
    attachment?.contentType ||
    attachment?.mime_type ||
    attachment?.mimeType ||
    ''
  ).toString();
  const byType =
    attachment?.extension ||
    (type.includes('/') ? type.split('/')[1] : type.includes('.') ? type.split('.').pop() : '');

  const byName =
    attachment?.file_name ||
    attachment?.filename ||
    attachment?.name ||
    attachment?.title ||
    '';

  if (byType) return byType.toLowerCase();
  if (byName && byName.includes('.')) {
    const parts = byName.split('.');
    return parts.pop().toLowerCase();
  }

  const url = getAttachmentUrl(attachment);
  if (!url) return '';
  const cleanUrl = url.split('?')[0];
  const segments = cleanUrl.split('.');
  return segments.length > 1 ? segments.pop().toLowerCase() : '';
};

const getNormalizedType = attachment => {
  const rawType = (
    attachment?.file_type ||
    attachment?.fileType ||
    attachment?.content_type ||
    attachment?.contentType ||
    attachment?.mime_type ||
    attachment?.mimeType ||
    ''
  )
    .toString()
    .toLowerCase();
  const ext = getExtension(attachment);
  const url = getAttachmentUrl(attachment);

  if (rawType.includes('audio')) return 'audio';
  if (rawType.includes('video') || rawType.includes('ig_reel')) return 'video';
  if (rawType.includes('image')) return 'image';

  if (url.startsWith('data:')) {
    if (url.includes('audio')) return 'audio';
    if (url.includes('video')) return 'video';
    if (url.includes('image')) return 'image';
  }

  const audioExts = ['mp3', 'm4a', 'aac', 'wav', 'ogg', 'oga', 'flac', 'opus', 'amr'];
  const videoExts = ['mp4', 'mov', 'mkv', 'webm', 'avi', 'm4v'];
  const imageExts = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'heic', 'bmp', 'tiff', 'svg'];

  if (audioExts.includes(ext)) return 'audio';
  if (videoExts.includes(ext)) return 'video';
  if (imageExts.includes(ext)) return 'image';

  return 'unknown';
};

const isImage = attachment => getNormalizedType(attachment) === 'image';
const isVideo = attachment => getNormalizedType(attachment) === 'video';
const isAudio = attachment => getNormalizedType(attachment) === 'audio';
const isMediaFile = attachment => ['image', 'video', 'audio'].includes(getNormalizedType(attachment));

const getDisplayName = attachment => {
  const name =
    attachment?.file_name ||
    attachment?.filename ||
    attachment?.name ||
    attachment?.title ||
    '';
  if (name) return name;
  const url = getAttachmentUrl(attachment);
  if (!url) return attachment?.id || '';
  const last = url.split('/').pop();
  return last ? decodeURIComponent(last.split('?')[0]) : attachment?.id || '';
};

const getLinkPreview = url => {
  try {
    const parsed = new URL(url);
    return `${parsed.origin}/favicon.ico`;
  } catch (error) {
    return '';
  }
};

const onPreviewError = event => {
  if (event?.target) {
    event.target.style.display = 'none';
  }
};

const downloadAttachment = async attachment => {
  const url = getAttachmentUrl(attachment);
  if (!url) {
    useAlert(t('GALLERY_VIEW.ERROR_DOWNLOADING'));
    return;
  }
  const type = attachment?.file_type || attachment?.fileType;
  const extension = getExtension(attachment);
  const fileName = getDisplayName(attachment) || `attachment${extension ? `.${extension}` : ''}`;
  try {
    await downloadFile({ url, type, extension, fileName });
  } catch (error) {
    useAlert(t('GALLERY_VIEW.ERROR_DOWNLOADING'));
  }
};

const openDocument = (attachment, event) => {
  const url = getAttachmentUrl(attachment);
  event?.preventDefault?.();
  event?.stopPropagation?.();

  if (!url) {
    useAlert(t('GALLERY_VIEW.ERROR_DOWNLOADING'));
    return;
  }

  const opened = window.open(url, '_blank', 'noopener');
  if (!opened) {
    useAlert(t('GALLERY_VIEW.ERROR_DOWNLOADING'));
  }
};

watch(
  () => props.show,
  value => {
    if (value) {
      dialogRef.value?.open();
    } else {
      dialogRef.value?.close();
      showGallery.value = false;
      previewAttachment.value = null;
      activeTab.value = 'media';
      mediaFilter.value = 'all';
      isDeleteSelectionActive.value = false;
      showDeleteConfirm.value = false;
      showDeleteInfo.value = false;
      deleteTarget.value = 'selected';
      deleteInfoCount.value = 0;
      isDeleting.value = false;
    }
  },
  { flush: 'post', immediate: true }
);

watch(
  showGallery,
  value => {
    if (!value && props.show) {
      nextTick(() => dialogRef.value?.open());
    }
  },
  { flush: 'post' }
);

watch(
  showDeleteConfirm,
  value => {
    if (value) {
      nextTick(() => deleteConfirmRef.value?.open());
    } else {
      deleteConfirmRef.value?.close();
    }
  },
  { flush: 'post' }
);

watch(
  showDeleteInfo,
  value => {
    if (value) {
      nextTick(() => deleteInfoRef.value?.open());
    } else {
      deleteInfoRef.value?.close();
    }
  },
  { flush: 'post' }
);

const close = () => emit('close');

const handleDialogClose = () => {
  if (showDeleteConfirm.value || showDeleteInfo.value) {
    nextTick(() => dialogRef.value?.open());
    return;
  }
  close();
};

const toDate = value => {
  const parsed = Number(value);
  if (!Number.isNaN(parsed)) {
    return parsed > 1000000000000 ? new Date(parsed) : new Date(parsed * 1000);
  }
  const asDate = new Date(value);
  return Number.isNaN(asDate.getTime()) ? new Date() : asDate;
};

const monthKey = date => `${date.getFullYear()}-${date.getMonth() + 1}`;

const monthLabel = date => {
  const now = new Date();
  if (
    date.getFullYear() === now.getFullYear() &&
    date.getMonth() === now.getMonth()
  ) {
    return t('CONVERSATION.MEDIA_LIBRARY.THIS_MONTH');
  }
  return new Intl.DateTimeFormat('pt-BR', {
    month: 'long',
    year: 'numeric',
  }).format(date);
};

const groupByMonth = items => {
  return items.reduce((acc, item) => {
    const date = toDate(item.created_at || item.timestamp || Date.now());
    const key = monthKey(date);
    const label = monthLabel(date);
    if (!acc[key]) {
      acc[key] = { label, items: [] };
    }
    acc[key].items.push({ ...item, createdAtDate: date });
    return acc;
  }, {});
};

const attachmentList = computed(() => props.attachments || []);
const messagesMapById = computed(() => {
  const map = new Map();
  (props.messages || []).forEach(message => {
    map.set(message.id, message);
  });
  return map;
});

const mediaAttachments = computed(() =>
  attachmentList.value
    .filter(attachment => isMediaFile(attachment))
    .sort(
      (a, b) =>
        toDate(b.created_at || b.timestamp).getTime() -
        toDate(a.created_at || a.timestamp).getTime()
    )
);

const filteredMediaAttachments = computed(() => {
  if (mediaFilter.value === 'all') return mediaAttachments.value;
  return mediaAttachments.value.filter(
    attachment => getNormalizedType(attachment) === mediaFilter.value
  );
});

const documents = computed(() =>
  attachmentList.value
    .filter(attachment => !isMediaFile(attachment))
    .sort(
      (a, b) =>
        toDate(b.created_at || b.timestamp).getTime() -
        toDate(a.created_at || a.timestamp).getTime()
    )
);

const urlRegex = /https?:\/\/[^\s<>"']+/gi;

const links = computed(() => {
  return (props.messages || []).flatMap(message => {
    const rawContent = message.content || '';
    const matches = rawContent.match(urlRegex) || [];
    return matches.map(url => ({
      url,
      sender: message.sender,
      created_at: message.created_at,
      message_id: message.id,
    }));
  });
});

const groupedDocs = computed(() => groupByMonth(documents.value));
const groupedLinks = computed(() => groupByMonth(links.value));

const mediaSummary = computed(() => {
  const photos = mediaAttachments.value.filter(item => isImage(item)).length;
  const videos = mediaAttachments.value.filter(item => isVideo(item)).length;
  const audios = mediaAttachments.value.filter(item => isAudio(item)).length;
  const total = photos + videos + audios;

  return {
    photos,
    videos,
    audios,
    total,
  };
});

const totalCountFromMeta = computed(
  () => props.attachmentsMeta?.totalCount || 0
);

const totalAttachmentCount = computed(() => {
  if (totalCountFromMeta.value) return totalCountFromMeta.value;
  return attachmentList.value.length || 0;
});

const selectedAttachments = computed(() =>
  attachmentList.value.filter(attachment => {
    const keys = getAttachmentSelectionKeys(attachment);
    return keys.some(key => selectedAttachmentIds.value.includes(key));
  })
);

const isAttachmentSelected = attachment => {
  const keys = getAttachmentSelectionKeys(attachment);
  return keys.some(key => selectedAttachmentIds.value.includes(key));
};

const selectedDeleteIds = computed(() =>
  selectedAttachments.value
    .map(attachment => attachment?.id || attachment?.attachment_id || attachment?.attachmentId)
    .filter(Boolean)
);

const selectedDeleteCount = computed(() => selectedAttachments.value.length);

const deleteConfirmationCount = computed(() =>
  deleteTarget.value === 'all'
    ? totalAttachmentCount.value
    : selectedDeleteCount.value
);

const hasMoreAttachments = computed(() => {
  const loaded = attachmentList.value.length || 0;
  if (!totalCountFromMeta.value) return false;
  return loaded < totalCountFromMeta.value;
});

const getMessageIdFromAttachment = attachment =>
  attachment?.message_id ||
  attachment?.messageId ||
  attachment?.message?.id ||
  null;

const selectedMessages = computed(() => {
  const ids = new Set();
  const selectedAttachmentByMessage = new Map();
  const allAttachmentsByMessage = new Map();

  // Build a lookup of all attachments per message for fallback
  attachmentList.value.forEach(att => {
    const mId = getMessageIdFromAttachment(att);
    if (!mId) return;
    const numericId = Number(mId);
    const existing = allAttachmentsByMessage.get(numericId) || [];
    existing.push(att);
    allAttachmentsByMessage.set(numericId, existing);
  });

  attachmentList.value.forEach(att => {
    if (selectedAttachmentIds.value.includes(getAttachmentSelectionKey(att))) {
      const mId = getMessageIdFromAttachment(att);
      if (mId) {
        const numericId = Number(mId);
        ids.add(numericId);
        const current = selectedAttachmentByMessage.get(numericId) || [];
        current.push(att);
        selectedAttachmentByMessage.set(numericId, current);
      }
    }
  });

  (selectedLinkMessageIds.value || []).forEach(id => ids.add(Number(id)));

  return Array.from(ids)
    .map(id => {
      const message =
        messagesMapById.value.get(id) || messagesMapById.value.get(Number(id));
      const selectedAttachments = selectedAttachmentByMessage.get(id) || [];
      const attachments =
        selectedAttachments.length > 0
          ? selectedAttachments
          : allAttachmentsByMessage.get(id) || message?.attachments || [];

      if (message) {
        return { ...message, attachments };
      }

      // Fallback stub when message details are not loaded
      return {
        id,
        content: '',
        attachments,
      };
    })
    .filter(message => message && Array.isArray(message.attachments));
});

const formatSize = bytes => {
  if (!bytes) return '';
  if (bytes < 1024) return `${bytes} B`;
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
  if (bytes < 1024 * 1024 * 1024)
    return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
  return `${(bytes / (1024 * 1024 * 1024)).toFixed(1)} GB`;
};

const formatDateTime = value =>
  new Intl.DateTimeFormat('pt-BR', {
    dateStyle: 'medium',
    timeStyle: 'short',
  }).format(toDate(value));

const openPreview = attachment => {
  previewAttachment.value = attachment;
  showGallery.value = true;
};

const toggleAttachmentSelection = attachment => {
  const keys = getAttachmentSelectionKeys(attachment);
  if (!keys.length) return;
  const hasSelection = keys.some(key =>
    selectedAttachmentIds.value.includes(key)
  );
  if (hasSelection) {
    selectedAttachmentIds.value = selectedAttachmentIds.value.filter(
      id => !keys.includes(id)
    );
    return;
  }

  const primaryKey = getAttachmentSelectionKey(attachment);
  if (primaryKey) {
    selectedAttachmentIds.value.push(primaryKey);
  }
};

const toggleLinkSelection = link => {
  const id = link?.message_id || link?.messageId;
  if (!id) return;
  const numericId = Number(id);
  const index = selectedLinkMessageIds.value.indexOf(numericId);
  if (index === -1) {
    selectedLinkMessageIds.value.push(numericId);
  } else {
    selectedLinkMessageIds.value.splice(index, 1);
  }
};

const handleMediaClick = attachment => {
  if (isSelectionActive.value) {
    toggleAttachmentSelection(attachment);
    return;
  }
  openPreview(attachment);
};

const handleLinkClick = (link, event) => {
  if (isForwardSelectionActive.value) {
    event?.preventDefault?.();
    event?.stopPropagation?.();
    toggleLinkSelection(link);
  }
};

const resetSelections = () => {
  selectedAttachmentIds.value = [];
  selectedLinkMessageIds.value = [];
};

const startForwardSelection = () => {
  isDeleteSelectionActive.value = false;
  resetSelections();
  isForwardSelectionActive.value = true;
};

const cancelForwardSelection = () => {
  isForwardSelectionActive.value = false;
  resetSelections();
  showForwardModal.value = false;
};

const startDeleteSelection = () => {
  isForwardSelectionActive.value = false;
  showForwardModal.value = false;
  resetSelections();
  isDeleteSelectionActive.value = true;
};

const cancelDeleteSelection = () => {
  isDeleteSelectionActive.value = false;
  resetSelections();
};

const openForwardModal = () => {
  if (!props.conversationId) {
    useAlert(t('CONVERSATION.FORWARD_MESSAGES.ERROR_API'));
    return;
  }
  if (!selectedMessages.value.length) {
    useAlert(t('CONVERSATION.FORWARD_MESSAGES.ERROR_NO_CONTENT'));
    return;
  }
  showForwardModal.value = true;
};

const openDeleteConfirm = target => {
  deleteTarget.value = target;
  showDeleteConfirm.value = true;
};

const closeDeleteConfirm = () => {
  showDeleteConfirm.value = false;
};

const closeDeleteInfo = () => {
  showDeleteInfo.value = false;
};

const requestDeleteSelected = () => {
  if (!selectedDeleteCount.value) return;
  openDeleteConfirm('selected');
};

const requestDeleteAll = () => {
  if (!totalAttachmentCount.value) return;
  openDeleteConfirm('all');
};

const confirmDelete = async () => {
  if (!props.conversationId || deleteConfirmationCount.value <= 0) {
    useAlert(t('CONVERSATION.MEDIA_LIBRARY.DELETE_ERROR'));
    return;
  }

  const deleteAll = deleteTarget.value === 'all';
  const attachmentIds = deleteAll ? [] : selectedDeleteIds.value;

  if (!deleteAll && !attachmentIds.length) {
    useAlert(t('CONVERSATION.MEDIA_LIBRARY.DELETE_ERROR'));
    return;
  }

  isDeleting.value = true;
  try {
    const { count } = await store.dispatch('deleteConversationAttachments', {
      conversationId: props.conversationId,
      attachmentIds,
      deleteAll,
    });
    deleteInfoCount.value = count || deleteConfirmationCount.value;
    showDeleteConfirm.value = false;
    showDeleteInfo.value = true;
    cancelDeleteSelection();
  } catch (error) {
    useAlert(t('CONVERSATION.MEDIA_LIBRARY.DELETE_ERROR'));
  } finally {
    isDeleting.value = false;
  }
};

const handleForwarded = conversation => {
  cancelForwardSelection();
  emit('close', conversation);
  if (conversation && conversation.id) {
    router.push({
      name: 'inbox_conversation',
      params: {
        accountId: conversation.account_id || conversation.accountId,
        conversation_id: conversation.id,
      },
    });
  }
};

const selectedItemsCount = computed(
  () => selectedAttachmentIds.value.length + selectedLinkMessageIds.value.length
);

const requestLoadMore = () => {
  if (!hasMoreAttachments.value || props.isLoadingMore) return;
  emit('load-more');
};

const setMediaFilter = type => {
  activeTab.value = 'media';
  mediaFilter.value = mediaFilter.value === type ? 'all' : type;
};

watch(
  () => props.show,
  value => {
    if (!value) {
      cancelForwardSelection();
      cancelDeleteSelection();
      showDeleteConfirm.value = false;
      showDeleteInfo.value = false;
    }
  }
);

watch(
  showForwardModal,
  value => {
    if (!value && props.show && !showGallery.value) {
      nextTick(() => dialogRef.value?.open());
    }
  },
  { flush: 'post' }
);
</script>

<template>
  <Dialog
    v-if="showDialog"
    ref="dialogRef"
    width="3xl"
    dialog-class="z-30"
    :overflow-y-auto="true"
    :show-cancel-button="false"
    :show-confirm-button="false"
    @close="handleDialogClose"
  >
    <template #default>
      <div class="flex flex-col gap-4">
        <div
          class="sticky top-0 z-10 flex items-center justify-between gap-3 px-1 py-2 bg-n-alpha-3 backdrop-blur-sm"
        >
          <div class="text-sm font-medium text-n-slate-12">
            {{ $t('CONVERSATION.MEDIA_LIBRARY.TITLE') }}
          </div>
          <button
            type="button"
            class="p-1 rounded-md text-n-slate-11 hover:text-n-slate-12 hover:bg-n-alpha-3"
            @click="close"
          >
            <span class="i-lucide-x w-5 h-5" />
          </button>
        </div>
        <div class="flex items-center gap-2">
          <Button
            size="sm"
            variant="faded"
            :color="activeTab === 'media' ? 'blue' : 'slate'"
            class="min-w-[6rem]"
            type="button"
            @click="activeTab = 'media'"
          >
            <span class="flex items-center gap-2">
              <span>{{ $t('CONVERSATION.MEDIA_LIBRARY.TAB_MEDIA') }}</span>
              <span
                class="min-w-[1.75rem] px-2 rounded-md text-xs leading-5 font-medium text-center text-n-slate-11 outline outline-1 outline-n-strong"
              >
                {{ mediaSummary.total }}
              </span>
            </span>
          </Button>
          <Button
            size="sm"
            variant="faded"
            :color="activeTab === 'docs' ? 'blue' : 'slate'"
            class="min-w-[6rem]"
            type="button"
            @click="activeTab = 'docs'"
          >
            <span class="flex items-center gap-2">
              <span>{{ $t('CONVERSATION.MEDIA_LIBRARY.TAB_DOCS') }}</span>
              <span
                class="min-w-[1.75rem] px-2 rounded-md text-xs leading-5 font-medium text-center text-n-slate-11 outline outline-1 outline-n-strong"
              >
                {{ documents.length }}
              </span>
            </span>
          </Button>
          <Button
            size="sm"
            variant="faded"
            :color="activeTab === 'links' ? 'blue' : 'slate'"
            class="min-w-[6rem]"
            type="button"
            @click="activeTab = 'links'"
          >
            <span class="flex items-center gap-2">
              <span>{{ $t('CONVERSATION.MEDIA_LIBRARY.TAB_LINKS') }}</span>
              <span
                class="min-w-[1.75rem] px-2 rounded-md text-xs leading-5 font-medium text-center text-n-slate-11 outline outline-1 outline-n-strong"
              >
                {{ links.length }}
              </span>
            </span>
          </Button>
        </div>

        <div v-if="isLoading" class="flex justify-center py-12">
          <div class="flex items-center gap-2 text-sm text-n-slate-11">
            <span class="i-lucide-loader-2 animate-spin" />
            <span>{{ $t('CONVERSATION.MEDIA_LIBRARY.LOADING') }}</span>
          </div>
        </div>

        <div v-else class="flex flex-col gap-6">
          <div class="flex flex-wrap items-center gap-4 text-sm text-n-slate-11">
            <button
              type="button"
              class="inline-flex items-center gap-1 rounded-md px-2 py-1 transition cursor-pointer"
              :class="[
                mediaFilter === 'all'
                  ? 'bg-n-alpha-3 text-n-slate-12'
                  : 'hover:bg-n-alpha-2'
              ]"
              @click="setMediaFilter('all')"
            >
              <span class="i-lucide-layers w-4 h-4" />
              <span>
                {{ mediaSummary.total }}
                {{ $t('CONVERSATION.MEDIA_LIBRARY.ALL_LABEL') }}
              </span>
            </button>
            <button
              type="button"
              class="inline-flex items-center gap-1 rounded-md px-2 py-1 transition cursor-pointer"
              :class="[
                mediaFilter === 'image'
                  ? 'bg-n-alpha-3 text-n-slate-12'
                  : 'hover:bg-n-alpha-2'
              ]"
              @click="setMediaFilter('image')"
            >
              <span class="i-lucide-image w-4 h-4" />
              <span>
                {{ mediaSummary.photos }}
                {{ $t('CONVERSATION.MEDIA_LIBRARY.PHOTOS_LABEL') }}
              </span>
            </button>
            <button
              type="button"
              class="inline-flex items-center gap-1 rounded-md px-2 py-1 transition cursor-pointer"
              :class="[
                mediaFilter === 'video'
                  ? 'bg-n-alpha-3 text-n-slate-12'
                  : 'hover:bg-n-alpha-2'
              ]"
              @click="setMediaFilter('video')"
            >
              <span class="i-lucide-clapperboard w-4 h-4" />
              <span>
                {{ mediaSummary.videos }}
                {{ $t('CONVERSATION.MEDIA_LIBRARY.VIDEOS_LABEL') }}
              </span>
            </button>
            <button
              type="button"
              class="inline-flex items-center gap-1 rounded-md px-2 py-1 transition cursor-pointer"
              :class="[
                mediaFilter === 'audio'
                  ? 'bg-n-alpha-3 text-n-slate-12'
                  : 'hover:bg-n-alpha-2'
              ]"
              @click="setMediaFilter('audio')"
            >
              <span class="i-lucide-waveform w-4 h-4" />
              <span>
                {{ mediaSummary.audios }}
                {{ $t('CONVERSATION.MEDIA_LIBRARY.AUDIOS_LABEL') }}
              </span>
            </button>
            <div class="ml-auto flex items-center gap-2">
              <Button
                v-if="!isDeleteSelectionActive"
                size="xs"
                variant="ghost"
                color="ruby"
                :disabled="isForwardSelectionActive"
                type="button"
                @click="startDeleteSelection"
              >
                {{ $t('CONVERSATION.MEDIA_LIBRARY.DELETE_ACTION') }}
              </Button>
              <Button
                v-if="isDeleteSelectionActive"
                size="xs"
                color="ruby"
                :disabled="!selectedDeleteCount"
                type="button"
                @click="requestDeleteSelected"
              >
                {{ $t('CONVERSATION.MEDIA_LIBRARY.DELETE_SELECTED_ACTION') }}
              </Button>
              <Button
                v-if="isDeleteSelectionActive"
                size="xs"
                variant="ghost"
                color="ruby"
                type="button"
                @click="requestDeleteAll"
              >
                {{ $t('CONVERSATION.MEDIA_LIBRARY.DELETE_ALL_ACTION') }}
              </Button>
              <Button
                v-if="isDeleteSelectionActive"
                size="xs"
                variant="ghost"
                color="slate"
                type="button"
                @click="cancelDeleteSelection"
              >
                {{ $t('CONVERSATION.FORWARD_MESSAGES.CANCEL') }}
              </Button>
              <Button
                v-if="!isForwardSelectionActive"
                size="xs"
                variant="ghost"
                color="slate"
                :disabled="isDeleteSelectionActive"
                type="button"
                @click="startForwardSelection"
              >
                {{ $t('CONVERSATION.FORWARD_MESSAGES.TITLE') }}
              </Button>
              <Button
                v-if="isForwardSelectionActive"
                size="xs"
                color="blue"
                :disabled="!selectedItemsCount"
                type="button"
                @click="openForwardModal"
              >
                {{
                  $t('CONVERSATION.FORWARD_MESSAGES.SELECTED_COUNT', {
                    count: selectedItemsCount,
                  })
                }}
              </Button>
              <Button
                v-if="isForwardSelectionActive"
                size="xs"
                variant="ghost"
                color="slate"
                type="button"
                @click="cancelForwardSelection"
              >
                {{ $t('CONVERSATION.FORWARD_MESSAGES.CANCEL') }}
              </Button>
            </div>
          </div>

          <div v-if="activeTab === 'media'" class="flex flex-col gap-4">
            <div
              v-if="filteredMediaAttachments.length"
              class="grid grid-cols-2 md:grid-cols-3 gap-3"
            >
              <button
                v-for="attachment in filteredMediaAttachments"
                :key="attachment.id"
                type="button"
                class="relative flex flex-col gap-2 p-2 rounded-lg bg-n-alpha-2 hover:bg-n-alpha-3 text-left"
                @click="handleMediaClick(attachment)"
              >
                <div
                  v-if="isSelectionActive"
                  class="absolute top-2 right-2 z-10 w-5 h-5 rounded-full border border-blue-500 bg-blue-500 text-white shadow-md ring-1 ring-blue-400/70 flex items-center justify-center text-xs"
                  :class="{
                    'opacity-40': !isAttachmentSelected(attachment),
                    'ring-2 ring-white/70 shadow-lg opacity-100':
                      isAttachmentSelected(attachment),
                  }"
                  >
                    <span
                    class="i-lucide-check w-3 h-3 text-n-brand"
                    v-if="isAttachmentSelected(attachment)"
                  />
                </div>
                <div
                  class="w-full aspect-video overflow-hidden rounded-md bg-n-alpha-3 flex items-center justify-center"
                >
                  <img
                    v-if="isImage(attachment)"
                    class="object-cover w-full h-full"
                    :src="attachment.thumb_url || attachment.data_url"
                    :alt="attachment.file_name || 'image'"
                  />
                  <video
                    v-else-if="isVideo(attachment)"
                    class="object-cover w-full h-full"
                    :src="attachment.thumb_url || attachment.data_url"
                    muted
                  />
                  <div
                    v-else
                    class="flex flex-col items-center justify-center w-full h-full gap-2 text-n-slate-11"
                  >
                    <span class="i-lucide-waveform w-6 h-6" />
                    <span class="text-xs truncate px-2 text-center">
                      {{ getDisplayName(attachment) }}
                    </span>
                  </div>
                </div>
                <div class="flex items-center justify-between text-xs text-n-slate-11">
                  <span class="truncate">
                    {{ attachment.file_name || attachment.filename || attachment.id }}
                  </span>
                  <span class="flex items-center gap-1">
                    <i class="i-lucide-clock-3 w-3.5 h-3.5" />
                    {{ formatDateTime(attachment.created_at || attachment.timestamp) }}
                  </span>
                </div>
              </button>
            </div>
            <div
              v-else
              class="flex items-center justify-center py-12 text-sm text-n-slate-11"
            >
              {{ $t('CONVERSATION.MEDIA_LIBRARY.EMPTY') }}
            </div>
          </div>

          <div v-if="activeTab === 'docs'" class="flex flex-col gap-3">
            <div
              v-if="documents.length"
              class="flex flex-col gap-4"
            >
              <div
                v-for="group in Object.values(groupedDocs)"
                :key="group.label"
                class="flex flex-col gap-2"
              >
                <div class="text-xs font-medium text-n-slate-12 uppercase">
                  {{ group.label }}
                </div>
                <div class="flex flex-col gap-2">
                  <a
                    v-for="doc in group.items"
                    :key="doc.id"
                    class="relative flex items-center gap-3 p-3 rounded-lg bg-n-alpha-2 hover:bg-n-alpha-3 text-left no-underline"
                    :class="{
                      'ring-1 ring-blue-500':
                        isSelectionActive && isAttachmentSelected(doc),
                    }"
                    :href="getAttachmentUrl(doc) || undefined"
                    :download="getDisplayName(doc) || undefined"
                    target="_blank"
                    rel="noopener noreferrer"
                    @click.prevent.stop="
                      isSelectionActive
                        ? toggleAttachmentSelection(doc)
                        : openDocument(doc, $event)
                    "
                  >
                    <span class="i-lucide-file-text w-5 h-5 text-n-slate-11 flex-shrink-0" />
                    <div class="flex flex-col min-w-0 gap-0.5">
                      <span class="text-sm text-n-slate-12 truncate">
                        {{ getDisplayName(doc) }}
                      </span>
                      <span class="text-xs text-n-slate-11 flex items-center gap-2">
                        <span class="flex items-center gap-1">
                          <i class="i-lucide-clock-3 w-3.5 h-3.5" />
                          {{ formatDateTime(doc.created_at || doc.timestamp) }}
                        </span>
                        <span v-if="doc.file_size" class="flex items-center gap-1">
                          <span class="i-lucide-database w-3.5 h-3.5" />
                          {{ formatSize(doc.file_size) }}
                        </span>
                      </span>
                    </div>
                    <span class="i-lucide-download w-4 h-4 text-n-slate-11 flex-shrink-0" />
                    <span
                      v-if="isSelectionActive"
                      class="absolute top-2 right-2 w-4 h-4 rounded-full border border-blue-500 bg-blue-500 text-white shadow-md ring-1 ring-blue-400/70 flex items-center justify-center text-[10px]"
                      :class="{
                        'opacity-40': !isAttachmentSelected(doc),
                        'ring-2 ring-white/70 shadow-lg opacity-100':
                          isAttachmentSelected(doc),
                      }"
                      >
                        <span
                        class="i-lucide-check w-3 h-3 text-n-brand"
                        v-if="isAttachmentSelected(doc)"
                      />
                    </span>
                  </a>
                </div>
              </div>
              <div class="text-right text-xs text-n-slate-11">
                {{
                  $t('CONVERSATION.MEDIA_LIBRARY.DOC_COUNT', {
                    count: documents.length,
                  })
                }}
              </div>
            </div>
            <div
              v-else
              class="flex items-center justify-center py-12 text-sm text-n-slate-11"
            >
              {{ $t('CONVERSATION.MEDIA_LIBRARY.EMPTY') }}
            </div>
          </div>

          <div v-if="activeTab === 'links'" class="flex flex-col gap-3">
            <div v-if="links.length" class="flex flex-col gap-4">
              <div
                v-for="group in Object.values(groupedLinks)"
                :key="group.label"
                class="flex flex-col gap-2"
              >
                <div class="text-xs font-medium text-n-slate-12 uppercase">
                  {{ group.label }}
                </div>
                <div class="flex flex-col gap-2">
                  <a
                    v-for="link in group.items"
                    :key="`${link.url}-${link.created_at}`"
                    class="relative flex items-center justify-between gap-3 p-3 rounded-lg bg-n-alpha-2 hover:bg-n-alpha-3 text-n-slate-12"
                    :class="{
                      'ring-1 ring-blue-500':
                        isForwardSelectionActive &&
                        selectedLinkMessageIds.includes(Number(link.message_id)),
                    }"
                    :href="link.url"
                    target="_blank"
                    rel="noopener noreferrer"
                    @click="handleLinkClick(link, $event)"
                  >
                    <span class="flex items-center gap-3 truncate">
                      <span
                        class="w-8 h-8 rounded-md bg-n-alpha-3 flex items-center justify-center overflow-hidden flex-shrink-0"
                      >
                        <img
                          v-if="getLinkPreview(link.url)"
                          :src="getLinkPreview(link.url)"
                          class="w-full h-full object-contain"
                          :alt="link.url"
                          @error="onPreviewError"
                        />
                        <span v-else class="i-lucide-link-2 w-4 h-4 text-n-slate-11" />
                      </span>
                      <span class="flex items-center gap-2 truncate">
                        <span class="i-lucide-link-2 w-4 h-4 text-n-slate-11" />
                        <span class="truncate">{{ link.url }}</span>
                      </span>
                    </span>
                    <span class="text-xs text-n-slate-11">
                      {{ formatDateTime(link.created_at) }}
                    </span>
                    <span
                      v-if="isForwardSelectionActive"
                      class="absolute top-2 right-2 w-4 h-4 rounded-full border border-blue-500 bg-blue-500 text-white shadow-md ring-1 ring-blue-400/70 flex items-center justify-center text-[10px]"
                      :class="{
                        'opacity-40': !selectedLinkMessageIds.includes(Number(link.message_id)),
                        'ring-2 ring-white/70 shadow-lg opacity-100':
                          selectedLinkMessageIds.includes(Number(link.message_id)),
                      }"
                      >
                        <span
                        class="i-lucide-check w-3 h-3 text-n-brand"
                        v-if="selectedLinkMessageIds.includes(Number(link.message_id))"
                      />
                    </span>
                  </a>
                </div>
              </div>
              <div class="text-right text-xs text-n-slate-11">
                {{
                  $t('CONVERSATION.MEDIA_LIBRARY.LINK_COUNT', {
                    count: links.length,
                  })
                }}
              </div>
            </div>
            <div
              v-else
              class="flex items-center justify-center py-12 text-sm text-n-slate-11"
            >
              {{ $t('CONVERSATION.MEDIA_LIBRARY.EMPTY') }}
            </div>
          </div>

          <div
            v-if="hasMoreAttachments"
            class="flex justify-center pt-2"
          >
            <Button
              size="sm"
              variant="ghost"
              color="blue"
              type="button"
              :disabled="isLoadingMore"
              @click="requestLoadMore"
            >
              <span class="flex items-center gap-2">
                <span
                  v-if="isLoadingMore"
                  class="i-lucide-loader-2 animate-spin"
                />
                <span>{{ $t('CONVERSATION.MEDIA_LIBRARY.LOAD_MORE') }}</span>
                <span
                  v-if="totalCountFromMeta"
                  class="text-xs text-n-slate-11"
                >
                  {{ attachmentList.length }} / {{ totalCountFromMeta }}
                </span>
              </span>
            </Button>
          </div>
        </div>
      </div>
    </template>
  </Dialog>
  <GalleryView
    v-if="previewAttachment && showGallery"
    v-model:show="showGallery"
    :attachment="previewAttachment"
    :all-attachments="filteredMediaAttachments"
    @close="showGallery = false"
  />
  <ForwardMessagesModal
    v-model:show="showForwardModal"
    :selected-messages="selectedMessages"
    :conversation-id="conversationId"
    @forwarded="handleForwarded"
    @close="cancelForwardSelection"
  />
  <Dialog
    ref="deleteConfirmRef"
    width="sm"
    :show-cancel-button="false"
    :show-confirm-button="false"
    dialog-class="z-40"
    @close="closeDeleteConfirm"
  >
    <div class="flex flex-col gap-4 p-6">
      <div class="text-base font-medium text-n-slate-12">
        {{ $t('CONVERSATION.MEDIA_LIBRARY.DELETE_CONFIRM_TITLE') }}
      </div>
      <p class="text-sm text-n-slate-11">
        {{
          $t('CONVERSATION.MEDIA_LIBRARY.DELETE_CONFIRM_MESSAGE', {
            count: deleteConfirmationCount,
          })
        }}
      </p>
      <div class="flex items-center justify-end gap-2">
        <Button
          size="sm"
          variant="faded"
          color="slate"
          type="button"
          @click="closeDeleteConfirm"
        >
          {{ $t('DIALOG.BUTTONS.CANCEL') }}
        </Button>
        <Button
          size="sm"
          color="ruby"
          :is-loading="isDeleting"
          :disabled="isDeleting"
          type="button"
          @click="confirmDelete"
        >
          {{ $t('DIALOG.BUTTONS.CONFIRM') }}
        </Button>
      </div>
    </div>
  </Dialog>
  <Dialog
    ref="deleteInfoRef"
    width="sm"
    :show-cancel-button="false"
    :show-confirm-button="false"
    dialog-class="z-40"
    @close="closeDeleteInfo"
  >
    <div class="flex flex-col gap-3 p-6">
      <div class="text-base font-medium text-n-slate-12">
        {{ $t('CONVERSATION.MEDIA_LIBRARY.DELETE_BACKGROUND_TITLE') }}
      </div>
      <p class="text-sm text-n-slate-11">
        {{
          $t('CONVERSATION.MEDIA_LIBRARY.DELETE_BACKGROUND_MESSAGE', {
            count: deleteInfoCount,
          })
        }}
      </p>
      <p class="text-xs text-n-slate-11">
        {{ $t('CONVERSATION.MEDIA_LIBRARY.DELETE_BACKGROUND_HINT') }}
      </p>
      <div class="flex justify-end">
        <Button size="sm" color="blue" type="button" @click="closeDeleteInfo">
          {{ $t('DIALOG.BUTTONS.CONFIRM') }}
        </Button>
      </div>
    </div>
  </Dialog>
</template>
