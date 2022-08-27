<template>
  <div class="portal" :class="{ active }">
    <thumbnail :username="portal.name" variant="square" />
    <div class="actions-container">
      <header>
        <div>
          <h2 class="portal-title">{{ portal.name }}</h2>
          <p class="portal-count">
            {{ articlesCount }}
            {{ $t('HELP_CENTER.PORTAL.ARTICLES_LABEL') }}
          </p>
        </div>
        <span v-if="active" class="badge">{{
          $t('HELP_CENTER.PORTAL.ACTIVE_BADGE')
        }}</span>
      </header>
      <div class="portal-locales">
        <h2 class="locale-title">
          {{ $t('HELP_CENTER.PORTAL.CHOOSE_LOCALE_LABEL') }}
        </h2>
        <ul>
          <li v-for="locale in locales" :key="locale.code">
            <label :for="`locale-${locale.code}`" class="locale-item">
              <input
                :id="`locale-${locale.code}`"
                v-model="selectedLocale"
                type="radio"
                name="locale"
                :value="locale.code"
                @click="onClick(locale.code, portal)"
              />
              <div>
                <p>{{ localeName(locale.code) }}</p>
                <span>
                  {{ locale.articles_count }}
                  {{ $t('HELP_CENTER.PORTAL.ARTICLES_LABEL') }} -
                  {{ locale.code }}
                </span>
              </div>
            </label>
          </li>
          <li>
            <a>+ {{ $t('HELP_CENTER.PORTAL.ADD_NEW_LOCALE') }}</a>
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
    onClick(code, portal) {
      this.$emit('open-portal-page', { slug: portal.slug, locale: code });
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
        color: var(--s-900);
        font-size: var(--font-size-medium);
        font-weight: var(--font-weight-bold);
        margin-bottom: 0;
      }

      .portal-count {
        font-size: var(--font-size-mini);
        margin-bottom: 0;
        color: var(--s-500);
      }
    }

    .portal-locales {
      .locale-title {
        color: var(--s-600);
        font-size: var(--font-size-default);
        font-weight: var(--font-weight-medium);
      }

      ul {
        list-style: none;
        padding: 0;
        margin: 0;

        .locale-item {
          display: flex;
          align-items: flex-start;
          margin-bottom: var(--space-smaller);
          cursor: pointer;
          padding: var(--space-smaller);
          border-radius: var(--border-radius-normal);

          &:hover {
            background-color: var(--w-25);
          }

          p {
            margin-bottom: 0;
          }

          span {
            color: var(--s-500);
            font-size: var(--font-size-small);
          }
        }
      }
    }
  }
}
label > [type='radio'] {
  margin-bottom: 0;
  margin-top: var(--space-smaller);
  margin-right: var(--space-one);
}
</style>
