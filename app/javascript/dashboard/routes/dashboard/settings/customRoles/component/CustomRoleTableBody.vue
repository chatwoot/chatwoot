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
  <tbody class="divide-y divide-n-weak text-n-slate-11">
    <tr v-for="(customRole, index) in roles" :key="index">
      <td
        class="max-w-xs py-4 ltr:pr-4 rtl:pl-4 font-medium truncate align-baseline"
        :title="customRole.name"
      >
        {{ customRole.name }}
      </td>
      <td
        class="py-4 ltr:pr-4 rtl:pl-4 whitespace-normal align-baseline md:break-words"
      >
        {{ customRole.description }}
      </td>
      <td
        class="py-4 ltr:pr-4 rtl:pl-4 whitespace-normal align-baseline md:break-words"
      >
        {{ getFormattedPermissions(customRole) }}
      </td>
      <td class="flex justify-end gap-1 py-4">
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
