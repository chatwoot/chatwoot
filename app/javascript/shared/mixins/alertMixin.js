export default {
  methods: {
    showAlert(message) {
      bus.$emit('newToastMessage', message);
    },
  },
};
