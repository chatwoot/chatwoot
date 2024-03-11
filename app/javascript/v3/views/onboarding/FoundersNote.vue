<template>
  <main
    class="relative h-screen overflow-hidden dark:bg-slate-900 bg-[radial-gradient(var(--w-100)_1px,transparent_1px)] [background-size:16px_16px] z-0 flex items-center justify-center"
  >
    <div
      class="absolute h-full w-full bg-signup-gradient dark:bg-signup-gradient-dark top-0 left-0 scale-y-110 blur-[3px] z-20"
    />
    <section
      class="flex gap-4 flex-col z-50 bg-white max-w-[560px] p-10 border border-solid dark:bg-slate-900 border-slate-100 dark:border-slate-800 rounded-2xl space-y-4 text-sm leading-relaxed text-slate-900 dark:text-white"
    >
      <div class="inline-block">
        <img
          src="/assets/images/dashboard/onboarding/waving-hand.svg"
          alt="Waving hand icon"
          class="object-contain w-12 h-12 p-2.5 border border-solid rounded-full border-woot-500"
        />
      </div>
      <div>
        <p
          class="text-xs tracking-widest uppercase text-slate-600 dark:text-slate-200"
        >
          a note from the founder
        </p>
        <h3 class="text-3xl font-semibold text-slate-900 dark:text-white">
          Hey {{ userName }},
        </h3>
      </div>
      <div class="space-y-3">
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
      </div>
      <figure class="text-sm leading-relaxed text-slate-900 dark:text-white">
        <woot-thumbnail
          src="/assets/images/dashboard/onboarding/pranav-square.png"
          username="Pranav"
        />
        <p class="mt-2">Pranav, <br />Co-founder & CEO, Chatwoot</p>
      </figure>
      <submit-button
        button-class="flex justify-center w-full text-sm text-center"
        :button-text="$t('START_ONBOARDING.FOUNDERS_NOTE.SUBMIT')"
        @click="onSubmit"
      />
    </section>
  </main>
</template>

<script>
import SubmitButton from 'dashboard/components/buttons/FormSubmitButton.vue';
import { mapGetters } from 'vuex';

export default {
  components: {
    SubmitButton,
  },
  computed: {
    ...mapGetters({
      currentUser: 'getCurrentUser',
    }),
    userName() {
      const { display_name: displayName, name } = this.currentUser;
      return displayName || name;
    },
  },
  methods: {
    onSubmit() {
      this.$router.push({ name: 'home' });
    },
  },
};
</script>
