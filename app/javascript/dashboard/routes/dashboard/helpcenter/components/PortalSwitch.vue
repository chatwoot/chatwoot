<template>
  <div>
    <woot-dropdown-menu>
      <div class="sticky top-0 dark:bg-slate-800 bg-white">
        <woot-dropdown-item>
          <woot-button
            variant="clear"
            color-scheme="secondary"
            size="small"
            icon="settings"
            @click="$emit('fetch-portal')"
          >
            {{ $t('HELP_CENTER.PORTAL.POPOVER.PORTAL_SETTINGS') }}
          </woot-button>
        </woot-dropdown-item>
        <woot-dropdown-item>
          <woot-button
            variant="clear"
            size="small"
            color-scheme="secondary"
            icon="app-folder"
            @click="$emit('fetch-portal')"
          >
            {{ $t('HELP_CENTER.PORTAL.POPOVER.ALL_PORTALS') }}
          </woot-button>
        </woot-dropdown-item>
      </div>
      <woot-dropdown-divider />
      <woot-dropdown-header
        :title="$t('HELP_CENTER.PORTAL.POPOVER.SWITCH_PORTAL')"
      />
      <woot-dropdown-item
        v-for="portal in portals"
        :key="portal.id"
        class="my-1"
      >
        <woot-button
          variant="clear"
          color-scheme="secondary"
          class-name=""
          :is-active="portal.slug === activePortalSlug"
          @click="() => openSnoozeModal()"
        >
          <div
            class="portal"
            :class="{ active: portal.slug === activePortalSlug }"
          >
            <thumbnail :username="portal.name" variant="square" size="32px" />

            <div class="flex items-center justify-between">
              <div>
                <h3
                  class="text-sm leading-4 font-semibold text-slate-700 dark:text-slate-100 mb-0"
                >
                  {{ portal.name }}
                </h3>
                <div class="text-xs text-slate-600 dark:text-slate-300">
                  <span>{{ articlesCount(portal) }}</span>
                </div>
              </div>

              <woot-label
                v-if="active"
                size="tiny"
                color-scheme="success"
                :title="$t('HELP_CENTER.PORTAL.ACTIVE_BADGE')"
              />
            </div>
          </div>
        </woot-button>
      </woot-dropdown-item>
    </woot-dropdown-menu>
  </div>
</template>

<script>
import WootDropdownItem from 'shared/components/ui/dropdown/DropdownItem.vue';
import WootDropdownMenu from 'shared/components/ui/dropdown/DropdownMenu.vue';
import WootDropdownDivider from 'shared/components/ui/dropdown/DropdownDivider.vue';
import WootDropdownHeader from 'shared/components/ui/dropdown/DropdownHeader.vue';
import thumbnail from 'dashboard/components/widgets/Thumbnail.vue';
import portalMixin from '../mixins/portalMixin';

export default {
  components: {
    thumbnail,
    WootDropdownMenu,
    WootDropdownItem,
    WootDropdownHeader,
    WootDropdownDivider,
  },
  mixins: [portalMixin],
  props: {
    portals: {
      type: Array,
      default: () => [],
    },
    active: {
      type: Boolean,
      default: false,
    },
    activePortalSlug: {
      type: String,
      default: '',
    },
    activeLocale: {
      type: String,
      default: '',
    },
  },
  data() {
    return {
      selectedLocale: null,
    };
  },
  computed: {},
  mounted() {
    this.selectedLocale = this.locale || this.portal?.meta?.default_locale;
  },
  methods: {
    articlesCount(portal) {
      const { allowed_locales: allowedLocales } = portal.config;
      return allowedLocales.reduce((acc, locale) => {
        return acc + locale.articles_count;
      }, 0);
    },
    onClick(event, code, portal) {
      event.preventDefault();
      this.$router.push({
        name: 'list_all_locale_articles',
        params: {
          portalSlug: portal.slug,
          locale: code,
        },
      });
      this.$emit('fetch-portal');
      this.$emit('open-portal-page');
    },
    isLocaleActive(code, slug) {
      const isPortalActive = this.portal.slug === slug;
      const isLocaleActive = this.activeLocale === code;
      return isPortalActive && isLocaleActive;
    },
    isLocaleDefault(code) {
      return this.portal?.meta?.default_locale === code;
    },
  },
};
</script>

<style lang="scss" scoped>
.portal {
  @apply rounded-md relative flex gap-2;
}
</style>
