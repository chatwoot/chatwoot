<template>
  <div
    class="grid grid-cols-1 gap-4 px-6 py-3 my-0 -mx-4 bg-white border-b text-slate-700 dark:text-slate-100 last:border-b-0 dark:bg-slate-900 lg:grid-cols-12 border-slate-50 dark:border-slate-800"
  >
    <span class="flex items-start col-span-6 gap-2 text-left">
      <fluent-icon
        v-if="showDragIcon"
        size="20"
        class="flex-shrink-0 block w-4 h-4 mt-1 cursor-move text-slate-200 dark:text-slate-700 hover:text-slate-400 hover:dark:text-slate-200"
        icon="grab-handle"
      />
      <div class="flex flex-col truncate">
        <router-link :to="articleUrl(id)">
          <h6
            :title="title"
            class="text-base ltr:text-left rtl:text-right text-slate-800 dark:text-slate-100 mb-0.5 leading-6 font-medium hover:underline overflow-hidden whitespace-nowrap text-ellipsis"
          >
            {{ title }}
          </h6>
        </router-link>
        <div class="flex items-center gap-1">
          <Thumbnail
            v-if="author"
            :src="author.thumbnail"
            :username="author.name"
            size="14px"
          />
          <div
            v-else
            v-tooltip.right="
              $t('HELP_CENTER.TABLE.COLUMNS.AUTHOR_NOT_AVAILABLE')
            "
            class="flex items-center justify-center rounded w-3.5 h-3.5 bg-woot-100 dark:bg-woot-700"
          >
            <fluent-icon
              icon="person"
              type="filled"
              size="10"
              class="text-woot-300 dark:text-woot-300"
            />
          </div>
          <span class="text-sm font-normal text-slate-700 dark:text-slate-200">
            {{ articleAuthorName }}
          </span>
        </div>
      </div>
    </span>
    <span class="flex items-center col-span-2">
      <router-link
        class="text-sm hover:underline p-0.5 truncate hover:bg-slate-25 hover:rounded-md"
        :to="getCategoryRoute(category.slug)"
      >
        <span :title="category.name">
          {{ category.name }}
        </span>
      </router-link>
    </span>
    <span
      class="flex items-center text-xs lg:text-sm"
      :title="formattedViewCount"
    >
      {{ readableViewCount }}
      <span class="ml-1 lg:hidden">
        {{ ` ${$t('HELP_CENTER.TABLE.HEADERS.READ_COUNT')}` }}
      </span>
    </span>
    <span class="flex items-center capitalize">
      <woot-label
        class="!mb-0"
        :title="status"
        size="small"
        variant="smooth"
        :color-scheme="labelColor"
      />
    </span>
    <span
      class="flex items-center justify-end col-span-2 text-xs first-letter:uppercase text-slate-700 dark:text-slate-100"
    >
      {{ lastUpdatedAt }}
    </span>
  </div>
</template>

<script>
import { dynamicTime } from 'shared/helpers/timeHelper';
import portalMixin from '../mixins/portalMixin';
import { frontendURL } from 'dashboard/helper/URLHelper';
import Thumbnail from 'dashboard/components/widgets/Thumbnail.vue';

export default {
  components: {
    Thumbnail,
  },
  mixins: [portalMixin],
  props: {
    showDragIcon: {
      type: Boolean,
      default: false,
    },
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
      return dynamicTime(this.updatedAt);
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
