<template>
  <tr>
    <td class="w-40 max-w-[10rem] truncate" :title="app.title">
      {{ app.title }}
    </td>
    <td class="max-w-xs truncate" :title="app.content[0].url">
      {{ app.content[0].url }}
    </td>
    <td class="flex justify-end gap-1">
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

<script>
export default {
  loading: {
    type: Boolean,
    default: false,
  },
  props: {
    app: {
      type: Object,
      default: () => ({}),
    },
  },
};
</script>

<style lang="scss" scoped>
.dashboard-app-label-url {
  @apply relative w-full;
  &:before {
    @apply invisible content-['&nbsp'];
  }
  span {
    @apply absolute left-0 right-0;
  }
}
</style>
