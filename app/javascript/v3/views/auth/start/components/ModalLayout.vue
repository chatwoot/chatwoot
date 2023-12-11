<template>
  <section
    class="min-h-screen px-8 py-20 dark:text-white bg-woot-25 dark:bg-slate-900"
  >
    <div class="relative max-w-lg mx-auto">
      <div
        id="steps"
        class="rounded-md w-48 -left-52 dark:shadow-[#000] p-1 border shadow-sm border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-900 absolute grid gap-1"
      >
        <h6
          class="px-2 pt-1 font-bold tracking-widest uppercase text-xxs text-slate-500"
        >
          Get Started
        </h6>
        <modal-step is-active title="Setup Profile" :step-number="1" />
        <modal-step title="Setup Company" :step-number="2" />
        <modal-step title="Invite your team" :step-number="3" />
      </div>
      <div
        id="modal-body"
        class="dark:shadow-[#000] rounded-md mx-auto p-9 border shadow border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-900"
      >
        <h2 class="text-lg font-bold tracking-tight">
          <slot name="title">
            {{ title }}
          </slot>
        </h2>
        <slot name="body">
          <p class="mt-2 text-sm dark:text-slate-200">
            {{ body }}
          </p>
        </slot>
        <div class="mt-8">
          <slot />
        </div>
      </div>
    </div>
  </section>
</template>

<script>
import ModalStep from './ModalStep.vue';

export default {
  components: {
    ModalStep,
  },
  props: {
    title: {
      type: String,
      default: '',
    },
    body: {
      type: String,
      default: '',
    },
  },
};
</script>
