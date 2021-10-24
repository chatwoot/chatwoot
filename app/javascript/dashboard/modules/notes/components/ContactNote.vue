<template>
  <div class="card note-wrap">
    <p class="note__content" v-html="formatMessage(note || '')" />
    <div class="footer">
      <div class="meta">
        <thumbnail
          :title="userName"
          :src="thumbnail"
          :username="userName"
          size="20px"
        />
        <div class="date-wrap">
          <span>{{ readableTime }}</span>
        </div>
      </div>
      <div class="actions">
        <!-- <woot-button
          variant="smooth"
          size="tiny"
          icon="ion-compose"
          color-scheme="secondary"
          @click="onEdit"
        /> -->
        <woot-button
          variant="smooth"
          size="tiny"
          icon="ion-trash-b"
          color-scheme="secondary"
          @click="onDelete"
        />
      </div>
    </div>
  </div>
</template>

<script>
import Thumbnail from 'dashboard/components/widgets/Thumbnail';
import timeMixin from 'dashboard/mixins/time';
import messageFormatterMixin from 'shared/mixins/messageFormatterMixin';

export default {
  components: {
    Thumbnail,
  },

  mixins: [timeMixin, messageFormatterMixin],

  props: {
    id: {
      type: Number,
      default: 0,
    },
    note: {
      type: String,
      default: '',
    },
    user: {
      type: Object,
      default: () => {},
    },
    createdAt: {
      type: Number,
      default: 0,
    },
    thumbnail: {
      type: String,
      default: '',
    },
  },

  computed: {
    readableTime() {
      return this.dynamicTime(this.createdAt);
    },
    userName() {
      const user = this.user || {};
      return user.name;
    },
  },

  methods: {
    onEdit() {
      this.$emit('edit', this.id);
    },
    onDelete() {
      this.$emit('delete', this.id);
    },
  },
};
</script>

<style lang="scss" scoped>
.note__content {
  margin-bottom: var(--space-smaller);
}

.footer {
  display: flex;
  justify-content: space-between;
  align-items: flex-end;
  font-size: var(--font-size-mini);

  .meta {
    display: flex;
    align-items: center;

    .date-wrap {
      margin-left: var(--space-smaller);
      padding: var(--space-micro);
      color: var(--color-body);
    }
  }
  .actions {
    display: flex;
    visibility: hidden;

    .button {
      margin-left: var(--space-small);
    }
  }
}

.note-wrap:hover {
  .actions {
    visibility: visible;
  }
}
</style>
