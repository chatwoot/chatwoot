<script>
import SnackbarContainer from './components/SnackBar/Container.vue';
import { setLocale } from 'dashboard/i18n/loader';
import { useI18n } from 'vue-i18n';

export default {
  components: { SnackbarContainer },
  setup() {
    const i18n = useI18n();

    return { i18n };
  },
  data() {
    return { theme: 'light' };
  },
  async mounted() {
    this.setColorTheme();
    this.listenToThemeChanges();
    await setLocale(this.i18n, window.chatwootConfig.selectedLocale);
  },
  methods: {
    setColorTheme() {
      if (window.matchMedia('(prefers-color-scheme: dark)').matches) {
        this.theme = 'dark';
      } else {
        this.theme = 'light ';
      }
    },
    listenToThemeChanges() {
      const mql = window.matchMedia('(prefers-color-scheme: dark)');

      mql.onchange = e => {
        if (e.matches) {
          this.theme = 'dark';
        } else {
          this.theme = 'light';
        }
      };
    },
  },
};
</script>

<template>
  <div class="h-full min-h-screen w-full antialiased" :class="theme">
    <router-view />
    <SnackbarContainer />
  </div>
</template>

<style lang="scss">
@tailwind base;
@tailwind components;
@tailwind utilities;

@import 'shared/assets/stylesheets/colors';
@import 'shared/assets/stylesheets/spacing';
@import 'shared/assets/stylesheets/font-size';
@import 'shared/assets/stylesheets/border-radius';

html,
body {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto,
    Oxygen-Sans, Ubuntu, Cantarell, 'Helvetica Neue', sans-serif;
  @apply h-full w-full;

  input,
  select {
    outline: none;
  }
}

.text-link {
  @apply text-woot-500 font-medium hover:text-woot-600;
}

.v-popper--theme-tooltip .v-popper__inner {
  background: black !important;
  font-size: 0.75rem;
  padding: 4px 8px !important;
  border-radius: 6px;
  font-weight: 400;
}

.v-popper--theme-tooltip .v-popper__arrow-container {
  display: none;
}
</style>
