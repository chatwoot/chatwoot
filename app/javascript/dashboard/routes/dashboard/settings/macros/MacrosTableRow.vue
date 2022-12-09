<template>
  <tr>
    <td>{{ macro.name }}</td>
    <td>
      <div class="avatar-container">
        <thumbnail :username="macro.created_by.name" size="24px" />
        <span class="ml-2">{{ macro.created_by.name }}</span>
      </div>
    </td>
    <td>
      <div class="avatar-container">
        <thumbnail :username="macro.updated_by.name" size="24px" />
        <span class="ml-2">{{ macro.updated_by.name }}</span>
      </div>
    </td>
    <td>{{ visibilityLabel }}</td>
    <td class="button-wrapper">
      <router-link :to="addAccountScoping(`settings/macros/${macro.id}/edit`)">
        <woot-button
          v-tooltip.top="$t('MACROS.EDIT.TOOLTIP')"
          variant="smooth"
          size="tiny"
          color-scheme="secondary"
          class-names="grey-btn"
          icon="edit"
        />
      </router-link>
      <woot-button
        v-tooltip.top="$t('MACROS.DELETE.TOOLTIP')"
        variant="smooth"
        color-scheme="alert"
        size="tiny"
        icon="dismiss-circle"
        class-names="grey-btn"
        @click="$emit('delete')"
      />
    </td>
  </tr>
</template>

<script>
import Thumbnail from 'dashboard/components/widgets/Thumbnail';
import accountMixin from 'dashboard/mixins/account.js';
export default {
  components: {
    Thumbnail,
  },
  mixins: [accountMixin],
  props: {
    macro: {
      type: Object,
      required: true,
    },
  },
  computed: {
    visibilityLabel() {
      return this.macro.visibility === 'global'
        ? this.$t('MACROS.EDITOR.VISIBILITY.GLOBAL.LABEL')
        : this.$t('MACROS.EDITOR.VISIBILITY.PERSONAL.LABEL');
    },
  },
};
</script>

<style scoped lang="scss">
.avatar-container {
  display: flex;
  align-items: center;

  span {
    margin-left: var(--space-one);
  }
}
</style>
