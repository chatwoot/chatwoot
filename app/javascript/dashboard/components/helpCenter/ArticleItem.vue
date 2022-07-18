<template>
  <tr>
    <td>
      <div class="row--article-block">
        <div class="article-block">
          <h6 class="sub-block-title text-truncate">
            <router-link class="article-name" :to="articlePath">
              {{ title }}
            </router-link>
          </h6>
          <div class="author">
            <span class="by">{{ $t('HELP_CENTER.TABLE.COLUMNS.BY') }}</span>
            <span class="name">{{ articleAuthorName }}</span>
          </div>
        </div>
      </div>
    </td>
    <td>{{ category }}</td>
    <td>{{ readCount }}</td>
    <td>
      <Label :title="status" :color-scheme="labelColor" />
    </td>
    <td>{{ lastUpdatedAt }}</td>
  </tr>
</template>
<script>
import { frontendURL } from 'dashboard/helper/URLHelper';
import Label from 'dashboard/components/ui/Label';
import timeMixin from 'dashboard/mixins/time';
export default {
  components: {
    Label,
  },
  mixins: [timeMixin],

  props: {
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
      type: String,
      default: '',
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
    articlePath() {
      return frontendURL(`accounts/${this.accountId}/hc/articles/${this.id}`);
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
  align-items: center;
  display: flex;
  text-align: left;

  .article-block {
    min-width: 0;
  }

  .sub-block-title {
    margin-bottom: 0;
  }

  .article-name {
    font-size: var(--font-size-small);
    font-weight: var(--font-weight-default);
    margin: 0;
    text-transform: capitalize;
    color: var(--s-900);
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
      font-size: var(--font-size-mini);
    }
  }
}
</style>
