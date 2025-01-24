<template>
  <with-label
    :label="label"
    :icon="icon"
    :name="name"
    :has-error="hasError"
    :error-message="errorMessage"
  >
    <template #rightOfLabel>
      <slot />
    </template>
    <div class="relative w-full">
      <div
        ref="inputDiv"
        class="inputDiv"
        contenteditable="true"
        @input="onInput"
        @blur="hideSuggestions"
        @focus="showSuggestions"
      ></div>
      <ul
        v-if="showSuggestionList && suggestions.length > 0"
        class="content_select"
      >
        <li
          v-for="(suggestion, index) in suggestions"
          :key="index"
          @mousedown="selectSuggestion(suggestion)"
          class="multiselect__option"
          :class="{
            'multiselect__option--selected':
              selectedSuggestion && selectedSuggestion.name === suggestion.name,
          }"
        >
          {{ suggestion && suggestion.name }}
        </li>
      </ul>
    </div>
  </with-label>
</template>
<script>
import WithLabel from './WithLabel.vue';

export default {
  components: {
    WithLabel,
  },
  props: {
    label: {
      type: String,
      default: '',
    },
    name: {
      type: String,
      default: '',
    },
    type: {
      type: String,
      default: 'text',
    },
    tabindex: {
      type: Number,
      default: undefined,
    },
    required: {
      type: Boolean,
      default: false,
    },
    placeholder: {
      type: String,
      default: '',
    },
    value: {
      type: [String, Number],
      default: '',
    },
    icon: {
      type: String,
      default: '',
    },
    hasError: {
      type: Boolean,
      default: false,
    },
    errorMessage: {
      type: String,
      default: '',
    },
    dataTestid: {
      type: String,
      default: '',
    },
    spacing: {
      type: String,
      default: 'base',
      validator: value => ['base', 'compact'].includes(value),
    },
    suggestions: {
      type: Array,
      default: () => [],
    },
    selected: {
      type: String,
      default: '',
    },
  },
  data() {
    return {
      inputValue: this.value,
      showSuggestionList: false,
      isSuggestionSelected: false,
      selectedSuggestion: {},
    };
  },

  mounted() {
    if (this.selected) {
      console.log(this.selected);
      this.inputValue = this.selected;
      this.$nextTick(() => {
        const element = this.$refs.inputDiv;
        if (element) {
          element.textContent = this.selected;
        }
        this.suggestions.forEach(suggestion => {
          if (suggestion.name === this.selected) {
            this.$refs.inputDiv.innerHTML = `<span class="highlighted-suggestion">${this.selected}</span>`;
          }
        });
      });
    }
  },

  watch: {
    value(newValue) {
      this.inputValue = newValue;
    },
    inputValue(newValue) {
      this.selectedSuggestion = this.suggestions.filter(suggestion => {
        return suggestion.name === newValue;
      })[0];

      this.$emit('input', newValue.trim());

      if (this.selectedSuggestion) {
        this.$refs.inputDiv.innerHTML = `<span class="highlighted-suggestion">${this.selectedSuggestion.name}</span>`;
        this.$emit('variable', this.selectedSuggestion);
      }
    },

    selectedSuggestion(newValue) {
      this.isSuggestionSelected = !!newValue;
      const inputDiv = this.$refs.inputDiv;
      this.setCaretToEnd(inputDiv);

      if (!this.isSuggestionSelected) {
        const content = inputDiv.textContent;
        inputDiv.removeChild(inputDiv.firstChild);
        inputDiv.textContent = content;
        this.setCaretToEnd(inputDiv);
      }
    },
  },
  methods: {
    onInput(e) {
      this.inputValue = e.target.textContent;
    },
    selectSuggestion(suggestion) {
      this.inputValue = suggestion.name;
      this.showSuggestionList = false;
      this.$emit('input', suggestion.name);
    },

    setCaretToEnd(element) {
      // move o cursor para o final da div
      const range = document.createRange();
      const selection = window.getSelection();
      range.setStart(element, 1);
      range.collapse(true);
      selection.removeAllRanges();
      selection.addRange(range);
    },

    showSuggestions() {
      this.showSuggestionList = true;
    },
    hideSuggestions() {
      setTimeout(() => {
        this.showSuggestionList = false;
      }, 100);
    },
  },
};
</script>

<style scoped lang="scss">
.inputDiv {
  @apply block w-full outline-none box-border transition-colors focus:border-woot-500 dark:focus:border-woot-600 duration-[0.25s] ease-[ease-in-out] h-10 text-base font-normal bg-white focus:bg-white focus:dark:bg-slate-900 border border-solid border-slate-200 dark:border-slate-600 p-2 rounded-md shadow-sm appearance-none outline outline-1 focus:outline-2 text-slate-900 dark:text-slate-100 placeholder:text-slate-400 sm:text-sm sm:leading-6 dark:bg-slate-900;
}

.content_select {
  @apply w-full bg-white dark:bg-slate-900 
  border border-solid border-slate-200 dark:border-slate-700
 text-slate-800 dark:text-slate-100 rounded-md overflow-hidden
  min-h-[2.5rem] absolute top-[42px] z-10;

  .multiselect__option {
    @apply text-sm font-normal bg-woot-50 dark:bg-slate-900 text-slate-800 dark:text-slate-100 p-2;
  }

  .multiselect__option:hover {
    @apply bg-woot-75 dark:bg-woot-600 text-slate-800 dark:text-slate-100;

    &::after {
      @apply bg-woot-75 dark:bg-woot-600 text-slate-600 dark:text-slate-200;
    }
  }

  .multiselect__option--selected {
    @apply bg-woot-75 dark:bg-woot-600 text-slate-800 dark:text-slate-100;

    &.multiselect__option--highlight:hover {
      @apply bg-woot-75 dark:bg-woot-600;

      &::after {
        @apply bg-transparent;
      }

      &::after:hover {
        @apply text-slate-800 dark:text-slate-100;
      }
    }
  }
}

.multiselect__tag {
  @apply bg-slate-50 dark:bg-slate-800 mt-1 text-slate-800 dark:text-slate-100 pr-6 pl-2.5 py-1.5;
}

.no-margin {
  margin: 0 !important ;
}
</style>
