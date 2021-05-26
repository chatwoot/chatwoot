<template>
  <div class="wrap">
    <div class="input-select-wrap">
      <textarea
        v-model="content"
        class="input--reminder"
        @keydown.enter.shift.exact="onAdd"
      >
      </textarea>
      <div class="select-wrap">
        <div class="select">
          <div class="date-wrap">
            <i class="icon ion-android-calendar" />
            <input
              v-model="date"
              type="text"
              :placeholder="$t('REMINDER.FOOTER.DUE_DATE')"
              class="date-input"
            />
          </div>
          <div class="task-wrap">
            <select class="task__type" @change="optionSelected($event)">
              <option value="" disabled selected>
                {{ $t('REMINDER.FOOTER.LABEL_TITLE') }}
              </option>
              <option
                v-for="option in options"
                :key="option.id"
                :value="option.id"
              >
                {{ option.name }}
              </option>
            </select>
          </div>
        </div>
        <woot-button
          size="tiny"
          color-scheme="primary"
          class-names="add-button"
          :is-disabled="buttonDisabled"
          @click="onAdd"
        >
          Add
        </woot-button>
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
  computed: {
    buttonDisabled() {
      return this.content && this.date === '';
    },
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

  .input-select-wrap {
    padding: var(--space-small) var(--space-small);
    width: 100%;

    .input--reminder {
      font-size: var(--font-size-mini);
      margin-bottom: var(--space-small);
      resize: none;
    }

    .select-wrap {
      display: flex;
      justify-content: space-between;

      .select {
        display: flex;
      }
    }

    .date-wrap {
      position: relative;

      .icon {
        position: absolute;
        margin-left: var(--space-small);
        top: 5px;
      }

      .date-input {
        font-size: var(--font-size-micro);
        height: var(--space-medium);
        padding: var(--space-smaller) var(--space-smaller) var(--space-smaller)
          var(--space-two);
      }
    }

    .task-wrap {
      .task__type {
        margin: 0 0 0 var(--space-smaller);
        height: var(--space-medium);
        padding: 0 var(--space-two) 0 var(--space-smaller);
        font-size: var(--font-size-micro);
      }
    }
  }
}
</style>
