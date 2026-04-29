<script setup>
import { useStore } from 'dashboard/composables/store';
import { useMapGetter } from 'dashboard/composables/store';
import { useKeyboardEvents } from 'dashboard/composables/useKeyboardEvents';
import ContactForm from './ContactForm.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  show: { type: Boolean, default: false },
  contact: { type: Object, default: () => ({}) },
});

const emit = defineEmits(['cancel']);

const store = useStore();
const uiFlags = useMapGetter('contacts/getUIFlags');

const onCancel = () => emit('cancel');

const onSubmit = async contactItem => {
  await store.dispatch('contacts/update', contactItem);
  await store.dispatch('contacts/fetchContactableInbox', props.contact.id);
};

// Restore Escape-to-close behavior that was provided by woot-modal before
// this drawer was reimplemented as a plain fixed panel.
useKeyboardEvents({
  Escape: {
    action: () => {
      if (props.show) onCancel();
    },
    allowOnFocusedInput: true,
  },
});
</script>

<template>
  <transition
    enter-active-class="transition duration-200 ease-out"
    enter-from-class="ltr:translate-x-full rtl:-translate-x-full opacity-0"
    leave-active-class="transition duration-150 ease-in"
    leave-to-class="ltr:translate-x-[30%] rtl:-translate-x-[30%] opacity-0"
  >
    <div
      v-if="show"
      class="fixed inset-y-0 ltr:right-0 rtl:left-0 z-50 flex flex-col w-[30rem] max-w-full h-full bg-n-surface-2 ltr:border-l rtl:border-r border-n-weak shadow-lg overflow-auto"
    >
      <div class="flex items-center justify-between px-8 pt-8 pb-2">
        <div>
          <h2 class="text-lg font-medium text-n-slate-12 mb-1">
            {{
              `${$t('EDIT_CONTACT.TITLE')} - ${contact.name || contact.email}`
            }}
          </h2>
          <p class="text-sm text-n-slate-11 mb-0">
            {{ $t('EDIT_CONTACT.DESC') }}
          </p>
        </div>
        <Button icon="i-lucide-x" slate ghost sm @click="onCancel" />
      </div>
      <ContactForm
        :contact="contact"
        :in-progress="uiFlags.isUpdating"
        :on-submit="onSubmit"
        @success="onCancel"
        @cancel="onCancel"
      />
    </div>
  </transition>
</template>
