<script>
import globalConfigMixin from 'shared/mixins/globalConfigMixin';
import { mapGetters } from 'vuex';

export default {
  mixins: [globalConfigMixin],
  computed: {
    ...mapGetters({ globalConfig: 'globalConfig/get' }),
  },
};
</script>

<template>
  <div class="py-16 flex items-center relative overflow-hidden">
    <div class="flex flex-row items-center justify-center w-full h-full z-10">
      <img
        :src="globalConfig.logo"
        :alt="globalConfig.installationName"
        class="block w-auto h-46 mx-auto dark:hidden"
      />
      <img
        v-if="globalConfig.logoDark"
        :src="globalConfig.logoDark"
        :alt="globalConfig.installationName"
        class="hidden w-auto h-46 mx-auto dark:block"
      />
    </div>
    <div class="bg-background" />
    <div class="bg-overlay bg-circle-1" />
    <div class="bg-overlay bg-circle-2" />
    <div class="bg-overlay bg-circle-3" />
  </div>
</template>

<style>
.bg-background {
  width: 100%;
  height: 100%;
  position: absolute;
  top: 0;
  background: linear-gradient(180deg, #002606 0%, #389947 100%);
}
.bg-overlay {
  position: absolute;
  border-radius: 100%;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  opacity: 5%;
  background: rgba(255, 255, 255, 1);
}
.bg-circle-1 {
  width: 115%;
  height: 115%;
  left: 16%;
  top: -7%;
}
.bg-circle-2 {
  width: 100%;
  height: 100%;
  left: 43%;
  top: -10%;
}
.bg-circle-3 {
  width: 65%;
  height: 65%;
  left: 73%;
  top: -6%;
}
</style>
