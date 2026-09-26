<script setup>
import { useI18n } from 'vue-i18n';
import { isVerifiedOwner } from 'dashboard/api/captain/toolsCatalog';

defineProps({
  toolset: {
    type: Object,
    required: true,
  },
});

const { t } = useI18n();
</script>

<template>
  <div class="flex items-center w-full min-w-0 gap-3">
    <div
      class="flex items-center justify-center overflow-hidden rounded-lg size-10 shrink-0 bg-n-alpha-2"
    >
      <template v-if="toolset.logo_url">
        <img
          :src="toolset.logo_url"
          alt=""
          class="object-contain size-full dark:hidden"
        />
        <img
          :src="toolset.logo_dark_url || toolset.logo_url"
          alt=""
          class="hidden object-contain size-full dark:block"
        />
      </template>
      <i v-else class="i-lucide-blocks size-5 text-n-slate-11" />
    </div>
    <div class="flex flex-col min-w-0">
      <span class="text-sm font-medium truncate text-n-slate-12">
        {{ toolset.name }}
      </span>
      <span class="flex items-center min-w-0 gap-1 text-xs text-n-slate-11">
        <span class="truncate">{{ toolset.owner }}</span>
        <i
          v-if="isVerifiedOwner(toolset.owner)"
          class="i-lucide-badge-check size-3.5 shrink-0 text-n-blue-11"
          :aria-label="t('CAPTAIN.CUSTOM_TOOLS.CATALOG.VERIFIED')"
        />
      </span>
    </div>
  </div>
</template>
