<template>
  <tr>
    <td>{{ app.title }}</td>
    <td>{{ app.content[0].url }}</td>
    <td class="button-wrapper">
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
  props: {
    app: {
      type: Object,
      default: () => ({}),
    },
  },
  loading: {
    type: Boolean,
    default: false,
  },
};
</script>
