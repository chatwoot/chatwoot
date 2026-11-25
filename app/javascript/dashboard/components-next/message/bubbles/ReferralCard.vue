<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import Icon from 'next/icon/Icon.vue';

const props = defineProps({
  referral: {
    type: Object,
    required: true,
    // Webhook-derived payload — guard the string fields the template renders so a
    // malformed referral warns in dev instead of silently rendering a broken card.
    validator: value =>
      value != null &&
      typeof value === 'object' &&
      ['title', 'body', 'sourceUrl', 'thumbnailUrl'].every(
        key => value[key] == null || typeof value[key] === 'string'
      ),
  },
});

const { t } = useI18n();

// content_attributes keys are deep-camelized by MessageList (useCamelCase),
// so the referral payload arrives as sourceUrl/thumbnailUrl/etc.

// Both the ad link (href) and the thumbnail (img src) come from the webhook, so
// only accept well-formed http(s) URLs: this keeps an unsafe scheme (e.g.
// javascript:) out of the link and stops an arbitrary URL from triggering a
// request from the agent's browser through the image.
const toHttpUrl = url => {
  if (!url) return null;
  try {
    return ['http:', 'https:'].includes(new URL(url).protocol) ? url : null;
  } catch {
    return null;
  }
};

const adUrl = computed(() => toHttpUrl(props.referral.sourceUrl));
const imageUrl = computed(() => toHttpUrl(props.referral.thumbnailUrl));

const hasImageError = ref(false);
const showImage = computed(
  () => Boolean(imageUrl.value) && !hasImageError.value
);
</script>

<template>
  <component
    :is="adUrl ? 'a' : 'div'"
    :href="adUrl || undefined"
    :target="adUrl ? '_blank' : undefined"
    rel="noopener noreferrer"
    class="flex flex-col gap-2 p-2 -mx-1 mb-2 overflow-hidden no-underline rounded-lg bg-n-alpha-black1"
    :class="adUrl ? 'cursor-pointer hover:bg-n-alpha-black2' : ''"
  >
    <div class="flex items-center gap-1 text-xs text-n-slate-11">
      <Icon icon="i-lucide-megaphone" class="size-3" />
      <span>{{ t('COMPONENTS.REFERRAL_CARD.AD_LABEL') }}</span>
    </div>
    <img
      v-if="showImage"
      :src="imageUrl || undefined"
      :alt="referral.title || ''"
      class="object-cover w-full rounded max-h-44 skip-context-menu"
      @error="hasImageError = true"
    />
    <div class="min-w-0">
      <p v-if="referral.title" class="mb-0 text-sm font-medium line-clamp-2">
        {{ referral.title }}
      </p>
      <p v-if="referral.body" class="mb-0 text-xs text-n-slate-11 line-clamp-2">
        {{ referral.body }}
      </p>
    </div>
    <div
      v-if="adUrl"
      class="flex items-center gap-1 text-xs font-medium text-n-slate-12"
    >
      <Icon icon="i-lucide-external-link" class="size-3 shrink-0" />
      <span>{{ t('COMPONENTS.REFERRAL_CARD.VIEW_AD') }}</span>
    </div>
  </component>
</template>
