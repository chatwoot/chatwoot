<template>
  <div class="h-full w-full antialiased" :class="theme">
    <router-view />
    <snackbar-container />
  </div>
</template>
<script>
import SnackbarContainer from './components/SnackBar/Container.vue';

export default {
  components: { SnackbarContainer },
  data() {
    return { theme: 'light' };
  },
  mounted() {
    this.setColorTheme();
    this.listenToThemeChanges();
    this.setLocale(window.chatwootConfig.selectedLocale);
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
    setLocale(locale) {
      this.$root.$i18n.locale = locale;
    },
  },
};
</script>
<style lang="scss">
@tailwind base;
@tailwind components;
@tailwind utilities;

@import 'shared/assets/fonts/plus-jakarta';
@import 'shared/assets/stylesheets/colors';
@import 'shared/assets/stylesheets/spacing';
@import 'shared/assets/stylesheets/font-size';
@import 'shared/assets/stylesheets/border-radius';

html,
body {
  font-family:
    'PlusJakarta',
    -apple-system,
    BlinkMacSystemFont,
    'Segoe UI',
    Roboto,
    Oxygen-Sans,
    Ubuntu,
    Cantarell,
    'Helvetica Neue',
    sans-serif;
  @apply h-full w-full;

  input,
  select {
    outline: none;
  }
}

.text-link {
  @apply text-woot-500 font-medium hover:text-woot-600;
}

.tooltip {
  @apply bg-slate-900 text-white py-1 px-2 z-40 text-xs rounded-md dark:bg-slate-300 dark:text-slate-900;
}
</style>
