<template>
  <onboarding-base-modal
    :title="$t('START_ONBOARDING.INVITE_TEAM.TITLE')"
    :subtitle="$t('START_ONBOARDING.INVITE_TEAM.BODY')"
  >
    <section class="space-y-5">
      <div class="flex gap-2">
        <form-input
          v-model="emailToAdd"
          name="email"
          spacing="compact"
          class="flex-grow"
          :placeholder="$t('START_ONBOARDING.INVITE_TEAM.PLACEHOLDER')"
          :autofocus="true"
          @keyup.enter="pushEmail"
        />
        <woot-button
          variant="smooth"
          icon="add"
          color-scheme="secondary"
          @click="pushEmail"
        >
          {{ $t('START_ONBOARDING.INVITE_TEAM.ADD') }}
        </woot-button>
      </div>
      <div
        class="rounded-md divide-y divide-slate-100 dark:divide-slate-700 border border-slate-200 dark:border-slate-700 max-h-[40vh] overflow-auto"
        :class="{
          'border-dashed grid place-content-center':
            emailsToInvite.length === 0,
        }"
      >
        <div v-if="emailsToInvite.length === 0" class="px-5 py-16">
          <p class="text-sm text-slate-400">
            {{ $t('START_ONBOARDING.INVITE_TEAM.LIST_EMPTY') }}
          </p>
        </div>
        <div
          v-for="email in emailsToInvite"
          :key="email"
          class="flex items-center justify-between p-4"
        >
          <div class="flex items-center gap-2">
            <woot-thumbnail :username="email" size="24px" />
            <span
              class="text-sm font-medium text-slate-700 dark:text-slate-200"
            >
              {{ email }}
            </span>
          </div>
          <woot-button
            variant="clear"
            size="small"
            color-scheme="secondary"
            icon="dismiss"
            @click="emailsToInvite.splice(emailsToInvite.indexOf(email), 1)"
          />
        </div>
      </div>
      <div class="space-y-2">
        <submit-button
          button-class="flex justify-center w-full text-sm text-center"
          :button-text="$t('START_ONBOARDING.INVITE_TEAM.SUBMIT.BUTTON')"
          @click="onSubmit"
        />

        <woot-button
          variant="clear"
          color-scheme="secondary"
          size="expanded"
          class="w-full"
          is-expanded
          @click="nextStep"
        >
          {{ $t('START_ONBOARDING.INVITE_TEAM.SKIP') }}
        </woot-button>
      </div>
    </section>
  </onboarding-base-modal>
</template>

<script>
import { mapGetters } from 'vuex';
import FormInput from 'v3/components/Form/Input.vue';
import SubmitButton from 'dashboard/components/buttons/FormSubmitButton.vue';
import OnboardingBaseModal from 'v3/views/onboarding/BaseModal.vue';
import emailValidator from 'vuelidate/lib/validators/email';

import AgentAPI from 'dashboard/api/agents.js';
import alertMixin from 'shared/mixins/alertMixin';

export default {
  components: {
    SubmitButton,
    FormInput,
    OnboardingBaseModal,
  },
  mixins: [alertMixin],
  data() {
    return {
      emailsToInvite: [],
      emailToAdd: '',
    };
  },
  computed: {
    ...mapGetters({
      isAChatwootInstance: 'globalConfig/isAChatwootInstance',
    }),
  },
  methods: {
    pushEmail() {
      if (!this.emailToAdd) return;
      if (emailValidator(this.emailToAdd)) {
        this.emailsToInvite.push(this.emailToAdd);
        this.emailsToInvite = [...new Set(this.emailsToInvite)];
        this.emailToAdd = '';
      } else {
        this.showAlert(this.$t('START_ONBOARDING.INVITE_TEAM.EMAIL_ERROR'));
      }
    },
    async nextStep() {
      if (this.isAChatwootInstance) {
        this.$router.push({ name: 'onboarding_founders_note' });
      } else {
        this.$router.push({ name: 'home' });
      }
    },
    async onSubmit() {
      if (this.emailsToInvite.length === 0) {
        this.showAlert(
          this.$t('START_ONBOARDING.INVITE_TEAM.SUBMIT.NO_MEMBER_ERROR')
        );
        return;
      }

      try {
        await AgentAPI.bulkInvite({ emails: this.emailsToInvite });
        this.showAlert(this.$t('START_ONBOARDING.INVITE_TEAM.SUBMIT.SUCCESS'));
        this.nextStep();
      } catch (error) {
        this.showAlert(this.$t('START_ONBOARDING.INVITE_TEAM.SUBMIT.ERROR'));
      }
    },
  },
};
</script>
