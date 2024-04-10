<template>
  <table>
    <thead>
      <tr>
        <th scope="col">
          {{
            $t(
              'HELP_CENTER.PORTAL.PORTAL_SETTINGS.LIST_ITEM.AVAILABLE_LOCALES.TABLE.NAME'
            )
          }}
        </th>
        <th scope="col">
          {{
            $t(
              'HELP_CENTER.PORTAL.PORTAL_SETTINGS.LIST_ITEM.AVAILABLE_LOCALES.TABLE.CODE'
            )
          }}
        </th>
        <th scope="col">
          {{
            $t(
              'HELP_CENTER.PORTAL.PORTAL_SETTINGS.LIST_ITEM.AVAILABLE_LOCALES.TABLE.ARTICLE_COUNT'
            )
          }}
        </th>
        <th scope="col">
          {{
            $t(
              'HELP_CENTER.PORTAL.PORTAL_SETTINGS.LIST_ITEM.AVAILABLE_LOCALES.TABLE.CATEGORIES'
            )
          }}
        </th>
        <th scope="col" />
      </tr>
    </thead>
    <tr>
      <td colspan="100%" class="horizontal-line" />
    </tr>
    <tbody>
      <tr v-for="locale in locales" :key="locale.code">
        <td>
          <span>{{ localeName(locale.code) }}</span>
          <woot-label
            v-if="locale.code === selectedLocaleCode"
            :title="
              $t(
                'HELP_CENTER.PORTAL.PORTAL_SETTINGS.LIST_ITEM.AVAILABLE_LOCALES.TABLE.DEFAULT_LOCALE'
              )
            "
            color-scheme="warning"
            :small="true"
            variant="smooth"
            class="default-status"
          />
        </td>
        <td>
          <span>{{ locale.code }}</span>
        </td>
        <td>
          <span>{{ locale.articles_count }}</span>
        </td>
        <td>
          <span>{{ locale.categories_count }}</span>
        </td>
        <td>
          <woot-button
            v-tooltip.top-end="
              $t(
                'HELP_CENTER.PORTAL.PORTAL_SETTINGS.LIST_ITEM.AVAILABLE_LOCALES.TABLE.SWAP'
              )
            "
            size="tiny"
            variant="smooth"
            icon="arrow-swap"
            color-scheme="primary"
            :disabled="locale.code === selectedLocaleCode"
            @click="changeDefaultLocale(locale.code)"
          />
          <woot-button
            v-tooltip.top-end="
              $t(
                'HELP_CENTER.PORTAL.PORTAL_SETTINGS.LIST_ITEM.AVAILABLE_LOCALES.TABLE.DELETE'
              )
            "
            size="tiny"
            variant="smooth"
            icon="delete"
            color-scheme="alert"
            :disabled="locale.code === selectedLocaleCode"
            @click="deleteLocale(locale.code)"
          />
        </td>
      </tr>
    </tbody>
  </table>
</template>

<script>
import portalMixin from '../mixins/portalMixin';
export default {
  mixins: [portalMixin],
  props: {
    locales: {
      type: Array,
      default: () => [],
    },
    selectedLocaleCode: {
      type: String,
      default: '',
    },
  },

  methods: {
    changeDefaultLocale(localeCode) {
      this.$emit('change-default-locale', { localeCode });
    },
    deleteLocale(localeCode) {
      this.$emit('delete', { localeCode });
    },
  },
};
</script>

<style lang="scss" scoped>
table {
  thead tr th {
    @apply text-sm font-medium normal-case text-slate-600 dark:text-slate-200 pl-0 rtl:pl-2.5 rtl:pr-0 pt-0;
  }

  tbody tr {
    @apply border-b-0;
    td {
      @apply text-sm pl-0 rtl:pl-2.5 rtl:pr-0;
      .default-status {
        @apply py-0 pr-0 pl-1;
      }
      span {
        @apply text-slate-700 dark:text-slate-200;
      }
    }
  }
}
.horizontal-line {
  @apply border-b border-solid border-slate-75 dark:border-slate-700;
}
</style>
