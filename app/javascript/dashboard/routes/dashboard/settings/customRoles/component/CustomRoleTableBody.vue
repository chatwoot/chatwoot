<script setup>
import { useI18n } from 'vue-i18n';
import { getI18nKey } from 'dashboard/routes/dashboard/settings/helper/settingsHelper';

import Button from 'dashboard/components-next/button/Button.vue';

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
    class="divide-y divide-surface-container-high/30 text-on-surface-variant [&>tr]:transition-colors [&>tr]:duration-150 [&>tr]:hover:bg-surface-container-high/20"
  >
    <tr v-for="customRole in roles" :key="customRole.id">
      <td
        class="max-w-xs px-6 py-4 text-sm font-medium text-on-surface truncate align-baseline"
        :title="customRole.name"
      >
        {{ customRole.name }}
      </td>
      <td
        class="px-6 py-4 text-sm align-baseline whitespace-normal md:break-words"
      >
        {{ customRole.description }}
      </td>
      <td
        class="px-6 py-4 text-sm align-baseline whitespace-normal md:break-words"
      >
        {{ getFormattedPermissions(customRole) }}
      </td>
      <td class="flex justify-end gap-1 px-6 py-4">
        <Button
          v-tooltip.top="$t('CUSTOM_ROLE.EDIT.BUTTON_TEXT')"
          icon="i-lucide-pen"
          slate
          xs
          faded
          @click="emit('edit', customRole)"
        />
        <Button
          v-tooltip.top="$t('CUSTOM_ROLE.DELETE.BUTTON_TEXT')"
          icon="i-lucide-trash-2"
          xs
          ruby
          faded
          :is-loading="loading[customRole.id]"
          @click="emit('delete', customRole)"
        />
      </td>
    </tr>
  </tbody>
</template>
