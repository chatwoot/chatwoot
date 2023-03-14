<template>
  <button
    type="submit"
    :disabled="disabled"
    class="icon-button flex items-center justify-center shadow-sm"
    :style="{ backgroundColor: widgetColor }"
    @click="onClick"
  >
    <fluent-icon v-if="!loading" icon="send" :style="`color: ${textColor}`" />
    <spinner v-else size="small" />
  </button>
</template>

<script>
import { mapGetters } from 'vuex';
import { getContrastingTextColor } from '@chatwoot/utils';
import Spinner from 'shared/components/Spinner.vue';
import FluentIcon from 'shared/components/FluentIcon/Index.vue';

export default {
  components: {
    FluentIcon,
    Spinner,
  },
  computed: {
    ...mapGetters({
      widgetColor: 'appConfig/getWidgetColor',
    }),
    textColor() {
      return getContrastingTextColor(this.widgetColor);
    },
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
      default: '#6e6f73',
    },
  },
};
</script>

<style scoped lang="scss">
@import '~widget/assets/scss/variables.scss';

.icon-button {
  border-radius: 50%;
  background-color: $color-woot;
  margin-bottom: $space-micro;
  padding: $space-slab;
}
</style>
