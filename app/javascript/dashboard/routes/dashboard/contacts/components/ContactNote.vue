<template>
  <div class="card note-wrap">
    <p class="note__content">
      {{ note }}
    </p>
    <div class="footer">
      <div class="meta">
        <div :title="userName">
          <Thumbnail :src="thumbnail" :username="userName" size="16px" />
        </div>
        <div class="date-wrap">
          <span>{{ readableTime }}</span>
        </div>
      </div>
      <div class="actions">
        <woot-button
          variant="clear"
          size="small"
          icon="ion-compose"
          color-scheme="secondary"
          class-names="button--emoji"
          @click="onEdit"
        />
        <woot-button
          variant="clear"
          size="small"
          icon="ion-trash-b"
          color-scheme="secondary"
          class-names="button--emoji"
          @click="onDelete"
        />
      </div>
    </div>
  </div>
</template>

<script>
import Thumbnail from 'dashboard/components/widgets/Thumbnail.vue';
import timeMixin from 'dashboard/mixins/time';
import WootButton from 'dashboard/components/ui/WootButton.vue';

export default {
  components: {
    Thumbnail,
    WootButton,
  },

  mixins: [timeMixin],

  props: {
    id: {
      type: Number,
      default: 0,
    },
    note: {
      type: String,
      default: '',
    },
    userName: {
      type: String,
      default: '',
    },
    timeStamp: {
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
      return this.dynamicTime(this.timeStamp);
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
  font-size: var(--font-size-mini);
  margin-bottom: var(--space-small);
}

.footer {
  display: flex;
  justify-content: space-between;

  .meta {
    display: flex;
    padding: var(--space-smaller) 0;

    .date-wrap {
      margin-left: var(--space-smaller);
      padding: var(--space-micro);
      color: var(--color-body);
      font-size: var(--font-size-micro);
    }
  }
  .actions {
    display: flex;
    visibility: hidden;
  }

  .button--emoji {
    margin-left: var(--space-small);
    height: var(--space-medium);
    width: var(--space-medium);
  }
}

.note-wrap:hover {
  .actions {
    visibility: visible;
  }
}
</style>
