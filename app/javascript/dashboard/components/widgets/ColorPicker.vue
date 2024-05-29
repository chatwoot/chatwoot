<template>
  <div class="colorpicker">
    <div
      class="colorpicker--selected"
      :style="`background-color: ${value}`"
      @click.prevent="toggleColorPicker"
    />
    <chrome
      v-if="isPickerOpen"
      v-on-clickaway="closeTogglePicker"
      :disable-alpha="true"
      :value="value"
      class="colorpicker--chrome"
      @input="updateColor"
    />
  </div>
</template>

<script>
import { Chrome } from 'vue-color';

export default {
  components: {
    Chrome,
  },
  props: {
    value: {
      type: String,
      default: '',
    },
  },
  data() {
    return {
      isPickerOpen: false,
    };
  },
  methods: {
    closeTogglePicker() {
      if (this.isPickerOpen) {
        this.toggleColorPicker();
      }
    },
    toggleColorPicker() {
      this.isPickerOpen = !this.isPickerOpen;
    },
    updateColor(e) {
      this.$emit('input', e.hex);
    },
  },
};
</script>

<style scoped lang="scss">
@import '~dashboard/assets/scss/variables';
@import '~dashboard/assets/scss/mixins';

.colorpicker {
  position: relative;
}

.colorpicker--selected {
  @apply border border-solid border-slate-50 dark:border-slate-600 rounded cursor-pointer h-8 w-8 mb-4;
}

.colorpicker--chrome.vc-chrome {
  @apply shadow-lg -mt-2.5 absolute z-[9999] border border-solid border-slate-75 dark:border-slate-600 rounded;

  ::v-deep {
    input {
      @apply bg-white dark:bg-white;
    }
  }
}
</style>
