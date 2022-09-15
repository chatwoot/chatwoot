<template>
  <div class="row auth-screen--view align-center">
    <router-view />
    <auth-right-screen />
  </div>
</template>
<script>
import AuthRightScreen from 'dashboard/routes/auth/components/AuthRightScreen';
export default {
  components: {
    AuthRightScreen,
  },
};
</script>
