<template>
  <li class="sub-menu-container">
    <ul class="sub-menu-li-container">
      <woot-dropdown-header :title="title" />
      <slot />
    </ul>
  </li>
</template>
<script>
import WootDropdownHeader from 'shared/components/ui/dropdown/DropdownHeader';

export default {
  name: 'WootDropdownMenu',
  componentName: 'WootDropdownMenu',

  components: {
    WootDropdownHeader,
  },
  props: {
    title: {
      type: String,
      default: '',
    },
  },
};
</script>
<style lang="scss" scoped>
.sub-menu-container {
  margin-top: var(--space-micro);
}

.sub-menu-li-container {
  margin: 0;
}
</style>
