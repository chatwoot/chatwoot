<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import Icon from 'dashboard/components-next/icon/Icon.vue';

const props = defineProps({
  selectedContact: {
    type: Object,
    required: true,
  },
});

const { t } = useI18n();

const additional = computed(
  () => props.selectedContact?.additionalAttributes || {}
);

const SOCIAL_ICONS = {
  linkedin: 'i-ri-linkedin-box-fill',
  facebook: 'i-ri-facebook-circle-fill',
  instagram: 'i-ri-instagram-line',
  telegram: 'i-ri-telegram-fill',
  tiktok: 'i-ri-tiktok-fill',
  twitter: 'i-ri-twitter-x-fill',
  github: 'i-ri-github-fill',
};

const socialProfiles = computed(() => {
  const raw =
    additional.value.socialProfiles ||
    additional.value.social_profiles ||
    {};
  const telegramFallback =
    additional.value.socialTelegramUserName ||
    additional.value.social_telegram_user_name ||
    '';

  const entries = Object.entries(raw)
    .filter(([, value]) => value)
    .map(([key, value]) => ({
      key: key.toLowerCase(),
      value: String(value).trim(),
      icon: SOCIAL_ICONS[key.toLowerCase()] || 'i-lucide-link',
    }));

  if (
    telegramFallback &&
    !entries.some(item => item.key === 'telegram')
  ) {
    entries.push({
      key: 'telegram',
      value: String(telegramFallback).trim(),
      icon: SOCIAL_ICONS.telegram,
    });
  }

  return entries;
});

const socialHref = profile => {
  const value = profile.value;
  if (/^https?:\/\//i.test(value)) return value;
  if (profile.key === 'telegram') {
    return `https://t.me/${value.replace(/^@/, '')}`;
  }
  if (profile.key === 'twitter') {
    return `https://x.com/${value.replace(/^@/, '')}`;
  }
  if (profile.key === 'instagram') {
    return `https://instagram.com/${value.replace(/^@/, '')}`;
  }
  if (profile.key === 'github') {
    return `https://github.com/${value.replace(/^@/, '')}`;
  }
  if (profile.key === 'linkedin') {
    return value.includes('linkedin.com')
      ? `https://${value.replace(/^\/\//, '')}`
      : `https://www.linkedin.com/in/${value.replace(/^@/, '')}`;
  }
  if (profile.key === 'facebook') {
    return value.includes('facebook.com')
      ? `https://${value.replace(/^\/\//, '')}`
      : `https://facebook.com/${value.replace(/^@/, '')}`;
  }
  if (profile.key === 'tiktok') {
    return `https://tiktok.com/@${value.replace(/^@/, '')}`;
  }
  return `https://${value}`;
};

// Identity + location context only once here (not repeated in the hero card).
const rows = computed(() => {
  const contact = props.selectedContact;
  const items = [
    {
      key: 'email',
      label: t('CONTACTS_LAYOUT.DETAILS.FIELDS.EMAIL'),
      value: contact?.email,
    },
    {
      key: 'phone',
      label: t('CONTACTS_LAYOUT.DETAILS.FIELDS.PHONE'),
      value: contact?.phoneNumber,
    },
    {
      key: 'document',
      label: t('CONTACTS_LAYOUT.DETAILS.FIELDS.DOCUMENT'),
      value: contact?.documentNumber,
    },
    {
      key: 'identifier',
      label: t('CONTACTS_LAYOUT.DETAILS.FIELDS.IDENTIFIER'),
      value: contact?.identifier,
    },
    {
      key: 'company',
      label: t('CONTACTS_LAYOUT.DETAILS.FIELDS.COMPANY'),
      value: additional.value.companyName,
    },
    {
      key: 'city',
      label: t('CONTACTS_LAYOUT.DETAILS.FIELDS.CITY'),
      value: additional.value.city,
    },
    {
      key: 'country',
      label: t('CONTACTS_LAYOUT.DETAILS.FIELDS.COUNTRY'),
      value: additional.value.country || additional.value.countryCode,
    },
    {
      key: 'bio',
      label: t('CONTACTS_LAYOUT.DETAILS.FIELDS.BIO'),
      value: additional.value.description,
      fullWidth: true,
    },
  ];

  return items.filter(item => item.value);
});
</script>

<template>
  <section
    class="rounded-xl border border-n-weak bg-n-alpha-1 dark:bg-n-solid-2 p-4 flex flex-col gap-5"
  >
    <div>
      <h4 class="text-sm font-medium text-n-slate-12 mb-3">
        {{ t('CONTACTS_LAYOUT.DETAILS.SECTIONS.CONTACT_DATA') }}
      </h4>

      <dl v-if="rows.length" class="grid grid-cols-1 gap-3 sm:grid-cols-2">
        <div
          v-for="row in rows"
          :key="row.key"
          class="min-w-0 flex flex-col gap-0.5"
          :class="{ 'sm:col-span-2': row.fullWidth }"
        >
          <dt class="text-xs text-n-slate-10">{{ row.label }}</dt>
          <dd class="text-sm text-n-slate-12 break-words whitespace-pre-wrap">
            {{ row.value }}
          </dd>
        </div>
      </dl>
      <p v-else class="text-sm text-n-slate-11">
        {{ t('CONTACTS_LAYOUT.DETAILS.EMPTY_CONTACT_DATA') }}
      </p>
    </div>

    <div class="pt-4 border-t border-n-weak">
      <h4 class="text-sm font-medium text-n-slate-12 mb-3">
        {{ t('CONTACTS_LAYOUT.DETAILS.SECTIONS.SOCIAL_PROFILES') }}
      </h4>
      <ul v-if="socialProfiles.length" class="flex flex-wrap gap-2">
        <li v-for="profile in socialProfiles" :key="profile.key">
          <a
            :href="socialHref(profile)"
            target="_blank"
            rel="noopener noreferrer"
            class="inline-flex items-center gap-2 rounded-lg border border-n-weak bg-n-solid-1 px-2.5 py-1.5 text-sm text-n-slate-12 hover:bg-n-alpha-2 transition-colors max-w-full"
            :title="profile.key"
          >
            <Icon :icon="profile.icon" class="size-4 text-n-slate-11 shrink-0" />
            <span class="truncate capitalize">{{ profile.key }}</span>
            <span class="truncate text-n-slate-11 max-w-[10rem]">{{
              profile.value
            }}</span>
          </a>
        </li>
      </ul>
      <p v-else class="text-sm text-n-slate-11">
        {{ t('CONTACTS_LAYOUT.DETAILS.EMPTY_SOCIAL_PROFILES') }}
      </p>
    </div>
  </section>
</template>
