<template>
  <onboarding-layout
    :title="$t('ONBOARDING.FOUNDERS_NOTE.TITLE')"
    current-step="founders-note"
  >
    <template #body>
      <section class="mt-4 space-y-3 text-sm leading-relaxed">
        <p>👋 Hey {{ user.name }},</p>
        <p>
          I'm Pranav, one of the co-founders at Chatwoot. Thanks for checking
          out Chatwoot. We're eager to understand your needs and expectations.
        </p>
        <p>
          If you are facing trouble using the app or achieving your use case, we
          want to help you as quickly as possible.
        </p>
        <p>
          Feel free to schedule a call with our team. We are open to your
          feedback. Talk soon!
        </p>
      </section>
      <figure class="mt-5 text-sm leading-relaxed">
        <thumbnail
          src="https://www.chatwoot.com/images/team/pranav.jpg"
          username="Pranav"
        />
        <p class="mt-2">Pranav, <br />Co-founder & CEO, Chatwoot</p>
      </figure>
    </template>
    <submit-button
      button-class="text-sm"
      :button-text="$t('ONBOARDING.FOUNDERS_NOTE.SUBMIT')"
    />
  </onboarding-layout>
</template>

<script>
import OnboardingLayout from './components/OnboardingLayout.vue';
import Thumbnail from '../../../../dashboard/components/widgets/Thumbnail.vue';
import SubmitButton from '../../../components/buttons/FormSubmitButton.vue';

export default {
  components: {
    OnboardingLayout,
    Thumbnail,
    SubmitButton,
  },
  data() {
    return {
      user: {
        name: 'Shivam',
      },
    };
  },
};
</script>
