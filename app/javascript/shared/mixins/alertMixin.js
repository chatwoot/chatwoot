export default {
  methods: {
    showAlert(message, action, options = {}) {
      bus.$emit('newToastMessage', message, action, options);
    },
  },
};
