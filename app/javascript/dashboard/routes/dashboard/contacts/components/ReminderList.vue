<template>
  <div class="note-wrap">
    <div class="radio-button">
      <input type="radio" />
    </div>
    <div class="wrap">
      <div class="text">
        {{ text }}
      </div>
      <div class="footer">
        <div class="meta">
          <div class="date-wrap">
            <i class="icon ion-android-calendar" />
            <span class="date">
              {{ date }}
            </span>
          </div>
          <div class="label-wrap">
            <div class="label-text">
              {{ label }}
            </div>
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
.note-wrap {
  display: flex;
  margin-bottom: var(--space-smaller);

  .radio-button {
    padding: var(--space-one) var(--space-smaller);
  }

  .wrap {
    padding: var(--space-one);

    .text {
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

        .date-wrap {
          padding: var(--space-micro) var(--space-small);
          border-radius: var(--border-radius-normal);
          background: var(--color-background);
          line-height: var(--space-one);
          display: flex;
          align-items: center;

          .icon {
            font-size: var(--font-size-small);
            font-weight: var(--font-weight-bold);
            color: var(--w-300);
          }

          .date {
            font-size: var(--font-size-micro);
            font-weight: var(--font-weight-bold);
            color: var(--color-body);
            margin-left: var(--space-smaller);
          }
        }

        .label-wrap {
          margin-left: var(--space-one);

          .label-text {
            font-size: var(--font-size-micro);
            color: var(--color-body);
            padding: var(--space-micro) var(--space-small);
            font-weight: var(--font-weight-bold);
            border-radius: var(--border-radius-normal);
            background: var(--color-background);
          }
        }
      }
    }
  }
}

.actions {
  display: none;
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
