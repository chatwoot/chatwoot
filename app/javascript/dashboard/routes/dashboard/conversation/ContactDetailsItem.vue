<script setup>
import Icon from 'dashboard/components-next/icon/Icon.vue';

defineProps({
  title: { type: String, default: '' },
  icon: { type: String, default: '' },
  value: { type: [String, Number], default: '' },
});
</script>

<template>
  <div class="flex items-start gap-2 py-2 min-h-9">
    <Icon
      v-if="icon"
      v-tooltip.top="{
        content: title,
        delay: { show: 500, hide: 0 },
      }"
      :icon="icon"
      class="text-n-slate-11 size-4 flex-shrink-0 mt-0.5"
    />
    <div v-if="value" class="break-words text-body-main">
      <slot>
        {{ value }}
      </slot>
    </div>
  </div>
</template>
