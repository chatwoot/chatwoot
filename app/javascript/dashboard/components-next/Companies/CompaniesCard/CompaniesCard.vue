<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { dynamicTime } from 'shared/helpers/timeHelper';
import { useExactTimestamp } from 'shared/composables/useExactTimestamp';

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

const avatarSource = computed(() => props.avatarUrl || null);

const details = computed(() => {
  const {
    industry,
    sub_industry: subIndustry,
    employee_count_range: employeeCountRange,
    employee_count: employeeCount,
    city,
    country,
    country_code: countryCode,
  } = props.additionalAttributes || {};
  const employees = employeeCount
    ? employeeCount.toLocaleString()
    : employeeCountRange;
  const contactsCount = Number(props.contactsCount || 0);

  return [
    props.domain && {
      key: 'domain',
      icon: 'i-lucide-globe',
      label: props.domain,
    },
    (subIndustry || industry) && {
      key: 'industry',
      icon: 'i-lucide-building-2',
      label: subIndustry || industry,
    },
    employees && {
      key: 'employees',
      icon: 'i-lucide-users',
      label: t('COMPANIES.CARD.EMPLOYEES', { count: employees }),
    },
    (city || country) && {
      key: 'location',
      countryCode,
      label: [city, city ? countryCode || country : country]
        .filter(Boolean)
        .join(', '),
    },
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
    class="flex items-start justify-between gap-4 py-4 cursor-pointer group"
    @click="onClickViewDetails"
  >
    <div class="flex items-start flex-1 min-w-0 gap-3">
      <Avatar
        :username="displayName"
        :src="avatarSource"
        class="shrink-0"
        :name="name"
        :size="36"
        hide-offline-status
      />
      <div class="flex flex-col flex-1 min-w-0 gap-1">
        <span
          class="block truncate text-heading-3 text-n-slate-12 group-hover:text-n-blue-11"
        >
          {{ displayName }}
        </span>
        <p
          v-if="description"
          class="mb-0 text-n-slate-11 text-body-main line-clamp-1"
        >
          {{ description }}
        </p>
        <div
          v-if="details.length"
          class="flex flex-wrap items-center min-w-0 gap-x-3 gap-y-1"
        >
          <template v-for="(detail, index) in details" :key="detail.key">
            <div v-if="index" class="w-px h-3 bg-n-slate-6" />
            <span
              class="inline-flex items-center gap-1.5 truncate text-body-main text-n-slate-11 max-w-60"
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
              <span class="truncate">{{ detail.label }}</span>
            </span>
          </template>
        </div>
      </div>
    </div>
    <span
      v-if="lastActivityAt"
      v-tooltip.top="{
        content: exactTimestamp(lastActivityAt),
        delay: { show: 500, hide: 0 },
      }"
      class="flex-shrink-0 text-sm text-n-slate-11 leading-[1.3125rem]"
    >
      {{ formattedLastActivityAt }}
    </span>
  </div>
</template>
