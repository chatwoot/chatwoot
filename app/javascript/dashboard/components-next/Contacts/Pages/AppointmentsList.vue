<script setup>
import AppointmentCard from 'dashboard/components-next/Contacts/ContactsCard/AppointmentCard.vue';

defineProps({ appointments: { type: Array, required: true } });
</script>

<template>
  <div class="flex flex-col gap-4 px-6 pt-4 pb-6">
    <AppointmentCard
      v-for="appointment in appointments"
      :id="appointment.id"
      :key="appointment.id"
      :contact="appointment.contact"
      :start-time="appointment.start_time"
      :end-time="appointment.end_time"
      :location="appointment.location"
      :description="appointment.description"
      :assisted="appointment.assisted"
    />
  </div>
</template>
