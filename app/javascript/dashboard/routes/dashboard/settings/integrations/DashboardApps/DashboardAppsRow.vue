<template>
  <tr>
    <td>
      <p class="dashboard_app-title text-truncate">
        {{ app.title }}
      </p>
    </td>
    <td>
      <p class="dashboard_app-url text-truncate">{{ app.content[0].url }}</p>
    </td>
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

<style lang="scss" scoped>
.dashboard_app-url {
  max-width: calc(var(--space-giga) + var(--space-mega));
}
.dashboard_app-title {
  max-width: calc(var(--space-giga) / var(--space-two));
}
p {
  margin: 0;
}
</style>
