<script setup>
import { computed } from 'vue';
import { frontendURL } from 'dashboard/helper/URLHelper';
import countries from 'shared/constants/countries';
import { dynamicTime } from 'shared/helpers/timeHelper';

import CardLayout from 'dashboard/components-next/CardLayout.vue';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import Flag from 'dashboard/components-next/flag/Flag.vue';

const props = defineProps({
  id: {
    type: [String, Number],
    default: 0,
  },
  email: {
    type: String,
    default: '',
  },
  phone: {
    type: String,
    default: '',
  },
  name: {
    type: String,
    default: '',
  },
  thumbnail: {
    type: String,
    default: '',
  },
  accountId: {
    type: [String, Number],
    default: 0,
  },
  additionalAttributes: {
    type: Object,
    default: () => ({}),
  },
  updatedAt: {
    type: Number,
    default: 0,
  },
});

const navigateTo = computed(() => {
  return frontendURL(`accounts/${props.accountId}/contacts/${props.id}`);
});

const countriesMap = computed(() => {
  return countries.reduce((acc, country) => {
    acc[country.code] = country;
    acc[country.id] = country;
    return acc;
  }, {});
});

const updatedAtTime = computed(() => {
  if (!props.updatedAt) return '';
  return dynamicTime(props.updatedAt);
});

const countryDetails = computed(() => {
  const { country, countryCode, city } = props.additionalAttributes;

  if (!country && !countryCode) return null;

  const activeCountry =
    countriesMap.value[country] || countriesMap.value[countryCode];

  if (!activeCountry) return null;

  return {
    countryCode: activeCountry.id,
    city: city ? `${city},` : null,
    name: activeCountry.name,
  };
});

const formattedLocation = computed(() => {
  if (!countryDetails.value) return '';

  return [countryDetails.value.city, countryDetails.value.name]
    .filter(Boolean)
    .join(' ');
});
</script>

<template>
  <router-link :to="navigateTo">
    <CardLayout
      layout="row"
      class="[&>div]:justify-start [&>div]:px-4 [&>div]:py-3 [&>div]:items-start hover:bg-n-slate-2 dark:hover:bg-n-solid-3"
    >
      <Avatar
        :name="name"
        :src="thumbnail"
        :size="24"
        rounded-full
        class="mt-1 flex-shrink-0"
      />
      <div class="min-w-0 flex flex-col items-start gap-1.5 w-full">
        <div class="flex items-center min-w-0 justify-between gap-2 w-full">
          <h5 class="text-sm font-medium truncate min-w-0 text-n-slate-12 py-1">
            {{ name }}
          </h5>
          <span
            v-if="updatedAtTime"
            class="text-sm font-normal min-w-0 truncate text-n-slate-11"
          >
            {{ $t('SEARCH.UPDATED_AT', { time: updatedAtTime }) }}
          </span>
        </div>
        <div
          class="grid items-center gap-3 m-0 text-sm overflow-hidden min-w-0 grid-cols-[minmax(0,max-content)_auto_minmax(0,max-content)_auto_minmax(0,max-content)]"
        >
          <span
            v-if="email"
            class="truncate text-n-slate-11 min-w-0"
            :title="email"
          >
            {{ email }}
          </span>

          <div v-if="email && phone" class="w-px h-3 bg-n-slate-6 rounded" />

          <span
            v-if="phone"
            :title="phone"
            class="truncate text-n-slate-11 min-w-0"
          >
            {{ phone }}
          </span>

          <div
            v-if="(email || phone) && countryDetails"
            class="w-px h-3 bg-n-slate-6 rounded"
          />

          <span
            v-if="countryDetails"
            class="truncate text-n-slate-11 flex items-center gap-1 min-w-0"
          >
            <Flag
              :country="countryDetails.countryCode"
              class="size-3 shrink-0"
            />
            <span class="truncate min-w-0">{{ formattedLocation }}</span>
          </span>
        </div>
      </div>
    </CardLayout>
  </router-link>
</template>
