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
      class="py-4 ltr:pr-4 rtl:pl-4 text-sm w-40 max-w-[10rem] truncate"
      :title="app.title"
    >
      {{ app.title }}
    </td>
    <td
      class="max-w-lg py-4 ltr:pr-4 rtl:pl-4 text-sm truncate"
      :title="app.content[0].url"
    >
      {{ app.content[0].url }}
    </td>
    <td class="flex gap-1 py-4 ltr:pr-4 rtl:pl-4 text-sm sm:pr-0 justify-end">
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
