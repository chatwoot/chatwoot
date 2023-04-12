<template>
  <div class="article-container--row">
    <span class="article-column article-title">
      <div class="article-content-wrap">
        <div class="article-block">
          <router-link :to="articleUrl(id)">
            <h6 :title="title" class="sub-block-title text-truncate">
              {{ title }}
            </h6>
          </router-link>
          <div class="author">
            <span class="by">{{ $t('HELP_CENTER.TABLE.COLUMNS.BY') }}</span>
            <span class="name">{{ articleAuthorName }}</span>
          </div>
        </div>
      </div>
    </span>
    <span class="article-column">
      <router-link
        class="fs-small button clear link secondary"
        :to="getCategoryRoute(category.slug)"
      >
        <span
          :title="category.name"
          class="category-link-content text-ellipsis"
        >
          {{ category.name }}
        </span>
      </router-link>
    </span>
    <span class="article-column">
      <span class="fs-small" :title="formattedViewCount">
        {{ readableViewCount }}
      </span>
    </span>
    <span class="article-column">
      <div>
        <woot-label
          :title="status"
          size="small"
          variant="smooth"
          :color-scheme="labelColor"
        />
      </div>
    </span>
    <span class="article-column">
      <span class="fs-small">
        {{ lastUpdatedAt }}
      </span>
    </span>
  </div>
</template>
<script>
import timeMixin from 'dashboard/mixins/time';
import portalMixin from '../mixins/portalMixin';
import { frontendURL } from 'dashboard/helper/URLHelper';

export default {
  mixins: [timeMixin, portalMixin],

  props: {
    id: {
      type: Number,
      required: true,
    },
    title: {
      type: String,
      default: '',
      required: true,
    },
    author: {
      type: Object,
      default: () => {},
    },
    category: {
      type: Object,
      default: () => {},
    },
    views: {
      type: Number,
      default: 0,
    },
    status: {
      type: String,
      default: 'draft',
      values: ['archived', 'draft', 'published'],
    },
    updatedAt: {
      type: Number,
      default: 0,
    },
  },

  computed: {
    lastUpdatedAt() {
      return this.dynamicTime(this.updatedAt);
    },
    formattedViewCount() {
      return Number(this.views || 0).toLocaleString('en');
    },
    readableViewCount() {
      return new Intl.NumberFormat('en-US', {
        notation: 'compact',
        compactDisplay: 'short',
      }).format(this.views || 0);
    },
    articleAuthorName() {
      return this.author.name;
    },
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
  },
  methods: {
    getCategoryRoute(categorySlug) {
      const { portalSlug, locale } = this.$route.params;
      return frontendURL(
        `accounts/${this.accountId}/portals/${portalSlug}/${locale}/categories/${categorySlug}`
      );
    },
  },
};
</script>

<style lang="scss" scoped>
.article-container--row {
  margin: 0 var(--space-minus-normal);
  padding: 0 var(--space-normal);
  display: grid;
  gap: var(--space-normal);
  grid-template-columns: repeat(8, minmax(0, 1fr));
  border-bottom: 1px solid var(--s-50);
  background: var(--white);

  span.article-column {
    font-weight: var(--font-weight-bold);
    text-transform: capitalize;
    color: var(--s-700);
    font-size: var(--font-size-small);
    text-align: right;
    padding: var(--space-small) 0;

    &.article-title {
      text-align: left;
      grid-column: span 4 / span 4;
    }
  }

  .article-content-wrap {
    align-items: center;
    display: flex;
    text-align: left;
  }
  .article-block {
    min-width: 0;
  }

  .sub-block-title {
    margin-bottom: 0;
    line-height: var(--space-medium);
    height: var(--space-medium);
    &:hover {
      text-decoration: underline;
    }
  }

  .author {
    .by {
      font-weight: var(--font-weight-normal);
      color: var(--s-500);
      font-size: var(--font-size-small);
    }
    .name {
      font-weight: var(--font-weight-medium);
      color: var(--s-600);
      font-size: var(--font-size-small);
    }
  }
}

span {
  font-weight: var(--font-weight-normal);
  color: var(--s-700);
  font-size: var(--font-size-mini);
  padding-left: 0;
}
</style>
