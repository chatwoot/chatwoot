<template>
  <div>
    <div class="portal">
      <thumbnail :username="portal.name" variant="square" />
      <div class="container">
        <header>
          <div>
            <div class="title-status--wrap">
              <h2 class="portal-title block-title">
                {{ portal.name }}
              </h2>
              <woot-label
                :title="status"
                :color-scheme="labelColor"
                size="small"
                variant="smooth"
                class="status"
              />
            </div>
            <p class="portal-count">
              {{ articleCount }}
              {{
                $t(
                  'HELP_CENTER.PORTAL.PORTAL_SETTINGS.LIST_ITEM.HEADER.COUNT_LABEL'
                )
              }}
            </p>
          </div>
          <div>
            <woot-button
              variant="smooth"
              size="small"
              color-scheme="primary"
              class="header-action-buttons"
              @click="addLocale"
            >
              {{
                $t('HELP_CENTER.PORTAL.PORTAL_SETTINGS.LIST_ITEM.HEADER.ADD')
              }}
            </woot-button>
            <woot-button
              variant="hollow"
              size="small"
              color-scheme="secondary"
              class="header-action-buttons"
              @click="openSite"
            >
              {{
                $t('HELP_CENTER.PORTAL.PORTAL_SETTINGS.LIST_ITEM.HEADER.VISIT')
              }}
            </woot-button>
            <woot-button
              v-tooltip.top-end="
                $t(
                  'HELP_CENTER.PORTAL.PORTAL_SETTINGS.LIST_ITEM.HEADER.SETTINGS'
                )
              "
              variant="hollow"
              size="small"
              icon="settings"
              class="header-action-buttons"
              color-scheme="secondary"
              @click="openSettings"
            />
            <woot-button
              v-tooltip.top-end="
                $t('HELP_CENTER.PORTAL.PORTAL_SETTINGS.LIST_ITEM.HEADER.DELETE')
              "
              variant="hollow"
              color-scheme="alert"
              size="small"
              icon="delete"
              class="header-action-buttons"
              @click="onClickOpenDeleteModal(portal)"
            />
          </div>
        </header>
        <div class="portal-locales">
          <h2 class="locale-title sub-block-title">
            {{
              $t(
                'HELP_CENTER.PORTAL.PORTAL_SETTINGS.LIST_ITEM.PORTAL_CONFIG.TITLE'
              )
            }}
          </h2>
          <div class="configuration-items--wrap">
            <div class="configuration-items">
              <div class="configuration-item">
                <label>{{
                  $t(
                    'HELP_CENTER.PORTAL.PORTAL_SETTINGS.LIST_ITEM.PORTAL_CONFIG.ITEMS.NAME'
                  )
                }}</label>
                <span class="text-block-title">
                  {{ portal.name }}
                </span>
              </div>
              <div class="configuration-item">
                <label>{{
                  $t(
                    'HELP_CENTER.PORTAL.PORTAL_SETTINGS.LIST_ITEM.PORTAL_CONFIG.ITEMS.DOMAIN'
                  )
                }}</label>
                <span class="text-block-title">
                  {{ portal.custom_domain }}
                </span>
              </div>
            </div>
            <div class="configuration-items">
              <div class="configuration-item">
                <label>{{
                  $t(
                    'HELP_CENTER.PORTAL.PORTAL_SETTINGS.LIST_ITEM.PORTAL_CONFIG.ITEMS.SLUG'
                  )
                }}</label>
                <span class="text-block-title">
                  {{ portal.slug }}
                </span>
              </div>
              <div class="configuration-item">
                <label>{{
                  $t(
                    'HELP_CENTER.PORTAL.PORTAL_SETTINGS.LIST_ITEM.PORTAL_CONFIG.ITEMS.TITLE'
                  )
                }}</label>
                <span class="text-block-title">
                  {{ portal.page_title }}
                </span>
              </div>
            </div>
            <div class="configuration-items">
              <div class="configuration-item">
                <label>{{
                  $t(
                    'HELP_CENTER.PORTAL.PORTAL_SETTINGS.LIST_ITEM.PORTAL_CONFIG.ITEMS.THEME'
                  )
                }}</label>
                <div class="content-theme-wrap">
                  <div
                    class="theme-color"
                    :style="{ background: portal.color }"
                  />
                </div>
              </div>
              <div class="configuration-item">
                <label>{{
                  $t(
                    'HELP_CENTER.PORTAL.PORTAL_SETTINGS.LIST_ITEM.PORTAL_CONFIG.ITEMS.SUB_TEXT'
                  )
                }}</label>
                <span class="text-block-title">
                  {{ portal.header_text }}
                </span>
              </div>
            </div>
          </div>
        </div>
        <div class="portal-locales">
          <h2 class="locale-title sub-block-title">
            {{
              $t(
                'HELP_CENTER.PORTAL.PORTAL_SETTINGS.LIST_ITEM.AVAILABLE_LOCALES.TITLE'
              )
            }}
          </h2>
          <locale-item-table
            :locales="locales"
            :selected-locale-code="portal.meta.default_locale"
            @change-default-locale="changeDefaultLocale"
            @delete="deletePortalLocale"
          />
        </div>
      </div>
    </div>
    <woot-delete-modal
      :show.sync="showDeleteConfirmationPopup"
      :on-close="closeDeletePopup"
      :on-confirm="onClickDeletePortal"
      :title="$t('HELP_CENTER.PORTAL.PORTAL_SETTINGS.DELETE_PORTAL.TITLE')"
      :message="$t('HELP_CENTER.PORTAL.PORTAL_SETTINGS.DELETE_PORTAL.MESSAGE')"
      :message-value="deleteMessageValue"
      :confirm-text="$t('HELP_CENTER.PORTAL.PORTAL_SETTINGS.DELETE_PORTAL.YES')"
      :reject-text="$t('HELP_CENTER.PORTAL.PORTAL_SETTINGS.DELETE_PORTAL.NO')"
    />
  </div>
</template>

<script>
import thumbnail from 'dashboard/components/widgets/Thumbnail';
import LocaleItemTable from './PortalListItemTable';
import alertMixin from 'shared/mixins/alertMixin';
export default {
  components: {
    thumbnail,
    LocaleItemTable,
  },
  mixins: [alertMixin],
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
      const { all_articles_count: count } = this.portal.meta;
      return count;
    },
  },
  methods: {
    addLocale() {
      this.$emit('add-locale', this.portal.id);
    },
    openSite() {
      this.$emit('open-site', this.portal.slug);
    },
    openSettings() {
      this.fetchPortalsAndItsCategories();
      this.navigateToPortalEdit();
    },
    onClickOpenDeleteModal(portal) {
      this.selectedPortalForDelete = portal;
      this.showDeleteConfirmationPopup = true;
    },
    closeDeletePopup() {
      this.showDeleteConfirmationPopup = false;
    },
    fetchPortalsAndItsCategories() {
      this.$store.dispatch('portals/index').then(() => {
        this.$store.dispatch('categories/index', {
          portalSlug: this.portal.slug,
        });
      });
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
    changeDefaultLocale({ localeCode }) {
      this.updatePortalLocales({
        allowedLocales: this.allowedLocales,
        defaultLocale: localeCode,
        successMessage: this.$t(
          'HELP_CENTER.PORTAL.CHANGE_DEFAULT_LOCALE.API.SUCCESS_MESSAGE'
        ),
        errorMessage: this.$t(
          'HELP_CENTER.PORTAL.CHANGE_DEFAULT_LOCALE.API.ERROR_MESSAGE'
        ),
      });
    },
    deletePortalLocale({ localeCode }) {
      const updatedLocales = this.allowedLocales.filter(
        code => code !== localeCode
      );
      const defaultLocale = this.portal.meta.default_locale;
      this.updatePortalLocales({
        allowedLocales: updatedLocales,
        defaultLocale,
        successMessage: this.$t(
          'HELP_CENTER.PORTAL.DELETE_LOCALE.API.SUCCESS_MESSAGE'
        ),
        errorMessage: this.$t(
          'HELP_CENTER.PORTAL.DELETE_LOCALE.API.ERROR_MESSAGE'
        ),
      });
    },
    async updatePortalLocales({
      allowedLocales,
      defaultLocale,
      successMessage,
      errorMessage,
    }) {
      try {
        await this.$store.dispatch('portals/update', {
          portalSlug: this.portal.slug,
          config: {
            default_locale: defaultLocale,
            allowed_locales: allowedLocales,
          },
        });
        this.alertMessage = successMessage;
      } catch (error) {
        this.alertMessage = error?.message || errorMessage;
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
  },
};
</script>

<style lang="scss" scoped>
.portal {
  background-color: var(--white);
  padding: var(--space-normal);
  border: 1px solid var(--color-border-dark);
  border-radius: var(--border-radius-medium);
  position: relative;
  display: flex;
  margin-bottom: var(--space-slab);

  .container {
    margin-left: var(--space-small);
    flex-grow: 1;

    header {
      display: flex;
      align-items: flex-start;
      justify-content: space-between;
      margin-bottom: var(--space-large);
      .title-status--wrap {
        display: flex;
        align-items: center;
        .status {
          margin: 0 0 0 var(--space-small);
        }
      }
      .portal-title {
        color: var(--s-900);
        margin-bottom: 0;
      }
      .portal-count {
        font-size: var(--font-size-small);
        margin-bottom: 0;
        color: var(--s-700);
      }
      .header-action-buttons {
        margin-left: var(--space-smaller);
      }
    }
    .portal-locales {
      margin-top: var(--space-medium);
      margin-bottom: var(--space-small);
      .locale-title {
        color: var(--s-800);
        font-weight: var(--font-weight-medium);
        margin-bottom: var(--space-small);
      }
    }
  }
  .portal-settings--icon {
    padding: var(--space-smaller);
    margin-left: var(--space-small);

    &:hover {
      cursor: pointer;
      background: var(--s-50);
      border-radius: var(--border-radius-normal);
    }
  }
  .configuration-items--wrap {
    display: flex;
    justify-content: space-between;
    margin-right: var(--space-mega);
    max-width: 80vw;
    .configuration-items {
      display: flex;
      flex-direction: column;
    }
    .configuration-item {
      display: flex;
      align-items: flex-start;
      flex-direction: column;
      margin-bottom: var(--space-normal);
      .content-theme-wrap {
        display: flex;
        align-items: center;
      }
      .theme-color {
        width: var(--space-normal);
        height: var(--space-normal);
        border-radius: var(--border-radius-normal);
        margin-right: var(--space-smaller);
        border: 1px solid var(--color-border-light);
      }
    }
  }
}
</style>
