<template>
  <div class="container">
    <div class="header-wrap">
      <h1 class="page-title">{{ $t('HELP_CENTER.PORTAL.HEADER') }}</h1>
      <woot-button color-scheme="primary" size="small" @click="createPortal">
        {{ $t('HELP_CENTER.PORTAL.NEW_BUTTON') }}
      </woot-button>
    </div>
    <div class="portal-container">
      <portal-list-item
        :portals="portals"
        status="published"
        selected-locale-code="en-US"
      />
      <div v-if="isFetching" class="articles--loader">
        <spinner />
        <span>{{ $t('HELP_CENTER.TABLE.LOADING_MESSAGE') }}</span>
      </div>
      <empty-state
        v-else-if="!isFetching && !portals.length"
        :title="$t('HELP_CENTER.TABLE.NO_ARTICLES')"
      />
    </div>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import PortalListItem from '../../components/PortalListItem';
import Spinner from 'shared/components/Spinner.vue';
import EmptyState from 'dashboard/components/widgets/EmptyState';
export default {
  components: {
    PortalListItem,
    EmptyState,
    Spinner,
  },
  data() {
    return {
      // Dummy data for testing will remove once the state is implemented.
      portals: [
        {
          name: 'Chatwoot Help Center',
          id: 1,
          color: 'red',
          custom_domain: 'help-center.chatwoot.com',
          articles_count: 123,
          header_text: 'Help center',
          homepage_link: null,
          page_title: 'English',
          slug: 'help-center',
          archived: false,
          config: {
            allowed_locales: [
              {
                code: 'en-US',
                name: 'English',
                articles_count: 123,
                categories_count: 42,
              },
              {
                code: 'fr-FR',
                name: 'Français',
                articles_count: 23,
                categories_count: 11,
              },
              {
                code: 'de-DE',
                name: 'Deutsch',
                articles_count: 32,
                categories_count: 12,
              },
              {
                code: 'es-ES',
                name: 'Español',
                articles_count: 12,
                categories_count: 4,
              },
            ],
          },
          locales: [
            {
              code: 'en-US',
              name: 'English',
              articles_count: 123,
              categories_count: 42,
            },
            {
              code: 'fr-FR',
              name: 'Français',
              articles_count: 23,
              categories_count: 11,
            },
            {
              code: 'de-DE',
              name: 'Deutsch',
              articles_count: 32,
              categories_count: 12,
            },
            {
              code: 'es-ES',
              name: 'Español',
              articles_count: 12,
              categories_count: 4,
            },
          ],
        },
        {
          name: 'Chatwoot Docs',
          id: 2,
          color: 'green',
          custom_domain: 'doc-chatwoot.com',
          articles_count: 67,
          header_text: 'Docs',
          homepage_link: null,
          page_title: 'Portal',
          slug: 'second_portal',
          archived: false,
          config: {
            allowed_locales: [
              {
                name: 'English',
                code: 'en-EN',
                articles_count: 12,
                categories_count: 66,
              },
              {
                name: 'Mandarin',
                code: 'ch-CH',
                articles_count: 6,
                categories_count: 23,
              },
            ],
          },
          locales: [
            {
              name: 'English',
              code: 'en-EN',
              articles_count: 12,
              categories_count: 66,
            },
            {
              name: 'Mandarin',
              code: 'ch-CH',
              articles_count: 6,
              categories_count: 23,
            },
          ],
        },
      ],
    };
  },
  computed: {
    ...mapGetters({
      allPortals: 'portals/allPortals',
      isFetching: 'portals/isFetchingPortals',
    }),
  },
  mounted() {
    this.fetchPortals();
  },
  methods: {
    fetchPortals() {
      this.$store.dispatch('portals/index');
    },
    createPortal() {
      this.$emit('create-portal');
    },
  },
};
</script>

<style lang="scss" scoped>
.container {
  padding: var(--space-small) var(--space-normal);
  width: 100%;

  .header-wrap {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin: 0 0 var(--space-small) 0;
    height: var(--space-larger);
  }
  .portal-container {
    height: 90vh;
    overflow-y: scroll;
  }
}
</style>
