<template>
  <div>
    <div
      class="relative flex p-4 mb-3 bg-white border border-solid rounded-md dark:bg-slate-900 border-slate-100 dark:border-slate-600"
    >
      <thumbnail :username="portal.name" variant="square" />
      <div class="flex-grow ml-2 rtl:ml-0 rtl:mr-2">
        <header class="flex items-start justify-between mb-8">
          <div>
            <div class="flex items-center">
              <h2 class="mb-0 text-lg text-slate-800 dark:text-slate-100">
                {{ portal.name }}
              </h2>
              <woot-label
                :title="status"
                :color-scheme="labelColor"
                size="small"
                variant="smooth"
                class="mx-2 my-0"
              />
            </div>
            <p class="mb-0 text-sm text-slate-700 dark:text-slate-200">
              {{ articleCount }}
              {{
                $t(
                  'HELP_CENTER.PORTAL.PORTAL_SETTINGS.LIST_ITEM.HEADER.COUNT_LABEL'
                )
              }}
            </p>
          </div>
          <div class="flex flex-row gap-1">
            <woot-button
              variant="smooth"
              size="small"
              color-scheme="primary"
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
              @click="onClickOpenDeleteModal(portal)"
            />
          </div>
        </header>
        <div class="mb-12">
          <h2
            class="mb-2 text-base font-medium text-slate-800 dark:text-slate-100"
          >
            {{
              $t(
                'HELP_CENTER.PORTAL.PORTAL_SETTINGS.LIST_ITEM.PORTAL_CONFIG.TITLE'
              )
            }}
          </h2>
          <div
            class="flex justify-between mr-[6.25rem] rtl:mr-0 rtl:ml-[6.25rem] max-w-[80vw]"
          >
            <div class="flex flex-col">
              <div class="flex flex-col items-start mb-4">
                <label>{{
                  $t(
                    'HELP_CENTER.PORTAL.PORTAL_SETTINGS.LIST_ITEM.PORTAL_CONFIG.ITEMS.NAME'
                  )
                }}</label>
                <span class="text-sm text-slate-600 dark:text-slate-300">
                  {{ portal.name }}
                </span>
              </div>
              <div class="flex flex-col items-start mb-4">
                <label>{{
                  $t(
                    'HELP_CENTER.PORTAL.PORTAL_SETTINGS.LIST_ITEM.PORTAL_CONFIG.ITEMS.DOMAIN'
                  )
                }}</label>
                <span class="text-sm text-slate-600 dark:text-slate-300">
                  {{ portal.custom_domain }}
                </span>
              </div>
            </div>
            <div class="flex flex-col">
              <div class="flex flex-col items-start mb-4">
                <label>{{
                  $t(
                    'HELP_CENTER.PORTAL.PORTAL_SETTINGS.LIST_ITEM.PORTAL_CONFIG.ITEMS.SLUG'
                  )
                }}</label>
                <span class="text-sm text-slate-600 dark:text-slate-300">
                  {{ portal.slug }}
                </span>
              </div>
              <div class="flex flex-col items-start mb-4">
                <label>{{
                  $t(
                    'HELP_CENTER.PORTAL.PORTAL_SETTINGS.LIST_ITEM.PORTAL_CONFIG.ITEMS.TITLE'
                  )
                }}</label>
                <span class="text-sm text-slate-600 dark:text-slate-300">
                  {{ portal.page_title }}
                </span>
              </div>
            </div>
            <div class="flex flex-col">
              <div class="flex flex-col items-start mb-4">
                <label>{{
                  $t(
                    'HELP_CENTER.PORTAL.PORTAL_SETTINGS.LIST_ITEM.PORTAL_CONFIG.ITEMS.THEME'
                  )
                }}</label>
                <div class="flex items-center">
                  <div
                    class="w-4 h-4 mr-1 border border-solid rounded-md rtl:mr-0 rtl:ml-1 border-slate-25 dark:border-slate-800"
                    :style="{ background: portal.color }"
                  />
                </div>
              </div>
              <div class="flex flex-col items-start mb-4">
                <label>{{
                  $t(
                    'HELP_CENTER.PORTAL.PORTAL_SETTINGS.LIST_ITEM.PORTAL_CONFIG.ITEMS.SUB_TEXT'
                  )
                }}</label>
                <span class="text-sm text-slate-600 dark:text-slate-300">
                  {{ portal.header_text }}
                </span>
              </div>
            </div>
          </div>
        </div>
        <div class="mb-12">
          <h2
            class="mb-2 text-base font-medium text-slate-800 dark:text-slate-100"
          >
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
import { useAlert } from 'dashboard/composables';
import { useUISettings } from 'dashboard/composables/useUISettings';
import thumbnail from 'dashboard/components/widgets/Thumbnail.vue';
import LocaleItemTable from './PortalListItemTable.vue';
import { PORTALS_EVENTS } from '../../../../helper/AnalyticsHelper/events';

export default {
  components: {
    thumbnail,
    LocaleItemTable,
  },
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
  setup() {
    const { updateUISettings } = useUISettings();

    return {
      updateUISettings,
    };
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
  },
  methods: {
    addLocale() {
      this.$emit('add-locale', this.portal.id);
    },
    openSite() {
      this.$emit('open-site', this.portal.slug);
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
        useAlert(this.alertMessage);
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
      this.$track(PORTALS_EVENTS.SET_DEFAULT_LOCALE, {
        newLocale: localeCode,
        from: this.$route.name,
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
      this.$track(PORTALS_EVENTS.DELETE_LOCALE, {
        deletedLocale: localeCode,
        from: this.$route.name,
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
        useAlert(this.alertMessage);
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
