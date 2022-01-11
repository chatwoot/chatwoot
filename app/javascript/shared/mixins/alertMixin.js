export default {
  methods: {
    showAlert(message, action) {
      bus.$emit('newToastMessage', message, action);
    },
  },
};
