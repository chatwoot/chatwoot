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
  <li class="!mt-0.5">
    <ul class="!m-0">
      <WootDropdownHeader v-if="title" :title="title" />
      <slot />
    </ul>
  </li>
</template>
