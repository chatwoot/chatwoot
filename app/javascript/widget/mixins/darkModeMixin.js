import { mapGetters } from 'vuex';

export default {
  computed: {
    ...mapGetters({ darkMode: 'appConfig/darkMode' }),
    prefersDarkMode() {
      const isOSOnDarkMode =
        this.darkMode === 'auto' &&
        window.matchMedia('(prefers-color-scheme: dark)').matches;
      return isOSOnDarkMode || this.darkMode === 'dark';
    },
  },
  methods: {
    $dm(light, dark) {
      if (this.darkMode === 'light') {
        return light;
      }
      if (this.darkMode === 'dark') {
        return dark;
      }
      return light + ' ' + dark;
    },
  },
};
