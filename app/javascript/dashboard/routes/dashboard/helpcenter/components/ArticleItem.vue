<template>
  <div class="article-container--row">
    <span class="article-column article-title">
      <emoji-or-icon class="icon-grab" icon="grab-handle" />
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
    </span>
    <span class="article-column article-category">
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
    <span class="article-column article-read-count">
      <span class="fs-small" :title="formattedViewCount">
        {{ readableViewCount }}
      </span>
    </span>
    <span class="article-column article-status">
      <div>
        <woot-label
          :title="status"
          size="small"
          variant="smooth"
          :color-scheme="labelColor"
        />
      </div>
    </span>
    <span class="article-column article-last-edited">
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
import EmojiOrIcon from '../../../../../shared/components/EmojiOrIcon.vue';

export default {
  components: {
    EmojiOrIcon,
  },
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
  background: var(--white);
  border-bottom: 1px solid var(--s-50);
  display: grid;
  gap: var(--space-normal);
  grid-template-columns: repeat(8, minmax(0, 1fr));
  margin: 0 var(--space-minus-normal);
  padding: 0 var(--space-normal);

  @media (max-width: 1024px) {
    grid-template-columns: repeat(7, minmax(0, 1fr));
  }

  @media (max-width: 768px) {
    grid-template-columns: repeat(6, minmax(0, 1fr));
  }

  &.draggable {
    span.article-column.article-title {
      margin-left: var(--space-minus-small);

      .icon-grab {
        display: block;
        cursor: move;
        height: var(--space-normal);
        margin-top: var(--space-smaller);
        width: var(--space-normal);

        color: var(--s-100);

        &:hover {
          color: var(--s-300);
        }
      }
    }
  }

  span.article-column {
    color: var(--s-700);
    font-size: var(--font-size-small);
    font-weight: var(--font-weight-bold);
    padding: var(--space-small) 0;
    text-align: right;
    text-transform: capitalize;

    &.article-title {
      align-items: start;
      display: flex;
      gap: var(--space-small);
      grid-column: span 4 / span 4;
      text-align: left;
      text-align: left;

      .icon-grab {
        display: none;
      }
    }

    // for screen sizes smaller than 1024px
    @media (max-width: 63.9375em) {
      &.article-read-count {
        display: none;
      }
    }

    @media (max-width: 47.9375em) {
      &.article-read-count,
      &.article-last-edited {
        display: none;
      }
    }
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
