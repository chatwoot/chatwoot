<template>
  <tr>
    <td>
      <woot-button
        variant="clear"
        color-scheme="secondary"
        @click="navigateToPortalArticles"
      >
        <div class="flex items-center gap-2 -mx-1">
          <thumbnail :username="portal.name" variant="square" size="24px" />
          {{ portal.name }}
        </div>
      </woot-button>
    </td>
    <td class="w-20">
      <div class="flex items-center">
        <woot-label
          :title="status"
          :color-scheme="labelColor"
          size="small"
          variant="smooth"
          class="mx-0 !mb-0"
        />
      </div>
    </td>
    <td>
      {{ portal.slug }}
    </td>
    <td class="">
      {{ portal.domain || '--' }}
    </td>
    <td>
      {{ locales.length }}
    </td>
    <td class="">
      {{ articleCount }}
      {{
        $t('HELP_CENTER.PORTAL.PORTAL_SETTINGS.LIST_ITEM.HEADER.COUNT_LABEL')
      }}
    </td>
    <!-- Action Buttons -->
    <td>
      <div class="flex items-center justify-end gap-1">
        <woot-button
          variant="hollow"
          color-scheme="secondary"
          size="small"
          @click="navigateToPortalArticles"
        >
          {{ $t('HELP_CENTER.PORTAL.PORTAL_SETTINGS.LIST_ITEM.HEADER.SWITCH') }}
        </woot-button>
        <woot-button
          v-tooltip.top-end="
            $t(
              'HELP_CENTER.PORTAL.PORTAL_SETTINGS.LIST_ITEM.HEADER.PUBLIC_PORTAL'
            )
          "
          variant="smooth"
          size="small"
          icon="open"
          @click="navigateToPublicPortal"
        />
        <woot-button
          v-tooltip.top-end="
            $t('HELP_CENTER.PORTAL.PORTAL_SETTINGS.LIST_ITEM.HEADER.SETTINGS')
          "
          variant="smooth"
          size="small"
          color-scheme="secondary"
          icon="edit"
          @click="openSettings"
        />
        <woot-button
          v-tooltip.top-end="
            $t('HELP_CENTER.PORTAL.PORTAL_SETTINGS.LIST_ITEM.HEADER.DELETE')
          "
          variant="smooth"
          color-scheme="alert"
          size="small"
          icon="dismiss-circle"
          @click="onClickOpenDeleteModal(portal)"
        />
        <woot-delete-modal
          :show.sync="showDeleteConfirmationPopup"
          :on-close="closeDeletePopup"
          :on-confirm="onClickDeletePortal"
          :title="$t('HELP_CENTER.PORTAL.PORTAL_SETTINGS.DELETE_PORTAL.TITLE')"
          :message="
            $t('HELP_CENTER.PORTAL.PORTAL_SETTINGS.DELETE_PORTAL.MESSAGE')
          "
          :message-value="deleteMessageValue"
          :confirm-text="
            $t('HELP_CENTER.PORTAL.PORTAL_SETTINGS.DELETE_PORTAL.YES')
          "
          :reject-text="
            $t('HELP_CENTER.PORTAL.PORTAL_SETTINGS.DELETE_PORTAL.NO')
          "
        />
      </div>
    </td>
  </tr>
</template>

<script>
import thumbnail from 'dashboard/components/widgets/Thumbnail.vue';
import uiSettingsMixin from 'dashboard/mixins/uiSettings';
import alertMixin from 'shared/mixins/alertMixin';

export default {
  components: {
    thumbnail,
  },
  mixins: [alertMixin, uiSettingsMixin],
  props: {
    portal: {
      type: Object,
      default: () => {},
    },
    status: {
      type: String,
      default: '',
      values: ['archived', 'draft', 'published'],
    },
  },
  data() {
    return {
      showDeleteConfirmationPopup: false,
      alertMessage: '',
      selectedPortalForDelete: {},
    };
  },
  computed: {
    labelColor() {
      switch (this.status) {
        case 'Archived':
          return 'warning';
        default:
          return 'success';
      }
    },
    deleteMessageValue() {
      return ` ${this.selectedPortalForDelete.name}?`;
    },
    locales() {
      return this.portal ? this.portal.config.allowed_locales : [];
    },
    allowedLocales() {
      return Object.keys(this.locales).map(key => {
        return this.locales[key].code;
      });
    },
    articleCount() {
      const { allowed_locales: allowedLocales } = this.portal.config;
      return allowedLocales.reduce((acc, locale) => {
        return acc + locale.articles_count;
      }, 0);
    },
    defaultLocale() {
      const { meta: { default_locale: defaultLocale = '' } = {} } = this.portal;
      return defaultLocale;
    },
    portalLink() {
      return `/hc/${this.portal.slug}/${this.defaultLocale}`;
    },
  },
  methods: {
    addLocale() {
      this.$emit('add-locale', this.portal.id);
    },
    openSettings() {
      this.fetchPortalAndItsCategories();
      this.navigateToPortalEdit();
    },
    onClickOpenDeleteModal(portal) {
      this.selectedPortalForDelete = portal;
      this.showDeleteConfirmationPopup = true;
    },
    closeDeletePopup() {
      this.showDeleteConfirmationPopup = false;
    },
    async fetchPortalAndItsCategories() {
      await this.$store.dispatch('portals/index');
      const {
        slug,
        config: { allowed_locales: allowedLocales },
      } = this.portal;
      const selectedPortalParam = {
        portalSlug: slug,
        locale: allowedLocales[0].code,
      };
      this.$store.dispatch('portals/show', selectedPortalParam);
      this.$store.dispatch('categories/index', selectedPortalParam);
    },
    async onClickDeletePortal() {
      const { slug } = this.selectedPortalForDelete;
      try {
        await this.$store.dispatch('portals/delete', {
          portalSlug: slug,
        });
        this.selectedPortalForDelete = {};
        this.closeDeletePopup();
        this.alertMessage = this.$t(
          'HELP_CENTER.PORTAL.PORTAL_SETTINGS.DELETE_PORTAL.API.DELETE_SUCCESS'
        );
        this.updateUISettings({
          last_active_portal_slug: undefined,
          last_active_locale_code: undefined,
        });
      } catch (error) {
        this.alertMessage =
          error?.message ||
          this.$t(
            'HELP_CENTER.PORTAL.PORTAL_SETTINGS.DELETE_PORTAL.API.DELETE_ERROR'
          );
      } finally {
        this.showAlert(this.alertMessage);
      }
    },
    navigateToPortalEdit() {
      this.$router.push({
        name: 'edit_portal_information',
        params: { portalSlug: this.portal.slug },
      });
    },
    navigateToPortalArticles() {
      this.$router.push({
        name: 'list_all_locale_articles',
        params: { portalSlug: this.portal.slug, locale: this.defaultLocale },
      });
    },
    navigateToPublicPortal() {
      window.open(this.portalLink, '_blank');
    },
  },
};
</script>
