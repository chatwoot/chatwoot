<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useMapGetter } from 'dashboard/composables/store';
import { vOnClickOutside } from '@vueuse/components';

import NextButton from 'dashboard/components-next/button/Button.vue';
import Input from 'dashboard/components-next/input/Input.vue';

const emit = defineEmits(['close', 'assign']);

const { t } = useI18n();

const labels = useMapGetter('labels/getLabels');

const query = ref('');
const selectedLabels = ref([]);

const filteredLabels = computed(() => {
  if (!query.value) return labels.value;
  return labels.value.filter(label =>
    label.title.toLowerCase().includes(query.value.toLowerCase())
  );
});

const hasLabels = computed(() => labels.value.length > 0);
const hasFilteredLabels = computed(() => filteredLabels.value.length > 0);

const isLabelSelected = label => {
  return selectedLabels.value.includes(label);
};

const onClose = () => {
  emit('close');
};

const handleAssign = () => {
  if (selectedLabels.value.length > 0) {
    emit('assign', selectedLabels.value);
  }
};
</script>

<template>
  <div
    v-on-click-outside="onClose"
    class="absolute ltr:right-2 rtl:left-2 top-12 origin-top-right z-20 w-60 bg-n-alpha-3 backdrop-blur-[100px] border-n-weak rounded-lg border border-solid shadow-md"
    role="dialog"
    aria-labelledby="label-dialog-title"
  >
    <div class="triangle">
      <svg height="12" viewBox="0 0 24 12" width="24">
        <path d="M20 12l-8-8-12 12" fill-rule="evenodd" stroke-width="1px" />
      </svg>
    </div>
    <div class="flex items-center justify-between p-2.5">
      <span class="text-sm font-medium">{{
        t('BULK_ACTION.LABELS.ASSIGN_LABELS')
      }}</span>
      <NextButton ghost xs slate icon="i-lucide-x" @click="onClose" />
    </div>
    <div class="flex flex-col max-h-60 min-h-0">
      <header class="py-2 px-2.5">
        <Input
          v-model="query"
          type="search"
          :placeholder="t('BULK_ACTION.SEARCH_INPUT_PLACEHOLDER')"
          icon-left="i-lucide-search"
          size="sm"
          class="w-full"
          :aria-label="t('BULK_ACTION.SEARCH_INPUT_PLACEHOLDER')"
        />
      </header>
      <ul
        v-if="hasLabels"
        class="flex-1 overflow-y-auto m-0 list-none"
        role="listbox"
        :aria-label="t('BULK_ACTION.LABELS.ASSIGN_LABELS')"
      >
        <li v-if="!hasFilteredLabels" class="p-2 text-center">
          <span class="text-sm text-n-slate-11">{{
            t('BULK_ACTION.LABELS.NO_LABELS_FOUND')
          }}</span>
        </li>
        <li
          v-for="label in filteredLabels"
          :key="label.id"
          class="my-1 mx-0 py-0 px-2.5"
          role="option"
          :aria-selected="isLabelSelected(label.title)"
        >
          <label
            class="items-center rounded-md cursor-pointer flex py-1 px-2.5 hover:bg-n-slate-3 dark:hover:bg-n-solid-3 has-[:checked]:bg-n-slate-2"
          >
            <input
              v-model="selectedLabels"
              type="checkbox"
              :value="label.title"
              class="my-0 ltr:mr-2.5 rtl:ml-2.5"
              :aria-label="label.title"
            />
            <span
              class="overflow-hidden flex-grow w-full text-sm whitespace-nowrap text-ellipsis"
            >
              {{ label.title }}
            </span>
            <span
              class="rounded-md h-3 w-3 flex-shrink-0 border border-solid border-n-weak"
              :style="{ backgroundColor: label.color }"
            />
          </label>
        </li>
      </ul>
      <div v-else class="p-2 text-center">
        <span class="text-sm text-n-slate-11">{{
          t('CONTACTS_BULK_ACTIONS.NO_LABELS_FOUND')
        }}</span>
      </div>
      <footer class="p-2">
        <NextButton
          sm
          type="submit"
          class="w-full"
          :label="t('BULK_ACTION.LABELS.ASSIGN_SELECTED_LABELS')"
          :disabled="!selectedLabels.length"
          @click="handleAssign"
        />
      </footer>
    </div>
  </div>
</template>

<style scoped lang="scss">
.triangle {
  @apply block z-10 absolute text-left -top-3 ltr:right-[--triangle-position] rtl:left-[--triangle-position];

  svg path {
    @apply fill-n-alpha-3 backdrop-blur-[100px]  stroke-n-weak;
  }
}
</style>
