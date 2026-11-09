<script setup>
import { computed, ref, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useOrderedMacros } from 'dashboard/composables/useOrderedMacros';
import { useMacros } from 'dashboard/composables/useMacros';
import CaretAnchoredPicker from 'dashboard/components-next/preview-picker/CaretAnchoredPicker.vue';

const props = defineProps({
  caretPosition: {
    type: Object,
    default: null,
  },
  searchKey: {
    type: String,
    default: '',
  },
});

const emit = defineEmits(['selectMacro', 'close', 'removeTrigger']);

const store = useStore();
const { t } = useI18n();

const { orderedMacros } = useOrderedMacros();
const { resolveMacroActions } = useMacros();

const uiFlags = useMapGetter('macros/getUIFlags');

// The trigger can already be followed by text, from a draft or a caret moved back onto it
const searchQuery = ref(props.searchKey);

const searchTerm = computed(() => searchQuery.value.trim().toLowerCase());

const items = computed(() =>
  orderedMacros.value
    .filter(macro => macro.name?.toLowerCase().includes(searchTerm.value))
    .map(macro => ({
      id: macro.id,
      macro,
      label: macro.name,
      title: macro.name,
      subtitle: t('CONVERSATION.PICKER.MACRO.ACTION_COUNT', {
        count: macro.actions.length,
      }),
    }))
);

const onSelect = item => emit('selectMacro', item.macro);

onMounted(() => {
  if (!orderedMacros.value.length) store.dispatch('macros/get');
});
</script>

<template>
  <CaretAnchoredPicker
    v-model:search="searchQuery"
    :caret-position="caretPosition"
    :items="items"
    :search-placeholder="t('CONVERSATION.PICKER.MACRO.SEARCH_PLACEHOLDER')"
    :is-loading="uiFlags.isFetching"
    :empty-label="t('COMBOBOX.EMPTY_STATE')"
    @select="onSelect"
    @close="emit('close')"
    @remove-trigger="emit('removeTrigger')"
  >
    <template #preview="{ item }">
      <div v-if="item" class="px-4 py-3">
        <div
          v-for="(action, index) in resolveMacroActions(item.macro)"
          :key="index"
          class="relative flex flex-col pb-2 group ps-4 last:pb-0 gap-0.5"
        >
          <span
            class="absolute top-1 -bottom-1 w-px start-[3.5px] bg-n-slate-6 group-last:hidden"
          />
          <span
            class="absolute border-2 rounded-full top-1 start-0 size-2 bg-n-solid-1 border-n-weak dark:border-n-slate-6"
          />
          <span class="text-xs text-n-slate-10">
            {{ t(`MACROS.ACTIONS.${action.actionName}`) }}
          </span>
          <span
            v-if="action.actionValue"
            class="text-sm break-words text-n-slate-12"
          >
            {{ action.actionValue }}
          </span>
        </div>
      </div>
    </template>
  </CaretAnchoredPicker>
</template>
