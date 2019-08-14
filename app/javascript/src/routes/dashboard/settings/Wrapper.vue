<template>
  <section class="app-content columns">
    <div class="view-box columns bg-light">
      <settings-header
        button-route="new"
        :icon="icon"
        :header-title="$t(headerTitle)"
        :button-text="$t(headerButtonText)"
        :show-button="showButton()"
        :show-new-button="showNewButton()"
      />
        <!-- <transition name="slide-fade"> -->
          <keep-alive>
            <router-view></router-view>
          </keep-alive>
        <!-- </transition> -->
    </div>
  </section>
</template>

<script>
/* eslint no-console: 0 */
import SettingsHeader from './SettingsHeader';

export default {
  data() {
    return {
    };
  },
  props: {
    headerTitle: String,
    headerButtonText: String,
    icon: String,
    newButtonRoutes: Array,
  },
  components: {
    SettingsHeader,
  },
  computed: {
    currentPage() {
      return this.$store.state.route.name;
    },
  },
  methods: {
    showButton() {
      /* eslint-disable no-unneeded-ternary */
      return this.newButtonRoutes ? this.newButtonRoutes.indexOf(this.currentPage) > -1 : true;
    },
    showNewButton() {
      return this.newButtonRoutes ? true : false;
    },
  },
};
</script>
