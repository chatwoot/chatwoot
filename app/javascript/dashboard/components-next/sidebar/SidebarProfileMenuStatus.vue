<script setup>
import { computed } from 'vue';
import { useMapGetter, useStore } from 'dashboard/composables/store';
import wootConstants from 'dashboard/constants/globals';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';

import Icon from 'next/icon/Icon.vue';

const { t } = useI18n();
const store = useStore();
const currentUserAvailability = useMapGetter('getCurrentUserAvailability');
const currentAccountId = useMapGetter('getCurrentAccountId');
const currentUserAutoOffline = useMapGetter('getCurrentUserAutoOffline');

const { AVAILABILITY_STATUS_KEYS } = wootConstants;
const statusList = computed(() => {
  return [
    t('PROFILE_SETTINGS.FORM.AVAILABILITY.STATUS.ONLINE'),
    t('PROFILE_SETTINGS.FORM.AVAILABILITY.STATUS.BUSY'),
    t('PROFILE_SETTINGS.FORM.AVAILABILITY.STATUS.OFFLINE'),
  ];
});

const availabilityStatuses = computed(() => {
  return statusList.value.map((statusLabel, index) => ({
    label: statusLabel,
    value: AVAILABILITY_STATUS_KEYS[index],
    active: currentUserAvailability.value === AVAILABILITY_STATUS_KEYS[index],
  }));
});

function changeAvailabilityStatus(availability) {
  try {
    store.dispatch('updateAvailability', {
      availability,
      account_id: currentAccountId.value,
    });
  } catch (error) {
    useAlert(t('PROFILE_SETTINGS.FORM.AVAILABILITY.SET_AVAILABILITY_ERROR'));
  }
}

function updateAutoOffline(autoOffline) {
  store.dispatch('updateAutoOffline', {
    accountId: currentAccountId.value,
    autoOffline,
  });
}
</script>

<template>
  <div class="pt-2 text-n-slate-12">
    <span
      class="px-3 leading-4 font-medium tracking-[0.2px] text-n-slate-10 text-xs"
    >
      {{ t('SIDEBAR.SET_AVAILABILITY_TITLE') }}
    </span>
    <ul class="list-none m-0 grid gap-1 p-1">
      <li
        v-for="status in availabilityStatuses"
        :key="status.value"
        class="flex items-baseline"
      >
        <button
          class="text-left rtl:text-right hover:bg-n-alpha-1 px-2 py-1.5 w-full flex items-center gap-2"
          :class="{
            'pointer-events-none bg-n-amber-10/10': status.active,
            'bg-n-teal-3': status.active && status.value === 'online',
            'bg-n-amber-3': status.active && status.value === 'busy',
            'bg-n-slate-3': status.active && status.value === 'offline',
          }"
          @click="changeAvailabilityStatus(status.value)"
        >
          <div
            class="rounded-full w-2.5 h-2.5"
            :class="{
              'bg-n-teal-10': status.value === 'online',
              'bg-n-amber-10': status.value === 'busy',
              'bg-n-slate-10': status.value === 'offline',
            }"
          />
          <span class="flex-grow">{{ status.label }}</span>
          <Icon
            v-if="status.active"
            icon="i-lucide-check"
            class="size-4 flex-shrink-0"
            :class="{
              'text-n-teal-11': status.value === 'online',
              'text-n-amber-11': status.value === 'busy',
              'text-n-slate-11': status.value === 'offline',
            }"
          />
        </button>
      </li>
    </ul>
  </div>
  <div class="border-t border-n-strong mx-2 my-0" />
  <ul class="list-none m-0 grid gap-1 p-1">
    <li class="px-2 py-1.5 flex items-start w-full gap-2">
      <div class="h-5 flex items-center flex-shrink-0">
        <Icon icon="i-lucide-info" class="size-4" />
      </div>
      <div class="flex-grow">
        <div class="h-5 leading-none flex place-items-center text-n-slate-12">
          {{ $t('SIDEBAR.SET_AUTO_OFFLINE.TEXT') }}
        </div>
        <div class="text-xs leading-tight text-n-slate-10 mt-1">
          {{ t('SIDEBAR.SET_AUTO_OFFLINE.INFO_SHORT') }}
        </div>
      </div>
      <woot-switch
        class="flex-shrink-0"
        :model-value="currentUserAutoOffline"
        @input="updateAutoOffline"
      />
    </li>
  </ul>
</template>
