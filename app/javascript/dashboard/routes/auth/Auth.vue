<template>
  <div class="row auth--wrap h-full w-full">
    <router-view></router-view>
    <auth-right-screen />
  </div>
</template>
<script>
import AuthRightScreen from 'dashboard/routes/auth/components/AuthRightScreen.vue';
export default {
  components: {
    AuthRightScreen,
  },
};
</script>
