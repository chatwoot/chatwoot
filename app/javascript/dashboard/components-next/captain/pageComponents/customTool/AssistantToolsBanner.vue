<script setup>
import { computed, ref } from 'vue';
import { LocalStorage } from 'shared/helpers/localStorage';
import { LOCAL_STORAGE_KEYS } from 'dashboard/constants/localStorage';

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
  <div
    :class="{ hidden: !showBanner }"
    role="status"
    class="flex items-start gap-3 px-4 py-3 mb-4 text-sm rounded-lg bg-n-blue-2 text-n-blue-11"
  >
    <span class="mt-0.5 i-lucide-info size-4 shrink-0" />
    <p class="flex-1 m-0">
      {{ $t('CAPTAIN.CUSTOM_TOOLS.ASSISTANT_TOOLS_BANNER.MESSAGE') }}
    </p>
    <button
      type="button"
      class="grid rounded-md size-6 shrink-0 place-content-center hover:bg-n-blue-3"
      :aria-label="$t('CAPTAIN.CUSTOM_TOOLS.ASSISTANT_TOOLS_BANNER.DISMISS')"
      @click="dismiss"
    >
      <span class="i-lucide-x size-4" />
    </button>
  </div>
</template>
