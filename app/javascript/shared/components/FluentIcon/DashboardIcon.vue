<template>
  <base-icon :size="size" :icon="icon" :type="type" :icons="icons" />
</template>
<script>
import BaseIcon from './Icon';
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
  },
  data() {
    return { icons };
  },
};
</script>
