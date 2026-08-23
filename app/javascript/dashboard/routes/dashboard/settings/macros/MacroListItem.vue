<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';

import Button from 'dashboard/components-next/button/Button.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import SettingsListItem from '../components/SettingsListItem.vue';

const props = defineProps({
  macro: {
    type: Object,
    required: true,
  },
  canManagePublicMacros: {
    type: Boolean,
    default: true,
  },
  isDuplicating: {
    type: Boolean,
    default: false,
  },
});

defineEmits(['delete', 'duplicate']);

const { t } = useI18n();

const createdByName = computed(() => {
  const createdBy = props.macro.created_by;
  if (!createdBy) return '';
  return createdBy.available_name ?? createdBy.email ?? '';
});

const categoryLabel = computed(() => {
  const folder = (props.macro.folder || '').trim();
  return folder || t('MACROS.UNCATEGORIZED');
});

const visibilityLabel = computed(() => {
  const i18nKey =
    props.macro.visibility === 'global'
      ? 'MACROS.EDITOR.VISIBILITY.GLOBAL.LABEL'
      : 'MACROS.EDITOR.VISIBILITY.PERSONAL.LABEL';
  return t(i18nKey);
});

const canManageMacro = computed(
  () => props.canManagePublicMacros || props.macro.visibility !== 'global'
);

const editTooltip = computed(() =>
  canManageMacro.value ? t('MACROS.EDIT.TOOLTIP') : t('MACROS.VIEW.TOOLTIP')
);

const metaItems = computed(() =>
  [categoryLabel.value, createdByName.value].filter(Boolean)
);
</script>

<template>
  <SettingsListItem :title="macro.name" :meta="metaItems">
    <template #icon>
      <Icon icon="i-lucide-zap" class="size-5 text-n-slate-11" />
    </template>
    <template #badges>
      <span
        class="inline-flex shrink-0 px-2 py-0.5 text-xs font-medium rounded-md bg-n-alpha-1 text-n-slate-11"
      >
        {{ visibilityLabel }}
      </span>
    </template>
    <template #actions>
      <Button
        v-tooltip.top="$t('MACROS.DUPLICATE.TOOLTIP')"
        icon="i-woot-clone"
        slate
        sm
        :is-loading="isDuplicating"
        @click="$emit('duplicate')"
      />
      <router-link :to="{ name: 'macros_edit', params: { macroId: macro.id } }">
        <Button v-tooltip.top="editTooltip" icon="i-woot-edit-pen" slate sm />
      </router-link>
      <Button
        v-if="canManageMacro"
        v-tooltip.top="$t('MACROS.DELETE.TOOLTIP')"
        icon="i-woot-bin"
        slate
        sm
        class="hover:enabled:text-n-ruby-11 hover:enabled:bg-n-ruby-2"
        @click="$emit('delete')"
      />
    </template>
  </SettingsListItem>
</template>
