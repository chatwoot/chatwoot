<script setup>
import Icon from 'dashboard/components-next/icon/Icon.vue';
</script>

<template>
  <Icon
    v-tooltip.top="{
      content: $t('CONVERSATION.PIN.PINNED_TOOLTIP'),
      delay: { show: 500, hide: 0 },
    }"
    icon="i-lucide-pin"
    class="size-3.5 text-n-slate-11"
  />
</template>
