<template>
  <div class="article-container--row">
    <span class="article-column article-title">
      <emoji-or-icon class="icon-grab" icon="grab-handle" />
      <div class="article-block">
        <router-link :to="articleUrl(id)">
          <h6
            :title="title"
            class="text-base ltr:text-left rtl:text-right text-slate-800 dark:text-slate-100 mb-0 leading-6 h-6 hover:underline overflow-hidden whitespace-nowrap text-ellipsis"
          >
            {{ title }}
          </h6>
        </router-link>
        <div class="flex gap-1 items-center">
          <Thumbnail
            v-if="author"
            :src="author.thumbnail"
            :username="author.name"
            size="16px"
          />
          <div
            v-else
            v-tooltip.right="
              $t('HELP_CENTER.TABLE.COLUMNS.AUTHOR_NOT_AVAILABLE')
            "
            class="flex items-center justify-center rounded w-4 h-4 bg-woot-100 dark:bg-woot-700"
          >
            <fluent-icon
              icon="person"
              type="filled"
              size="10"
              class="text-woot-300 dark:text-woot-300"
            />
          </div>
          <span class="font-normal text-slate-500 dark:text-slate-200 text-sm">
            {{ articleAuthorName }}
          </span>
        </div>
      </div>
    </span>
    <span class="article-column article-category">
      <router-link
        class="text-sm button clear link secondary min-w-0 max-w-full"
        :to="getCategoryRoute(category.slug)"
      >
        <span
          :title="category.name"
          class="category-link-content overflow-hidden whitespace-nowrap text-ellipsis"
        >
          {{ category.name }}
        </span>
      </router-link>
    </span>
    <span class="article-column article-read-count">
      <span class="text-sm" :title="formattedViewCount">
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
      <span class="text-sm">
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
import Thumbnail from 'dashboard/components/widgets/Thumbnail.vue';

export default {
  components: {
    EmojiOrIcon,
    Thumbnail,
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
      return this.author?.name || '-';
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
  @apply bg-white dark:bg-slate-900 my-0 -mx-4 py-0 px-4 grid grid-cols-8 gap-4 border-b border-slate-50 dark:border-slate-800;

  @media (max-width: 1024px) {
    @apply grid-cols-7;
  }

  @media (max-width: 768px) {
    @apply grid-cols-6;
  }

  &.draggable {
    span.article-column.article-title {
      @apply -ml-2;

      .icon-grab {
        @apply block cursor-move h-4 mt-1 w-4 text-slate-100 dark:text-slate-700;

        &:hover {
          @apply text-slate-300 dark:text-slate-200;
        }
      }
    }
  }

  span.article-column {
    @apply text-slate-700 dark:text-slate-100 text-sm font-semibold py-2 px-0 text-left capitalize last:text-right;

    &.article-title {
      @apply items-start flex gap-2 col-span-4 text-left;

      .icon-grab {
        @apply hidden;
      }
    }

    // for screen sizes smaller than 1024px
    @media (max-width: 63.9375em) {
      &.article-read-count {
        @apply hidden;
      }
    }

    @media (max-width: 47.9375em) {
      &.article-read-count,
      &.article-last-edited {
        @apply hidden;
      }
    }
  }

  .article-block {
    @apply min-w-0;
  }
}

span {
  @apply font-normal text-slate-700 dark:text-slate-100 text-sm pl-0;
}
</style>
