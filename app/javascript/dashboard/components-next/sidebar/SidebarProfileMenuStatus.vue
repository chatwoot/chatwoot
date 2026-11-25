<script setup>
import { computed, h } from 'vue';
import { useMapGetter, useStore } from 'dashboard/composables/store';
import wootConstants from 'dashboard/constants/globals';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';
import { useImpersonation } from 'dashboard/composables/useImpersonation';

import {
  DropdownContainer,
  DropdownBody,
  DropdownSection,
  DropdownItem,
  DropdownSeparator,
} from 'next/dropdown-menu/base';
import Icon from 'next/icon/Icon.vue';
import Button from 'next/button/Button.vue';
import ToggleSwitch from 'dashboard/components-next/switch/Switch.vue';
import Checkbox from 'dashboard/components-next/checkbox/Checkbox.vue';

defineProps({
  hasVoiceInbox: { type: Boolean, default: false },
});

const { t } = useI18n();
const store = useStore();
const currentUserAvailability = useMapGetter('getCurrentUserAvailability');
const currentAccountId = useMapGetter('getCurrentAccountId');
const currentUserAutoOffline = useMapGetter('getCurrentUserAutoOffline');
const currentUserAcceptsConversations = useMapGetter(
  'getCurrentUserAcceptsConversations'
);
const currentUserAcceptsCalls = useMapGetter('getCurrentUserAcceptsCalls');

const { isImpersonating } = useImpersonation();

const { AVAILABILITY_STATUS_KEYS } = wootConstants;
const statusList = computed(() => {
  return [
    t('PROFILE_SETTINGS.FORM.AVAILABILITY.STATUS.ONLINE'),
    t('PROFILE_SETTINGS.FORM.AVAILABILITY.STATUS.BUSY'),
    t('PROFILE_SETTINGS.FORM.AVAILABILITY.STATUS.OFFLINE'),
  ];
});

const statusColors = ['bg-n-teal-9', 'bg-n-amber-9', 'bg-n-slate-9'];

const availabilityStatuses = computed(() => {
  return statusList.value.map((statusLabel, index) => ({
    label: statusLabel,
    value: AVAILABILITY_STATUS_KEYS[index],
    color: statusColors[index],
    icon: h('span', { class: [statusColors[index], 'size-[12px] rounded'] }),
    active: currentUserAvailability.value === AVAILABILITY_STATUS_KEYS[index],
  }));
});

const activeStatus = computed(() => {
  return availabilityStatuses.value.find(status => status.active);
});

const autoOfflineToggle = computed({
  get: () => currentUserAutoOffline.value,
  set: autoOffline => {
    store.dispatch('updateAutoOffline', {
      accountId: currentAccountId.value,
      autoOffline,
    });
  },
});

const isOnline = computed(() => currentUserAvailability.value === 'online');

const blockedWhileImpersonating = () => {
  if (isImpersonating.value) {
    useAlert(t('PROFILE_SETTINGS.FORM.AVAILABILITY.IMPERSONATING_ERROR'));
  }
  return isImpersonating.value;
};

const updateWorkPreferences = preferences => {
  if (blockedWhileImpersonating()) return;
  store.dispatch('updateWorkPreferences', {
    accountId: currentAccountId.value,
    ...preferences,
  });
};

const workPreferences = computed(() => {
  const preferences = [
    {
      key: 'accepts_conversations',
      value: currentUserAcceptsConversations.value,
      label: t('SIDEBAR.ACCEPT_CONVERSATIONS.TEXT'),
      info: t('SIDEBAR.ACCEPT_CONVERSATIONS.INFO_SHORT'),
    },
    {
      key: 'accepts_calls',
      value: currentUserAcceptsCalls.value,
      label: t('SIDEBAR.ACCEPT_CALLS.TEXT'),
      info: t('SIDEBAR.ACCEPT_CALLS.INFO_SHORT'),
    },
  ];
  const enabledCount = preferences.filter(({ value }) => value).length;
  return preferences.map(preference => ({
    ...preference,
    isLocked: preference.value && enabledCount === 1,
  }));
});

function changeAvailabilityStatus(availability) {
  if (blockedWhileImpersonating()) return;
  try {
    store.dispatch('updateAvailability', {
      availability,
      account_id: currentAccountId.value,
    });
  } catch (error) {
    useAlert(t('PROFILE_SETTINGS.FORM.AVAILABILITY.SET_AVAILABILITY_ERROR'));
  }
}
</script>

<template>
  <DropdownSection class="[&>ul]:overflow-visible">
    <div class="grid gap-0">
      <DropdownItem preserve-open class="gap-1">
        <div class="flex flex-grow gap-3 items-center min-w-0">
          <Icon
            icon="i-lucide-user-check"
            class="flex-shrink-0 size-4 text-n-slate-11"
          />
          {{ $t('PROFILE_SETTINGS.FORM.AVAILABILITY.LABEL') }}
        </div>
        <DropdownContainer class="shrink-0">
          <template #trigger="{ toggle }">
            <Button
              size="sm"
              color="slate"
              variant="faded"
              icon="i-lucide-chevron-down"
              trailing-icon
              @click="toggle"
            >
              <div class="flex gap-1 items-center min-w-0 text-sm">
                <div class="p-1 flex-shrink-0">
                  <div class="size-2 rounded-sm" :class="activeStatus.color" />
                </div>
                <span class="truncate max-w-[7rem]">
                  {{ activeStatus.label }}
                </span>
              </div>
            </Button>
          </template>
          <DropdownBody class="min-w-32 z-20">
            <DropdownItem
              v-for="status in availabilityStatuses"
              :key="status.value"
              :label="status.label"
              :icon="status.icon"
              class="cursor-pointer"
              @click="changeAvailabilityStatus(status.value)"
            />
          </DropdownBody>
        </DropdownContainer>
      </DropdownItem>
      <template v-if="hasVoiceInbox">
        <div v-if="isOnline" class="grid">
          <DropdownItem
            v-for="preference in workPreferences"
            :key="preference.key"
            preserve-open
          >
            <label
              class="flex flex-grow gap-3 items-center min-w-0"
              :class="
                preference.isLocked
                  ? 'cursor-not-allowed text-n-slate-11'
                  : 'cursor-pointer'
              "
            >
              <Checkbox
                :model-value="preference.value"
                class="[&>input:disabled:checked]:border-n-slate-8 [&>input:disabled:checked]:bg-n-slate-8 [&>input:disabled]:cursor-not-allowed"
                :disabled="preference.isLocked"
                @update:model-value="
                  value => updateWorkPreferences({ [preference.key]: value })
                "
              />
              {{ preference.label }}
              <Icon
                v-tooltip.top="preference.info"
                icon="i-lucide-info"
                class="flex-shrink-0 -ms-1 size-4 text-n-slate-10"
              />
            </label>
          </DropdownItem>
        </div>
        <div
          v-else
          class="px-3 py-2.5 mx-2 mb-1 text-sm rounded-lg border border-dashed border-n-slate-5 text-n-slate-11"
        >
          {{ $t('SIDEBAR.WORK_PAUSED') }}
        </div>
      </template>
      <DropdownSeparator class="my-1" />
      <DropdownItem preserve-open>
        <div class="flex flex-grow gap-3 items-center min-w-0">
          <Icon
            icon="i-lucide-timer-off"
            class="flex-shrink-0 size-4 text-n-slate-11"
          />
          {{ $t('SIDEBAR.SET_AUTO_OFFLINE.TEXT') }}
          <Icon
            v-tooltip.top="$t('SIDEBAR.SET_AUTO_OFFLINE.INFO_SHORT')"
            icon="i-lucide-info"
            class="flex-shrink-0 -ms-1 size-4 text-n-slate-10"
          />
        </div>
        <ToggleSwitch v-model="autoOfflineToggle" />
      </DropdownItem>
    </div>
  </DropdownSection>
</template>
