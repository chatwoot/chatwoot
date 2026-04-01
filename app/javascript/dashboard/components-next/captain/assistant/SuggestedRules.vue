<script setup>
import { useI18n } from 'vue-i18n';
import Button from 'dashboard/components-next/button/Button.vue';

defineProps({
  title: {
    type: String,
    default: '',
  },
  items: {
    type: Array,
    default: () => [],
  },
});

const emit = defineEmits(['add', 'close']);

const { t } = useI18n();

const onAddClick = () => {
  emit('add');
};

const onClickClose = () => {
  emit('close');
};
</script>

<template>
  <div
    class="flex w-full flex-col items-start self-stretch overflow-hidden rounded-xl border border-dashed border-outline-variant/40"
  >
    <div class="flex items-center justify-between w-full gap-3 px-4 pb-1 pt-4">
      <div class="flex items-center gap-3">
        <h5 class="text-sm font-medium text-on-surface-variant">{{ title }}</h5>
        <span class="h-3 w-px bg-outline-variant" />
        <Button
          :label="t('CAPTAIN.ASSISTANTS.GUARDRAILS.ADD.SUGGESTED.ADD')"
          ghost
          xs
          class="!text-sm flex-shrink-0 text-on-surface-variant"
          @click="onAddClick"
        />
      </div>
      <Button
        ghost
        xs
        icon="i-lucide-x"
        class="!text-sm flex-shrink-0 text-on-surface-variant"
        @click="onClickClose"
      />
    </div>
    <div
      class="flex w-full flex-col items-start divide-y divide-dashed divide-outline-variant/40"
    >
      <div v-for="item in items" :key="item.content" class="w-full px-4 py-4">
        <slot :item="item" />
      </div>
    </div>
  </div>
</template>
