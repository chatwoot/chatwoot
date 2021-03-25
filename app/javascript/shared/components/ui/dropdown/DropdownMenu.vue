<template>
  <ul
    class="dropdown menu vertical"
    :class="[placement && `dropdown--${placement}`]"
  >
    <slot></slot>
  </ul>
</template>
<script>
export default {
  name: 'WootDropdownMenu',
  componentName: 'WootDropdownMenu',

  props: {
    placement: {
      type: String,
      default: 'top',
    },
  },
};
</script>
