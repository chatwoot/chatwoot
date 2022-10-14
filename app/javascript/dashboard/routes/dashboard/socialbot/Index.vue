<template>
  <div class="view-box columns bg-white">
    <settings-header
      button-route="new"
      :icon="'bot'"
      :header-title="'Social Bot'"
    />
    <!-- List Calendar Response -->
    <div class="row row_custom">
      <div class="medium-12 small-12 columns margin_top_1">
        <iframe
          :src="iframeLink"
          allow="clipboard-read; clipboard-write"
          sandbox="allow-forms allow-modals allow-orientation-lock allow-pointer-lock allow-popups allow-popups-to-escape-sandbox  allow-presentation allow-same-origin allow-scripts  allow-top-navigation allow-top-navigation-by-user-activation"
          style="height: calc(100vh - 66px);border: none;"
          width="100%"
          height="100%"
          @load="stopLoader"
        />
      </div>
    </div>
  </div>
</template>

<script>
import SettingsHeader from 'dashboard/routes/dashboard/settings/SettingsHeader';
export default {
  name: 'IndexVue',
  components: {
    SettingsHeader,
  },
  data() {
    return {
      showLoader: true,
      iframeLink: '',
      payload: '',
      color: 'black',
    };
  },
  created() {
    this.encryptedToken();
  },
  methods: {
    stopLoader() {
      this.showLoader = false;
    },
    encryptedToken() {
      try {
        let vm = this;
        this.$store.dispatch('agents/generateToken').then(res => {
          vm.iframeLink = `${window.chatwootConfig.socialBotUrl}?token=${res?.token}`;
        });
      } catch (error) {
        throw new Error(error);
      }
    },
  },
};
</script>

<style scoped></style>
