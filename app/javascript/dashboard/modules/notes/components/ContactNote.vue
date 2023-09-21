<template>
  <div
    class="flex flex-col mb-2 p-4 border border-solid border-slate-75 dark:border-slate-700 overflow-hidden rounded-md flex-grow shadow-sm bg-white dark:bg-slate-900 text-slate-700 dark:text-slate-100 note-wrap"
  >
    <div class="flex justify-between items-end text-xs gap-1">
      <div class="flex items-center">
        <thumbnail
          :title="noteAuthorName"
          :src="noteAuthor.thumbnail"
          :username="noteAuthorName"
          size="20px"
        />
        <div class="my-0 mx-1 p-0.5 flex flex-row gap-1">
          <span class="font-medium text-slate-800 dark:text-slate-100">
            {{ noteAuthorName }}
          </span>
          <span class="text-slate-700 dark:text-slate-100">
            {{ $t('NOTES.LIST.LABEL') }}
          </span>
          <span class="font-medium text-slate-700 dark:text-slate-100">
            {{ readableTime }}
          </span>
        </div>
      </div>
      <div class="actions flex invisible">
        <woot-button
          v-tooltip="$t('NOTES.CONTENT_HEADER.DELETE')"
          variant="smooth"
          size="tiny"
          icon="delete"
          color-scheme="secondary"
          @click="toggleDeleteModal"
        />
      </div>
      <woot-delete-modal
        v-if="showDeleteModal"
        :show.sync="showDeleteModal"
        :on-close="closeDelete"
        :on-confirm="confirmDeletion"
        :title="$t('DELETE_NOTE.CONFIRM.TITLE')"
        :message="$t('DELETE_NOTE.CONFIRM.MESSAGE')"
        :confirm-text="$t('DELETE_NOTE.CONFIRM.YES')"
        :reject-text="$t('DELETE_NOTE.CONFIRM.NO')"
      />
    </div>
    <p
      v-dompurify-html="formatMessage(note || '')"
      class="note__content mt-4"
    />
  </div>
</template>

<script>
import Thumbnail from 'dashboard/components/widgets/Thumbnail.vue';
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
  data() {
    return {
      showDeleteModal: false,
    };
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
    toggleDeleteModal() {
      this.showDeleteModal = !this.showDeleteModal;
    },
    onDelete() {
      this.$emit('delete', this.id);
    },
    confirmDeletion() {
      this.onDelete();
      this.closeDelete();
    },
    closeDelete() {
      this.showDeleteModal = false;
    },
  },
};
</script>

<style lang="scss" scoped>
// For RTL direction view
.app-rtl--wrapper {
  .note__content {
    ::v-deep {
      p {
        unicode-bidi: plaintext;
      }
    }
  }
}

.note-wrap:hover {
  .actions {
    @apply visible;
  }
}
</style>
