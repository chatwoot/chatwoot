<script setup>
import WeeklyAvailabilitySection from '../components/WeeklyAvailabilitySection.vue';
import NextButton from '../../../../components-next/button/Button.vue';
import { useStore } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';
import { ref } from 'vue';

const props = defineProps({
  user: {
    type: Object,
    default: () => ({}),
  },
});

const store = useStore();
const { t } = useI18n();
const childRef = ref(null);

const editWorkinghours = async () => {
  try {
    const availability = childRef.value.updateWeeklyAvailability();

    const payload = {
      id: props.id,
      timezone: availability.timezone,
      workingHours: availability.working_hours,
    };

    await store.dispatch('updateWorkingHours', payload);
    useAlert(t('PROFILE_SETTINGS.FORM.WORKING_HOURS_SECTION.UPDATE_SUCCESS'));
  } catch (error) {
    useAlert(t('PROFILE_SETTINGS.FORM.WORKING_HOURS_SECTION.UPDATE_ERROR'));
  }
};
</script>

<template>
  <div>
    <form class="w-full" @submit.prevent="editWorkinghours">
      <WeeklyAvailabilitySection ref="childRef" :user="user" />
      <div>
        <NextButton
          type="submit"
          :label="
            t(
              'PROFILE_SETTINGS.FORM.WORKING_HOURS_SECTION.UPDATE_WORKING_HOURS'
            )
          "
        />
      </div>
    </form>
  </div>
</template>
