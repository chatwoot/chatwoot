<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import Icon from 'next/icon/Icon.vue';

const props = defineProps({
  referral: { type: Object, required: true },
});

const { t } = useI18n();
const hasMediaError = ref(false);

const safeUrl = value => {
  if (!value) return '';

  try {
    const url = new URL(value);
    return ['http:', 'https:'].includes(url.protocol) ? url.toString() : '';
  } catch {
    return '';
  }
};

const sourceUrl = computed(() => safeUrl(props.referral.sourceUrl));
const mediaUrl = computed(() =>
  safeUrl(
    props.referral.thumbnailUrl ||
      props.referral.imageUrl ||
      props.referral.mediaUrl ||
      props.referral.videoUrl
  )
);
const showMedia = computed(() => mediaUrl.value && !hasMediaError.value);
const isVideo = computed(
  () =>
    props.referral.mediaType === 'video' ||
    props.referral.mediaContentType?.startsWith('video/')
);
const renderVideo = computed(
  () => isVideo.value && !props.referral.thumbnailUrl
);

const handleMediaError = () => {
  hasMediaError.value = true;
};
</script>

<template>
  <div
    class="w-full max-w-lg overflow-hidden border rounded-lg border-n-weak bg-n-alpha-1"
    data-testid="whatsapp-referral"
  >
    <a
      v-if="sourceUrl"
      :href="sourceUrl"
      target="_blank"
      rel="noopener noreferrer"
      class="block text-current no-underline hover:no-underline"
    >
      <div
        v-if="showMedia"
        class="relative overflow-hidden bg-n-alpha-2 aspect-video"
      >
        <video
          v-if="renderVideo"
          :src="mediaUrl"
          muted
          preload="metadata"
          class="object-cover w-full h-full skip-context-menu"
          @error="handleMediaError"
        />
        <img
          v-else
          :src="mediaUrl"
          :alt="referral.headline || t('CONVERSATION.WHATSAPP_REFERRAL.AD')"
          class="object-cover w-full h-full skip-context-menu"
          @error="handleMediaError"
        />
        <div
          v-if="isVideo"
          class="absolute inset-0 flex items-center justify-center pointer-events-none bg-n-alpha-black2"
        >
          <div
            class="flex items-center justify-center rounded-full shadow-md size-10 bg-n-solid-1"
          >
            <Icon icon="i-lucide-play" class="size-4 ms-0.5 text-n-slate-12" />
          </div>
        </div>
      </div>
      <div class="p-3">
        <div class="flex items-center gap-1 text-xs text-n-slate-11">
          <span>{{ t('CONVERSATION.WHATSAPP_REFERRAL.AD') }}</span>
          <Icon icon="i-lucide-external-link" class="size-3" />
        </div>
        <p
          v-if="referral.headline"
          class="mt-1 mb-0 font-medium break-words text-n-slate-12"
        >
          {{ referral.headline }}
        </p>
        <p
          v-if="referral.body"
          class="mt-1 mb-0 whitespace-pre-line break-words line-clamp-3 text-n-slate-11"
        >
          {{ referral.body }}
        </p>
      </div>
    </a>
    <div v-else class="p-3">
      <div class="text-xs text-n-slate-11">
        {{ t('CONVERSATION.WHATSAPP_REFERRAL.AD') }}
      </div>
      <p
        v-if="referral.headline"
        class="mt-1 mb-0 font-medium break-words text-n-slate-12"
      >
        {{ referral.headline }}
      </p>
      <p
        v-if="referral.body"
        class="mt-1 mb-0 whitespace-pre-line break-words line-clamp-3 text-n-slate-11"
      >
        {{ referral.body }}
      </p>
    </div>
  </div>
</template>
