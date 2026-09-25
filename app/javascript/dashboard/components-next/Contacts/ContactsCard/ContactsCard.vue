<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { dynamicTime } from 'shared/helpers/timeHelper';
import { useExactTimestamp } from 'shared/composables/useExactTimestamp';

import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import Checkbox from 'dashboard/components-next/checkbox/Checkbox.vue';
import Flag from 'dashboard/components-next/flag/Flag.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

const props = defineProps({
  id: { type: Number, required: true },
  name: { type: String, default: '' },
  email: { type: String, default: '' },
  additionalAttributes: { type: Object, default: () => ({}) },
  phoneNumber: { type: String, default: '' },
  thumbnail: { type: String, default: '' },
  availabilityStatus: { type: String, default: null },
  lastActivityAt: { type: [String, Number], default: null },
  selectable: { type: Boolean, default: false },
  isSelected: { type: Boolean, default: false },
});

const emit = defineEmits(['showContact', 'select', 'avatarHover']);

const { t } = useI18n();
const exactTimestamp = useExactTimestamp();

const description = computed(() => props.additionalAttributes?.description);

const details = computed(() => {
  const { jobTitle, companyName, city, country, countryCode } =
    props.additionalAttributes || {};
  const role =
    jobTitle && companyName
      ? t('CONTACTS_LAYOUT.DETAIL.HEADER.ROLE_AT', {
          title: jobTitle,
          company: companyName,
        })
      : jobTitle || companyName;

  return [
    role && { key: 'role', icon: 'i-lucide-building-2', label: role },
    props.email && { key: 'email', icon: 'i-lucide-mail', label: props.email },
    props.phoneNumber && {
      key: 'phone',
      icon: 'i-lucide-phone',
      label: props.phoneNumber,
    },
    (city || country) && {
      key: 'location',
      icon: 'i-lucide-map-pin',
      countryCode,
      label: [city, city ? countryCode || country : country]
        .filter(Boolean)
        .join(', '),
    },
  ].filter(Boolean);
});
</script>

<template>
  <div
    class="flex items-start justify-between gap-4 px-3 py-4 -mx-3 cursor-pointer group rounded-xl"
    :class="{ 'bg-n-alpha-2': isSelected }"
    @click="emit('showContact', id)"
  >
    <div class="flex items-start flex-1 min-w-0 gap-3">
      <div
        class="relative shrink-0"
        @mouseenter="emit('avatarHover', true)"
        @mouseleave="emit('avatarHover', false)"
      >
        <Avatar
          :name="name"
          :src="thumbnail"
          :size="36"
          :status="availabilityStatus"
          hide-offline-status
        >
          <template v-if="selectable" #overlay="{ size }">
            <label
              class="flex items-center justify-center rounded-full cursor-pointer absolute inset-0 z-10 backdrop-blur-[2px] border border-n-weak"
              :style="{ width: `${size}px`, height: `${size}px` }"
              @click.stop
            >
              <Checkbox
                :model-value="isSelected"
                @change="event => emit('select', event.target.checked)"
              />
            </label>
          </template>
        </Avatar>
      </div>
      <div class="flex flex-col flex-1 min-w-0 gap-1">
        <span
          class="block truncate text-heading-3 text-n-slate-12 group-hover:text-n-blue-11"
        >
          {{ name }}
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
              class="inline-flex items-center gap-1.5 truncate text-body-main text-n-slate-11 max-w-72"
              :title="detail.label"
            >
              <Flag
                v-if="detail.countryCode"
                :country="detail.countryCode"
                class="size-3.5 shrink-0"
              />
              <Icon
                v-else
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
      {{ dynamicTime(lastActivityAt) }}
    </span>
  </div>
</template>
