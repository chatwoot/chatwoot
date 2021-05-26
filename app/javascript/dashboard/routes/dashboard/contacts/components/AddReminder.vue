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
          <select class="label" @change="optionSelected($event)">
            <option value="" disabled selected>
              {{ $t('REMINDER.FOOTER.LABEL_TITLE') }}
            </option>
            <option
              v-for="option in options"
              :key="option.id"
              :value="option.name"
            >
              {{ option.name }}
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
    options: {
      type: Array,
      default: () => [],
    },
  },
  data() {
    return {
      content: '',
      date: '',
      label: '',
    };
  },
  methods: {
    resetValue() {
      this.content = '';
      this.date = '';
    },

    optionSelected(event) {
      this.label = event.target.value;
    },

    onAdd() {
      const task = {
        content: this.content,
        date: this.date,
        label: this.label,
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
    margin: var(--space-slab) 0 0 var(--space-smaller);
    font-size: var(--font-size-medium);
  }

  .input-select-wrap {
    padding: var(--space-one) var(--space-one) var(--space-one)
      var(--space-small);
    width: 100%;

    .input {
      border: 1px solid var(--color-border);
      margin-bottom: var(--space-smaller);
      border-radius: var(--border-radius-small);

      .input--reminder {
        font-size: var(--font-size-mini);
        border-color: transparent;
        resize: none;
        box-sizing: border-box;
        margin-bottom: var(--space-small);
      }
    }

    .select {
      display: flex;
    }

    .date-wrap {
      position: relative;

      .icon {
        position: absolute;
        margin-left: var(--space-slab);
        top: 3px;
      }

      .date-input {
        border: 1px solid var(--color-border);
        border-radius: var(--border-radius-small);
        padding: var(--space-smaller) var(--space-smaller) var(--space-smaller)
          var(--space-medium);
        background: var(--color-background-light);
        color: var(--color-body);

        &:focus {
          border: 1px solid var(--color-border-dark);
        }
      }
    }

    .label-wrap {
      .label {
        margin: 0 0 0 var(--space-smaller);
        border: 1px solid var(--color-border);
        background: var(--color-background-light);
        font-size: var(--font-size-micro);
        height: auto;
        line-height: 1.1;
        border-radius: var(--border-radius-small);
        color: var(--s-400);

        &:focus {
          border: 1px solid var(--color-border-dark);
        }
      }
    }
  }
}
</style>
