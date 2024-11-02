<script setup>
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
      class="py-4 pr-4 text-sm w-40 max-w-[10rem] truncate"
      :title="app.title"
    >
      {{ app.title }}
    </td>
    <td class="max-w-lg py-4 pr-4 text-sm truncate" :title="app.content[0].url">
      {{ app.content[0].url }}
    </td>
    <td class="flex gap-1 py-4 pr-4 text-sm sm:pr-0 justify-end">
      <woot-button
        v-tooltip.top="
          $t('INTEGRATION_SETTINGS.DASHBOARD_APPS.LIST.EDIT_TOOLTIP')
        "
        variant="smooth"
        size="tiny"
        color-scheme="secondary"
        class-names="grey-btn"
        icon="edit"
        @click="$emit('edit', app)"
      />
      <woot-button
        v-tooltip.top="
          $t('INTEGRATION_SETTINGS.DASHBOARD_APPS.LIST.DELETE_TOOLTIP')
        "
        variant="smooth"
        color-scheme="alert"
        size="tiny"
        icon="dismiss-circle"
        class-names="grey-btn"
        @click="$emit('delete', app)"
      />
    </td>
  </tr>
</template>
