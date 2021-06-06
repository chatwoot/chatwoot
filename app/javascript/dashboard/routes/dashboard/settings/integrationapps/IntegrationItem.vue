<template>
  <div class="row">
    <div class="integration--image">
      <img :src="'/dashboard/images/integrations/' + integrationLogo" />
    </div>
    <div class="column">
      <h3 class="integration--title">
        {{ integrationName }}
      </h3>
      <p class="integration--description">
        {{ integrationDescription }}
      </p>
    </div>
    <div class="small-2 column button-wrap">
      <woot-label :title="labelText" :color-scheme="labelColor" />
    </div>
    <div class="small-2 column button-wrap">
      <router-link
        :to="
          frontendURL(
            `accounts/${accountId}/settings/applications/` + integrationId
          )
        "
      >
        <woot-button icon="ion-gear-b">
          {{ $t('INTEGRATION_APPS.CONFIGURE') }}
        </woot-button>
      </router-link>
    </div>
  </div>
</template>
<script>
import { mapGetters } from 'vuex';
import { frontendURL } from '../../../../helper/URLHelper';
import WootLabel from 'dashboard/components/ui/Label';

export default {
  components: {
    WootLabel,
  },
  props: {
    integrationId: {
      type: String,
      default: '',
    },
    integrationLogo: {
      type: String,
      default: '',
    },
    integrationName: {
      type: String,
      default: '',
    },
    integrationDescription: {
      type: String,
      default: '',
    },
    integrationEnabled: {
      type: Number,
      default: 0,
    },
  },
  computed: {
    ...mapGetters({ accountId: 'getCurrentAccountId' }),
    labelText() {
      return this.integrationEnabled
        ? this.$t('INTEGRATION_APPS.STATUS.ENABLED')
        : this.$t('INTEGRATION_APPS.STATUS.DISABLED');
    },
    labelColor() {
      return this.integrationEnabled ? 'success' : 'secondary';
    },
  },
  methods: {
    frontendURL,
  },
};
</script>
