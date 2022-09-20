<template>
  <div class="column content-box">
    <router-link to="macros/new" class="button success button--fixed-right-top">
      <fluent-icon icon="add-circle" />
      <span class="button__content">
        {{ $t('MACROS.HEADER_BTN_TXT') }}
      </span>
    </router-link>
    <div class="row">
      <div class="small-8 columns with-right-space">
        <p
          v-if="!uiFlags.isFetching && !records.length"
          class="no-items-error-message"
        >
          {{ $t('MACROS.LIST.404') }}
        </p>
        <woot-loading-state
          v-if="uiFlags.isFetching"
          :message="$t('MACROS.LOADING')"
        />
        <table class="woot-table">
          <thead>
            <th
              v-for="thHeader in $t('MACROS.LIST.TABLE_HEADER')"
              :key="thHeader"
            >
              {{ thHeader }}
            </th>
          </thead>
          <tbody>
            <tr v-for="(macro, index) in records" :key="index">
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
              <td class="macro-visibility">{{ macro.visibility }}</td>
              <td class="button-wrapper">
                <woot-button
                  v-tooltip.top="$t('MACROS.FORM.EDIT')"
                  variant="smooth"
                  size="tiny"
                  color-scheme="secondary"
                  class-names="grey-btn"
                  icon="edit"
                />
                <woot-button
                  v-tooltip.top="$t('MACROS.FORM.DELETE')"
                  variant="smooth"
                  color-scheme="alert"
                  size="tiny"
                  icon="dismiss-circle"
                  class-names="grey-btn"
                />
              </td>
            </tr>
          </tbody>
        </table>
      </div>
      <div class="small-4 columns">
        <span v-dompurify-html="$t('MACROS.SIDEBAR_TXT')" />
      </div>
    </div>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';

import Thumbnail from 'dashboard/components/widgets/Thumbnail';
export default {
  components: {
    Thumbnail,
  },
  computed: {
    ...mapGetters({
      records: ['macros/getMacros'],
      uiFlags: 'macros/getUIFlags',
    }),
  },
  mounted() {
    this.$store.dispatch('macros/get');
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

.macro-visibility {
  text-transform: capitalize;
}
</style>
