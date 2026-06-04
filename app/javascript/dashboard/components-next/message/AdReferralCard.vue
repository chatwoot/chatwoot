<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';

/**
 * @typedef {Object} ReferralBlock
 * @property {string} [source_id]    - Meta ad/post id
 * @property {string} [source_type]  - 'ad' | 'post'
 * @property {string} [source_url]   - Public URL of the ad/post
 * @property {string} [headline]     - Ad headline
 * @property {string} [body]         - Ad body text
 * @property {string} [media_type]   - 'image' | 'video' | ...
 * @property {string} [media_url]    - Meta CDN URL (often expires)
 * @property {string} [image_url]    - Optional cover image (some payloads)
 * @property {string} [image]        - Legacy alias for image_url
 * @property {string} [thumbnail_url]- Cached thumbnail when present
 * @property {string} [ctwa_clid]    - Click-to-WhatsApp click id (attribution only)
 */

const props = defineProps({
  referral: {
    type: Object,
    required: true,
    validator: value => value && typeof value === 'object',
  },
});

const { t } = useI18n();

// Meta does not name the platform on the referral payload itself;
// the cleanest signal we have is the host of source_url. Short links
// like fb.me are owned by Meta and used for Facebook ads.
const sourcePlatform = computed(() => {
  const url = String(props.referral?.source_url || '');
  if (/(^|\.)instagram\.com\b/i.test(url)) return 'instagram';
  if (/(^|\.)(facebook\.com|fb\.com|fb\.me)\b/i.test(url)) return 'facebook';
  return 'unknown';
});

// Meta sends 'ad' or 'post'; default to 'ad' which is the more common CTWA case.
const sourceType = computed(() => {
  return props.referral?.source_type === 'post' ? 'post' : 'ad';
});

const sourceLabelKey = computed(() => {
  // CONVERSATION.WHATSAPP_AD_REFERRAL.FROM_<TYPE>_<PLATFORM>
  const typePart = sourceType.value.toUpperCase();
  const platformPart = sourcePlatform.value.toUpperCase();
  return `CONVERSATION.WHATSAPP_AD_REFERRAL.FROM_${typePart}_${platformPart}`;
});

const sourceLabel = computed(() => t(sourceLabelKey.value));

const headline = computed(() =>
  String(props.referral?.headline || '').trim()
);
const body = computed(() => String(props.referral?.body || '').trim());
const sourceId = computed(() => String(props.referral?.source_id || '').trim());
const sourceUrl = computed(() => props.referral?.source_url || '');

// CTWA payloads are inconsistent across Meta versions — try the
// modern keys first, then media_url when media_type is image, then
// the legacy aliases. Empty string disables the <img> branch.
const imageUrl = computed(() => {
  const r = props.referral || {};
  if (typeof r.thumbnail_url === 'string' && r.thumbnail_url) {
    return r.thumbnail_url;
  }
  if (typeof r.image_url === 'string' && r.image_url) return r.image_url;
  if (typeof r.image === 'string' && r.image) return r.image;
  if (r.media_type === 'image' && typeof r.media_url === 'string') {
    return r.media_url;
  }
  return '';
});

const hasAnyContent = computed(() => {
  return Boolean(
    headline.value ||
      body.value ||
      sourceId.value ||
      sourceUrl.value ||
      imageUrl.value
  );
});

// Meta's scontent.fbcdn.net image URLs expire after a few hours; failing
// silently is the right UX — the rest of the card is still useful.
const handleImageError = event => {
  if (event?.target) {
    event.target.style.display = 'none';
  }
};
</script>

<template>
  <div
    v-if="hasAnyContent"
    class="flex gap-2 items-start p-2 -mx-1 mb-2 rounded-lg text-start bg-n-alpha-black1"
    data-testid="ad-referral-card"
  >
    <img
      v-if="imageUrl"
      :src="imageUrl"
      :alt="headline || sourceLabel"
      class="object-cover flex-shrink-0 w-12 h-12 rounded-md skip-context-menu"
      loading="lazy"
      decoding="async"
      referrerpolicy="no-referrer"
      @error="handleImageError"
    />
    <div class="flex flex-col flex-1 gap-0.5 min-w-0">
      <span class="text-xs font-medium truncate text-n-slate-11">
        {{ sourceLabel }}
      </span>
      <span
        v-if="sourceId"
        class="text-[11px] font-mono truncate text-n-slate-10"
        :title="sourceId"
      >
        {{ sourceType === 'post' ? 'Post ID' : 'Ad ID' }}: {{ sourceId }}
      </span>
      <span
        v-if="headline"
        class="text-sm font-semibold truncate text-n-slate-12"
        :title="headline"
      >
        {{ headline }}
      </span>
      <p
        v-if="body"
        class="text-xs break-words line-clamp-2 text-n-slate-11"
        :title="body"
      >
        {{ body }}
      </p>
      <a
        v-if="sourceUrl"
        :href="sourceUrl"
        target="_blank"
        rel="noreferrer noopener nofollow"
        class="text-xs underline truncate text-n-blue-11 skip-context-menu"
        :title="sourceUrl"
      >
        {{ $t('CONVERSATION.WHATSAPP_AD_REFERRAL.VIEW_AD') }}
      </a>
    </div>
  </div>
</template>
