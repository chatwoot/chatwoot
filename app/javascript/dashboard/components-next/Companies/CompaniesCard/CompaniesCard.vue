<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { dynamicTime } from 'shared/helpers/timeHelper';
import { useExactTimestamp } from 'shared/composables/useExactTimestamp';

import { getCompanyProfile } from 'dashboard/components-next/Companies/helpers/companyHelper';

import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import Flag from 'dashboard/components-next/flag/Flag.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

const props = defineProps({
  id: { type: Number, required: true },
  name: { type: String, default: '' },
  domain: { type: String, default: '' },
  contactsCount: { type: Number, default: 0 },
  avatarUrl: { type: String, default: '' },
  lastActivityAt: { type: [String, Number], default: null },
  description: { type: String, default: '' },
  additionalAttributes: { type: Object, default: () => ({}) },
});

const emit = defineEmits(['showCompany']);

const exactTimestamp = useExactTimestamp();

const { t } = useI18n();

const onClickViewDetails = () => emit('showCompany', props.id);

const displayName = computed(() => props.name || t('COMPANIES.UNNAMED'));

const details = computed(() => {
  const { industry, employees, location, countryCode } = getCompanyProfile(
    props.additionalAttributes
  );
  const contactsCount = Number(props.contactsCount || 0);

  return [
    props.domain && {
      key: 'domain',
      icon: 'i-lucide-globe',
      label: props.domain,
    },
    industry && {
      key: 'industry',
      icon: 'i-lucide-building-2',
      label: industry,
    },
    employees && {
      key: 'employees',
      icon: 'i-lucide-users',
      label: t('COMPANIES.CARD.EMPLOYEES', { count: employees }),
    },
    location && { key: 'location', countryCode, label: location },
    contactsCount > 0 && {
      key: 'contacts',
      icon: 'i-lucide-contact',
      label: t('COMPANIES.CONTACTS_COUNT', { n: contactsCount }),
    },
  ].filter(Boolean);
});

const formattedLastActivityAt = computed(() => {
  if (!props.lastActivityAt) return '';
  return dynamicTime(props.lastActivityAt);
});
</script>

<template>
  <div
    class="flex items-start justify-between gap-4 py-4 cursor-pointer group max-sm:grid max-sm:grid-cols-[auto_minmax(0,1fr)_auto] max-sm:gap-x-3 max-sm:gap-y-1"
    @click="onClickViewDetails"
  >
    <div class="flex items-start flex-1 min-w-0 gap-3 max-sm:contents">
      <Avatar
        :name="displayName"
        :src="avatarUrl"
        class="shrink-0 max-sm:row-span-3"
        :size="36"
        hide-offline-status
      />
      <div class="flex flex-col flex-1 min-w-0 gap-1 max-sm:contents">
        <span
          class="block truncate text-heading-3 text-n-slate-12 group-hover:text-n-blue-11 max-sm:col-start-2"
        >
          {{ displayName }}
        </span>
        <p
          v-if="description"
          class="mb-0 text-n-slate-11 text-body-main line-clamp-2 sm:line-clamp-1 max-sm:col-start-2 max-sm:col-span-2"
        >
          {{ description }}
        </p>
        <div
          v-if="details.length"
          class="overflow-hidden max-sm:col-start-2 max-sm:col-span-2"
        >
          <div class="flex flex-wrap gap-y-1 -ms-[calc(0.75rem+1px)]">
            <span
              v-for="detail in details"
              :key="detail.key"
              class="inline-flex items-center min-w-0 gap-1.5 text-body-main text-n-slate-11 max-w-full me-3 before:content-[''] before:w-px before:h-3 before:shrink-0 before:bg-n-slate-6 before:me-1.5"
              :title="detail.label"
            >
              <Flag
                v-if="detail.countryCode"
                :country="detail.countryCode"
                class="size-3.5 shrink-0"
              />
              <Icon
                v-else-if="detail.icon"
                :icon="detail.icon"
                class="size-3.5 shrink-0 text-n-slate-10"
              />
              <span class="truncate sm:max-w-60">{{ detail.label }}</span>
            </span>
          </div>
        </div>
      </div>
    </div>
    <span
      v-if="lastActivityAt"
      v-tooltip.top="{
        content: exactTimestamp(lastActivityAt),
        delay: { show: 500, hide: 0 },
      }"
      class="flex-shrink-0 text-sm text-n-slate-11 leading-[1.3125rem] max-sm:col-start-3 max-sm:row-start-1"
    >
      {{ formattedLastActivityAt }}
    </span>
  </div>
</template>
