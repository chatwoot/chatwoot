<script>
import WootDropdownHeader from 'shared/components/ui/dropdown/DropdownHeader.vue';

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

<template>
  <li class="sub-menu-container">
    <ul class="sub-menu-li-container">
      <WootDropdownHeader v-if="title" :title="title" />
      <slot />
    </ul>
  </li>
</template>

<style lang="scss" scoped>
.sub-menu-container {
  margin-top: var(--space-micro);
}

.sub-menu-li-container {
  margin: 0;
}
</style>
