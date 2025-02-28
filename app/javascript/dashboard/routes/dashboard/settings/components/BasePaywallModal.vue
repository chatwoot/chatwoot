<script setup>
import Icon from 'next/icon/Icon.vue';
import ButtonV4 from 'next/button/Button.vue';

defineProps({
  featurePrefix: {
    type: String,
    required: true,
  },
  i18nKey: {
    type: String,
    required: true,
  },
  isOnChatwootCloud: {
    type: Boolean,
    default: false,
  },
  isSuperAdmin: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['upgrade']);
</script>

<template>
  <div
    class="flex flex-col max-w-md px-6 py-6 border shadow bg-n-solid-1 rounded-xl border-n-weak"
  >
    <div class="flex items-center w-full gap-2 mb-4">
      <span
        class="flex items-center justify-center w-6 h-6 rounded-full bg-n-solid-blue"
      >
        <Icon
          class="flex-shrink-0 text-n-brand size-[14px]"
          icon="i-lucide-lock-keyhole"
        />
      </span>
      <span class="text-base font-medium text-n-slate-12">
        {{ $t(`${featurePrefix}.PAYWALL.TITLE`) }}
      </span>
    </div>
    <p
      v-dompurify-html="$t(`${featurePrefix}.${i18nKey}.AVAILABLE_ON`)"
      class="text-sm font-normal text-n-slate-11"
    />
    <p class="text-sm font-normal text-n-slate-11">
      {{ $t(`${featurePrefix}.${i18nKey}.UPGRADE_PROMPT`) }}
      <span v-if="!isOnChatwootCloud && !isSuperAdmin">
        {{ $t(`${featurePrefix}.ENTERPRISE_PAYWALL.ASK_ADMIN`) }}
      </span>
    </p>
    <template v-if="isOnChatwootCloud">
      <ButtonV4 blue solid md @click="emit('upgrade')">
        {{ $t(`${featurePrefix}.PAYWALL.UPGRADE_NOW`) }}
      </ButtonV4>
      <span class="mt-2 text-xs tracking-tight text-center text-n-slate-11">
        {{ $t(`${featurePrefix}.PAYWALL.CANCEL_ANYTIME`) }}
      </span>
    </template>
    <template v-else-if="isSuperAdmin">
      <a href="/super_admin" class="block w-full">
        <ButtonV4 solid blue md class="w-full">
          {{ $t(`${featurePrefix}.PAYWALL.UPGRADE_NOW`) }}
        </ButtonV4>
      </a>
    </template>
  </div>
</template>
