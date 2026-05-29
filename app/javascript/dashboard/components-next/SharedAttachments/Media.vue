<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import {
  dynamicTime,
  formatDuration,
  shortTimestamp,
} from 'shared/helpers/timeHelper';
import { downloadFile } from '@chatwoot/utils';
import {
  ATTACHMENT_TYPES,
  MEDIA_TYPES,
} from 'dashboard/components-next/message/constants';

import Icon from 'next/icon/Icon.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  attachments: { type: Array, default: () => [] },
  peekLimit: { type: Number, default: 0 },
  showJumpToMessage: { type: Boolean, default: false },
});

const emit = defineEmits(['select', 'jumpToMessage']);

const { t } = useI18n();

const mediaAttachments = computed(() =>
  [...props.attachments]
    .filter(a => a.data_url && MEDIA_TYPES.includes(a.file_type))
    .sort((a, b) => (b.created_at || 0) - (a.created_at || 0))
);

const showAll = ref(false);
const failedThumbs = ref(new Set());
const failedPreviews = ref(new Set());
const durations = ref({});
const downloadingId = ref(null);

const isPeekable = computed(() => props.peekLimit > 0);

const visibleMedia = computed(() => {
  if (!isPeekable.value || showAll.value) return mediaAttachments.value;
  return mediaAttachments.value.slice(0, props.peekLimit);
});

const overflow = computed(() => {
  if (!isPeekable.value) return 0;
  const total = mediaAttachments.value.length;
  return total > props.peekLimit ? total - (props.peekLimit - 1) : 0;
});

const fileNameFromUrl = url => {
  if (!url) return '';
  const name = url.split('/').pop();
  return name ? decodeURIComponent(name) : '';
};

const isVideoType = type =>
  [ATTACHMENT_TYPES.VIDEO, ATTACHMENT_TYPES.IG_REEL].includes(type);
const isAudioType = type => type === ATTACHMENT_TYPES.AUDIO;
const isPlayableType = type => isVideoType(type) || isAudioType(type);

const imagePreviewSrc = ({
  id,
  file_type: type,
  thumb_url: thumbUrl,
  data_url: dataUrl,
}) => {
  const canUseThumb = thumbUrl && !failedThumbs.value.has(id);
  if (type === ATTACHMENT_TYPES.IMAGE) return canUseThumb ? thumbUrl : dataUrl;
  if (isVideoType(type)) return canUseThumb ? thumbUrl : null;
  return null;
};

const onPreviewError = ({
  id,
  file_type: type,
  thumb_url: thumbUrl,
  data_url: dataUrl,
}) => {
  const canRetryWithFull = thumbUrl && !failedThumbs.value.has(id) && dataUrl;
  if (
    canRetryWithFull &&
    (type === ATTACHMENT_TYPES.IMAGE || isVideoType(type))
  ) {
    failedThumbs.value.add(id);
    return;
  }
  failedPreviews.value.add(id);
};

const hasPreview = attachment =>
  !!imagePreviewSrc(attachment) && !failedPreviews.value.has(attachment.id);

const hasVideoPreview = attachment =>
  isVideoType(attachment.file_type) &&
  attachment.data_url &&
  !failedPreviews.value.has(attachment.id);

const fallbackIcon = type => {
  if (isAudioType(type)) return 'i-lucide-music';
  if (isVideoType(type)) return 'i-lucide-video';
  return 'i-lucide-image';
};

const onLoadedMetadata = (attachment, event) => {
  const seconds = event.target?.duration;
  if (Number.isFinite(seconds) && seconds > 0) {
    durations.value[attachment.id] = seconds;
  }
};

const displayDuration = attachment => {
  const seconds = durations.value[attachment.id];
  return seconds ? formatDuration(Math.round(seconds)) : '';
};

const displayTime = attachment => {
  if (!attachment.created_at) return '';
  return shortTimestamp(dynamicTime(attachment.created_at), true);
};

const isOverflowTile = index =>
  isPeekable.value &&
  !showAll.value &&
  overflow.value > 0 &&
  index === props.peekLimit - 1;

const onTileActivate = (attachment, index) => {
  if (isOverflowTile(index)) {
    showAll.value = true;
    return;
  }
  emit('select', attachment);
};

const onDownloadFile = async attachment => {
  const { id, file_type: type, data_url: url, extension } = attachment;
  try {
    downloadingId.value = id;
    await downloadFile({ url, type, extension });
  } catch (error) {
    useAlert(t('CONVERSATION_SIDEBAR.SHARED_FILES.DOWNLOAD_ERROR'));
  } finally {
    downloadingId.value = null;
  }
};
</script>

<template>
  <section v-if="mediaAttachments.length" class="flex flex-col gap-2.5">
    <header class="flex items-center justify-between px-0.5">
      <h4
        class="text-xs font-semibold tracking-wider uppercase text-n-slate-11"
      >
        {{ t('CONVERSATION_SIDEBAR.SHARED_FILES.MEDIA_HEADING') }}
        <span
          class="ms-1 font-medium tracking-normal normal-case text-n-slate-10"
        >
          {{ mediaAttachments.length }}
        </span>
      </h4>
      <NextButton
        v-if="overflow > 0"
        ghost
        slate
        xs
        trailing-icon
        :icon="showAll ? 'i-lucide-chevron-up' : 'i-lucide-chevron-right'"
        :label="
          showAll
            ? t('CONVERSATION_SIDEBAR.SHARED_FILES.SHOW_LESS')
            : t('CONVERSATION_SIDEBAR.SHARED_FILES.VIEW_ALL')
        "
        @click="showAll = !showAll"
      />
    </header>
    <div class="grid grid-cols-3 gap-2">
      <div
        v-for="(attachment, index) in visibleMedia"
        :key="attachment.id"
        role="button"
        tabindex="0"
        class="relative w-full overflow-hidden transition-all duration-200 rounded-lg cursor-pointer aspect-square bg-n-slate-3 shadow-sm hover:shadow-md hover:-translate-y-px group focus:outline-none focus-visible:ring-2 focus-visible:ring-n-blue-9"
        @click="onTileActivate(attachment, index)"
        @keydown.enter="onTileActivate(attachment, index)"
        @keydown.space.prevent="onTileActivate(attachment, index)"
      >
        <template v-if="!isOverflowTile(index)">
          <img
            v-if="hasPreview(attachment)"
            :src="imagePreviewSrc(attachment)"
            class="object-cover w-full h-full transition-transform duration-300 group-hover:scale-110"
            loading="lazy"
            :alt="fileNameFromUrl(attachment.data_url)"
            @error="onPreviewError(attachment)"
          />
          <video
            v-else-if="hasVideoPreview(attachment)"
            :src="`${attachment.data_url}#t=0.1`"
            preload="metadata"
            muted
            playsinline
            class="object-cover w-full h-full transition-transform duration-300 group-hover:scale-110 pointer-events-none"
            @loadedmetadata="onLoadedMetadata(attachment, $event)"
            @error="onPreviewError(attachment)"
          />
          <div
            v-else
            class="flex items-center justify-center w-full h-full bg-gradient-to-br from-n-slate-3 to-n-slate-4"
          >
            <Icon
              :icon="fallbackIcon(attachment.file_type)"
              class="size-6 text-n-slate-11"
            />
          </div>

          <audio
            v-if="isAudioType(attachment.file_type) && attachment.data_url"
            :src="attachment.data_url"
            preload="metadata"
            class="hidden"
            @loadedmetadata="onLoadedMetadata(attachment, $event)"
          />

          <div
            class="absolute inset-0 transition-opacity duration-200 opacity-0 pointer-events-none group-hover:opacity-100 bg-gradient-to-t from-black/40 via-transparent to-transparent"
          />

          <div
            v-if="hasVideoPreview(attachment)"
            class="absolute inset-0 flex items-center justify-center pointer-events-none bg-gradient-to-t from-black/30 via-transparent to-transparent"
          >
            <div
              class="flex items-center justify-center rounded-full size-7 bg-white/95 shadow-md"
            >
              <Icon icon="i-lucide-play" class="ms-0.5 size-3.5 text-n-black" />
            </div>
          </div>

          <span
            v-if="
              isPlayableType(attachment.file_type) &&
              displayDuration(attachment)
            "
            class="absolute text-xxs font-medium tabular-nums transition-opacity bottom-1.5 ltr:right-1.5 rtl:left-1.5 text-white [text-shadow:_0_1px_3px_rgba(0,0,0,0.95),_0_0_10px_rgba(0,0,0,0.7)] group-hover:opacity-0"
          >
            {{ displayDuration(attachment) }}
          </span>

          <span
            v-if="displayTime(attachment)"
            class="absolute text-xxs font-medium transition-opacity opacity-0 bottom-1.5 ltr:left-1.5 rtl:right-1.5 text-white [text-shadow:_0_1px_3px_rgba(0,0,0,0.95),_0_0_10px_rgba(0,0,0,0.7)] group-hover:opacity-100"
          >
            {{ displayTime(attachment) }}
          </span>

          <button
            type="button"
            class="absolute flex items-center justify-center !p-px transition-all rounded-full opacity-0 bottom-1.5 ltr:right-1.5 rtl:left-1.5 size-6 bg-white/95 shadow-md group-hover:opacity-100 hover:bg-white disabled:opacity-50"
            :disabled="downloadingId === attachment.id"
            :aria-label="t('CONVERSATION_SIDEBAR.SHARED_FILES.DOWNLOAD')"
            @click.stop="onDownloadFile(attachment)"
            @keydown.enter.stop
            @keydown.space.stop
          >
            <Icon icon="i-lucide-download" class="size-3 text-n-black" />
          </button>

          <button
            v-if="showJumpToMessage && attachment.message_id"
            v-tooltip.top="{
              content: t('CONVERSATION_SIDEBAR.SHARED_FILES.JUMP_TO_MESSAGE'),
              delay: { show: 500, hide: 0 },
            }"
            type="button"
            class="absolute flex items-center justify-center !p-px transition-all rounded-full opacity-0 top-1.5 ltr:right-1.5 rtl:left-1.5 size-6 bg-white/95 shadow-md group-hover:opacity-100 hover:bg-white"
            :aria-label="t('CONVERSATION_SIDEBAR.SHARED_FILES.JUMP_TO_MESSAGE')"
            @click.stop="emit('jumpToMessage', attachment)"
            @keydown.enter.stop
            @keydown.space.stop
          >
            <Icon icon="i-lucide-external-link" class="size-3 text-n-black" />
          </button>
        </template>

        <div
          v-if="isOverflowTile(index)"
          class="absolute inset-0 flex items-center justify-center bg-n-slate-5"
        >
          <span class="text-base font-semibold text-n-slate-12">
            {{
              t('CONVERSATION_SIDEBAR.SHARED_FILES.MORE_COUNT', {
                count: overflow,
              })
            }}
          </span>
        </div>
      </div>
    </div>
  </section>
  <template v-else />
</template>
