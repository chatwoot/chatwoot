import { emitter } from 'shared/helpers/mitt';

export default {
  methods: {
    showAlert(message, action) {
      emitter.emit('newToastMessage', message, action);
    },
  },
};
