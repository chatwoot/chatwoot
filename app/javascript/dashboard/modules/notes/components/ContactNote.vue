<template>
  <div class="card note-wrap">
    <div class="header">
      <div class="meta">
        <thumbnail
          :title="noteAuthorName"
          :src="noteAuthor.thumbnail"
          :username="noteAuthorName"
          size="20px"
        />
        <div class="date-wrap">
          <span class="fw-medium"> {{ noteAuthorName }} </span>
          <span> {{ $t('NOTES.LIST.LABEL') }} </span>
          <span class="fw-medium"> {{ readableTime }} </span>
        </div>
      </div>
      <div class="actions">
        <woot-button
          v-tooltip="$t('NOTES.CONTENT_HEADER.DELETE')"
          variant="smooth"
          size="tiny"
          icon="ion-trash-b"
          color-scheme="secondary"
          @click="onDelete"
        />
      </div>
    </div>
    <p class="note__content" v-html="formatMessage(note || '')" />
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
  },

  computed: {
    readableTime() {
      return this.dynamicTime(this.createdAt);
    },
    noteAuthor() {
      return this.user || {};
    },
    noteAuthorName() {
      return this.noteAuthor.name || this.$t('APP_GLOBAL.DELETED_USER');
    },
  },

  methods: {
    onDelete() {
      this.$emit('delete', this.id);
    },
  },
};
</script>

<style lang="scss" scoped>
.note__content {
  margin-top: var(--space-normal);
}

.header {
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
