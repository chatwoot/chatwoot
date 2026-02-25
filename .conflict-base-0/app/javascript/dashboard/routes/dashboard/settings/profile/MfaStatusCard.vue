<script setup>
import Button from 'dashboard/components-next/button/Button.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

defineProps({
  mfaEnabled: {
    type: Boolean,
    required: true,
  },
  showSetup: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['enableMfa']);

const startSetup = () => {
  emit('enableMfa');
};
</script>

<template>
  <div v-if="!mfaEnabled && !showSetup" class="space-y-6">
    <div
      class="bg-n-solid-1 rounded-lg p-6 outline outline-n-weak outline-1 text-center"
    >
      <Icon
        icon="i-lucide-lock-keyhole"
        class="size-8 text-n-slate-10 mx-auto mb-4 block"
      />
      <h3 class="text-lg font-medium text-n-slate-12 mb-2">
        {{ $t('MFA_SETTINGS.ENHANCE_SECURITY') }}
      </h3>
      <p class="text-sm text-n-slate-11 mb-6 max-w-md mx-auto">
        {{ $t('MFA_SETTINGS.ENHANCE_SECURITY_DESC') }}
      </p>
      <Button
        icon="i-lucide-settings"
        :label="$t('MFA_SETTINGS.ENABLE_BUTTON')"
        @click="startSetup"
      />
    </div>
  </div>
  <div v-else-if="mfaEnabled && !showSetup">
    <div
      class="bg-n-solid-1 rounded-xl outline-1 outline-n-weak outline p-4 flex-1 flex flex-col gap-2"
    >
      <div class="flex items-center gap-2">
        <Icon
          icon="i-lucide-lock-keyhole"
          class="size-4 flex-shrink-0 text-n-slate-11"
        />
        <h4 class="text-sm font-medium text-n-slate-12">
          {{ $t('MFA_SETTINGS.STATUS_ENABLED') }}
        </h4>
      </div>
      <p class="text-sm text-n-slate-11">
        {{ $t('MFA_SETTINGS.STATUS_ENABLED_DESC') }}
      </p>
    </div>
  </div>
</template>
