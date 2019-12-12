<template>
  <div class="view-box columns bg-light">
    <settings-header
      button-route="new"
      :icon="icon"
      :header-title="$t(headerTitle)"
      :button-text="$t(headerButtonText)"
      :show-button="showButton()"
      :show-new-button="showNewButton()"
    />
    <keep-alive>
      <router-view></router-view>
    </keep-alive>
  </div>
</template>

<script>
/* eslint no-console: 0 */
import SettingsHeader from './SettingsHeader';

export default {
  components: {
    SettingsHeader,
  },
  props: {
    headerTitle: String,
    headerButtonText: String,
    icon: String,
    newButtonRoutes: Array,
  },
  data() {
    return {};
  },
  computed: {
    currentPage() {
      return this.$store.state.route.name;
    },
  },
  methods: {
    showButton() {
      /* eslint-disable no-unneeded-ternary */
      return this.newButtonRoutes
        ? this.newButtonRoutes.indexOf(this.currentPage) > -1
        : true;
    },
    showNewButton() {
      return this.newButtonRoutes ? true : false;
    },
  },
};
</script>
