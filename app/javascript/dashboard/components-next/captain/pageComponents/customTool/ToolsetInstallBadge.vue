<script setup>
import { useI18n } from 'vue-i18n';

defineProps({
  // 'installed' or 'update', from the catalog page's installed toolsets
  status: {
    type: String,
    required: true,
    validator: value => ['installed', 'update'].includes(value),
  },
});

const { t } = useI18n();
</script>

<template>
  <span
    class="inline-flex items-center gap-1 px-1.5 py-0.5 text-xs rounded-md shrink-0"
    :class="
      status === 'update'
        ? 'bg-n-amber-3 text-n-amber-11'
        : 'bg-n-teal-3 text-n-teal-11'
    "
  >
    <i
      :class="
        status === 'update' ? 'i-lucide-arrow-up-circle' : 'i-lucide-check'
      "
      class="size-3"
    />
    {{
      status === 'update'
        ? t('CAPTAIN.CUSTOM_TOOLS.CATALOG.UPDATE_AVAILABLE')
        : t('CAPTAIN.CUSTOM_TOOLS.CATALOG.INSTALLED')
    }}
  </span>
</template>
