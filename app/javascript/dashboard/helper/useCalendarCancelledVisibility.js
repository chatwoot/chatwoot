import { ref, watch } from 'vue';
import { LocalStorage } from 'shared/helpers/localStorage';
import { LOCAL_STORAGE_KEYS } from 'dashboard/constants/localStorage';

const showCancelled = ref(
  LocalStorage.get(LOCAL_STORAGE_KEYS.CALENDAR_SHOW_CANCELLED) === true
);

watch(showCancelled, value => {
  LocalStorage.set(LOCAL_STORAGE_KEYS.CALENDAR_SHOW_CANCELLED, value);
});

export function useCalendarCancelledVisibility() {
  return { showCancelled };
}
