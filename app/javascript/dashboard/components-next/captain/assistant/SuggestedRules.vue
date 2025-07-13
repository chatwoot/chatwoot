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

const emit = defineEmits(['add']);

const { t } = useI18n();

const onAddClick = () => {
  emit('add');
};
</script>

<template>
  <div
    class="flex flex-col items-start self-stretch rounded-xl w-full overflow-hidden border border-dashed border-n-strong"
  >
    <div class="flex items-center gap-3 px-4 pb-1 pt-4">
      <h5 class="text-sm font-medium text-n-slate-11">{{ title }}</h5>
      <span class="h-3 w-px bg-n-weak" />
      <Button
        :label="t('CAPTAIN.ASSISTANTS.GUARDRAILS.ADD.SUGGESTED.ADD')"
        ghost
        xs
        slate
        class="!text-sm !text-n-slate-11 flex-shrink-0"
        @click="onAddClick"
      />
    </div>
    <div
      class="flex flex-col items-start divide-y divide-n-strong divide-dashed w-full"
    >
      <div
        v-for="item in items"
        :key="item.content"
        class="w-full px-4 py-4 flex items-center justify-between"
      >
        <slot :item="item" />
      </div>
    </div>
  </div>
</template>
