<template>
  <div class="reminder-wrap">
    <div class="status-wrap">
      <input :checked="isCompleted" @click="onClick" type="radio" />
    </div>
    <div class="wrap">
      <div class="content">
        {{ text }}
      </div>
      <div class="footer">
        <div class="meta">
          <woot-label
            :title="date"
            description="date"
            bg-color="#f4f6fb"
            icon="ion-android-calendar"
            color-scheme="secondary"
          />
          <woot-label
            :title="label"
            description="label"
            bg-color="#f4f6fb"
            color-scheme="secondary"
          />
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
      type: Number,
      default: 0,
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
    padding: var(--space-one) var(--space-smaller);
  }

  .wrap {
    padding: var(--space-one);

    .content {
      padding-bottom: var(--space-small);
      font-size: var(--font-size-mini);
      color: var(--color-body);
    }

    .footer {
      display: flex;
      justify-content: space-between;

      .meta {
        display: flex;
        margin-top: var(--space-smaller);
      }
    }
  }
}

.actions {
  display: none;
}

.reminder-wrap:hover {
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
