<script setup>
import { useRouter } from 'vue-router';
import Button from 'dashboard/components-next/button/Button.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

defineProps({
  controlItem: {
    type: Object,
    default: () => ({}),
  },
});

const router = useRouter();

const onClick = name => {
  router.push({ name });
};
</script>

<template>
  <div
    :key="controlItem.name"
    class="flex w-full cursor-pointer flex-col gap-3 rounded-xl border border-outline-variant/10 bg-surface-container-low p-4 shadow-sm transition-all duration-200 hover:border-secondary/30 hover:bg-surface-container hover:shadow-md"
    @click="onClick(controlItem.routeName)"
  >
    <div class="flex h-8 w-full items-center justify-between gap-2">
      <span class="flex min-w-0 items-center gap-2">
        <Icon
          v-if="controlItem.icon"
          :icon="controlItem.icon"
          class="size-4 shrink-0 text-secondary"
        />
        <span class="line-clamp-1 text-sm font-semibold text-on-surface">
          {{ controlItem.name }}
        </span>
      </span>
      <div class="flex items-center gap-2">
        <Button
          icon="i-lucide-chevron-right"
          faded
          teal
          xs
          @click="onClick(controlItem.routeName)"
        />
      </div>
    </div>
    <span class="line-clamp-4 text-sm leading-[1.45] text-on-surface-variant">
      {{ controlItem.description }}
    </span>
  </div>
</template>
