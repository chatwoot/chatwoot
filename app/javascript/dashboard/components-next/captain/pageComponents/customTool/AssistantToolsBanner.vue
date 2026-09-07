<script setup>
import { computed, ref } from 'vue';
import { LocalStorage } from 'shared/helpers/localStorage';
import { LOCAL_STORAGE_KEYS } from 'dashboard/constants/localStorage';
import Banner from 'dashboard/components-next/banner/Banner.vue';

// TODO: Remove this banner and its translation/storage key after September 30, 2026.
const BANNER_EXPIRES_AT = new Date(2026, 9, 1).getTime();
const dismissed = ref(
  LocalStorage.get(LOCAL_STORAGE_KEYS.CAPTAIN_ASSISTANT_TOOLS_BANNER_DISMISSED)
);
const showBanner = computed(
  () => !dismissed.value && Date.now() < BANNER_EXPIRES_AT
);

const dismiss = () => {
  LocalStorage.set(
    LOCAL_STORAGE_KEYS.CAPTAIN_ASSISTANT_TOOLS_BANNER_DISMISSED,
    true
  );
  dismissed.value = true;
};
</script>

<template>
  <Banner
    :class="{ hidden: !showBanner }"
    color="blue"
    :action-label="$t('CAPTAIN.CUSTOM_TOOLS.ASSISTANT_TOOLS_BANNER.DISMISS')"
    class="mb-4"
    @action="dismiss"
  >
    {{ $t('CAPTAIN.CUSTOM_TOOLS.ASSISTANT_TOOLS_BANNER.MESSAGE') }}
  </Banner>
</template>
