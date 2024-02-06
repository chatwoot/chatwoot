<template>
  <base-icon
    :size="size"
    :icon="icon"
    :type="type"
    :icons="icons"
    :view-box="viewBox"
    :icon-lib="iconLib"
  />
</template>
<script>
import BaseIcon from './Icon.vue';
import icons from './dashboard-icons.json';

export default {
  name: 'FluentIcon',
  components: {
    BaseIcon,
  },
  props: {
    icon: {
      type: String,
      required: true,
    },
    size: {
      type: [String, Number],
      default: '20',
    },
    type: {
      type: String,
      default: 'outline',
    },
    viewBox: {
      type: String,
      default: '0 0 24 24',
    },
    iconLib: {
      type: String,
      default: 'fluent',
    },
  },
  data() {
    return { icons };
  },
};
</script>
