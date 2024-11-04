import { useI18n } from 'vue-i18n';
import {
  messageStamp,
  messageTimestamp,
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
  const localeMessageStamp = (...args) => messageStamp(...args, locale.value);
  const localeMessageTimestamp = (...args) =>
    messageTimestamp(...args, locale.value);

  return {
    localeDynamicTime,
    localeDateFormat,
    localeShortTimestamp,
    localeMessageStamp,
    localeMessageTimestamp,
  };
}
