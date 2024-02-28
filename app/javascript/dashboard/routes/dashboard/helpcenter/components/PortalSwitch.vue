<template>
  <div class="portal" :class="{ active }">
    <thumbnail :username="portal.name" variant="square" />
    <div class="actions-container">
      <header class="flex items-center justify-between mb-2.5">
        <div>
          <h3 class="text-sm mb-0.5 text-slate-700 dark:text-slate-100">
            {{ portal.name }}
          </h3>
          <p class="text-slate-600 dark:text-slate-200 mb-0 text-xs">
            {{ articlesCount }}
            {{ $t('HELP_CENTER.PORTAL.ARTICLES_LABEL') }}
          </p>
        </div>
        <woot-label
          v-if="active"
          variant="smooth"
          size="small"
          color-scheme="success"
          :title="$t('HELP_CENTER.PORTAL.ACTIVE_BADGE')"
        />
      </header>
      <div class="portal-locales">
        <h5 class="text-base text-slate-700 dark:text-slate-100">
          {{ $t('HELP_CENTER.PORTAL.CHOOSE_LOCALE_LABEL') }}
        </h5>
        <ul>
          <li v-for="locale in locales" :key="locale.code">
            <woot-button
              :variant="`locale-item ${
                isLocaleActive(locale.code, activePortalSlug)
                  ? 'smooth'
                  : 'clear'
              }`"
              size="large"
              color-scheme="secondary"
              @click="event => onClick(event, locale.code, portal)"
            >
              <div class="flex items-center justify-between w-full">
                <div class="meta">
                  <h6 class="text-sm text-left mb-0.5">
                    <span class="text-slate-700 dark:text-slate-100">
                      {{ localeName(locale.code) }}
                    </span>
                    <span
                      v-if="isLocaleDefault(locale.code)"
                      class="text-sm text-slate-300 dark:text-slate-200"
                    >
                      {{ `(${$t('HELP_CENTER.PORTAL.DEFAULT')})` }}
                    </span>
                  </h6>

                  <span
                    class="flex text-slate-600 dark:text-slate-200 text-sm text-left leading-4 w-full"
                  >
                    {{ locale.articles_count }}
                    {{ $t('HELP_CENTER.PORTAL.ARTICLES_LABEL') }} -
                    {{ locale.code }}
                  </span>
                </div>
                <div v-if="isLocaleActive(locale.code, activePortalSlug)">
                  <fluent-icon icon="checkmark" class="locale__radio" />
                </div>
              </div>
            </woot-button>
          </li>
        </ul>
      </div>
    </div>
  </div>
</template>

<script>
import thumbnail from 'dashboard/components/widgets/Thumbnail.vue';
import portalMixin from '../mixins/portalMixin';

export default {
  components: {
    thumbnail,
  },
  mixins: [portalMixin],
  props: {
    portal: {
      type: Object,
      default: () => ({}),
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
  computed: {
    locales() {
      return this.portal?.config?.allowed_locales;
    },
    articlesCount() {
      const { allowed_locales: allowedLocales } = this.portal.config;
      return allowedLocales.reduce((acc, locale) => {
        return acc + locale.articles_count;
      }, 0);
    },
  },
  mounted() {
    this.selectedLocale = this.locale || this.portal?.meta?.default_locale;
  },
  methods: {
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
  @apply bg-white dark:bg-slate-800 rounded-md p-4 relative flex mb-4 border border-solid border-slate-100 dark:border-slate-600;

  &.active {
    @apply bg-white dark:bg-slate-800 border border-solid border-woot-400 dark:border-woot-500;
  }

  .actions-container {
    @apply ml-2.5 rtl:ml-0 rtl:mr-2.5 flex-grow;

    .portal-locales {
      ul {
        @apply list-none p-0 m-0;
      }

      .locale__radio {
        @apply w-8 text-green-600 dark:text-green-600;
      }
    }
  }

  .locale-item {
    @apply flex items-start py-1 px-4 rounded-md w-full mb-2;

    p {
      @apply mb-0 text-left;
    }
  }
}
</style>
