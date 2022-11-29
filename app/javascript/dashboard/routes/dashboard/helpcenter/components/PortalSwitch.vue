<template>
  <div class="portal" :class="{ active }">
    <thumbnail :username="portal.name" variant="square" />
    <div class="actions-container">
      <header>
        <div>
          <h3 class="sub-block-title portal-title">{{ portal.name }}</h3>
          <p class="portal-count">
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
        <h5 class="locale-title sub-block-title">
          {{ $t('HELP_CENTER.PORTAL.CHOOSE_LOCALE_LABEL') }}
        </h5>
        <ul>
          <li v-for="locale in locales" :key="locale.code">
            <woot-button
              :variant="
                `locale-item ${
                  isLocaleActive(locale.code, activePortalSlug)
                    ? 'smooth'
                    : 'clear'
                }`
              "
              size="large"
              color-scheme="secondary"
              @click="event => onClick(event, locale.code, portal)"
            >
              <div class="locale-content">
                <div class="meta">
                  <h6 class="text-block-title text-left locale-name">
                    <span>
                      {{ localeName(locale.code) }}
                    </span>
                    <span
                      v-if="isLocaleDefault(locale.code)"
                      class="fs-small text-muted"
                    >
                      {{ `(${$t('HELP_CENTER.PORTAL.DEFAULT')})` }}
                    </span>
                  </h6>

                  <span class="locale-meta">
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
import thumbnail from 'dashboard/components/widgets/Thumbnail';
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
      return this.portal?.meta?.all_articles_count;
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
  background-color: var(--white);
  padding: var(--space-normal);
  border: 1px solid var(--color-border-dark);
  border-radius: var(--border-radius-medium);
  position: relative;
  display: flex;
  margin-bottom: var(--space-normal);

  &.active {
    border: 1px solid var(--w-400);
    background: var(---25);
  }

  .actions-container {
    margin-left: var(--space-one);
    flex-grow: 1;

    header {
      display: flex;
      align-items: flex-start;
      justify-content: space-between;
      margin-bottom: var(--space-one);

      .badge {
        font-size: var(--font-size-mini);
        background-color: var(--w-100);
        color: var(--w-600);
        padding: var(--space-smaller) var(--space-small);
      }

      .portal-title {
        margin-bottom: var(--space-micro);
      }

      .portal-count {
        font-size: var(--font-size-mini);
        margin-bottom: 0;
        color: var(--s-600);
      }
    }

    .portal-locales {
      .locale-name {
        margin-bottom: var(--space-micro);
      }

      .locale-content {
        display: flex;
        align-items: center;
        justify-content: flex-start;
        width: 100%;
      }

      ul {
        list-style: none;
        padding: 0;
        margin: 0;
      }

      .locale__radio {
        width: var(--space-large);
        margin-top: var(--space-tiny);
        color: var(--g-600);
      }

      .add-locale-wrap {
        margin-top: var(--spacing-small);
      }
    }
  }

  .locale-item {
    display: flex;
    align-items: flex-start;
    padding: var(--space-smaller) var(--space-normal);
    border-radius: var(--border-radius-normal);
    width: 100%;
    margin-bottom: var(--space-small);

    p {
      margin-bottom: 0;
      text-align: left;
    }

    .locale-meta {
      display: flex;
      color: var(--s-600);
      font-size: var(--font-size-small);
      text-align: left;
      line-height: var(--space-normal);
      width: 100%;
    }

    .meta {
      flex-grow: 1;
    }
  }
}
</style>
