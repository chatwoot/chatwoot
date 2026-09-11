<script setup>
import { computed, ref } from 'vue';
import { LocalStorage } from 'shared/helpers/localStorage';
import { LOCAL_STORAGE_KEYS } from 'dashboard/constants/localStorage';
import Banner from 'dashboard/components-next/banner/Banner.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';

// TODO: Remove this banner and its translation/storage key after October 31, 2026.
const BANNER_EXPIRES_AT = new Date(2026, 10, 1).getTime();
const dismissed = ref(
  LocalStorage.get(LOCAL_STORAGE_KEYS.CAPTAIN_ASSISTANT_TOOLS_BANNER_DISMISSED)
);
const dialogRef = ref(null);
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

const openLearnMore = () => dialogRef.value?.open();

const acknowledge = () => {
  dismiss();
  dialogRef.value?.close();
};
</script>

<template>
  <Banner :class="{ hidden: !showBanner }" color="blue" class="mb-4">
    {{ $t('CAPTAIN.CUSTOM_TOOLS.ASSISTANT_TOOLS_BANNER.MESSAGE') }}
    <template #actions>
      <div class="flex items-center gap-1">
        <Button
          :label="$t('CAPTAIN.CUSTOM_TOOLS.ASSISTANT_TOOLS_BANNER.LEARN_MORE')"
          variant="faded"
          color="blue"
          size="xs"
          @click="openLearnMore"
        />
        <Button
          v-tooltip.top="
            $t('CAPTAIN.CUSTOM_TOOLS.ASSISTANT_TOOLS_BANNER.DISMISS')
          "
          :aria-label="
            $t('CAPTAIN.CUSTOM_TOOLS.ASSISTANT_TOOLS_BANNER.DISMISS')
          "
          icon="i-lucide-x"
          variant="ghost"
          color="blue"
          size="xs"
          @click="dismiss"
        />
      </div>
    </template>
  </Banner>

  <Dialog
    ref="dialogRef"
    width="md"
    :title="$t('CAPTAIN.CUSTOM_TOOLS.ASSISTANT_TOOLS_BANNER.MODAL_TITLE')"
    :confirm-button-label="
      $t('CAPTAIN.CUSTOM_TOOLS.ASSISTANT_TOOLS_BANNER.ACKNOWLEDGE')
    "
    :show-cancel-button="false"
    @confirm="acknowledge"
  >
    <template #description>
      <div class="flex flex-col gap-2 text-sm text-n-slate-11">
        <p class="mb-0">
          {{
            $t('CAPTAIN.CUSTOM_TOOLS.ASSISTANT_TOOLS_BANNER.MODAL_DESCRIPTION')
          }}
        </p>
        <p class="mb-0">
          {{
            $t('CAPTAIN.CUSTOM_TOOLS.ASSISTANT_TOOLS_BANNER.MODAL_INSTRUCTIONS')
          }}
        </p>
      </div>
    </template>
  </Dialog>
</template>
