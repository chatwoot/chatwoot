<template>
  <div class="w-full max-w-full px-4 py-2">
    <div class="flex items-center justify-between h-12 mx-0 mt-0 mb-2">
      <div class="flex items-center">
        <woot-sidemenu-icon />
        <h1
          class="mx-2 my-0 text-2xl font-medium text-slate-800 dark:text-slate-100"
        >
          {{ $t('HELP_CENTER.PORTAL.HEADER') }}
        </h1>
      </div>
      <woot-button
        color-scheme="primary"
        icon="add"
        size="small"
        @click="addPortal"
      >
        {{ $t('HELP_CENTER.PORTAL.NEW_BUTTON') }}
      </woot-button>
    </div>
    <div class="h-[90vh] overflow-y-scroll">
      <portal-list-item
        v-for="portal in portals"
        :key="portal.id"
        :portal="portal"
        :status="portalStatus"
        @add-locale="addLocale"
        @open-site="openPortal"
      />
      <div
        v-if="isFetching"
        class="flex items-center justify-center p-40 text-base"
      >
        <spinner />
        <span>{{ $t('HELP_CENTER.PORTAL.LOADING_MESSAGE') }}</span>
      </div>
      <empty-state
        v-else-if="shouldShowEmptyState"
        :title="$t('HELP_CENTER.PORTAL.NO_PORTALS_MESSAGE')"
      />
    </div>
    <woot-modal
      :show.sync="isAddLocaleModalOpen"
      :on-close="closeAddLocaleModal"
    >
      <add-locale
        :show="isAddLocaleModalOpen"
        :portal="selectedPortal"
        @cancel="closeAddLocaleModal"
      />
    </woot-modal>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import PortalListItem from '../../components/PortalListItem.vue';
import Spinner from 'shared/components/Spinner.vue';
import EmptyState from 'dashboard/components/widgets/EmptyState.vue';
import AddLocale from '../../components/AddLocale.vue';
import { buildPortalURL } from 'dashboard/helper/portalHelper';

export default {
  components: {
    PortalListItem,
    EmptyState,
    Spinner,
    AddLocale,
  },
  data() {
    return {
      isAddLocaleModalOpen: false,
      selectedPortal: {},
    };
  },
  computed: {
    ...mapGetters({
      portals: 'portals/allPortals',
      meta: 'portals/getMeta',
      isFetching: 'portals/isFetchingPortals',
    }),
    portalStatus() {
      return this.archived ? 'Archived' : 'Live';
    },
    shouldShowEmptyState() {
      return !this.isFetching && !this.portals.length;
    },
  },
  methods: {
    openPortal(portalSlug) {
      window.open(buildPortalURL(portalSlug), '_blank');
    },
    addPortal() {
      this.$router.push({ name: 'new_portal_information' });
    },
    closeAddLocaleModal() {
      this.isAddLocaleModalOpen = false;
      this.selectedPortal = {};
    },
    addLocale(portalId) {
      this.isAddLocaleModalOpen = true;
      this.selectedPortal = this.portals.find(portal => portal.id === portalId);
    },
  },
};
</script>
