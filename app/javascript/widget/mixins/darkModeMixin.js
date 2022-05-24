import { mapGetters } from 'vuex';

export default {
  computed: {
    ...mapGetters({ darkMode: 'appConfig/darkMode' }),
  },
  methods: {
    $dm(light, dark) {
      if (this.darkMode === 'light') {
        return light;
      }
      return light + ' ' + dark;
    },
  },
};
