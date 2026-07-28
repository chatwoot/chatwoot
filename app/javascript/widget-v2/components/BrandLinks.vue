<script setup>
import { computed } from 'vue';
import { isWebUrl } from 'widget-v2/helpers/urlHelpers';
import HomeSection from 'widget-v2/components/HomeSection.vue';

const props = defineProps({
  brand: { type: Object, required: true },
});

// Known networks → Phosphor brand glyphs; unknown keys are ignored.
const SOCIAL_ICONS = {
  x: 'i-ph-x-logo',
  twitter: 'i-ph-x-logo',
  linkedin: 'i-ph-linkedin-logo',
  facebook: 'i-ph-facebook-logo',
  instagram: 'i-ph-instagram-logo',
  youtube: 'i-ph-youtube-logo',
  github: 'i-ph-github-logo',
  tiktok: 'i-ph-tiktok-logo',
  discord: 'i-ph-discord-logo',
  telegram: 'i-ph-telegram-logo',
  whatsapp: 'i-ph-whatsapp-logo',
};

const socialLinks = computed(() =>
  Object.entries(props.brand.social || {})
    .filter(([network, url]) => SOCIAL_ICONS[network] && isWebUrl(url))
    .map(([network, url]) => ({ network, url, icon: SOCIAL_ICONS[network] }))
);

// Normalize everything into rows: email/phone first, then custom links.
const rows = computed(() => {
  const items = [];
  if (props.brand.email) {
    items.push({
      label: props.brand.email,
      href: `mailto:${props.brand.email}`,
      icon: 'i-ph-envelope-simple',
    });
  }
  if (props.brand.phone) {
    items.push({
      label: props.brand.phone,
      href: `tel:${props.brand.phone.replace(/[^\d+]/g, '')}`,
      icon: 'i-ph-phone',
    });
  }
  (props.brand.links || [])
    .filter(link => link.label && isWebUrl(link.url))
    .forEach(link =>
      items.push({
        label: link.label,
        href: link.url,
        icon: 'i-ph-globe',
        external: true,
      })
    );
  return items;
});
</script>

<template>
  <HomeSection
    v-if="rows.length || socialLinks.length"
    :label="$t('HOME.CONTACT')"
  >
    <a
      v-for="row in rows"
      :key="row.href"
      :href="row.href"
      :target="row.external ? '_blank' : undefined"
      :rel="row.external ? 'noreferrer noopener' : undefined"
      class="group flex items-center gap-3 row-pad rounded-token-sm transition-colors hover:bg-cw-surface outline-none focus-visible:ring-[3px] focus-visible:ring-inset focus-visible:ring-cw-ring"
    >
      <span
        class="flex items-center justify-center w-8 h-8 rounded-full bg-cw-muted text-cw-text-muted"
      >
        <span :class="row.icon" class="text-sm" />
      </span>
      <span class="flex-1 text-sm font-520 text-cw-text truncate">
        {{ row.label }}
      </span>
      <span
        class="shrink-0 text-cw-text-faint"
        :class="row.external ? 'i-ph-arrow-square-out' : 'i-ph-caret-right'"
      />
    </a>

    <div v-if="socialLinks.length" class="flex items-center gap-2 px-2 pt-2">
      <a
        v-for="social in socialLinks"
        :key="social.network"
        :href="social.url"
        target="_blank"
        rel="noreferrer noopener"
        class="flex items-center justify-center w-8 h-8 rounded-full bg-cw-muted text-cw-text-muted transition-colors hover:bg-cw-primary-soft hover:text-cw-primary outline-none focus-visible:ring-[3px] focus-visible:ring-cw-ring"
        :aria-label="social.network"
      >
        <span :class="social.icon" class="text-sm" />
      </a>
    </div>
  </HomeSection>
</template>
