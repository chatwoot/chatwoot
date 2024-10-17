<script setup>
import { useI18n } from 'vue-i18n';
import { getI18nKey } from 'dashboard/routes/dashboard/settings/helper/settingsHelper';

defineProps({
  roles: {
    type: Array,
    required: true,
  },
  loading: {
    type: Object,
    default: () => ({}),
  },
});

const emit = defineEmits(['edit', 'delete']);

const { t } = useI18n();

const getFormattedPermissions = role => {
  return role.permissions
    .map(event => t(getI18nKey('CUSTOM_ROLE.PERMISSIONS', event)))
    .join(', ');
};
</script>

<template>
  <tbody
    class="divide-y divide-slate-50 dark:divide-slate-800 text-slate-700 dark:text-slate-300"
  >
    <tr v-for="(customRole, index) in roles" :key="index">
      <td
        class="max-w-xs py-4 pr-4 font-medium truncate align-baseline"
        :title="customRole.name"
      >
        {{ customRole.name }}
      </td>
      <td class="py-4 pr-4 whitespace-normal align-baseline md:break-words">
        {{ customRole.description }}
      </td>
      <td class="py-4 pr-4 whitespace-normal align-baseline md:break-words">
        {{ getFormattedPermissions(customRole) }}
      </td>
      <td class="flex justify-end gap-1 py-4">
        <woot-button
          v-tooltip.top="$t('CUSTOM_ROLE.EDIT.BUTTON_TEXT')"
          variant="smooth"
          size="tiny"
          color-scheme="secondary"
          class-names="grey-btn"
          icon="edit"
          @click="emit('edit', customRole)"
        />
        <woot-button
          v-tooltip.top="$t('CUSTOM_ROLE.DELETE.BUTTON_TEXT')"
          variant="smooth"
          color-scheme="alert"
          size="tiny"
          icon="dismiss-circle"
          class-names="grey-btn"
          :is-loading="loading[customRole.id]"
          @click="emit('delete', customRole)"
        />
      </td>
    </tr>
  </tbody>
</template>
