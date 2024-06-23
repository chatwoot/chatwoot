<template>
  <div
    class="flex flex-col bg-white z-50 dark:bg-slate-900 w-[200px] border shadow-md border-slate-100 dark:border-slate-700/50 rounded-xl divide-y divide-slate-100 dark:divide-slate-700/50"
  >
    <div>
      <span
        class="font-medium text-xs py-4 px-3 text-slate-400 dark:text-slate-400"
      >
        {{ $t('INBOX.DISPLAY_MENU.DISPLAY') }}
      </span>
      <div
        class="flex flex-col divide-y divide-slate-100 dark:divide-slate-700/50"
      >
        <div
          v-for="option in displayOptionsInput"
          :key="option.key"
          class="flex items-center px-3 py-2 gap-1.5 h-9"
        >
          <input
            :id="option.key"
            v-model="option.selected"
            type="checkbox"
            :name="option.key"
            :value="option.selected"
            class="m-0 border-[1.5px] shadow border-slate-200 dark:border-slate-600 appearance-none rounded-[4px] w-4 h-4 dark:bg-slate-800 focus:ring-1 focus:ring-slate-100 dark:focus:ring-slate-700 checked:bg-woot-600 dark:checked:bg-woot-600 after:content-[''] after:text-white checked:after:content-['✓'] after:flex after:items-center after:justify-center checked:border-t checked:border-woot-700 dark:checked:border-woot-300 checked:border-b-0 checked:border-r-0 checked:border-l-0 after:text-center after:text-xs after:font-bold after:relative after:-top-[1.5px]"
            @input="updateDisplayOption(option)"
          />
          <label
            :for="option.key"
            class="text-sm font-medium text-slate-800 !ml-0 !mr-0 dark:text-slate-200"
          >
            {{ option.name }}
          </label>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  props: {
    displayOptions: {
      type: Object,
      default: null,
    },
  },
  computed: {
    displayOptionsInput() {
      return Object.entries(this.displayOptions).map(([key, value]) => {
        return {
          key: key,
          selected: value,
          name: this.$t(`CARD_DISPLAY.${key}.OPTION_LABEL`),
        };
      });
    },
  },
  methods: {
    updateDisplayOption(option) {
      this.$emit('option-changed', option);
    },
  },
};
</script>
