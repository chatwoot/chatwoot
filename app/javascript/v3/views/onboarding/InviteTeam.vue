<template>
  <onboarding-layout
    :title="$t('ONBOARDING.INVITE_TEAM.TITLE')"
    :body="$t('ONBOARDING.INVITE_TEAM.BODY')"
    :intro="$t('ONBOARDING.PROFILE.INTRO')"
    current-step="invite"
  >
    <section class="space-y-5">
      <div class="flex gap-2">
        <form-input
          v-model="emailToAdd"
          name="email"
          spacing="compact"
          class="flex-grow"
          :placeholder="$t('ONBOARDING.INVITE_TEAM.PLACEHOLDER')"
          @keyup.enter="pushEmail"
        />
        <woot-button
          variant="smooth"
          color-scheme="secondary"
          @click="pushEmail"
        >
          {{ $t('ONBOARDING.INVITE_TEAM.ADD') }}
        </woot-button>
      </div>
      <div
        class="rounded-md divide-y divide-slate-100 dark:divide-slate-700 border border-slate-200 dark:border-slate-700 max-h-[40vh] overflow-auto"
        :class="{
          ' border-dashed grid place-content-center':
            emailsToInvite.length === 0,
        }"
      >
        <div v-if="emailsToInvite.length === 0" class="px-5 py-5">
          <p class="text-sm text-slate-400">No members to invite</p>
        </div>
        <div
          v-for="email in emailsToInvite"
          :key="email"
          class="flex items-center justify-between p-4"
        >
          <div class="flex items-center gap-2">
            <woot-thumbnail :username="email" size="24px" />
            <span
              class="text-slate-700 dark:text-slate-200 text-sm font-medium"
            >
              {{ email }}
            </span>
          </div>
          <woot-button
            variant="clear"
            size="small"
            color-scheme="alert"
            icon="delete"
            @click="emailsToInvite.splice(emailsToInvite.indexOf(email), 1)"
          />
        </div>
      </div>
      <div class="space-y-2">
        <submit-button
          button-class="flex justify-center w-full text-sm text-center"
          :button-text="$t('ONBOARDING.INVITE_TEAM.SUBMIT.BUTTON')"
          @click="onSubmit"
        />

        <woot-button
          variant="clear"
          color-scheme="secondary"
          size="expanded"
          is-expanded
        >
          {{ $t('ONBOARDING.INVITE_TEAM.SKIP') }}
        </woot-button>
      </div>
    </section>
  </onboarding-layout>
</template>

<script>
import FormInput from 'v3/components/Form/Input.vue';
import SubmitButton from 'dashboard/components/buttons/FormSubmitButton.vue';
import OnboardingLayout from './Layout.vue';

import AgentAPI from 'dashboard/api/agents.js';
import alertMixin from 'shared/mixins/alertMixin';

export default {
  components: {
    OnboardingLayout,
    SubmitButton,
    FormInput,
  },
  mixins: [alertMixin],
  data() {
    return {
      emailsToInvite: [],
      emailToAdd: '',
    };
  },
  methods: {
    pushEmail() {
      if (!this.emailToAdd) return;
      this.emailsToInvite.push(this.emailToAdd);
      this.emailsToInvite = [...new Set(this.emailsToInvite)];
      this.emailToAdd = '';
    },
    async onSubmit() {
      if (this.emailsToInvite.length === 0) {
        this.showAlert(
          this.$t('ONBOARDING.INVITE_TEAM.SUBMIT.NO_MEMBER_ERROR')
        );
        return;
      }

      try {
        await AgentAPI.bulkInvite(this.emailsToInvite);
        this.showAlert(this.$t('ONBOARDING.PROFILE.SUBMIT.SUCCESS'));
        this.$router.push({ name: 'onboarding_setup_company' });
      } catch (error) {
        this.showAlert(this.$t('ONBOARDING.PROFILE.SUBMIT.SUCCESS'));
      }
    },
  },
};
</script>
