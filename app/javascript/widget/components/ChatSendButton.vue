<template>
  <button
    type="submit"
    :disabled="disabled"
    class="icon-button flex items-center justify-center bg-[#F0F0F0] hover-button shadow-[0px_1.25px_0px_rgba(0,0,0,0.05)] p-2 rounded-md h-9 w-9 transition-all duration-200"
    :style="`--widget-color: ${widgetColor}; --text-color: ${textColor};`"
    @click="onClick"
  >
    <fluent-icon
      v-if="!loading"
      icon="chevron-right"
      :style="`color: ${color}`"
      class="icon-color"
    />
    <spinner v-else size="small" />
  </button>
</template>

<script>
import Spinner from 'shared/components/Spinner.vue';
import FluentIcon from 'shared/components/FluentIcon/Index.vue';
import { mapGetters } from 'vuex';
import { getContrastingTextColor } from '@chatwoot/utils';

export default {
  components: {
    FluentIcon,
    Spinner,
  },
  props: {
    loading: {
      type: Boolean,
      default: false,
    },
    disabled: {
      type: Boolean,
      default: false,
    },
    onClick: {
      type: Function,
      default: () => {},
    },
    color: {
      type: String,
      default: '#808080',
    },
  },
  computed: {
    ...mapGetters({
      widgetColor: 'appConfig/getWidgetColor',
    }),
    textColor() {
      return getContrastingTextColor(this.widgetColor);
    },
  },
};
</script>

<style scoped>
.hover-button:hover {
  background-color: var(--widget-color) !important;
}

.hover-button:hover .icon-color {
  color: var(--text-color) !important;
}
</style>
