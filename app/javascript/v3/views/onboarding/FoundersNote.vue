<template>
  <div class="h-full w-full dark:bg-slate-900 relative">
    <div
      class="absolute inset-0 h-full w-full bg-white dark:bg-slate-900 bg-[radial-gradient(var(--w-100)_1px,transparent_1px)] [background-size:16px_16px] z-0"
    />
    <div
      class="absolute h-full w-full overlay-gradient top-0 left-0 scale-y-110 blur-[3px]"
    />
    <div class="flex h-full relative z-50">
      <div
        class="flex-1 min-h-[640px] inline-flex items-center h-full justify-center overflow-auto py-6"
      >
        <div
          class="p-10 max-w-[560px] w-full overflow-auto bg-white dark:bg-slate-900 border border-solid border-slate-100 dark:border-slate-800 rounded-2xl"
        >
          <section class="mt-4 space-y-6 text-sm leading-relaxed">
            <div
              class="rounded-full h-16 w-16 border border-solid border-woot-500 p-4"
            >
              <div
                class="bg-[url('/assets/images/dashboard/onboarding/waving-hand.svg')] bg-contain w-8 h-8"
              />
            </div>
            <div>
              <p
                class="uppercase tracking-wide text-slate-900 dark:text-white mb-1"
              >
                a note from the founder
              </p>
              <h3 class="text-slate-900 dark:text-white text-3xl font-semibold">
                Hey {{ userName }},
              </h3>
            </div>
            <p>
              I'm Pranav, one of the co-founders at Chatwoot. Thanks for
              checking out Chatwoot. We're eager to understand your needs and
              expectations.
            </p>
            <p>
              If you are facing trouble using the app or achieving your use
              case, we want to help you as quickly as possible.
            </p>
            <p>
              Feel free to schedule a call with our team. We are open to your
              feedback. Talk soon!
            </p>
          </section>
          <figure class="mt-5 text-sm leading-relaxed">
            <woot-thumbnail
              src="https://www.chatwoot.com/images/team/pranav.jpg"
              username="Pranav"
            />
            <p class="mt-2">Pranav, <br />Co-founder & CEO, Chatwoot</p>
          </figure>

          <submit-button
            button-class="flex justify-center w-full text-sm text-center mt-8"
            :button-text="$t('ONBOARDING.FOUNDERS_NOTE.SUBMIT')"
            @click="onSubmit"
          />
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import SubmitButton from 'dashboard/components/buttons/FormSubmitButton.vue';
import { mapGetters } from 'vuex';

export default {
  components: {
    SubmitButton,
  },
  data() {
    return {
      user: {
        name: '',
      },
    };
  },
  computed: {
    ...mapGetters({
      currentUser: 'getCurrentUser',
    }),
    userName() {
      return this.currentUser.name;
    },
  },
  methods: {
    onSubmit() {
      this.$router.push({ name: 'home' });
    },
  },
};
</script>
