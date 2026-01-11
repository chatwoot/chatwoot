import ar from './locale/ar';
import bg from './locale/bg';
import ca from './locale/ca';
import cs from './locale/cs';
import da from './locale/da';
import de from './locale/de';
import el from './locale/el';
import en from './locale/en';
import es from './locale/es';
import fa from './locale/fa';
import fi from './locale/fi';
import fr from './locale/fr';
import he from './locale/he';
import hi from './locale/hi';
import hu from './locale/hu';
import id from './locale/id';
import it from './locale/it';
import ja from './locale/ja';
import ko from './locale/ko';
import lv from './locale/lv';
import ml from './locale/ml';
import nl from './locale/nl';
import no from './locale/no';
import pl from './locale/pl';
import pt from './locale/pt';
import pt_BR from './locale/pt_BR';
import ro from './locale/ro';
import ru from './locale/ru';
import sk from './locale/sk';
import sr from './locale/sr';
import sv from './locale/sv';
import ta from './locale/ta';
import th from './locale/th';
import tr from './locale/tr';
import uk from './locale/uk';
import vi from './locale/vi';
import zh_CN from './locale/zh_CN';
import zh_TW from './locale/zh_TW';
import is from './locale/is';
import lt from './locale/lt';

// CommMate: Import custom translation fragments from custom/dashboard/i18n/locale/
// These are deep-merged into the Chatwoot translations to avoid modifying core locale files
import commmateEnWhatsappTemplates from '../../../../custom/dashboard/i18n/locale/en/inboxMgmt.whatsappTemplates.json';
import commmatePtBRWhatsappTemplates from '../../../../custom/dashboard/i18n/locale/pt_BR/inboxMgmt.whatsappTemplates.json';

// CommMate: Deep merge utility for nested translation objects
function deepMerge(target, source) {
  const result = { ...target };
  Object.keys(source).forEach(key => {
    if (
      source[key] &&
      typeof source[key] === 'object' &&
      !Array.isArray(source[key])
    ) {
      result[key] = deepMerge(result[key] || {}, source[key]);
    } else {
      result[key] = source[key];
    }
  });
  return result;
}

// CommMate: Merge custom translations into Chatwoot locales
const enWithCommMate = deepMerge(en, commmateEnWhatsappTemplates);
const pt_BRWithCommMate = deepMerge(pt_BR, commmatePtBRWhatsappTemplates);

export default {
  ar,
  bg,
  ca,
  cs,
  da,
  de,
  el,
  en: enWithCommMate, // CommMate: Use merged translations
  es,
  fa,
  fi,
  fr,
  he,
  hi,
  hu,
  id,
  it,
  ja,
  ko,
  ml,
  lv,
  nl,
  no,
  pl,
  pt_BR: pt_BRWithCommMate, // CommMate: Use merged translations
  pt,
  ro,
  ru,
  sk,
  sr,
  sv,
  ta,
  th,
  tr,
  uk,
  vi,
  zh_CN,
  zh_TW,
  is,
  lt,
};
