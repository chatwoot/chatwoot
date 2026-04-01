<script setup>
import Button from 'dashboard/components-next/button/Button.vue';

defineProps({
  app: {
    type: Object,
    default: () => ({}),
  },
});

defineEmits(['edit', 'delete']);
</script>

<template>
  <tr class="max-w-full py-1">
    <td
      class="px-6 py-4 text-sm w-40 max-w-[10rem] truncate ltr:pr-4 rtl:pl-4"
      :title="app.title"
    >
      {{ app.title }}
    </td>
    <td
      class="max-w-lg px-6 py-4 text-sm truncate ltr:pr-4 rtl:pl-4"
      :title="app.content[0].url"
    >
      {{ app.content[0].url }}
    </td>
    <td
      class="flex justify-end gap-1 px-6 py-4 text-sm ltr:pr-4 rtl:pl-4 sm:pr-0"
    >
      <Button
        v-tooltip.top="
          $t('INTEGRATION_SETTINGS.DASHBOARD_APPS.LIST.EDIT_TOOLTIP')
        "
        icon="i-lucide-pen"
        slate
        xs
        faded
        @click="$emit('edit', app)"
      />
      <Button
        v-tooltip.top="
          $t('INTEGRATION_SETTINGS.DASHBOARD_APPS.LIST.DELETE_TOOLTIP')
        "
        icon="i-lucide-trash-2"
        xs
        ruby
        faded
        @click="$emit('delete', app)"
      />
    </td>
  </tr>
</template>
