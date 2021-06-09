<template>
  <div class="reminder-wrap">
    <div class="status-wrap">
      <input :checked="isCompleted" type="radio" @click="onClick" />
    </div>
    <div class="wrap">
      <p class="content">
        {{ text }}
      </p>
      <div class="footer">
        <div class="meta">
          <woot-label
            :title="date"
            description="date"
            icon="ion-android-calendar"
            color-scheme="secondary"
          />
          <woot-label
            :title="label"
            description="label"
            color-scheme="secondary"
          />
        </div>
        <div class="actions">
          <woot-button
            variant="smooth"
            size="small"
            icon="ion-compose"
            color-scheme="secondary"
            class="action-button"
            @click="onEdit"
          />
          <woot-button
            variant="smooth"
            size="small"
            icon="ion-trash-b"
            color-scheme="secondary"
            class="action-button"
            @click="onDelete"
          />
        </div>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  props: {
    id: {
      type: Number,
      default: 0,
    },
    text: {
      type: String,
      default: '',
    },
    isCompleted: {
      type: Boolean,
      default: false,
    },
    date: {
      type: String,
      default: '',
    },
    label: {
      type: String,
      default: '',
    },
  },

  methods: {
    onClick() {
      this.$emit('completed', this.isCompleted);
    },
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
.reminder-wrap {
  display: flex;
  margin-bottom: var(--space-smaller);

  .status-wrap {
    padding: var(--space-small) var(--space-smaller);
    margin-top: var(--space-smaller);
  }

  .wrap {
    padding: var(--space-small);

    .footer {
      display: flex;
      justify-content: space-between;

      .meta {
        display: flex;
      }
    }
  }
}

.actions {
  display: none;

  .action-button {
    margin-right: var(--space-small);
    height: var(--space-medium);
    width: var(--space-medium);
  }
}

.reminder-wrap:hover {
  .actions {
    display: flex;
  }
}
</style>
