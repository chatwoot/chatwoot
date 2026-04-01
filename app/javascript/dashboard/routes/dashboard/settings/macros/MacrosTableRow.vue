<script setup>
import { computed } from 'vue';
import Avatar from 'next/avatar/Avatar.vue';
import { useI18n } from 'vue-i18n';
import Icon from 'dashboard/components-next/icon/Icon.vue';

const props = defineProps({
  macro: {
    type: Object,
    required: true,
  },
});

defineEmits(['delete']);
const { t } = useI18n();

const createdByName = computed(() => {
  const createdBy = props.macro.created_by;
  return createdBy?.available_name ?? createdBy?.email ?? '';
});

const updatedByName = computed(() => {
  const updatedBy = props.macro.updated_by;
  return updatedBy?.available_name ?? updatedBy?.email ?? '';
});

const visibilityLabel = computed(() => {
  const i18nKey =
    props.macro.visibility === 'global'
      ? 'MACROS.EDITOR.VISIBILITY.GLOBAL.LABEL'
      : 'MACROS.EDITOR.VISIBILITY.PERSONAL.LABEL';
  return t(i18nKey);
});
</script>

<template>
  <div
    class="grid grid-cols-12 items-center gap-y-2 px-6 py-4 transition-all duration-200 hover:bg-surface-container-high/40"
  >
    <div class="col-span-3 min-w-0">
      <span class="block truncate text-sm font-bold text-on-surface">
        {{ macro.name }}
      </span>
    </div>
    <div class="col-span-3 min-w-0 text-sm text-on-primary-container">
      <div v-if="macro.created_by" class="flex items-center gap-2">
        <Avatar :name="createdByName" :size="24" rounded-full />
        <span class="truncate">{{ createdByName }}</span>
      </div>
      <span v-else>{{ t('MACROS.LIST.EMPTY_PLACEHOLDER') }}</span>
    </div>
    <div class="col-span-3 min-w-0 text-sm text-on-primary-container">
      <div v-if="macro.updated_by" class="flex items-center gap-2">
        <Avatar :name="updatedByName" :size="24" rounded-full />
        <span class="truncate">{{ updatedByName }}</span>
      </div>
      <span v-else>{{ t('MACROS.LIST.EMPTY_PLACEHOLDER') }}</span>
    </div>
    <div class="col-span-2 text-sm text-on-primary-container">
      {{ visibilityLabel }}
    </div>
    <div class="col-span-1 flex justify-end gap-1">
      <router-link
        v-tooltip.top="t('MACROS.EDIT.TOOLTIP')"
        :to="{ name: 'macros_edit', params: { macroId: macro.id } }"
        class="rounded-lg p-2 text-tertiary opacity-70 outline-none transition-all hover:bg-surface-container-high hover:text-secondary hover:opacity-100 focus-visible:ring-2 focus-visible:ring-secondary/40"
      >
        <Icon icon="i-lucide-pen" class="size-5" />
      </router-link>
      <button
        v-tooltip.top="t('MACROS.DELETE.TOOLTIP')"
        type="button"
        class="rounded-lg p-2 text-tertiary opacity-70 outline-none transition-all hover:bg-surface-container-high hover:text-error hover:opacity-100 focus-visible:ring-2 focus-visible:ring-error/40"
        @click="$emit('delete')"
      >
        <Icon icon="i-lucide-trash-2" class="size-5" />
      </button>
    </div>
  </div>
</template>
