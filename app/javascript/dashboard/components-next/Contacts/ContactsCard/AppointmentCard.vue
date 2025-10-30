<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRouter } from 'vue-router';
import CardLayout from 'dashboard/components-next/CardLayout.vue';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  id: { type: Number, required: true },
  contact: { type: Object, default: () => ({}) },
  startTime: { type: String, required: true },
  endTime: { type: String, required: true },
  location: { type: String, default: '' },
  description: { type: String, default: '' },
  assisted: { type: Boolean, default: false },
});

const { t } = useI18n();
const router = useRouter();

const onClickViewContact = () => {
  if (props.contact?.id) {
    router.push({
      name: 'contacts_edit',
      params: { contactId: props.contact.id },
    });
  }
};

const appointmentDate = computed(() => {
  if (!props.startTime) return '';
  const date = new Date(props.startTime);
  return date.toLocaleDateString('es-ES', {
    weekday: 'long',
    year: 'numeric',
    month: 'long',
    day: 'numeric',
  });
});

const appointmentTime = computed(() => {
  if (!props.startTime || !props.endTime) return '';
  const start = new Date(props.startTime);
  const end = new Date(props.endTime);
  const startTimeStr = start.toLocaleTimeString('es-ES', {
    hour: '2-digit',
    minute: '2-digit',
  });
  const endTimeStr = end.toLocaleTimeString('es-ES', {
    hour: '2-digit',
    minute: '2-digit',
  });
  return `${startTimeStr} - ${endTimeStr}`;
});

const isPastAppointment = computed(() => {
  if (!props.endTime) return false;
  return new Date(props.endTime) < new Date();
});

const isUpcoming = computed(() => {
  if (!props.startTime) return false;
  const now = new Date();
  const start = new Date(props.startTime);
  const hoursDiff = (start - now) / (1000 * 60 * 60);
  return hoursDiff > 0 && hoursDiff <= 24;
});

const assistedStatusColor = computed(() => ({
  'text-n-teal-11': props.assisted,
}));

const upcomingStatusColor = computed(() => ({
  'text-n-amber-11': true,
}));
</script>

<template>
  <CardLayout :key="id" layout="row">
    <div class="flex items-center justify-start flex-1 gap-4">
      <Avatar
        :name="contact?.name || 'Unknown'"
        :src="contact?.thumbnail"
        :size="48"
        rounded-full
      />
      <div class="flex flex-col flex-1 gap-1">
        <div class="flex flex-wrap items-center gap-x-4 gap-y-1">
          <span
            v-if="description"
            class="text-base font-medium truncate text-n-slate-12"
          >
            {{ description }}
          </span>
          <span
            v-if="isUpcoming"
            class="text-xs font-medium inline-flex items-center h-6 px-2 py-0.5 rounded-md bg-n-alpha-2"
            :class="upcomingStatusColor"
          >
            {{ t('APPOINTMENTS.CARD.UPCOMING') }}
          </span>
          <span
            v-if="assisted"
            class="text-xs font-medium inline-flex items-center h-6 px-2 py-0.5 rounded-md bg-n-alpha-2"
            :class="assistedStatusColor"
          >
            {{ t('APPOINTMENTS.CARD.ASSISTED') }}
          </span>
        </div>

        <div class="flex flex-wrap items-center gap-x-3 gap-y-1">
          <span
            class="inline-flex items-center gap-1.5 text-sm text-n-slate-11"
          >
            <span class="i-lucide-calendar size-3.5" />
            {{ appointmentDate }}
          </span>
          <div class="w-px h-3 bg-n-slate-6" />
          <span
            class="inline-flex items-center gap-1.5 text-sm text-n-slate-11"
          >
            <span class="i-lucide-clock size-3.5" />
            {{ appointmentTime }}
          </span>
          <template v-if="location">
            <div class="w-px h-3 bg-n-slate-6" />
            <span
              class="inline-flex items-center gap-1.5 text-sm truncate text-n-slate-11"
              :title="location"
            >
              <span class="i-lucide-map-pin size-3.5" />
              {{ location }}
            </span>
          </template>
        </div>

        <div
          v-if="contact?.email || contact?.phone_number"
          class="flex flex-wrap items-center gap-x-3 gap-y-1 mt-1"
        >
          <span class="text-sm text-n-slate-10 line-clamp-2">
            {{ contact?.name || t('APPOINTMENTS.TABLE.NO_CONTACT') }}
          </span>

          <div class="w-px h-2 bg-n-slate-6" />

          <span v-if="contact?.email" class="text-xs text-n-slate-10">
            {{ contact.email }}
          </span>
          <div
            v-if="contact?.email && contact?.phone_number"
            class="w-px h-2 bg-n-slate-6"
          />
          <span v-if="contact?.phone_number" class="text-xs text-n-slate-10">
            {{ contact.phone_number }}
          </span>
          <template v-if="contact?.id">
            <div class="w-px h-2 bg-n-slate-6" />
            <Button
              :label="t('APPOINTMENTS.CARD.VIEW_CONTACT')"
              variant="link"
              size="xs"
              @click="onClickViewContact"
            />
          </template>
        </div>
      </div>
    </div>

    <div class="flex items-center gap-2">
      <span
        v-if="isPastAppointment && !assisted"
        class="text-xs text-n-slate-9"
      >
        {{ t('APPOINTMENTS.CARD.PAST') }}
      </span>
    </div>
  </CardLayout>
</template>
