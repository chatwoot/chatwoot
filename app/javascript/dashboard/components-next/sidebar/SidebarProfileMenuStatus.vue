<script setup>
import { computed } from 'vue';
import { useMapGetter, useStore } from 'dashboard/composables/store';
import wootConstants from 'dashboard/constants/globals';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';

import DropdownSection from 'next/dropdown-menu/base/DropdownSection.vue';
import DropdownItem from 'next/dropdown-menu/base/DropdownItem.vue';
import DropdownSeparator from 'next/dropdown-menu/base/DropdownSeparator.vue';

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
  <DropdownSection :title="t('SIDEBAR.SET_AVAILABILITY_TITLE')">
    <DropdownItem
      v-for="status in availabilityStatuses"
      :key="status.value"
      :label="status.label"
      :class="{
        'pointer-events-none bg-n-amber-10/10': status.active,
        'bg-n-teal-3': status.active && status.value === 'online',
        'bg-n-amber-3': status.active && status.value === 'busy',
        'bg-n-slate-3': status.active && status.value === 'offline',
      }"
      @click="changeAvailabilityStatus(status.value)"
    >
      <template #icon>
        <div
          class="rounded-full w-2.5 h-2.5"
          :class="{
            'bg-n-teal-10': status.value === 'online',
            'bg-n-amber-10': status.value === 'busy',
            'bg-n-slate-10': status.value === 'offline',
          }"
        />
      </template>
    </DropdownItem>
  </DropdownSection>
  <DropdownSeparator />
  <DropdownSection>
    <DropdownItem>
      <div class="flex-grow">
        {{ $t('SIDEBAR.SET_AUTO_OFFLINE.TEXT') }}
      </div>
      <woot-switch
        class="flex-shrink-0"
        :model-value="currentUserAutoOffline"
        @input="updateAutoOffline"
      />
    </DropdownItem>
  </DropdownSection>
</template>
