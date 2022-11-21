<template>
  <tr class="row--article-block">
    <td>
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
    </td>
    <td>
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
    </td>
    <td>
      <span class="fs-small">
        {{ readCount }}
      </span>
    </td>
    <td>
      <div>
        <woot-label
          :title="status"
          size="small"
          variant="smooth"
          :color-scheme="labelColor"
        />
      </div>
    </td>
    <td>
      <span class="fs-small">
        {{ lastUpdatedAt }}
      </span>
    </td>
  </tr>
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
    readCount: {
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
td {
  font-weight: var(--font-weight-normal);
  color: var(--s-700);
  font-size: var(--font-size-mini);
  padding-left: 0;
}
.row--article-block {
  border-bottom-color: transparent;
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

.category-link-content {
  max-width: 16rem;
  line-height: 1.5;
}
</style>
