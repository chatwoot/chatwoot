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
import { mixin as clickaway } from 'vue-clickaway';

export default {
  components: {
    Chrome,
  },
  mixins: [clickaway],
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
  border: 1px solid var(--color-border-light);
  border-radius: $space-smaller;
  cursor: pointer;
  height: $space-large;
  margin-bottom: $space-normal;
  width: $space-large;
}

.colorpicker--chrome.vc-chrome {
  @include elegant-card;

  border: 1px solid $color-border;
  border-radius: $space-smaller;
  margin-top: -$space-one;
  position: absolute;
  z-index: 9999;
}
</style>
