<script>
import { mapGetters } from 'vuex';

export default {
  components: {},
  props: {
    action: {
      type: Object,
      default: () => {},
    },
    isSelected: {
      type: Boolean,
      default: false,
    },
  },
  emits: ['optionSelect'],
  computed: {
    ...mapGetters({
      widgetColor: 'appConfig/getWidgetColor',
    }),
  },
  methods: {
    onClick() {
      this.$emit('optionSelect', this.action);
    },
  },
};
</script>

<template>
  <li
    class="option"
    :class="{ 'is-selected': isSelected }"
    :style="{ borderColor: widgetColor }"
  >
    <button class="option-button button" @click="onClick">
      <span :style="{ color: widgetColor }">{{ action.title }}</span>
    </button>
  </li>
</template>

<style scoped lang="scss">
.option {
  @apply rounded-[5rem] border border-solid border-n-brand ltr:float-left rtl:float-right m-1 max-w-full;

  .option-button {
    @apply bg-transparent border-0 cursor-pointer h-auto leading-normal ltr:text-left rtl:text-right whitespace-normal rounded-[2rem] min-h-[2.5rem];

    span {
      display: inline-block;
      vertical-align: middle;
    }
  }
}
</style>
