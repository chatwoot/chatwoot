<!--
 * Preserves RTL/LTR context when teleporting content
 * Ensures direction-specific classes (ltr:tailwind-class, rtl:tailwind-class) work correctly
 * when content is teleported outside the app's container with [dir] attribute
-->
<script setup>
import { computed } from 'vue';
import { useMapGetter } from 'dashboard/composables/store';

defineProps({
  to: {
    type: String,
    default: 'body',
  },
});

const isRTL = useMapGetter('accounts/isRTL');

const contentDirection = computed(() => (isRTL.value ? 'rtl' : 'ltr'));
</script>

<template>
  <Teleport :to="to">
    <div :dir="contentDirection">
      <slot />
    </div>
  </Teleport>
</template>
