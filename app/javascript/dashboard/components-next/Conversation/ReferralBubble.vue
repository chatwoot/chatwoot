<script setup>
import { computed, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';

/**
 * Renders a contextual card at the top of a WhatsApp conversation when the
 * contact arrived through a Click-to-WhatsApp ad. The ad metadata is captured
 * by the incoming-message service into `conversation.additional_attributes.referral`.
 *
 * The card is intentionally not a Message — it represents the pre-conversation
 * touchpoint that motivated the customer's first message, so agents can read
 * the conversation top-down with full context.
 */
const props = defineProps({
  referral: {
    type: Object,
    required: true,
  },
});

const { t } = useI18n();

const hasVideo = computed(
  () => props.referral?.media_type === 'video' && !!props.referral?.video_url
);
const hasImage = computed(
  () => props.referral?.media_type === 'image' && !!props.referral?.image_url
);

const mediaThumbnail = computed(
  () => props.referral?.thumbnail_url || props.referral?.image_url || null
);

const headline = computed(() => props.referral?.headline || '');
const body = computed(() => props.referral?.body || '');
const sourceUrl = computed(() => props.referral?.source_url || '');
const sourceType = computed(() => props.referral?.source_type || 'ad');
const welcomeText = computed(() => props.referral?.welcome_message?.text || '');

const adLabel = computed(() =>
  sourceType.value === 'post'
    ? t('CONVERSATION.REFERRAL.POST_LABEL')
    : t('CONVERSATION.REFERRAL.AD_LABEL')
);

const mediaLoadError = ref(false);
const handleMediaError = () => {
  mediaLoadError.value = true;
};

const showMedia = computed(
  () => (hasVideo.value || hasImage.value) && !mediaLoadError.value
);

// Reset the media error flag when the referral changes so that a fresh ad's
// media gets a real load attempt — Vue may reuse this component when the agent
// switches between conversations that both have referral data.
watch(
  () => props.referral,
  () => {
    mediaLoadError.value = false;
  }
);
</script>

<template>
  <li class="px-4 pt-3 pb-1 list-none" data-clarity-mask="True">
    <div class="flex justify-start">
      <div
        class="w-full max-w-md overflow-hidden border border-dashed rounded-xl rounded-bl-sm bg-n-alpha-1 border-n-amber-7"
      >
        <div
          class="flex items-center gap-2 px-3 py-2 bg-n-amber-3 border-b border-n-amber-7/40"
        >
          <span
            class="i-lucide-megaphone size-4 text-n-amber-11 flex-shrink-0"
          />
          <span class="text-xs font-medium text-n-amber-12">
            {{ adLabel }}
          </span>
        </div>

        <a
          v-if="showMedia"
          :href="sourceUrl"
          target="_blank"
          rel="noopener noreferrer"
          class="block relative bg-n-slate-3"
        >
          <video
            v-if="hasVideo"
            class="block w-full max-h-72 object-cover"
            :poster="mediaThumbnail"
            :src="referral.video_url"
            muted
            playsinline
            preload="metadata"
            @error="handleMediaError"
          />
          <img
            v-else
            class="block w-full max-h-72 object-cover"
            :src="mediaThumbnail"
            :alt="headline"
            @error="handleMediaError"
          />
          <span
            v-if="hasVideo"
            class="absolute inset-0 flex items-center justify-center pointer-events-none"
          >
            <span
              class="size-12 rounded-full bg-black/50 flex items-center justify-center"
            >
              <span class="i-lucide-play size-6 text-white" />
            </span>
          </span>
        </a>

        <div class="p-3 space-y-1.5">
          <h4
            v-if="headline"
            class="text-sm font-semibold text-n-slate-12 leading-tight"
          >
            {{ headline }}
          </h4>
          <p
            v-if="body"
            class="text-sm text-n-slate-11 leading-snug line-clamp-3"
          >
            {{ body }}
          </p>
          <a
            v-if="sourceUrl"
            :href="sourceUrl"
            target="_blank"
            rel="noopener noreferrer"
            class="inline-flex items-center gap-1 mt-1 text-xs font-medium text-n-amber-11 hover:text-n-amber-12 hover:underline"
          >
            <span class="i-lucide-external-link size-3" />
            {{ t('CONVERSATION.REFERRAL.VIEW_AD') }}
          </a>
        </div>

        <div
          v-if="welcomeText"
          class="px-3 pb-3 pt-1 text-xs text-n-slate-10 border-t border-n-amber-7/30 mt-0"
        >
          <span class="font-medium text-n-slate-11">
            {{ t('CONVERSATION.REFERRAL.WELCOME_MESSAGE_LABEL') }}
          </span>
          <span class="italic">{{ welcomeText }}</span>
        </div>
      </div>
    </div>

    <div
      class="flex items-center gap-1.5 mt-2 mb-1 text-xs text-n-slate-10 ml-2"
    >
      <span class="i-lucide-corner-down-right size-3" />
      <span>{{ t('CONVERSATION.REFERRAL.REPLIED_BELOW') }}</span>
    </div>
  </li>
</template>
