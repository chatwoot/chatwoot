<template>
  <span class="back-button ion-ios-arrow-left" @click.capture="goBack">Back</span>
</template>
<script>
import router from '../../routes/index';

export default {
  methods: {
    goBack() {
      router.go(-1);
    },
  },
};
</script>