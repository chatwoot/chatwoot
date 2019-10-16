import Auth from '../api/auth';

export default {
  methods: {
    isAdmin() {
      return Auth.isAdmin();
    },
  },
};
