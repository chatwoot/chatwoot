import { useI18n } from 'vue-i18n';
import {
  messageDateFormat,
  dynamicTime,
  dateFormat,
  shortTimestamp,
} from 'shared/helpers/timeHelper';

export default function useLocaleDateFormatter() {
  const { locale } = useI18n();

  const localeDynamicTime = (...args) => dynamicTime(...args, locale.value);
  const localeDateFormat = (...args) => dateFormat(...args, locale.value);
  const localeShortTimestamp = (...args) =>
    shortTimestamp(...args, locale.value);
  const localeMessageDateFormat = (...args) =>
    messageDateFormat(...args, locale.value);

  return {
    localeDynamicTime,
    localeDateFormat,
    localeShortTimestamp,
    localeMessageDateFormat,
  };
}
