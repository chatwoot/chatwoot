<template>
  <div>
    <div v-for="portal in portals" :key="portal.id" class="portal">
      <thumbnail :username="portal.name" variant="square" />
      <div class="container">
        <header>
          <div>
            <div class="title-status--wrap">
              <h2 class="portal-title block-title">{{ portal.name }}</h2>
              <Label
                :title="status"
                :color-scheme="labelColor"
                :small="true"
                class="status"
              />
            </div>
            <p class="portal-count">
              {{ portal.articles_count }}
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
                <span class="text-block-title">{{ portal.header_text }}</span>
              </div>
              <div class="configuration-item">
                <label>{{
                  $t(
                    'HELP_CENTER.PORTAL.PORTAL_SETTINGS.LIST_ITEM.PORTAL_CONFIG.ITEMS.DOMAIN'
                  )
                }}</label>
                <span class="text-block-title">{{ portal.custom_domain }}</span>
              </div>
            </div>
            <div class="configuration-items">
              <div class="configuration-item">
                <label>{{
                  $t(
                    'HELP_CENTER.PORTAL.PORTAL_SETTINGS.LIST_ITEM.PORTAL_CONFIG.ITEMS.SLUG'
                  )
                }}</label>
                <span class="text-block-title">{{ portal.slug }}</span>
              </div>
              <div class="configuration-item">
                <label>{{
                  $t(
                    'HELP_CENTER.PORTAL.PORTAL_SETTINGS.LIST_ITEM.PORTAL_CONFIG.ITEMS.TITLE'
                  )
                }}</label>
                <span class="text-block-title">{{ portal.page_title }}</span>
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
                  <span class="text-block-title">{{ portal.page_title }}</span>
                </div>
              </div>
              <div class="configuration-item">
                <label>{{
                  $t(
                    'HELP_CENTER.PORTAL.PORTAL_SETTINGS.LIST_ITEM.PORTAL_CONFIG.ITEMS.SUB_TEXT'
                  )
                }}</label>
                <span class="text-block-title">{{ portal.page_title }}</span>
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
            :portals="portal"
            :selected-locale-code="selectedLocaleCode"
            @swap="swapLocale"
            @delete="deleteLocale"
          />
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import thumbnail from 'dashboard/components/widgets/Thumbnail';
import Label from 'dashboard/components/ui/Label';
import LocaleItemTable from './PortalListItemTable';
export default {
  components: {
    thumbnail,
    Label,
    LocaleItemTable,
  },
  props: {
    portals: {
      type: Array,
      default: () => [],
    },
    status: {
      type: String,
      default: '',
      values: ['archived', 'draft', 'published'],
    },
    selectedLocaleCode: {
      type: String,
      default: '',
    },
  },
  computed: {
    labelColor() {
      switch (this.status) {
        case 'archived':
          return 'secondary';
        case 'draft':
          return 'warning';
        default:
          return 'success';
      }
    },
    defaultLocale(code) {
      return code === this.selectedLocaleCode;
    },
  },
  methods: {
    addLocale() {
      this.$emit('add');
    },
    openSite() {
      this.$emit('open-site');
    },
    openSettings() {
      this.$emit('open');
    },
    swapLocale() {
      this.$emit('swap');
    },
    deleteLocale() {
      this.$emit('delete');
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
      margin-bottom: var(--space-normal);
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
      margin-bottom: var(--space-slab);
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
