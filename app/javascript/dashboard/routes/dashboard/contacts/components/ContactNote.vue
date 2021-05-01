<template>
  <div class="note-wrap">
    <div class="text">
      {{ note }}
    </div>
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
          class="button-wrap"
          @click="onEdit"
        />
        <woot-button
          variant="clear"
          size="small"
          icon="ion-trash-b"
          color-scheme="secondary"
          class-names="button--emoji"
          class="button-wrap"
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
      this.$emit('edit');
    },
    onDelete() {
      this.$emit('delete');
    },
  },
};
</script>

<style lang="scss" scoped>
.note-wrap {
  padding: var(--space-small);
  border: 1px solid var(--color-border);
  border-radius: var(--border-radius-small);

  .text {
    padding-bottom: var(--space-small);
    font-size: var(--font-size-mini);
    color: var(--color-body);
  }
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
    display: none;
  }
}

.note-wrap:hover {
  .actions {
    display: flex;

    .button-wrap {
      margin-right: var(--space-small);
      height: var(--space-medium);
      width: var(--space-medium);
    }
  }
}
</style>
