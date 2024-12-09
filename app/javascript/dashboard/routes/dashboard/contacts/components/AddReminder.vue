<script>
export default {
  props: {
    options: {
      type: Array,
      default: () => [],
    },
  },
  emits: ['add'],
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

<template>
  <div class="wrap">
    <div class="input-select-wrap">
      <textarea
        v-model="content"
        class="input--reminder"
        @keydown.enter.shift.exact="onAdd"
      />
      <div class="select-wrap">
        <div class="select">
          <div class="input-group">
            <i class="ion-android-calendar input-group-label" />
            <input
              v-model="date"
              type="text"
              :placeholder="$t('REMINDER.FOOTER.DUE_DATE')"
              class="input-group-field"
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
          :title="$t('REMINDER.ADD_BUTTON.TITLE')"
          :is-disabled="buttonDisabled"
          @click="onAdd"
        >
          {{ $t('REMINDER.ADD_BUTTON.BUTTON') }}
        </woot-button>
      </div>
    </div>
  </div>
</template>

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

    .input-group {
      margin-bottom: 0;
      font-size: var(--font-size-mini);

      .input-group-field {
        height: var(--space-medium);
        font-size: var(--font-size-micro);
      }
    }

    .task-wrap {
      .task__type {
        margin: 0 0 0 var(--space-smaller);
        height: var(--space-medium);
        width: fit-content;
        padding: 0 var(--space-two) 0 var(--space-smaller);
        font-size: var(--font-size-micro);
      }
    }
  }
}
</style>
