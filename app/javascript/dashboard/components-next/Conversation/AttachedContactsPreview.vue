<script setup>
import Button from 'dashboard/components-next/button/Button.vue';

defineProps({
  contacts: {
    type: Array,
    default: () => [],
  },
});

const emit = defineEmits(['remove']);

const contactDisplayName = contact => {
  return (
    contact.formattedName ||
    contact.name ||
    [contact.firstName, contact.lastName].filter(Boolean).join(' ') ||
    ''
  );
};

const contactDisplayPhone = contact => {
  return contact.phoneNumber || contact.phone_number || contact.email || '';
};
</script>

<template>
  <div class="flex flex-wrap gap-2 mt-2">
    <div
      v-for="contact in contacts"
      :key="contact.id"
      class="flex items-center gap-2 px-3 py-2 rounded-lg bg-n-alpha-2 text-sm text-n-slate-12"
    >
      <span class="truncate max-w-[14rem]">
        {{ contactDisplayName(contact) }}
        <span
          v-if="contactDisplayPhone(contact)"
          class="text-n-slate-11"
        >
          ({{ contactDisplayPhone(contact) }})
        </span>
      </span>
      <Button
        xs
        ghost
        slate
        icon="i-lucide-x"
        @click="emit('remove', contact.id)"
      />
    </div>
  </div>
</template>
