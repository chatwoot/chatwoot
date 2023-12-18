<template>
  <onboarding-layout
    :title="$t('ONBOARDING.INVITE_TEAM.TITLE')"
    :body="$t('ONBOARDING.INVITE_TEAM.BODY')"
    current-step="invite"
  >
    <section class="space-y-5">
      <div class="space-y-2">
        <div class="flex gap-2">
          <form-input
            v-model="emailToAdd"
            name="email"
            spacing="compact"
            class="flex-grow"
          />
          <woot-button
            variant="smooth"
            color-scheme="secondary"
            @click="pushEmail"
          >
            Add
          </woot-button>
        </div>
        <div
          class="rounded-lg min-h-[10rem] divide-y divide-slate-100"
          :class="{
            'border border-slate-200 border-dashed':
              emailsToInvite.length === 0,
          }"
        >
          <div
            v-for="email in emailsToInvite"
            :key="email"
            class="flex items-center justify-between gap-2 py-2 first:pt-0 last:pb-0"
          >
            <div class="flex items-center gap-2">
              <thumbnail :username="email" size="30px" />
              {{ email }}
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
      </div>
      <div class="space-y-2">
        <submit-button
          button-class="flex justify-center w-full text-sm text-center"
          :button-text="$t('ONBOARDING.INVITE_TEAM.SUBMIT')"
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
import FormInput from '../../../components/form/Input.vue';
import WootButton from '../../../components/ui/WootButton.vue';
import Thumbnail from '../../../../dashboard/components/widgets/Thumbnail.vue';
import OnboardingLayout from './components/OnboardingLayout.vue';
import SubmitButton from '../../../components/buttons/FormSubmitButton.vue';

export default {
  components: {
    OnboardingLayout,
    WootButton,
    Thumbnail,
    SubmitButton,
    FormInput,
  },
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
  },
};
</script>
