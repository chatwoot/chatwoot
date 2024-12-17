<script setup>
defineProps({
  inbox: {
    type: Object,
    default: () => ({}),
  },
});

defineEmits(['delete']);
</script>

<template>
  <tr class="max-w-full py-1">
    <td
      class="py-4 pr-4 text-sm w-40 max-w-[10rem] truncate"
      :title="inbox.name"
    >
      {{ inbox.name }}
    </td>
    <td class="max-w-lg py-4 pr-4 text-sm truncate" :title="inbox.type">
      {{ inbox.type }}
    </td>
    <td class="flex gap-2 py-4 pr-4 text-sm sm:pr-0 justify-end">
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
