<template>
  <div class="wrap">
    <div
      class="add-button"
      :title="$t('REMINDER.ADD_BUTTON.TITLE')"
      @click="onAdd"
    >
      <i class="ion-android-add-circle" />
    </div>
    <div class="input-select-wrap">
      <div class="input">
        <textarea
          v-model="content"
          class="input--reminder"
          @keydown.enter.shift.exact="onAdd"
        >
        </textarea>
      </div>
      <div class="select">
        <div class="date-wrap">
          <i class="icon ion-android-calendar" />
          <input
            v-model="date"
            :placeholder="$t('REMINDER.FOOTER.DUE_DATE')"
            class="date-input"
          />
        </div>
        <div class="label-wrap">
          <select class="label">
            <option value="" disabled selected>
              {{ $t('REMINDER.FOOTER.LABEL_TITLE') }}
            </option>
            <option>
              {{ type }}
            </option>
          </select>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  props: {
    types: {
      type: Array,
      default: () => [],
    },
  },
  data() {
    return {
      content: '',
      date: '',
      type: 'Call',
    };
  },

  methods: {
    resetValue() {
      this.content = '';
      this.date = '';
    },
    onAdd() {
      const task = {
        content: this.content,
        date: this.date,
        type: this.type,
      };
      this.$emit('add', task);
      this.resetValue();
    },
  },
};
</script>

<style lang="scss" scoped>
.wrap {
  display: flex;
  margin-bottom: var(--space-smaller);
  width: 100%;

  .add-button {
    margin: var(--space-slab) var(--space-smaller) 0 0;
    font-size: var(--font-size-medium);
  }

  .input-select-wrap {
    padding: var(--space-one) var(--space-one) var(--space-one)
      var(--space-small);
    width: 100%;

    .input {
      display: flex;
      width: 100%;
      border: 1px solid var(--color-border);
      border-radius: var(--border-radius-small);

      .input--reminder {
        font-size: var(--font-size-mini);
        border-color: transparent;
        padding: var(--space-small) var(--space-smaller) 0 var(--space-smaller);
        resize: none;
        box-sizing: border-box;
        min-height: var(--space-larger);
        margin-bottom: var(--space-small);
      }
    }

    .select {
      display: flex;
    }

    .date-wrap {
      position: relative;
      margin-top: var(--space-smaller);

      .icon {
        position: absolute;
        margin-left: var(--space-slab);
        top: 3px;
      }

      .date-input {
        border: 1px solid var(--color-border);
        border-radius: var(--border-radius-normal);
        padding: var(--space-smaller) var(--space-smaller) var(--space-smaller)
          var(--space-medium);
        background: var(--color-background-light);
        color: var(--color-body);
        max-width: var(--space-mega);

        &:focus {
          border: 1px solid var(--color-border-dark);
        }
      }
    }

    .label-wrap {
      .label {
        margin-left: var(--space-smaller);
        margin-top: var(--space-smaller);
        border: 1px solid var(--color-border);
        background: var(--color-background-light);
        font-size: var(--font-size-micro);
        height: auto;
        padding: var(--space-smaller);
        line-height: 1.1;
        border-radius: var(--border-radius-normal);
        color: var(--s-200);

        &:focus {
          border: 1px solid var(--color-border-dark);
        }
      }
    }
  }
}
</style>
