<template>
  <div class="columns profile--settings ">
    <form @submit.prevent="updateAccount()">
      <div class="small-12 row profile--settings--row">
        <div class="columns small-3 ">
          <h4 class="block-title">
            {{ $t('GENERAL_SETTINGS.FORM.GENERAL_SECTION.TITLE') }}
          </h4>
          <p>{{ $t('GENERAL_SETTINGS.FORM.GENERAL_SECTION.NOTE') }}</p>
        </div>
        <div class="columns small-9 medium-5">
          <label :class="{ error: $v.name.$error }">
            {{ $t('GENERAL_SETTINGS.FORM.NAME.LABEL') }}
            <input
              v-model="name"
              type="text"
              :placeholder="$t('GENERAL_SETTINGS.FORM.NAME.PLACEHOLDER')"
              @blur="$v.name.$touch"
            />
            <span v-if="$v.name.$error" class="message">
              {{ $t('GENERAL_SETTINGS.FORM.NAME.ERROR') }}
            </span>
          </label>
          <label :class="{ error: $v.locale.$error }">
            {{ $t('GENERAL_SETTINGS.FORM.LANGUAGE.LABEL') }}
            <select v-model="locale">
              <option value="en">English</option>
              <option value="de">German</option>
              <option value="ml">Malayalam</option>
            </select>
            <span v-if="$v.locale.$error" class="message">
              {{ $t('GENERAL_SETTINGS.FORM.LANGUAGE.ERROR') }}
            </span>
          </label>
        </div>
      </div>
      <woot-submit-button
        class="button nice success button--fixed-right-top"
        :button-text="$t('GENERAL_SETTINGS.SUBMIT')"
        :loading="isUpdating"
      >
      </woot-submit-button>
    </form>
  </div>
</template>

<script>
import Vue from 'vue';
import { required } from 'vuelidate/lib/validators';
import { mapGetters } from 'vuex';
import { accountIdFromPathname } from 'dashboard/helper/URLHelper';
import alertMixin from 'shared/mixins/alertMixin';

export default {
  mixins: [alertMixin],
  data() {
    return {
      id: '',
      name: '',
      locale: 'en',
    };
  },
  validations: {
    name: {
      required,
    },
    locale: {
      required,
    },
  },
  computed: {
    ...mapGetters({
      getAccount: 'accounts/getAccount',
      uiFlags: 'accounts/getUIFlags',
    }),

    isUpdating() {
      return this.uiFlags.isUpdating;
    },
  },
  mounted() {
    if (!this.id) {
      this.initializeAccount();
    }
  },
  methods: {
    async initializeAccount() {
      const { pathname } = window.location;
      const accountId = accountIdFromPathname(pathname);

      if (accountId) {
        await this.$store.dispatch('accounts/get');
        const { name, locale, id } = this.getAccount(accountId);

        Vue.config.lang = locale;
        this.name = name;
        this.locale = locale;
        this.id = id;
      }
    },

    async updateAccount() {
      this.$v.$touch();
      if (this.$v.$invalid) {
        this.showAlert(this.$t('GENERAL_SETTINGS.FORM.ERROR'));
        return;
      }
      try {
        await this.$store.dispatch('accounts/update', {
          locale: this.locale,
          name: this.name,
        });
        Vue.config.lang = this.locale;
        this.showAlert(this.$t('GENERAL_SETTINGS.UPDATE.SUCCESS'));
      } catch (error) {
        this.showAlert(this.$t('GENERAL_SETTINGS.UPDATE.ERROR'));
      }
    },
  },
};
</script>

<style lang="scss">
@import '~dashboard/assets/scss/variables.scss';
@import '~dashboard/assets/scss/mixins.scss';

.profile--settings {
  padding: 24px;
  overflow: auto;
}

.profile--settings--row {
  @include border-normal-bottom;
  padding: $space-normal;
  .small-3 {
    padding: $space-normal $space-medium $space-normal 0;
  }
  .small-9 {
    padding: $space-normal;
  }
}
</style>
