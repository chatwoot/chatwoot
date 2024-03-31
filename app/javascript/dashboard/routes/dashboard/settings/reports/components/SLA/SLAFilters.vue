<template>
  <div>
    <woot-button
      color-scheme="secondary"
      icon="plus-sign"
      class="rounded-xl"
      @click="openContextMenu"
    >
      Add filter
    </woot-button>
    <woot-context-menu
      v-if="showContextMenu"
      ref="menu"
      :x="contextMenu.x"
      :y="contextMenu.y"
      @close="closeContextMenu"
    >
      <SLA-context-menu />
    </woot-context-menu>
  </div>
</template>

<script>
import SLAContextMenu from './SLAContextMenu.vue';
export default {
  name: 'SLAFilters',
  components: {
    SLAContextMenu,
  },
  props: {},
  data() {
    return {
      showContextMenu: false,
    };
  },
  computed: {},
  methods: {
    openContextMenu() {
      this.showContextMenu = true;
      this.contextMenu = {
        x: null,
        y: null,
      };
    },
    closeContextMenu() {
      this.showContextMenu = false;
    },
  },
};
</script>
