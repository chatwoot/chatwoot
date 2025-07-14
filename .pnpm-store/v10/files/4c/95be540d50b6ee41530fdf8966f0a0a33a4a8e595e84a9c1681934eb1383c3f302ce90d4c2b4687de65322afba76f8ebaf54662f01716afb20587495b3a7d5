import { createMessageName } from '@formkit/validation';
import { has } from '@formkit/utils';

// packages/i18n/src/locales/ar.ts

// packages/i18n/src/formatters.ts
function sentence(str) {
  return str[0].toUpperCase() + str.substr(1);
}
function list(items, conjunction = "or") {
  return items.reduce((oxford, item, index) => {
    oxford += item;
    if (index <= items.length - 2 && items.length > 2) {
      oxford += ", ";
    }
    if (index === items.length - 2) {
      oxford += `${items.length === 2 ? " " : ""}${conjunction} `;
    }
    return oxford;
  }, "");
}
function date(date2) {
  const dateTime = typeof date2 === "string" ? new Date(Date.parse(date2)) : date2;
  if (!(dateTime instanceof Date)) {
    return "(unknown)";
  }
  return new Intl.DateTimeFormat(void 0, {
    dateStyle: "medium",
    timeZone: "UTC"
  }).format(dateTime);
}
function order(first, second) {
  return Number(first) >= Number(second) ? [second, first] : [first, second];
}

// packages/i18n/src/locales/ar.ts
var ui = {
  /**
   * Shown on buttons for adding new items.
   */
  add: "إضافة",
  /**
   * Shown when a button to remove items is visible.
   */
  remove: "إزالة",
  /**
   * Shown when there are multiple items to remove at the same time.
   */
  removeAll: "إزالة الكل",
  /**
   * Shown when all fields are not filled out correctly.
   */
  incomplete: "عذرا، لم يتم تعبئة جميع الحقول بشكل صحيح.",
  /**
   * Shown in a button inside a form to submit the form.
   */
  submit: "إرسال",
  /**
   * Shown when no files are selected.
   */
  noFiles: "لا يوجد ملف مختار",
  /**
   * Shown on buttons that move fields up in a list.
   */
  moveUp: "تحرك لأعلى",
  /**
   * Shown on buttons that move fields down in a list.
   */
  moveDown: "انتقل لأسفل",
  /**
   * Shown when something is actively loading.
   */
  isLoading: "يتم الآن التحميل...",
  /**
   * Shown when there is more to load.
   */
  loadMore: "تحميل المزيد",
  /**
   * Shown on buttons that navigate state forward
   */
  next: "التالي",
  /**
   * Shown on buttons that navigate state backward
   */
  prev: "السابق",
  /**
   * Shown when transferring items between lists.
   */
  addAllValues: "أضف جميع القيم",
  /**
   * Shown when adding selected values.
   */
  addSelectedValues: "إضافة قيم محددة",
  /**
   * Shown when removing all values.
   */
  removeAllValues: "قم بإزالة جميع القيم",
  /**
   * Shown when removing selected values.
   */
  removeSelectedValues: "إزالة القيم المحددة",
  /**
   * Shown when there is a date to choose.
   */
  chooseDate: "اختر التاريخ",
  /**
   * Shown when there is a date to change.
   */
  changeDate: "تاريخ التغيير",
  /**
   * Shown when there is something to close
   */
  close: "أغلق",
  /**
   * Shown when there is something to open.
   */
  open: "افتح"
};
var validation = {
  /**
   * The value is not an accepted value.
   * @see {@link https://formkit.com/essentials/validation#accepted}
   */
  accepted({ name }) {
    return `الرجاء قبول ${name}.`;
  },
  /**
   * The date is not after
   * @see {@link https://formkit.com/essentials/validation#date-after}
   */
  date_after({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `يجب أن يكون ${sentence(name)} بعد ${date(args[0])}.`;
    }
    return `يجب أن يكون ${sentence(name)} في المستقبل.`;
  },
  /**
   * The value is not a letter.
   * @see {@link https://formkit.com/essentials/validation#alpha}
   */
  alpha({ name }) {
    return `يمكن أن يحتوي ${sentence(name)} على أحرف أبجدية فقط.`;
  },
  /**
   * The value is not alphanumeric
   * @see {@link https://formkit.com/essentials/validation#alphanumeric}
   */
  alphanumeric({ name }) {
    return `يمكن أن يحتوي ${sentence(name)} على أحرف وأرقام فقط.`;
  },
  /**
   * The value is not letter and/or spaces
   * @see {@link https://formkit.com/essentials/validation#alpha-spaces}
   */
  alpha_spaces({ name }) {
    return `يمكن أن تحتوي ${sentence(name)} على أحرف ومسافات فقط.`;
  },
  /**
   * The value have no letter.
   * @see {@link https://formkit.com/essentials/validation#contains_alpha}
   */
  contains_alpha({ name }) {
    return `يجب أن يحتوي ${sentence(name)} على أحرف أبجدية.`;
  },
  /**
   * The value have no alphanumeric
   * @see {@link https://formkit.com/essentials/validation#contains_alphanumeric}
   */
  contains_alphanumeric({ name }) {
    return `يجب أن يحتوي ${sentence(name)} على أحرف أو أرقام.`;
  },
  /**
   * The value have no letter and/or spaces
   * @see {@link https://formkit.com/essentials/validation#contains_alpha-spaces}
   */
  contains_alpha_spaces({ name }) {
    return `يجب أن يحتوي ${sentence(name)} على أحرف أو مسافات.`;
  },
  /**
   * The value have no symbol
   * @see {@link https://formkit.com/essentials/validation#contains_symbol}
   */
  contains_symbol({ name }) {
    return `يجب أن يحتوي ${sentence(name)} على رمز.`;
  },
  /**
   * The value have no uppercase
   * @see {@link https://formkit.com/essentials/validation#contains_uppercase}
   */
  contains_uppercase({ name }) {
    return `يجب أن يحتوي ${sentence(name)} على أحرف كبيرة.`;
  },
  /**
   * The value have no lowercase
   * @see {@link https://formkit.com/essentials/validation#contains_lowercase}
   */
  contains_lowercase({ name }) {
    return `يجب أن يحتوي ${sentence(name)} على أحرف صغيرة.`;
  },
  /**
   *  The value have no numeric
   * @see {@link https://formkit.com/essentials/validation#contains_numeric}
   */
  contains_numeric({ name }) {
    return `يجب أن يحتوي ${sentence(name)} على أرقام.`;
  },
  /**
   * The value is not symbol
   * @see {@link https://formkit.com/essentials/validation#symbol}
   */
  symbol({ name }) {
    return `يجب أن يكون ${sentence(name)} رمزًا.`;
  },
  /**
   * The value is not uppercase
   * @see {@link https://formkit.com/essentials/validation#uppercase}
   */
  uppercase({ name }) {
    return `يمكن أن يحتوي ${sentence(name)} على أحرف كبيرة فقط.`;
  },
  /**
   * The value is not lowercase
   * @see {@link https://formkit.com/essentials/validation#lowercase}
   */
  lowercase({ name }) {
    return `يمكن أن يحتوي ${sentence(name)} على أحرف صغيرة فقط.`;
  },
  /**
   * The date is not before
   * @see {@link https://formkit.com/essentials/validation#date-before}
   */
  date_before({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `يجب أن يكون ${sentence(name)} قبل ${date(args[0])}.`;
    }
    return `يجب أن يكون ${sentence(name)} في الماضي.`;
  },
  /**
   * The value is not between two numbers
   * @see {@link https://formkit.com/essentials/validation#between}
   */
  between({ name, args }) {
    if (isNaN(args[0]) || isNaN(args[1])) {
      return `تمت تهيئة هذا الحقل بشكل غير صحيح ولا يمكن إرساله.`;
    }
    const [a, b] = order(args[0], args[1]);
    return `يجب أن يكون ${sentence(name)} ما بين ${a} و ${b}.`;
  },
  /**
   * The confirmation field does not match
   * @see {@link https://formkit.com/essentials/validation#confirm}
   */
  confirm({ name }) {
    return `${sentence(name)} غير متطابق.`;
  },
  /**
   * The value is not a valid date
   * @see {@link https://formkit.com/essentials/validation#date-format}
   */
  date_format({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${sentence(name)} ليس تاريخًا صالحًا ، يرجى استخدام التنسيق ${args[0]}`;
    }
    return "تمت تهيئة هذا الحقل بشكل غير صحيح ولا يمكن إرساله";
  },
  /**
   * Is not within expected date range
   * @see {@link https://formkit.com/essentials/validation#date-between}
   */
  date_between({ name, args }) {
    return `يجب أن يكون ${sentence(name)} بين ${date(args[0])} و ${date(args[1])}`;
  },
  /**
   * Shown when the user-provided value is not a valid email address.
   * @see {@link https://formkit.com/essentials/validation#email}
   */
  email: "الرجاء أدخال بريد إليكتروني صالح.",
  /**
   * Does not end with the specified value
   * @see {@link https://formkit.com/essentials/validation#ends-with}
   */
  ends_with({ name, args }) {
    return `لا ينتهي ${sentence(name)} بـ ${list(args)}.`;
  },
  /**
   * Is not an allowed value
   * @see {@link https://formkit.com/essentials/validation#is}
   */
  is({ name }) {
    return `${sentence(name)} ليست قيمة مسموح بها.`;
  },
  /**
   * Does not match specified length
   * @see {@link https://formkit.com/essentials/validation#length}
   */
  length({ name, args: [first = 0, second = Infinity] }) {
    const min = Number(first) <= Number(second) ? first : second;
    const max = Number(second) >= Number(first) ? second : first;
    if (min == 1 && max === Infinity) {
      return `يجب أن يكون ${sentence(name)} حرفًا واحدًا على الأقل.`;
    }
    if (min == 0 && max) {
      return `يجب أن يكون ${sentence(name)} أقل من أو يساوي ${max} حرفًا.`;
    }
    if (min === max) {
      return `يجب أن يتكون ${sentence(name)} من الأحرف ${max}.`;
    }
    if (min && max === Infinity) {
      return `يجب أن يكون ${sentence(name)} أكبر من أو يساوي ${min} حرفًا.`;
    }
    return `يجب أن يكون ${sentence(name)} بين ${min} و ${max} حرفًا.`;
  },
  /**
   * Value is not a match
   * @see {@link https://formkit.com/essentials/validation#matches}
   */
  matches({ name }) {
    return `${sentence(name)} ليست قيمة مسموح بها.`;
  },
  /**
   * Exceeds maximum allowed value
   * @see {@link https://formkit.com/essentials/validation#max}
   */
  max({ name, node: { value }, args }) {
    if (Array.isArray(value)) {
      return `لا يمكن أن يكون أكثر من ${args[0]} ${name}.`;
    }
    return `يجب أن يكون ${sentence(name)} أقل من أو يساوي ${args[0]}.`;
  },
  /**
   * The (field-level) value does not match specified mime type
   * @see {@link https://formkit.com/essentials/validation#mime}
   */
  mime({ name, args }) {
    if (!args[0]) {
      return "لا يسمح بتنسيقات الملفات.";
    }
    return `يجب أن يكون ${sentence(name)} من النوع: ${args[0]}`;
  },
  /**
   * Does not fulfill minimum allowed value
   * @see {@link https://formkit.com/essentials/validation#min}
   */
  min({ name, node: { value }, args }) {
    if (Array.isArray(value)) {
      return `لا يمكن أن يكون أقل من ${args[0]} ${name}.`;
    }
    return `يجب أن يكون ${sentence(name)} على الأقل ${args[0]}.`;
  },
  /**
   * Is not an allowed value
   * @see {@link https://formkit.com/essentials/validation#not}
   */
  not({ name, node: { value } }) {
    return `“${value}” ليس ${name} مسموحًا به.`;
  },
  /**
   *  Is not a number
   * @see {@link https://formkit.com/essentials/validation#number}
   */
  number({ name }) {
    return `${sentence(name)} يجب ان يكون رقماً`;
  },
  /**
   * Require one field.
   * @see {@link https://formkit.com/essentials/validation#require-one}
   */
  require_one: ({ name, node, args: inputNames }) => {
    const labels = inputNames.map((name2) => {
      const dependentNode = node.at(name2);
      if (dependentNode) {
        return createMessageName(dependentNode);
      }
      return false;
    }).filter((name2) => !!name2);
    labels.unshift(name);
    return `${labels.join(" أو ")} مطلوب.`;
  },
  /**
   * Required field.
   * @see {@link https://formkit.com/essentials/validation#required}
   */
  required({ name }) {
    return `${sentence(name)} مطلوب.`;
  },
  /**
   * Does not start with specified value
   * @see {@link https://formkit.com/essentials/validation#starts-with}
   */
  starts_with({ name, args }) {
    return `لا يبدأ ${sentence(name)} بـ ${list(args)}.`;
  },
  /**
   * Is not a url
   * @see {@link https://formkit.com/essentials/validation#url}
   */
  url() {
    return `يرجى إدخال عنوان URL صالح.`;
  },
  /**
   * Shown when the date is invalid.
   */
  invalidDate: "التاريخ المحدد غير صالح."
};
var ar = { ui, validation };
var ui2 = {
  /**
   * Shown on a button for adding additional items.
   */
  add: "əlavə edin",
  /**
   * Shown when a button to remove items is visible.
   */
  remove: "çıxarmaq",
  /**
   * Shown when there are multiple items to remove at the same time.
   */
  removeAll: "Hamısını silin",
  /**
   * Shown when all fields are not filled out correctly.
   */
  incomplete: "Üzr istəyirik, bütün sahələr düzgün doldurulmayıb.",
  /**
   * Shown in a button inside a form to submit the form.
   */
  submit: "Təqdim et",
  /**
   * Shown when no files are selected.
   */
  noFiles: "Heç bir fayl seçilməyib",
  /**
   * Shown on buttons that move fields up in a list.
   */
  moveUp: "yuxarı hərəkət",
  /**
   * Shown on buttons that move fields down in a list.
   */
  moveDown: "Aşağı hərəkət",
  /**
   * Shown when something is actively loading.
   */
  isLoading: "Yükləmə...",
  /**
   * Shown when there is more to load.
   */
  loadMore: "Daha çox yüklə",
  /**
   * Shown on buttons that navigate state forward
   */
  next: "Növbəti",
  /**
   * Shown on buttons that navigate state backward
   */
  prev: "Əvvəlki",
  /**
   * Shown when adding all values.
   */
  addAllValues: "Bütün dəyərləri əlavə edin",
  /**
   * Shown when adding selected values.
   */
  addSelectedValues: "Seçilmiş dəyərləri əlavə edin",
  /**
   * Shown when removing all values.
   */
  removeAllValues: "Bütün dəyərləri sil",
  /**
   * Shown when removing selected values.
   */
  removeSelectedValues: "Seçilmiş dəyərləri sil",
  /**
   * Shown when there is a date to choose.
   */
  chooseDate: "Tarixi seçin",
  /**
   * Shown when there is a date to change.
   */
  changeDate: "Tarixi dəyişdirin",
  /**
   * Shown when there is something to close
   */
  close: "Bağlayın",
  /**
   * Shown when there is something to open.
   */
  open: "Açıq"
};
var validation2 = {
  /**
   * The value is not an accepted value.
   * @see {@link https://formkit.com/essentials/validation#accepted}
   */
  accepted({ name }) {
    return `${name} qəbul edin.`;
  },
  /**
   * The date is not after
   * @see {@link https://formkit.com/essentials/validation#date-after}
   */
  date_after({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${sentence(name)} ${date(args[0])} sonra olmalıdır.`;
    }
    return `${sentence(name)} gələcəkdə olmalıdır.`;
  },
  /**
   * The value is not a letter.
   * @see {@link https://formkit.com/essentials/validation#alpha}
   */
  alpha({ name }) {
    return `${sentence(name)} yalnız əlifba sırası simvollarından ibarət ola bilər.`;
  },
  /**
   * The value is not alphanumeric
   * @see {@link https://formkit.com/essentials/validation#alphanumeric}
   */
  alphanumeric({ name }) {
    return `${sentence(name)} yalnız hərf və rəqəmlərdən ibarət ola bilər.`;
  },
  /**
   * The value is not letter and/or spaces
   * @see {@link https://formkit.com/essentials/validation#alpha-spaces}
   */
  alpha_spaces({ name }) {
    return `${sentence(name)} yalnız hərflərdən və boşluqlardan ibarət ola bilər.`;
  },
  /**
   * The value have no letter.
   * @see {@link https://formkit.com/essentials/validation#contains_alpha}
   */
  contains_alpha({ name }) {
    return `${sentence(name)} əlifba sırası simvolları ehtiva etməlidir.`;
  },
  /**
   * The value have no alphanumeric
   * @see {@link https://formkit.com/essentials/validation#contains_alphanumeric}
   */
  contains_alphanumeric({ name }) {
    return `${sentence(name)} hərfləri və ya nömrələri ehtiva etməlidir.`;
  },
  /**
   * The value have no letter and/or spaces
   * @see {@link https://formkit.com/essentials/validation#contains_alpha-spaces}
   */
  contains_alpha_spaces({ name }) {
    return `${sentence(name)} hərfləri və ya boşluqları ehtiva etməlidir.`;
  },
  /**
   * The value have no symbol
   * @see {@link https://formkit.com/essentials/validation#contains_symbol}
   */
  contains_symbol({ name }) {
    return `${sentence(name)} simvolu ehtiva etməlidir.`;
  },
  /**
   * The value have no uppercase
   * @see {@link https://formkit.com/essentials/validation#contains_uppercase}
   */
  contains_uppercase({ name }) {
    return `${sentence(name)} böyük olmalıdır.`;
  },
  /**
   * The value have no lowercase
   * @see {@link https://formkit.com/essentials/validation#contains_lowercase}
   */
  contains_lowercase({ name }) {
    return `${sentence(name)} kiçik olmalıdır.`;
  },
  /**
   *  The value have no numeric
   * @see {@link https://formkit.com/essentials/validation#contains_numeric}
   */
  contains_numeric({ name }) {
    return `${sentence(name)} nömrələri ehtiva etməlidir.`;
  },
  /**
   * The value is not symbol
   * @see {@link https://formkit.com/essentials/validation#symbol}
   */
  symbol({ name }) {
    return `${sentence(name)} simvol olmalıdır.`;
  },
  /**
   * The value is not uppercase
   * @see {@link https://formkit.com/essentials/validation#uppercase}
   */
  uppercase({ name }) {
    return `${sentence(name)} yalnız böyük hərfləri ehtiva edə bilər.`;
  },
  /**
   * The value is not lowercase
   * @see {@link https://formkit.com/essentials/validation#lowercase}
   */
  lowercase({ name }) {
    return `${sentence(name)} yalnız kiçik hərfləri ehtiva edə bilər.`;
  },
  /**
   * The date is not before
   * @see {@link https://formkit.com/essentials/validation#date-before}
   */
  date_before({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${sentence(name)} ${date(args[0])} əvvəl olmalıdır.`;
    }
    return `${sentence(name)} keçmişdə olmalıdır.`;
  },
  /**
   * The value is not between two numbers
   * @see {@link https://formkit.com/essentials/validation#between}
   */
  between({ name, args }) {
    if (isNaN(args[0]) || isNaN(args[1])) {
      return `Bu sahə səhv konfiqurasiya edilib və onu təqdim etmək mümkün deyil.`;
    }
    const [a, b] = order(args[0], args[1]);
    return `${sentence(name)} ${a} və ${b} arasında olmalıdır.`;
  },
  /**
   * The confirmation field does not match
   * @see {@link https://formkit.com/essentials/validation#confirm}
   */
  confirm({ name }) {
    return `${sentence(name)} uyğun gəlmir.`;
  },
  /**
   * The value is not a valid date
   * @see {@link https://formkit.com/essentials/validation#date-format}
   */
  date_format({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${sentence(name)} etibarlı tarix deyil, ${args[0]} formatından istifadə edin`;
    }
    return "Bu sahə səhv konfiqurasiya edilib və onu təqdim etmək mümkün deyil";
  },
  /**
   * Is not within expected date range
   * @see {@link https://formkit.com/essentials/validation#date-between}
   */
  date_between({ name, args }) {
    return `${sentence(name)} ${date(args[0])} və ${date(args[1])} arasında olmalıdır`;
  },
  /**
   * Shown when the user-provided value is not a valid email address.
   * @see {@link https://formkit.com/essentials/validation#email}
   */
  email: "Etibarlı e-poçt ünvanı daxil edin.",
  /**
   * Does not end with the specified value
   * @see {@link https://formkit.com/essentials/validation#ends-with}
   */
  ends_with({ name, args }) {
    return `${sentence(name)} ${list(args)} ilə bitmir.`;
  },
  /**
   * Is not an allowed value
   * @see {@link https://formkit.com/essentials/validation#is}
   */
  is({ name }) {
    return `${sentence(name)} icazə verilən dəyər deyil.`;
  },
  /**
   * Does not match specified length
   * @see {@link https://formkit.com/essentials/validation#length}
   */
  length({ name, args: [first = 0, second = Infinity] }) {
    const min = Number(first) <= Number(second) ? first : second;
    const max = Number(second) >= Number(first) ? second : first;
    if (min == 1 && max === Infinity) {
      return `${sentence(name)} ən azı bir simvol olmalıdır.`;
    }
    if (min == 0 && max) {
      return `${sentence(name)} ${max} simvoldan kiçik və ya ona bərabər olmalıdır.`;
    }
    if (min === max) {
      return `${sentence(name)} ${max} simvol uzunluğunda olmalıdır.`;
    }
    if (min && max === Infinity) {
      return `${sentence(name)} ${min} simvoldan böyük və ya ona bərabər olmalıdır.`;
    }
    return `${sentence(name)} ${min} və ${max} simvol arasında olmalıdır.`;
  },
  /**
   * Value is not a match
   * @see {@link https://formkit.com/essentials/validation#matches}
   */
  matches({ name }) {
    return `${sentence(name)} icazə verilən dəyər deyil.`;
  },
  /**
   * Exceeds maximum allowed value
   * @see {@link https://formkit.com/essentials/validation#max}
   */
  max({ name, node: { value }, args }) {
    if (Array.isArray(value)) {
      return `${args[0]} ${name}-dən çox ola bilməz.`;
    }
    return `${sentence(name)} ${args[0]} dəyərindən kiçik və ya ona bərabər olmalıdır.`;
  },
  /**
   * The (field-level) value does not match specified mime type
   * @see {@link https://formkit.com/essentials/validation#mime}
   */
  mime({ name, args }) {
    if (!args[0]) {
      return "Fayl formatlarına icazə verilmir.";
    }
    return `${sentence(name)} aşağıdakı tipdə olmalıdır: ${args[0]}`;
  },
  /**
   * Does not fulfill minimum allowed value
   * @see {@link https://formkit.com/essentials/validation#min}
   */
  min({ name, node: { value }, args }) {
    if (Array.isArray(value)) {
      return `${args[0]} ${name}-dən az ola bilməz.`;
    }
    return `${sentence(name)} ən azı ${args[0]} olmalıdır.`;
  },
  /**
   * Is not an allowed value
   * @see {@link https://formkit.com/essentials/validation#not}
   */
  not({ name, node: { value } }) {
    return `“${value}” icazə verilən ${name} deyil.`;
  },
  /**
   *  Is not a number
   * @see {@link https://formkit.com/essentials/validation#number}
   */
  number({ name }) {
    return `${sentence(name)} rəqəm olmalıdır.`;
  },
  /**
   * Require one field.
   * @see {@link https://formkit.com/essentials/validation#require-one}
   */
  require_one: ({ name, node, args: inputNames }) => {
    const labels = inputNames.map((name2) => {
      const dependentNode = node.at(name2);
      if (dependentNode) {
        return createMessageName(dependentNode);
      }
      return false;
    }).filter((name2) => !!name2);
    labels.unshift(name);
    return `${labels.join(" və ya ")} tələb olunur.`;
  },
  /**
   * Required field.
   * @see {@link https://formkit.com/essentials/validation#required}
   */
  required({ name }) {
    return `${sentence(name)} tələb olunur.`;
  },
  /**
   * Does not start with specified value
   * @see {@link https://formkit.com/essentials/validation#starts-with}
   */
  starts_with({ name, args }) {
    return `${sentence(name)} ${list(args)} ilə başlamır.`;
  },
  /**
   * Is not a url
   * @see {@link https://formkit.com/essentials/validation#url}
   */
  url() {
    return `Xahiş edirik, düzgün URL daxil edin.`;
  },
  /**
   * Shown when the date is invalid.
   */
  invalidDate: "Seçilmiş tarix etibarsızdır."
};
var az = { ui: ui2, validation: validation2 };
var ui3 = {
  /**
   * Shown on a button for adding additional items.
   */
  add: "Добави",
  /**
   * Shown when a button to remove items is visible.
   */
  remove: "Премахни",
  /**
   * Shown when there are multiple items to remove at the same time.
   */
  removeAll: "Премахни всички",
  /**
   * Shown when all fields are not filled out correctly.
   */
  incomplete: "Извинете, не всички полета са попълнени правилно.",
  /**
   * Shown in a button inside a form to submit the form.
   */
  submit: "Изпрати",
  /**
   * Shown when no files are selected.
   */
  noFiles: "Няма избран файл",
  /**
   * Shown on buttons that move fields up in a list.
   */
  moveUp: "Преместване нагоре",
  /**
   * Shown on buttons that move fields down in a list.
   */
  moveDown: "Преместете се надолу",
  /**
   * Shown when something is actively loading.
   */
  isLoading: "Зареждане...",
  /**
   * Shown when there is more to load.
   */
  loadMore: "Заредете повече",
  /**
   * Shown on buttons that navigate state forward
   */
  next: "Следващ",
  /**
   * Shown on buttons that navigate state backward
   */
  prev: "Предишен",
  /**
   * Shown when adding all values.
   */
  addAllValues: "Добавете всички стойности",
  /**
   * Shown when adding selected values.
   */
  addSelectedValues: "Добавяне на избрани стойности",
  /**
   * Shown when removing all values.
   */
  removeAllValues: "Премахнете всички стойности",
  /**
   * Shown when removing selected values.
   */
  removeSelectedValues: "Премахване на избраните стойности",
  /**
   * Shown when there is a date to choose.
   */
  chooseDate: "Избери дата",
  /**
   * Shown when there is a date to change.
   */
  changeDate: "Промяна на датата",
  /**
   * Shown when there is something to close
   */
  close: "Затвори",
  /**
   * Shown when there is something to open.
   */
  open: "Отворете"
};
var validation3 = {
  /**
   * The value is not an accepted value.
   * @see {@link https://formkit.com/essentials/validation#accepted}
   */
  accepted({ name }) {
    return `Моля приемете ${name}.`;
  },
  /**
   * The date is not after
   * @see {@link https://formkit.com/essentials/validation#date-after}
   */
  date_after({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${sentence(name)} трябва да е след ${date(args[0])}.`;
    }
    return `${sentence(name)} трябва да бъде в бъдещето.`;
  },
  /**
   * The value is not a letter.
   * @see {@link https://formkit.com/essentials/validation#alpha}
   */
  alpha({ name }) {
    return `${sentence(name)} може да съдържа само букви.`;
  },
  /**
   * The value is not alphanumeric
   * @see {@link https://formkit.com/essentials/validation#alphanumeric}
   */
  alphanumeric({ name }) {
    return `${sentence(name)} може да съдържа само букви и цифри.`;
  },
  /**
   * The value is not letter and/or spaces
   * @see {@link https://formkit.com/essentials/validation#alpha-spaces}
   */
  alpha_spaces({ name }) {
    return `${sentence(name)} може да съдържа само букви и интервали.`;
  },
  /**
   * The value have no letter.
   * @see {@link https://formkit.com/essentials/validation#contains_alpha}
   */
  contains_alpha({ name }) {
    return `${sentence(name)} трябва да съдържа азбучни знаци.`;
  },
  /**
   * The value have no alphanumeric
   * @see {@link https://formkit.com/essentials/validation#contains_alphanumeric}
   */
  contains_alphanumeric({ name }) {
    return `${sentence(name)} трябва да съдържа букви или цифри.`;
  },
  /**
   * The value have no letter and/or spaces
   * @see {@link https://formkit.com/essentials/validation#contains_alpha-spaces}
   */
  contains_alpha_spaces({ name }) {
    return `${sentence(name)} трябва да съдържа букви или интервали.`;
  },
  /**
   * The value have no symbol
   * @see {@link https://formkit.com/essentials/validation#contains_symbol}
   */
  contains_symbol({ name }) {
    return `${sentence(name)} трябва да съдържа символ.`;
  },
  /**
   * The value have no uppercase
   * @see {@link https://formkit.com/essentials/validation#contains_uppercase}
   */
  contains_uppercase({ name }) {
    return `${sentence(name)} трябва да съдържа главни букви.`;
  },
  /**
   * The value have no lowercase
   * @see {@link https://formkit.com/essentials/validation#contains_lowercase}
   */
  contains_lowercase({ name }) {
    return `${sentence(name)} трябва да съдържа малки букви.`;
  },
  /**
   *  The value have no numeric
   * @see {@link https://formkit.com/essentials/validation#contains_numeric}
   */
  contains_numeric({ name }) {
    return `${sentence(name)} трябва да съдържа числа.`;
  },
  /**
   * The value is not symbol
   * @see {@link https://formkit.com/essentials/validation#symbol}
   */
  symbol({ name }) {
    return `${sentence(name)} трябва да бъде символ.`;
  },
  /**
   * The value is not uppercase
   * @see {@link https://formkit.com/essentials/validation#uppercase}
   */
  uppercase({ name }) {
    return `${sentence(name)} може да съдържа само главни букви.`;
  },
  /**
   * The value is not lowercase
   * @see {@link https://formkit.com/essentials/validation#lowercase}
   */
  lowercase({ name }) {
    return `${sentence(name)} може да съдържа само малки букви.`;
  },
  /**
   * The date is not before
   * @see {@link https://formkit.com/essentials/validation#date-before}
   */
  date_before({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${sentence(name)} трябва да е преди ${date(args[0])}.`;
    }
    return `${sentence(name)} трябва да бъде в миналото.`;
  },
  /**
   * The value is not between two numbers
   * @see {@link https://formkit.com/essentials/validation#between}
   */
  between({ name, args }) {
    if (isNaN(args[0]) || isNaN(args[1])) {
      return `Това поле е конфигурирано неправилно и не може да бъде изпратено`;
    }
    const [a, b] = order(args[0], args[1]);
    return `${sentence(name)} трябва да бъде между ${a} и ${b}.`;
  },
  /**
   * The confirmation field does not match
   * @see {@link https://formkit.com/essentials/validation#confirm}
   */
  confirm({ name }) {
    return `${sentence(name)} не съвпада.`;
  },
  /**
   * The value is not a valid date
   * @see {@link https://formkit.com/essentials/validation#date-format}
   */
  date_format({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${sentence(name)} е невалидна дата. Моля, използвайте формата ${args[0]}`;
    }
    return "Това поле е конфигурирано неправилно и не може да бъде изпратено";
  },
  /**
   * Is not within expected date range
   * @see {@link https://formkit.com/essentials/validation#date-between}
   */
  date_between({ name, args }) {
    return `${sentence(name)} трябва да бъде между ${date(args[0])} и ${date(
      args[1]
    )}.`;
  },
  /**
   * Shown when the user-provided value is not a valid email address.
   * @see {@link https://formkit.com/essentials/validation#email}
   */
  email: "Моля, въведете валиден имейл адрес.",
  /**
   * Does not end with the specified value
   * @see {@link https://formkit.com/essentials/validation#ends-with}
   */
  ends_with({ name, args }) {
    return `${sentence(name)} не завършва на ${list(args)}.`;
  },
  /**
   * Is not an allowed value
   * @see {@link https://formkit.com/essentials/validation#is}
   */
  is({ name }) {
    return `${sentence(name)} е неразрешена стойност.`;
  },
  /**
   * Does not match specified length
   * @see {@link https://formkit.com/essentials/validation#length}
   */
  length({ name, args: [first = 0, second = Infinity] }) {
    const min = Number(first) <= Number(second) ? first : second;
    const max = Number(second) >= Number(first) ? second : first;
    if (min == 1 && max === Infinity) {
      return `${sentence(name)} трябва да има поне един символ.`;
    }
    if (min == 0 && max) {
      return `${sentence(name)} трябва да бъде по-малко или равно на ${max} символа.`;
    }
    if (min === max) {
      return `${sentence(name)} трябва да бъде ${max} символи дълго.`;
    }
    if (min && max === Infinity) {
      return `${sentence(name)} трябва да бъде по-голямо или равно на ${min} символа.`;
    }
    return `${sentence(name)} трябва да бъде между ${min} и ${max} символа.`;
  },
  /**
   * Value is not a match
   * @see {@link https://formkit.com/essentials/validation#matches}
   */
  matches({ name }) {
    return `${sentence(name)} е неразрешена стойност.`;
  },
  /**
   * Exceeds maximum allowed value
   * @see {@link https://formkit.com/essentials/validation#max}
   */
  max({ name, node: { value }, args }) {
    if (Array.isArray(value)) {
      return `Не може да има повече от ${args[0]} ${name}.`;
    }
    return `${sentence(name)} трябва да бъде по-малко или равно на ${args[0]}.`;
  },
  /**
   * The (field-level) value does not match specified mime type
   * @see {@link https://formkit.com/essentials/validation#mime}
   */
  mime({ name, args }) {
    if (!args[0]) {
      return "Не са разрешени никакви файлови формати.";
    }
    return `${sentence(name)} трябва да бъде от тип: ${args[0]}`;
  },
  /**
   * Does not fulfill minimum allowed value
   * @see {@link https://formkit.com/essentials/validation#min}
   */
  min({ name, node: { value }, args }) {
    if (Array.isArray(value)) {
      return `Не може да има по-малко от ${args[0]} ${name}.`;
    }
    return `${sentence(name)} трябва да бъде поне ${args[0]}.`;
  },
  /**
   * Is not an allowed value
   * @see {@link https://formkit.com/essentials/validation#not}
   */
  not({ name, node: { value } }) {
    return `“${value}” е неразрешен ${name}.`;
  },
  /**
   *  Is not a number
   * @see {@link https://formkit.com/essentials/validation#number}
   */
  number({ name }) {
    return `${sentence(name)} трябва да бъде число.`;
  },
  /**
   * Require one field.
   * @see {@link https://formkit.com/essentials/validation#require-one}
   */
  require_one: ({ name, node, args: inputNames }) => {
    const labels = inputNames.map((name2) => {
      const dependentNode = node.at(name2);
      if (dependentNode) {
        return createMessageName(dependentNode);
      }
      return false;
    }).filter((name2) => !!name2);
    labels.unshift(name);
    return `${labels.join(" или ")} изисква се.`;
  },
  /**
   * Required field.
   * @see {@link https://formkit.com/essentials/validation#required}
   */
  required({ name }) {
    return `${sentence(name)} е задължително.`;
  },
  /**
   * Does not start with specified value
   * @see {@link https://formkit.com/essentials/validation#starts-with}
   */
  starts_with({ name, args }) {
    return `${sentence(name)} не започва с ${list(args)}.`;
  },
  /**
   * Is not a url
   * @see {@link https://formkit.com/essentials/validation#url}
   */
  url() {
    return `Моля, въведете валиден URL адрес.`;
  },
  /**
   * Shown when the date is invalid.
   */
  invalidDate: "Избраната дата е невалидна."
};
var bg = { ui: ui3, validation: validation3 };
var ui4 = {
  /**
   * Shown on a button for adding additional items.
   */
  add: "Dodaj",
  /**
   * Shown when a button to remove items is visible.
   */
  remove: "Ukloni",
  /**
   * Shown when there are multiple items to remove at the same time.
   */
  removeAll: "Ukloni sve",
  /**
   * Shown when all fields are not filled out correctly.
   */
  incomplete: "Nažalost, nisu sva polja ispravno popunjena.",
  /**
   * Shown in a button inside a form to submit the form.
   */
  submit: "Pošalji",
  /**
   * Shown when no files are selected.
   */
  noFiles: "Nije odabran nijedan fajl",
  /**
   * Shown on buttons that move fields up in a list.
   */
  moveUp: "Pomjeri gore",
  /**
   * Shown on buttons that move fields down in a list.
   */
  moveDown: "Pomjeri dole",
  /**
   * Shown when something is actively loading.
   */
  isLoading: "Učitavanje...",
  /**
   * Shown when there is more to load.
   */
  loadMore: "Učitaj više",
  /**
   * Show on buttons that navigate state forward
   */
  next: "Sljedeći",
  /**
   * Show on buttons that navigate state backward
   */
  prev: "Prethodni",
  /**
   * Shown when adding all values.
   */
  addAllValues: "Dodajte sve vrijednosti",
  /**
   * Shown when adding selected values.
   */
  addSelectedValues: "Dodajte odabrane vrijednosti",
  /**
   * Shown when removing all values.
   */
  removeAllValues: "Uklonite sve vrijednosti",
  /**
   * Shown when removing selected values.
   */
  removeSelectedValues: "Uklonite odabrane vrijednosti",
  /**
   * Shown when there is a date to choose.
   */
  chooseDate: "Odaberite datum",
  /**
   * Shown when there is a date to change.
   */
  changeDate: "Promjenite datum",
  /**
   * Shown when there is something to close
   */
  close: "Zatvori",
  /**
   * Shown when there is something to open.
   */
  open: "Otvoreno"
};
var validation4 = {
  /**
   * The value is not an accepted value.
   * @see {@link https://formkit.com/essentials/validation#accepted}
   */
  accepted({ name }) {
    return `Molimo prihvatite ${name}.`;
  },
  /**
   * The date is not after
   * @see {@link https://formkit.com/essentials/validation#date-after}
   */
  date_after({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${sentence(name)} mora biti poslije ${date(args[0])}.`;
    }
    return `${sentence(name)} mora biti u budućnosti.`;
  },
  /**
   * The value is not a letter.
   * @see {@link https://formkit.com/essentials/validation#alpha}
   */
  alpha({ name }) {
    return `${sentence(name)} može sadržavati samo abecedne karaktere.`;
  },
  /**
   * The value is not alphanumeric
   * @see {@link https://formkit.com/essentials/validation#alphanumeric}
   */
  alphanumeric({ name }) {
    return `${sentence(name)} može sadržavati samo slova i brojeve.`;
  },
  /**
   * The value is not letter and/or spaces
   * @see {@link https://formkit.com/essentials/validation#alpha-spaces}
   */
  alpha_spaces({ name }) {
    return `${sentence(name)} može sadržavati samo slova i razmake.`;
  },
  /**
   * The value have no letter.
   * @see {@link https://formkit.com/essentials/validation#contains_alpha}
   */
  contains_alpha({ name }) {
    return `${sentence(name)} mora sadržavati abecedne karaktere.`;
  },
  /**
   * The value have no alphanumeric
   * @see {@link https://formkit.com/essentials/validation#contains_alphanumeric}
   */
  contains_alphanumeric({ name }) {
    return `${sentence(name)} mora sadržavati slova ili brojeve.`;
  },
  /**
   * The value have no letter and/or spaces
   * @see {@link https://formkit.com/essentials/validation#contains_alpha-spaces}
   */
  contains_alpha_spaces({ name }) {
    return `${sentence(name)} mora sadržavati slova ili razmake.`;
  },
  /**
   * The value have no symbol
   * @see {@link https://formkit.com/essentials/validation#contains_symbol}
   */
  contains_symbol({ name }) {
    return `${sentence(name)} mora sadržavati simbol.`;
  },
  /**
   * The value have no uppercase
   * @see {@link https://formkit.com/essentials/validation#contains_uppercase}
   */
  contains_uppercase({ name }) {
    return `${sentence(name)} mora sadržavati veliko slovo.`;
  },
  /**
   * The value have no lowercase
   * @see {@link https://formkit.com/essentials/validation#contains_lowercase}
   */
  contains_lowercase({ name }) {
    return `${sentence(name)} mora sadržavati malo slovo.`;
  },
  /**
   *  The value have no numeric
   * @see {@link https://formkit.com/essentials/validation#contains_numeric}
   */
  contains_numeric({ name }) {
    return `${sentence(name)} mora sadržavati brojeve.`;
  },
  /**
   * The value is not symbol
   * @see {@link https://formkit.com/essentials/validation#symbol}
   */
  symbol({ name }) {
    return `${sentence(name)} mora biti simbol.`;
  },
  /**
   * The value is not uppercase
   * @see {@link https://formkit.com/essentials/validation#uppercase}
   */
  uppercase({ name }) {
    return `${sentence(name)} može sadržavati samo velika slova.`;
  },
  /**
   * The value is not lowercase
   * @see {@link https://formkit.com/essentials/validation#lowercase}
   */
  lowercase({ name }) {
    return `${sentence(name)} može sadržavati samo mala slova.`;
  },
  /**
   * The date is not before
   * @see {@link https://formkit.com/essentials/validation#date-before}
   */
  date_before({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${sentence(name)} mora biti prije ${date(args[0])}.`;
    }
    return `${sentence(name)} mora biti u prošlosti.`;
  },
  /**
   * The value is not between two numbers
   * @see {@link https://formkit.com/essentials/validation#between}
   */
  between({ name, args }) {
    if (isNaN(args[0]) || isNaN(args[1])) {
      return `Ovo polje je pogrešno konfigurirano i ne može se poslati.`;
    }
    const [a, b] = order(args[0], args[1]);
    return `${sentence(name)} mora biti između ${a} i ${b}.`;
  },
  /**
   * The confirmation field does not match
   * @see {@link https://formkit.com/essentials/validation#confirm}
   */
  confirm({ name }) {
    return `${sentence(name)} ne podudara se.`;
  },
  /**
   * The value is not a valid date
   * @see {@link https://formkit.com/essentials/validation#date-format}
   */
  date_format({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${sentence(name)} nije ispravan datum, molimo koristite format ${args[0]}`;
    }
    return "Ovo polje je pogrešno konfigurirano i ne može se poslati";
  },
  /**
   * Is not within expected date range
   * @see {@link https://formkit.com/essentials/validation#date-between}
   */
  date_between({ name, args }) {
    return `${sentence(name)} mora biti između ${date(args[0])} i ${date(args[1])}`;
  },
  /**
   * Shown when the user-provided value is not a valid email address.
   * @see {@link https://formkit.com/essentials/validation#email}
   */
  email: "Molimo Vas da unesete validnu email adresu.",
  /**
   * Does not end with the specified value
   * @see {@link https://formkit.com/essentials/validation#ends-with}
   */
  ends_with({ name, args }) {
    return `${sentence(name)} ne završava sa ${list(args)}.`;
  },
  /**
   * Is not an allowed value
   * @see {@link https://formkit.com/essentials/validation#is}
   */
  is({ name }) {
    return `${sentence(name)} nije dozvoljena vrijednost.`;
  },
  /**
   * Does not match specified length
   * @see {@link https://formkit.com/essentials/validation#length}
   */
  length({ name, args: [first = 0, second = Infinity] }) {
    const min = Number(first) <= Number(second) ? first : second;
    const max = Number(second) >= Number(first) ? second : first;
    if (min == 1 && max === Infinity) {
      return `${sentence(name)} mora biti najmanje jedan karakter.`;
    }
    if (min == 0 && max) {
      return `${sentence(name)} mora biti manje od ili jednako ${max} karaktera.`;
    }
    if (min === max) {
      return `${sentence(name)} treba imati ${max} karaktera.`;
    }
    if (min && max === Infinity) {
      return `${sentence(name)} mora biti veći od ili jednak ${min} karaktera.`;
    }
    return `${sentence(name)} mora biti između ${min} i ${max} karaktera.`;
  },
  /**
   * Value is not a match
   * @see {@link https://formkit.com/essentials/validation#matches}
   */
  matches({ name }) {
    return `${sentence(name)} nije dozvoljena vrijednost.`;
  },
  /**
   * Exceeds maximum allowed value
   * @see {@link https://formkit.com/essentials/validation#max}
   */
  max({ name, node: { value }, args }) {
    if (Array.isArray(value)) {
      return `Ne može imati više od ${args[0]} ${name}.`;
    }
    return `${sentence(name)} mora biti manji ili jednak ${args[0]}.`;
  },
  /**
   * The (field-level) value does not match specified mime type
   * @see {@link https://formkit.com/essentials/validation#mime}
   */
  mime({ name, args }) {
    if (!args[0]) {
      return "Nisu dozvoljeni formati datoteka.";
    }
    return `${sentence(name)} mora biti tipa: ${args[0]}`;
  },
  /**
   * Does not fulfill minimum allowed value
   * @see {@link https://formkit.com/essentials/validation#min}
   */
  min({ name, node: { value }, args }) {
    if (Array.isArray(value)) {
      return `Ne može imati manje od ${args[0]} ${name}.`;
    }
    return `Mora biti barem ${args[0]} ${name} .`;
  },
  /**
   * Is not an allowed value
   * @see {@link https://formkit.com/essentials/validation#not}
   */
  not({ name, node: { value } }) {
    return `“${value}” nije dozvoljeno ${name}.`;
  },
  /**
   *  Is not a number
   * @see {@link https://formkit.com/essentials/validation#number}
   */
  number({ name }) {
    return `${sentence(name)} mora biti broj.`;
  },
  /**
   * Require one field.
   * @see {@link https://formkit.com/essentials/validation#require-one}
   */
  require_one: ({ name, node, args: inputNames }) => {
    const labels = inputNames.map((name2) => {
      const dependentNode = node.at(name2);
      if (dependentNode) {
        return createMessageName(dependentNode);
      }
      return false;
    }).filter((name2) => !!name2);
    labels.unshift(name);
    return `${labels.join(" ili ")} je obavezno.`;
  },
  /**
   * Required field.
   * @see {@link https://formkit.com/essentials/validation#required}
   */
  required({ name }) {
    return `${sentence(name)} je obavezno.`;
  },
  /**
   * Does not start with specified value
   * @see {@link https://formkit.com/essentials/validation#starts-with}
   */
  starts_with({ name, args }) {
    return `${sentence(name)} ne počinje sa ${list(args)}.`;
  },
  /**
   * Is not a url
   * @see {@link https://formkit.com/essentials/validation#url}
   */
  url() {
    return `Unesite važeći link.`;
  },
  /**
   * Shown when the date is invalid.
   */
  invalidDate: "Odabrani datum je nevažeći."
};
var bs = { ui: ui4, validation: validation4 };
var ui5 = {
  /**
   * Shown on a button for adding additional items.
   */
  add: "Afegir",
  /**
   * Shown when a button to remove items is visible.
   */
  remove: "Eliminar",
  /**
   * Shown when there are multiple items to remove at the same time.
   */
  removeAll: "Eliminar tot",
  /**
   * Shown when all fields are not filled out correctly.
   */
  incomplete: "Disculpi, no tots els camps estan omplerts correctament.",
  /**
   * Shown in a button inside a form to submit the form.
   */
  submit: "Enviar",
  /**
   * Shown when no files are selected.
   */
  noFiles: "Cap fitxer triat",
  /**
   * Shown on buttons that move fields up in a list.
   */
  moveUp: "Moure amunt",
  /**
   * Shown on buttons that move fields down in a list.
   */
  moveDown: "Moure avall",
  /**
   * Shown when something is actively loading.
   */
  isLoading: "Carregant...",
  /**
   * Shown when there is more to load.
   */
  loadMore: "Carregar més",
  /**
   * Shown on buttons that navigate state forward
   */
  next: "Següent",
  /**
   * Shown on buttons that navigate state backward
   */
  prev: "Anterior",
  /**
   * Shown when adding all values.
   */
  addAllValues: "Afegir tots els valors",
  /**
   * Shown when adding selected values.
   */
  addSelectedValues: "Afegeix els valors seleccionats",
  /**
   * Shown when removing all values.
   */
  removeAllValues: "Eliminar tots els valors",
  /**
   * Shown when removing selected values.
   */
  removeSelectedValues: "Elimina els valors seleccionats",
  /**
   * Shown when there is a date to choose.
   */
  chooseDate: "Trieu la data",
  /**
   * Shown when there is a date to change.
   */
  changeDate: "Canviar data",
  /**
   * Shown when there is something to close
   */
  close: "Tancar",
  /**
   * Shown when there is something to open.
   */
  open: "Obert"
};
var validation5 = {
  /**
   * The value is not an accepted value.
   * @see {@link https://docs.formkit.com/essentials/validation#accepted}
   */
  accepted({ name }) {
    return `Si us plau accepti ${name}.`;
  },
  /**
   * The date is not after
   * @see {@link https://docs.formkit.com/essentials/validation#date-after}
   */
  date_after({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${sentence(name)} ha de ser posterior a ${date(args[0])}.`;
    }
    return `${sentence(name)} ha de succeïr al futur.`;
  },
  /**
   * The value is not a letter.
   * @see {@link https://docs.formkit.com/essentials/validation#alpha}
   */
  alpha({ name }) {
    return `${sentence(name)} només pot contenir caràcters alfabètics.`;
  },
  /**
   * The value is not alphanumeric
   * @see {@link https://docs.formkit.com/essentials/validation#alphanumeric}
   */
  alphanumeric({ name }) {
    return `${sentence(name)} només pot contenir lletres i números.`;
  },
  /**
   * The value is not letter and/or spaces
   * @see {@link https://docs.formkit.com/essentials/validation#alpha-spaces}
   */
  alpha_spaces({ name }) {
    return `${sentence(name)} només pot contenir lletres i espais.`;
  },
  /**
   * The value have no letter.
   * @see {@link https://formkit.com/essentials/validation#contains_alpha}
   */
  contains_alpha({ name }) {
    return `${sentence(name)} ha de contenir caràcters alfabètics.`;
  },
  /**
   * The value have no alphanumeric
   * @see {@link https://formkit.com/essentials/validation#contains_alphanumeric}
   */
  contains_alphanumeric({ name }) {
    return `${sentence(name)} ha de contenir lletres o números.`;
  },
  /**
   * The value have no letter and/or spaces
   * @see {@link https://formkit.com/essentials/validation#contains_alpha-spaces}
   */
  contains_alpha_spaces({ name }) {
    return `${sentence(name)} ha de contenir lletres o espais.`;
  },
  /**
   * The value have no symbol
   * @see {@link https://formkit.com/essentials/validation#contains_symbol}
   */
  contains_symbol({ name }) {
    return `${sentence(name)} ha de contenir símbol.`;
  },
  /**
   * The value have no uppercase
   * @see {@link https://formkit.com/essentials/validation#contains_uppercase}
   */
  contains_uppercase({ name }) {
    return `${sentence(name)} ha de contenir majúscules.`;
  },
  /**
   * The value have no lowercase
   * @see {@link https://formkit.com/essentials/validation#contains_lowercase}
   */
  contains_lowercase({ name }) {
    return `${sentence(name)} ha de contenir minúscules.`;
  },
  /**
   *  The value have no numeric
   * @see {@link https://formkit.com/essentials/validation#contains_numeric}
   */
  contains_numeric({ name }) {
    return `${sentence(name)} ha de contenir números.`;
  },
  /**
   * The value is not symbol
   * @see {@link https://formkit.com/essentials/validation#symbol}
   */
  symbol({ name }) {
    return `${sentence(name)} ha de ser un símbol.`;
  },
  /**
   * The value is not uppercase
   * @see {@link https://formkit.com/essentials/validation#uppercase}
   */
  uppercase({ name }) {
    return `${sentence(name)} només pot contenir lletres majúscules.`;
  },
  /**
   * The value is not lowercase
   * @see {@link https://formkit.com/essentials/validation#lowercase}
   */
  lowercase({ name }) {
    return `${sentence(name)} només pot contenir lletres minúscules.`;
  },
  /**
   * The date is not before
   * @see {@link https://docs.formkit.com/essentials/validation#date-before}
   */
  date_before({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${sentence(name)} ha de ser anterior a ${date(args[0])}.`;
    }
    return `${sentence(name)} ha d'estar al passat.`;
  },
  /**
   * The value is not between two numbers
   * @see {@link https://docs.formkit.com/essentials/validation#between}
   */
  between({ name, args }) {
    if (isNaN(args[0]) || isNaN(args[1])) {
      return `Aquest camp està configurat incorrectament i no pot ésser enviat.`;
    }
    const [a, b] = order(args[0], args[1]);
    return `${sentence(name)} ha d'estar entre ${a} i ${b}.`;
  },
  /**
   * The confirmation field does not match
   * @see {@link https://docs.formkit.com/essentials/validation#confirm}
   */
  confirm({ name }) {
    return `${sentence(name)} no concorda.`;
  },
  /**
   * The value is not a valid date
   * @see {@link https://docs.formkit.com/essentials/validation#date-format}
   */
  date_format({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${sentence(name)} no és una data vàlida, si us plau empri el format ${args[0]}`;
    }
    return "Aquest camp està configurat incorrectament i no pot ésser enviat";
  },
  /**
   * Is not within expected date range
   * @see {@link https://docs.formkit.com/essentials/validation#date-between}
   */
  date_between({ name, args }) {
    return `${sentence(name)} ha d'estar entre ${date(args[0])} i ${date(args[1])}`;
  },
  /**
   * Shown when the user-provided value is not a valid email address.
   * @see {@link https://docs.formkit.com/essentials/validation#email}
   */
  email: `Si us plau, entri una adreça d'e-mail vàlida.`,
  /**
   * Does not end with the specified value
   * @see {@link https://docs.formkit.com/essentials/validation#ends-with}
   */
  ends_with({ name, args }) {
    return `${sentence(name)} no acaba amb ${list(args)}.`;
  },
  /**
   * Is not an allowed value
   * @see {@link https://docs.formkit.com/essentials/validation#is}
   */
  is({ name }) {
    return `${sentence(name)} no és un valor acceptat.`;
  },
  /**
   * Does not match specified length
   * @see {@link https://docs.formkit.com/essentials/validation#length}
   */
  length({ name, args: [first = 0, second = Infinity] }) {
    const min = Number(first) <= Number(second) ? first : second;
    const max = Number(second) >= Number(first) ? second : first;
    if (min == 1 && max === Infinity) {
      return `${sentence(name)} ha de tenir com a mínim un caràcter.`;
    }
    if (min == 0 && max) {
      return `${sentence(name)} ha de ser inferior o igual a ${max} caràcters.`;
    }
    if (min === max) {
      return `${sentence(name)} ha de tenir una longitud de ${max} caràcters.`;
    }
    if (min && max === Infinity) {
      return `${sentence(name)} ha de ser major que o igual a ${min} caràcters.`;
    }
    return `${sentence(name)} ha d'estar entre ${min} i ${max} caràcters.`;
  },
  /**
   * Value is not a match
   * @see {@link https://docs.formkit.com/essentials/validation#matches}
   */
  matches({ name }) {
    return `${sentence(name)} no és un valor permès.`;
  },
  /**
   * Exceeds maximum allowed value
   * @see {@link https://docs.formkit.com/essentials/validation#max}
   */
  max({ name, node: { value }, args }) {
    if (Array.isArray(value)) {
      return `No pot tenir més de ${args[0]} ${name}.`;
    }
    return `${sentence(name)} ha de ser menys que o igual a ${args[0]}.`;
  },
  /**
   * The (field-level) value does not match specified mime type
   * @see {@link https://docs.formkit.com/essentials/validation#mime}
   */
  mime({ name, args }) {
    if (!args[0]) {
      return "No hi ha cap format de fitxer acceptat.";
    }
    return `${sentence(name)} ha de ser del tipus: ${args[0]}`;
  },
  /**
   * Does not fulfill minimum allowed value
   * @see {@link https://docs.formkit.com/essentials/validation#min}
   */
  min({ name, node: { value }, args }) {
    if (Array.isArray(value)) {
      return `No pot tenir menys de ${args[0]} ${name}.`;
    }
    return `${sentence(name)} ha de ser com a mínim ${args[0]}.`;
  },
  /**
   * Is not an allowed value
   * @see {@link https://docs.formkit.com/essentials/validation#not}
   */
  not({ name, node: { value } }) {
    return `“${value}” no s'accepta com a ${name}.`;
  },
  /**
   *  Is not a number
   * @see {@link https://docs.formkit.com/essentials/validation#number}
   */
  number({ name }) {
    return `${sentence(name)} ha de ser un número.`;
  },
  /**
   * Require one field.
   * @see {@link https://formkit.com/essentials/validation#require-one}
   */
  require_one: ({ name, node, args: inputNames }) => {
    const labels = inputNames.map((name2) => {
      const dependentNode = node.at(name2);
      if (dependentNode) {
        return createMessageName(dependentNode);
      }
      return false;
    }).filter((name2) => !!name2);
    labels.unshift(name);
    return `${labels.join(" o ")} es requereix.`;
  },
  /**
   * Required field.
   * @see {@link https://docs.formkit.com/essentials/validation#required}
   */
  required({ name }) {
    return `${sentence(name)} és obligatori.`;
  },
  /**
   * Does not start with specified value
   * @see {@link https://docs.formkit.com/essentials/validation#starts-with}
   */
  starts_with({ name, args }) {
    return `${sentence(name)} no comença amb ${list(args)}.`;
  },
  /**
   * Is not a url
   * @see {@link https://docs.formkit.com/essentials/validation#url}
   */
  url() {
    return `Si us plau inclogui una url vàlida.`;
  },
  /**
   * Shown when the date is invalid.
   */
  invalidDate: "La data seleccionada no és vàlida."
};
var ca = { ui: ui5, validation: validation5 };
var ui6 = {
  /**
   * Shown on buttons for adding new items.
   */
  add: "Přidat",
  /**
   * Shown when a button to remove items is visible.
   */
  remove: "Odebrat",
  /**
   * Shown when there are multiple items to remove at the same time.
   */
  removeAll: "Odebrat vše",
  /**
   * Shown when all fields are not filled out correctly.
   */
  incomplete: "Pardon, ale ne všechna pole jsou vyplněna správně.",
  /**
   * Shown in a button inside a form to submit the form.
   */
  submit: "Odeslat",
  /**
   * Shown when no files are selected.
   */
  noFiles: "Žádný soubor nebyl vybrán",
  /**
   * Shown on buttons that move fields up in a list.
   */
  moveUp: "Pohyb nahoru",
  /**
   * Shown on buttons that move fields down in a list.
   */
  moveDown: "Posunout dolů",
  /**
   * Shown when something is actively loading.
   */
  isLoading: "Načítání...",
  /**
   * Shown when there is more to load.
   */
  loadMore: "Načíst více",
  /**
   * Shown on buttons that navigate state forward
   */
  next: "Další",
  /**
   * Shown on buttons that navigate state backward
   */
  prev: "Předchozí",
  /**
   * Shown when adding all values.
   */
  addAllValues: "Přidat všechny hodnoty",
  /**
   * Shown when adding selected values.
   */
  addSelectedValues: "Přidání vybraných hodnot",
  /**
   * Shown when removing all values.
   */
  removeAllValues: "Odstraňte všechny hodnoty",
  /**
   * Shown when removing selected values.
   */
  removeSelectedValues: "Odstranění vybraných hodnot",
  /**
   * Shown when there is a date to choose.
   */
  chooseDate: "Zvolte datum",
  /**
   * Shown when there is a date to change.
   */
  changeDate: "Změnit datum",
  /**
   * Shown when there is something to close
   */
  close: "Zavřít",
  /**
   * Shown when there is something to open.
   */
  open: "Otevřeno"
};
var validation6 = {
  /**
   * The value is not an accepted value.
   * @see {@link https://formkit.com/essentials/validation#accepted}
   */
  accepted({ name }) {
    return `Prosím, zaškrtněte ${name}.`;
  },
  /**
   * The date is not after
   * @see {@link https://formkit.com/essentials/validation#date-after}
   */
  date_after({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${sentence(name)} musí být po ${date(args[0])}.`;
    }
    return `${sentence(name)} musí být v budoucnosti.`;
  },
  /**
   * The value is not a letter.
   * @see {@link https://formkit.com/essentials/validation#alpha}
   */
  alpha({ name }) {
    return `${sentence(name)} může obsahovat pouze písmena.`;
  },
  /**
   * The value is not alphanumeric
   * @see {@link https://formkit.com/essentials/validation#alphanumeric}
   */
  alphanumeric({ name }) {
    return `${sentence(name)} může obsahovat pouze písmena a čísla.`;
  },
  /**
   * The value have no letter.
   * @see {@link https://formkit.com/essentials/validation#contains_alpha}
   */
  contains_alpha({ name }) {
    return `${sentence(name)} musí obsahovat abecední znaky.`;
  },
  /**
   * The value have no alphanumeric
   * @see {@link https://formkit.com/essentials/validation#contains_alphanumeric}
   */
  contains_alphanumeric({ name }) {
    return `${sentence(name)} musí obsahovat písmena nebo číslice.`;
  },
  /**
   * The value have no letter and/or spaces
   * @see {@link https://formkit.com/essentials/validation#contains_alpha-spaces}
   */
  contains_alpha_spaces({ name }) {
    return `${sentence(name)} musí obsahovat písmena nebo mezery.`;
  },
  /**
   * The value have no symbol
   * @see {@link https://formkit.com/essentials/validation#contains_symbol}
   */
  contains_symbol({ name }) {
    return `${sentence(name)} musí obsahovat symbol.`;
  },
  /**
   * The value have no uppercase
   * @see {@link https://formkit.com/essentials/validation#contains_uppercase}
   */
  contains_uppercase({ name }) {
    return `${sentence(name)} musí obsahovat velká písmena.`;
  },
  /**
   * The value have no lowercase
   * @see {@link https://formkit.com/essentials/validation#contains_lowercase}
   */
  contains_lowercase({ name }) {
    return `${sentence(name)} musí obsahovat malá písmena.`;
  },
  /**
   *  The value have no numeric
   * @see {@link https://formkit.com/essentials/validation#contains_numeric}
   */
  contains_numeric({ name }) {
    return `${sentence(name)} musí obsahovat čísla.`;
  },
  /**
   * The value is not symbol
   * @see {@link https://formkit.com/essentials/validation#symbol}
   */
  symbol({ name }) {
    return `${sentence(name)} musí být symbol.`;
  },
  /**
   * The value is not uppercase
   * @see {@link https://formkit.com/essentials/validation#uppercase}
   */
  uppercase({ name }) {
    return `${sentence(name)} může obsahovat pouze velká písmena.`;
  },
  /**
   * The value is not lowercase
   * @see {@link https://formkit.com/essentials/validation#lowercase}
   */
  lowercase({ name }) {
    return `${sentence(name)} může obsahovat pouze malá písmena.`;
  },
  /**
   * The date is not before
   * @see {@link https://formkit.com/essentials/validation#date-before}
   */
  date_before({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${sentence(name)} musí být před ${date(args[0])}.`;
    }
    return `${sentence(name)} musí být v minulosti.`;
  },
  /**
   * The value is not between two numbers
   * @see {@link https://formkit.com/essentials/validation#between}
   */
  between({ name, args }) {
    if (isNaN(args[0]) || isNaN(args[1])) {
      return `Toto pole bylo špatně nakonfigurováno a nemůže být odesláno.`;
    }
    const [a, b] = order(args[0], args[1]);
    return `${sentence(name)} musí být mezi ${a} a ${b}.`;
  },
  /**
   * The confirmation field does not match
   * @see {@link https://formkit.com/essentials/validation#confirm}
   */
  confirm({ name }) {
    return `${sentence(name)} nejsou shodná.`;
  },
  /**
   * The value is not a valid date
   * @see {@link https://formkit.com/essentials/validation#date-format}
   */
  date_format({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${sentence(name)} není platné datum, prosím, použijte formát ${args[0]}`;
    }
    return "Toto pole bylo špatně nakonfigurováno a nemůže být odesláno.";
  },
  /**
   * Is not within expected date range
   * @see {@link https://formkit.com/essentials/validation#date-between}
   */
  date_between({ name, args }) {
    return `${sentence(name)} musí být mezi ${date(args[0])} a ${date(args[1])}`;
  },
  /**
   * Shown when the user-provided value is not a valid email address.
   * @see {@link https://formkit.com/essentials/validation#email}
   */
  email: "Prosím, zadejte platnou e-mailovou adresu.",
  /**
   * Does not end with the specified value
   * @see {@link https://formkit.com/essentials/validation#ends-with}
   */
  ends_with({ name, args }) {
    return `${sentence(name)} nekončí na ${list(args)}.`;
  },
  /**
   * Is not an allowed value
   * @see {@link https://formkit.com/essentials/validation#is}
   */
  is({ name }) {
    return `${sentence(name)} není povolená hodnota.`;
  },
  /**
   * Does not match specified length
   * @see {@link https://formkit.com/essentials/validation#length}
   */
  length({ name, args: [first = 0, second = Infinity] }) {
    const min = Number(first) <= Number(second) ? first : second;
    const max = Number(second) >= Number(first) ? second : first;
    if (min == 1 && max === Infinity) {
      return `${sentence(name)} musí mít nejméně jeden znak.`;
    }
    if (min == 0 && max) {
      return `${sentence(name)} může mít maximálně ${max} znaků.`;
    }
    if (min === max) {
      return `${sentence(name)} by mělo být ${max} znaků dlouhé.`;
    }
    if (min && max === Infinity) {
      return `${sentence(name)} musí obsahovat minimálně ${min} znaků.`;
    }
    return `${sentence(name)} musí být dlouhé ${min} až ${max} znaků.`;
  },
  /**
   * Value is not a match
   * @see {@link https://formkit.com/essentials/validation#matches}
   */
  matches({ name }) {
    return `${sentence(name)} není povolená hodnota.`;
  },
  /**
   * Exceeds maximum allowed value
   * @see {@link https://formkit.com/essentials/validation#max}
   */
  max({ name, node: { value }, args }) {
    if (Array.isArray(value)) {
      return `Nelze použít více než ${args[0]} ${name}.`;
    }
    return `${sentence(name)} musí mít menší nebo rovno než ${args[0]}.`;
  },
  /**
   * The (field-level) value does not match specified mime type
   * @see {@link https://formkit.com/essentials/validation#mime}
   */
  mime({ name, args }) {
    if (!args[0]) {
      return "Nejsou nakonfigurovány povolené typy souborů.";
    }
    return `${sentence(name)} musí být typu: ${args[0]}`;
  },
  /**
   * Does not fulfill minimum allowed value
   * @see {@link https://formkit.com/essentials/validation#min}
   */
  min({ name, node: { value }, args }) {
    if (Array.isArray(value)) {
      return `Nelze mít méně než ${args[0]} ${name}.`;
    }
    return `${sentence(name)} musí být minimálně ${args[0]}.`;
  },
  /**
   * Is not an allowed value
   * @see {@link https://formkit.com/essentials/validation#not}
   */
  not({ name, node: { value } }) {
    return `“${value}” není dovolená hodnota pro ${name}.`;
  },
  /**
   *  Is not a number
   * @see {@link https://formkit.com/essentials/validation#number}
   */
  number({ name }) {
    return `${sentence(name)} musí být číslo.`;
  },
  /**
   * Require one field.
   * @see {@link https://formkit.com/essentials/validation#require-one}
   */
  require_one: ({ name, node, args: inputNames }) => {
    const labels = inputNames.map((name2) => {
      const dependentNode = node.at(name2);
      if (dependentNode) {
        return createMessageName(dependentNode);
      }
      return false;
    }).filter((name2) => !!name2);
    labels.unshift(name);
    return `${labels.join(" nebo ")} je vyžadován.`;
  },
  /**
   * Required field.
   * @see {@link https://formkit.com/essentials/validation#required}
   */
  required({ name }) {
    return `${sentence(name)} je povinné.`;
  },
  /**
   * Does not start with specified value
   * @see {@link https://formkit.com/essentials/validation#starts-with}
   */
  starts_with({ name, args }) {
    return `${sentence(name)} nezačíná na ${list(args)}.`;
  },
  /**
   * Is not a url
   * @see {@link https://formkit.com/essentials/validation#url}
   */
  url() {
    return `Zadejte prosím platnou adresu URL.`;
  },
  /**
   * Shown when the date is invalid.
   */
  invalidDate: "Vybrané datum je neplatné."
};
var cs = { ui: ui6, validation: validation6 };
var ui7 = {
  /**
   * Shown on buttons for adding new items.
   */
  add: "Tilføj",
  /**
   * Shown when a button to remove items is visible.
   */
  remove: "Fjern",
  /**
   * Shown when there are multiple items to remove at the same time.
   */
  removeAll: "Fjern alle",
  /**
   * Shown when all fields are not filled out correctly.
   */
  incomplete: "Alle felter er ikke korrekt udfyldt.",
  /**
   * Shown in a button inside a form to submit the form.
   */
  submit: "Send",
  /**
   * Shown when no files are selected.
   */
  noFiles: "Ingen filer valgt",
  /**
   * Shown on buttons that move fields up in a list.
   */
  moveUp: "Flyt op",
  /**
   * Shown on buttons that move fields down in a list.
   */
  moveDown: "Flyt ned",
  /**
   * Shown when something is actively loading.
   */
  isLoading: "Indlæser...",
  /**
   * Shown when there is more to load.
   */
  loadMore: "Indlæs mere",
  /**
   * Shown on buttons that navigate state forward
   */
  next: "Næste",
  /**
   * Shown on buttons that navigate state backward
   */
  prev: "Forrige",
  /**
   * Shown when adding all values.
   */
  addAllValues: "Tilføj alle værdier",
  /**
   * Shown when adding selected values.
   */
  addSelectedValues: "Tilføj valgte værdier",
  /**
   * Shown when removing all values.
   */
  removeAllValues: "Fjern alle værdier",
  /**
   * Shown when removing selected values.
   */
  removeSelectedValues: "Fjern valgte værdier",
  /**
   * Shown when there is a date to choose.
   */
  chooseDate: "Vælg dato",
  /**
   * Shown when there is a date to change.
   */
  changeDate: "Skift dato",
  /**
   * Shown when there is something to close
   */
  close: "Luk",
  /**
   * Shown when there is something to open.
   */
  open: "Åbn"
};
var validation7 = {
  /**
   * The value is not an accepted value.
   * @see {@link https://formkit.com/essentials/validation#accepted}
   */
  accepted({ name }) {
    return `Accepter venligst ${name}.`;
  },
  /**
   * The date is not after
   * @see {@link https://formkit.com/essentials/validation#date-after}
   */
  date_after({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${sentence(name)} skal være senere end ${date(args[0])}.`;
    }
    return `${sentence(name)} skal være i fremtiden.`;
  },
  /**
   * The value is not a letter.
   * @see {@link https://formkit.com/essentials/validation#alpha}
   */
  alpha({ name }) {
    return `${sentence(name)} kan kun indeholde bogstaver.`;
  },
  /**
   * The value is not alphanumeric
   * @see {@link https://formkit.com/essentials/validation#alphanumeric}
   */
  alphanumeric({ name }) {
    return `${sentence(name)} kan kun indeholde bogstaver og tal.`;
  },
  /**
   * The value is not letter and/or spaces
   * @see {@link https://formkit.com/essentials/validation#alpha-spaces}
   */
  alpha_spaces({ name }) {
    return `${sentence(name)} kan kun indeholde bogstaver og mellemrum.`;
  },
  /**
   * The value have no letter.
   * @see {@link https://formkit.com/essentials/validation#contains_alpha}
   */
  contains_alpha({ name }) {
    return `${sentence(name)} skal indeholde alfabetiske tegn.`;
  },
  /**
   * The value have no alphanumeric
   * @see {@link https://formkit.com/essentials/validation#contains_alphanumeric}
   */
  contains_alphanumeric({ name }) {
    return `${sentence(name)} skal indeholde bogstaver eller tal.`;
  },
  /**
   * The value have no letter and/or spaces
   * @see {@link https://formkit.com/essentials/validation#contains_alpha-spaces}
   */
  contains_alpha_spaces({ name }) {
    return `${sentence(name)} skal indeholde bogstaver eller mellemrum.`;
  },
  /**
   * The value have no symbol
   * @see {@link https://formkit.com/essentials/validation#contains_symbol}
   */
  contains_symbol({ name }) {
    return `${sentence(name)} skal indeholde symbol.`;
  },
  /**
   * The value have no uppercase
   * @see {@link https://formkit.com/essentials/validation#contains_uppercase}
   */
  contains_uppercase({ name }) {
    return `${sentence(name)} skal indeholde store bogstaver.`;
  },
  /**
   * The value have no lowercase
   * @see {@link https://formkit.com/essentials/validation#contains_lowercase}
   */
  contains_lowercase({ name }) {
    return `${sentence(name)} skal indeholde små bogstaver.`;
  },
  /**
   *  The value have no numeric
   * @see {@link https://formkit.com/essentials/validation#contains_numeric}
   */
  contains_numeric({ name }) {
    return `${sentence(name)} skal indeholde tal.`;
  },
  /**
   * The value is not symbol
   * @see {@link https://formkit.com/essentials/validation#symbol}
   */
  symbol({ name }) {
    return `${sentence(name)} skal være et symbol.`;
  },
  /**
   * The value is not uppercase
   * @see {@link https://formkit.com/essentials/validation#uppercase}
   */
  uppercase({ name }) {
    return `${sentence(name)} kan kun indeholde store bogstaver.`;
  },
  /**
   * The value is not lowercase
   * @see {@link https://formkit.com/essentials/validation#lowercase}
   */
  lowercase({ name }) {
    return `${sentence(name)} kan kun indeholde små bogstaver.`;
  },
  /**
   * The date is not before
   * @see {@link https://formkit.com/essentials/validation#date-before}
   */
  date_before({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${sentence(name)} skal være før ${date(args[0])}.`;
    }
    return `${sentence(name)} skal være før i dag.`;
  },
  /**
   * The value is not between two numbers
   * @see {@link https://formkit.com/essentials/validation#between}
   */
  between({ name, args }) {
    if (isNaN(args[0]) || isNaN(args[1])) {
      return `Dette felt er ikke konfigureret korrekt og kan derfor ikke blive sendt.`;
    }
    const [a, b] = order(args[0], args[1]);
    return `${sentence(name)} skal være mellem ${a} og ${b}.`;
  },
  /**
   * The confirmation field does not match
   * @see {@link https://formkit.com/essentials/validation#confirm}
   */
  confirm({ name }) {
    return `${sentence(name)} matcher ikke.`;
  },
  /**
   * The value is not a valid date
   * @see {@link https://formkit.com/essentials/validation#date-format}
   */
  date_format({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${sentence(name)} er ikke gyldig, brug venligst formatet ${args[0]}`;
    }
    return "Dette felt er ikke konfigureret korrekt og kan derfor ikke blive sendt.";
  },
  /**
   * Is not within expected date range
   * @see {@link https://formkit.com/essentials/validation#date-between}
   */
  date_between({ name, args }) {
    return `${sentence(name)} skal være mellem ${date(args[0])} og ${date(args[1])}`;
  },
  /**
   * Shown when the user-provided value is not a valid email address.
   * @see {@link https://formkit.com/essentials/validation#email}
   */
  email: "Indtast venligst en gyldig email-adresse.",
  /**
   * Does not end with the specified value
   * @see {@link https://formkit.com/essentials/validation#ends-with}
   */
  ends_with({ name, args }) {
    return `${sentence(name)} slutter ikke med ${list(args)}.`;
  },
  /**
   * Is not an allowed value
   * @see {@link https://formkit.com/essentials/validation#is}
   */
  is({ name }) {
    return `${sentence(name)} er ikke en gyldig værdi.`;
  },
  /**
   * Does not match specified length
   * @see {@link https://formkit.com/essentials/validation#length}
   */
  length({ name, args: [first = 0, second = Infinity] }) {
    const min = Number(first) <= Number(second) ? first : second;
    const max = Number(second) >= Number(first) ? second : first;
    if (min == 1 && max === Infinity) {
      return `${sentence(name)} skal være på mindst ét tegn.`;
    }
    if (min == 0 && max) {
      return `${sentence(name)} skal være på højst ${max} tegn.`;
    }
    if (min === max) {
      return `${sentence(name)} skal være ${max} tegn lange.`;
    }
    if (min && max === Infinity) {
      return `${sentence(name)} skal være på mindst ${min} tegn.`;
    }
    return `${sentence(name)} skal være på mindst ${min} og højst ${max} tegn.`;
  },
  /**
   * Value is not a match
   * @see {@link https://formkit.com/essentials/validation#matches}
   */
  matches({ name }) {
    return `${sentence(name)} er ikke en gyldig værdi.`;
  },
  /**
   * Exceeds maximum allowed value
   * @see {@link https://formkit.com/essentials/validation#max}
   */
  max({ name, node: { value }, args }) {
    if (Array.isArray(value)) {
      return `Kan ikke have flere end ${args[0]} ${name}.`;
    }
    return `${sentence(name)} skal være mindre eller lig med ${args[0]}.`;
  },
  /**
   * The (field-level) value does not match specified mime type
   * @see {@link https://formkit.com/essentials/validation#mime}
   */
  mime({ name, args }) {
    if (!args[0]) {
      return "Ingen filformater tilladt.";
    }
    return `${sentence(name)} skal være af filtypen: ${args[0]}`;
  },
  /**
   * Does not fulfill minimum allowed value
   * @see {@link https://formkit.com/essentials/validation#min}
   */
  min({ name, node: { value }, args }) {
    if (Array.isArray(value)) {
      return `Kan ikke have mindre end ${args[0]} ${name}.`;
    }
    return `${sentence(name)} skal være mindst ${args[0]}.`;
  },
  /**
   * Is not an allowed value
   * @see {@link https://formkit.com/essentials/validation#not}
   */
  not({ name, node: { value } }) {
    return `“${value}” er ikke en tilladt ${name}.`;
  },
  /**
   *  Is not a number
   * @see {@link https://formkit.com/essentials/validation#number}
   */
  number({ name }) {
    return `${sentence(name)} skal være et tal.`;
  },
  /**
   * Require one field.
   * @see {@link https://formkit.com/essentials/validation#require-one}
   */
  require_one: ({ name, node, args: inputNames }) => {
    const labels = inputNames.map((name2) => {
      const dependentNode = node.at(name2);
      if (dependentNode) {
        return createMessageName(dependentNode);
      }
      return false;
    }).filter((name2) => !!name2);
    labels.unshift(name);
    return `${labels.join(" eller ")} er påkrævet.`;
  },
  /**
   * Required field.
   * @see {@link https://formkit.com/essentials/validation#required}
   */
  required({ name }) {
    return `${sentence(name)} er påkrævet.`;
  },
  /**
   * Does not start with specified value
   * @see {@link https://formkit.com/essentials/validation#starts-with}
   */
  starts_with({ name, args }) {
    return `${sentence(name)} starter ikke med ${list(args)}.`;
  },
  /**
   * Is not a url
   * @see {@link https://formkit.com/essentials/validation#url}
   */
  url() {
    return `Indtast en gyldig URL.`;
  },
  /**
   * Shown when the date is invalid.
   */
  invalidDate: "Den valgte dato er ugyldig."
};
var da = { ui: ui7, validation: validation7 };
var ui8 = {
  /**
   * Shown on buttons for adding new items.
   */
  add: "Hinzufügen",
  /**
   * Shown when a button to remove items is visible.
   */
  remove: "Entfernen",
  /**
   * Shown when there are multiple items to remove at the same time.
   */
  removeAll: "Alles entfernen",
  /**
   * Shown when all fields are not filled out correctly.
   */
  incomplete: "Entschuldigung, nicht alle Felder wurden korrekt ausgefüllt.",
  /**
   * Shown in a button inside a form to submit the form.
   */
  submit: "Senden",
  /**
   * Shown when no files are selected.
   */
  noFiles: "Keine Datei ausgewählt",
  /**
   * Shown on buttons that move fields up in a list.
   */
  moveUp: "Gehe nach oben",
  /**
   * Shown on buttons that move fields down in a list.
   */
  moveDown: "Gehen Sie nach unten",
  /**
   * Shown when something is actively loading.
   */
  isLoading: "Wird geladen...",
  /**
   * Shown when there is more to load.
   */
  loadMore: "Mehr laden",
  /**
   * Shown on buttons that navigate state forward
   */
  next: "Weiter",
  /**
   * Shown on buttons that navigate state backward
   */
  prev: "Zurück",
  /**
   * Shown when adding all values.
   */
  addAllValues: "Alle Werte hinzufügen",
  /**
   * Shown when adding selected values.
   */
  addSelectedValues: "Ausgewählte Werte hinzufügen",
  /**
   * Shown when removing all values.
   */
  removeAllValues: "Alle Werte entfernen",
  /**
   * Shown when removing selected values.
   */
  removeSelectedValues: "Ausgewählte Werte entfernen",
  /**
   * Shown when there is a date to choose.
   */
  chooseDate: "Datum wählen",
  /**
   * Shown when there is a date to change.
   */
  changeDate: "Datum ändern",
  /**
   * Shown when there is something to close
   */
  close: "Schliessen",
  /**
   * Shown when there is something to open.
   */
  open: "Offen"
};
var validation8 = {
  /**
   * The value is not an accepted value.
   * @see {@link https://formkit.com/essentials/validation#accepted}
   */
  accepted({ name }) {
    return `Bitte ${name} akzeptieren.`;
  },
  /**
   * The date is not after
   * @see {@link https://formkit.com/essentials/validation#date-after}
   */
  date_after({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${sentence(name)} muss nach dem ${date(args[0])} liegen.`;
    }
    return `${sentence(name)} muss in der Zukunft liegen.`;
  },
  /**
   * The value is not a letter.
   * @see {@link https://formkit.com/essentials/validation#alpha}
   */
  alpha({ name }) {
    return `${sentence(name)} darf nur Buchstaben enthalten.`;
  },
  /**
   * The value is not alphanumeric
   * @see {@link https://formkit.com/essentials/validation#alphanumeric}
   */
  alphanumeric({ name }) {
    return `${sentence(name)} darf nur Buchstaben und Zahlen enthalten.`;
  },
  /**
   * The value is not letter and/or spaces
   * @see {@link https://formkit.com/essentials/validation#alpha-spaces}
   */
  alpha_spaces({ name }) {
    return `${sentence(name)} dürfen nur Buchstaben und Leerzeichen enthalten.`;
  },
  /**
   * The value have no letter.
   * @see {@link https://formkit.com/essentials/validation#contains_alpha}
   */
  contains_alpha({ name }) {
    return `${sentence(name)} muss alphabetische Zeichen enthalten.`;
  },
  /**
   * The value have no alphanumeric
   * @see {@link https://formkit.com/essentials/validation#contains_alphanumeric}
   */
  contains_alphanumeric({ name }) {
    return `${sentence(name)} muss Buchstaben oder Zahlen enthalten.`;
  },
  /**
   * The value have no letter and/or spaces
   * @see {@link https://formkit.com/essentials/validation#contains_alpha-spaces}
   */
  contains_alpha_spaces({ name }) {
    return `${sentence(name)} muss Buchstaben oder Leerzeichen enthalten.`;
  },
  /**
   * The value have no symbol
   * @see {@link https://formkit.com/essentials/validation#contains_symbol}
   */
  contains_symbol({ name }) {
    return `${sentence(name)} muss ein Symbol enthalten.`;
  },
  /**
   * The value have no uppercase
   * @see {@link https://formkit.com/essentials/validation#contains_uppercase}
   */
  contains_uppercase({ name }) {
    return `${sentence(name)} muss Großbuchstaben enthalten.`;
  },
  /**
   * The value have no lowercase
   * @see {@link https://formkit.com/essentials/validation#contains_lowercase}
   */
  contains_lowercase({ name }) {
    return `${sentence(name)} muss Kleinbuchstaben enthalten.`;
  },
  /**
   *  The value have no numeric
   * @see {@link https://formkit.com/essentials/validation#contains_numeric}
   */
  contains_numeric({ name }) {
    return `${sentence(name)} muss Zahlen enthalten.`;
  },
  /**
   * The value is not symbol
   * @see {@link https://formkit.com/essentials/validation#symbol}
   */
  symbol({ name }) {
    return `${sentence(name)} muss ein Symbol sein.`;
  },
  /**
   * The value is not uppercase
   * @see {@link https://formkit.com/essentials/validation#uppercase}
   */
  uppercase({ name }) {
    return `${sentence(name)} kann nur Großbuchstaben enthalten.`;
  },
  /**
   * The value is not lowercase
   * @see {@link https://formkit.com/essentials/validation#lowercase}
   */
  lowercase({ name }) {
    return `${sentence(name)} kann nur Kleinbuchstaben enthalten.`;
  },
  /**
   * The date is not before
   * @see {@link https://formkit.com/essentials/validation#date-before}
   */
  date_before({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${sentence(name)} muss vor dem ${date(args[0])} liegen.`;
    }
    return `${sentence(name)} muss in der Vergangenheit liegen.`;
  },
  /**
   * The value is not between two numbers
   * @see {@link https://formkit.com/essentials/validation#between}
   */
  between({ name, args }) {
    if (isNaN(args[0]) || isNaN(args[1])) {
      return `Dieses Feld wurde falsch konfiguriert und kann nicht übermittelt werden.`;
    }
    return `${sentence(name)} muss zwischen ${args[0]} und ${args[1]} sein.`;
  },
  /**
   * The confirmation field does not match
   * @see {@link https://formkit.com/essentials/validation#confirm}
   */
  confirm({ name }) {
    return `${sentence(name)} stimmt nicht überein.`;
  },
  /**
   * The value is not a valid date
   * @see {@link https://formkit.com/essentials/validation#date-format}
   */
  date_format({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${sentence(name)} ist kein gültiges Datum im Format ${args[0]}.`;
    }
    return "Dieses Feld wurde falsch konfiguriert und kann nicht übermittelt werden.";
  },
  /**
   * Is not within expected date range
   * @see {@link https://formkit.com/essentials/validation#date-between}
   */
  date_between({ name, args }) {
    return `${sentence(name)} muss zwischen ${date(args[0])} und ${date(
      args[1]
    )} liegen.`;
  },
  /**
   * Shown when the user-provided value is not a valid email address.
   * @see {@link https://formkit.com/essentials/validation#email}
   */
  email: "E-Mail Adresse ist ungültig.",
  /**
   * Does not end with the specified value
   * @see {@link https://formkit.com/essentials/validation#ends-with}
   */
  ends_with({ name, args }) {
    return `${sentence(name)} endet nicht mit ${list(args)}.`;
  },
  /**
   * Is not an allowed value
   * @see {@link https://formkit.com/essentials/validation#is}
   */
  is({ name }) {
    return `${sentence(name)} enthält einen ungültigen Wert.`;
  },
  /**
   * Does not match specified length
   * @see {@link https://formkit.com/essentials/validation#length}
   */
  length({ name, args: [first = 0, second = Infinity] }) {
    const min = first <= second ? first : second;
    const max = second >= first ? second : first;
    if (min == 1 && max === Infinity) {
      return `${sentence(name)} muss mindestens ein Zeichen enthalten.`;
    }
    if (min == 0 && max) {
      return `${sentence(name)} darf maximal ${max} Zeichen enthalten.`;
    }
    if (min === max) {
      return `${sentence(name)} sollte ${max} Zeichen lang sein.`;
    }
    if (min && max === Infinity) {
      return `${sentence(name)} muss mindestens ${min} Zeichen enthalten.`;
    }
    return `${sentence(name)} muss zwischen ${min} und ${max} Zeichen enthalten.`;
  },
  /**
   * Value is not a match
   * @see {@link https://formkit.com/essentials/validation#matches}
   */
  matches({ name }) {
    return `${sentence(name)} enthält einen ungültigen Wert.`;
  },
  /**
   * Exceeds maximum allowed value
   * @see {@link https://formkit.com/essentials/validation#max}
   */
  max({ name, node: { value }, args }) {
    if (Array.isArray(value)) {
      return `Darf maximal ${args[0]} ${name} haben.`;
    }
    return `${sentence(name)} darf maximal ${args[0]} sein.`;
  },
  /**
   * The (field-level) value does not match specified mime type
   * @see {@link https://formkit.com/essentials/validation#mime}
   */
  mime({ name, args }) {
    if (!args[0]) {
      return "Keine Dateiformate konfiguriert.";
    }
    return `${sentence(name)} muss vom Typ ${args[0]} sein.`;
  },
  /**
   * Does not fulfill minimum allowed value
   * @see {@link https://formkit.com/essentials/validation#min}
   */
  min({ name, node: { value }, args }) {
    if (Array.isArray(value)) {
      return `Mindestens ${args[0]} ${name} erforderlich.`;
    }
    return `${sentence(name)} muss mindestens ${args[0]} sein.`;
  },
  /**
   * Is not an allowed value
   * @see {@link https://formkit.com/essentials/validation#not}
   */
  not({ name, node: { value } }) {
    return `“${value}” ist kein gültiger Wert für ${name}.`;
  },
  /**
   *  Is not a number
   * @see {@link https://formkit.com/essentials/validation#number}
   */
  number({ name }) {
    return `${sentence(name)} muss eine Zahl sein.`;
  },
  /**
   * Require one field.
   * @see {@link https://formkit.com/essentials/validation#require-one}
   */
  require_one: ({ name, node, args: inputNames }) => {
    const labels = inputNames.map((name2) => {
      const dependentNode = node.at(name2);
      if (dependentNode) {
        return createMessageName(dependentNode);
      }
      return false;
    }).filter((name2) => !!name2);
    labels.unshift(name);
    return `${labels.join(" oder ")} ist erforderlich.`;
  },
  /**
   * Required field.
   * @see {@link https://formkit.com/essentials/validation#required}
   */
  required({ name }) {
    return `${sentence(name)} ist erforderlich.`;
  },
  /**
   * Does not start with specified value
   * @see {@link https://formkit.com/essentials/validation#starts-with}
   */
  starts_with({ name, args }) {
    return `${sentence(name)} beginnt nicht mit ${list(args)}.`;
  },
  /**
   * Is not a url
   * @see {@link https://formkit.com/essentials/validation#url}
   */
  url() {
    return `Bitte geben Sie eine gültige URL ein.`;
  },
  /**
   * Shown when the date is invalid.
   */
  invalidDate: "Das gewählte Datum ist ungültig."
};
var de = { ui: ui8, validation: validation8 };
var ui9 = {
  /**
   * Shown on a button for adding additional items.
   */
  add: "Προσθήκη",
  /**
   * Shown when a button to remove items is visible.
   */
  remove: "Αφαίρεση",
  /**
   * Shown when there are multiple items to remove at the same time.
   */
  removeAll: "Αφαίρεση όλων",
  /**
   * Shown when all fields are not filled out correctly.
   */
  incomplete: "Λυπούμαστε, υπάρχουν πεδία που δεν έχουν συμπληρωθεί σωστά.",
  /**
   * Shown in a button inside a form to submit the form.
   */
  submit: "Υποβολή",
  /**
   * Shown when no files are selected.
   */
  noFiles: "Κανένα αρχείο δεν έχει επιλεγεί",
  /**
   * Shown on buttons that move fields up in a list.
   */
  moveUp: "Προς τα επάνω",
  /**
   * Shown on buttons that move fields down in a list.
   */
  moveDown: "Προς τα κάτω",
  /**
   * Shown when something is actively loading.
   */
  isLoading: "Φορτώνει...",
  /**
   * Shown when there is more to load.
   */
  loadMore: "Φόρτωση περισσότερων",
  /**
   * Shown on buttons that navigate state forward
   */
  next: "Επόμενη",
  /**
   * Shown on buttons that navigate state backward
   */
  prev: "Προηγούμενο",
  /**
   * Shown when adding all values.
   */
  addAllValues: "Προσθήκη όλων των τιμών",
  /**
   * Shown when adding selected values.
   */
  addSelectedValues: "Προσθήκη επιλεγμένων τιμών",
  /**
   * Shown when removing all values.
   */
  removeAllValues: "Κατάργηση όλων των τιμών",
  /**
   * Shown when removing selected values.
   */
  removeSelectedValues: "Αφαίρεση επιλεγμένων τιμών",
  /**
   * Shown when there is a date to choose.
   */
  chooseDate: "Επιλέξτε ημερομηνία",
  /**
   * Shown when there is a date to change.
   */
  changeDate: "Αλλαγή ημερομηνίας",
  /**
   * Shown when there is something to close
   */
  close: "Κλείσιμο",
  /**
   * Shown when there is something to open.
   */
  open: "Ανοιχτό"
};
var validation9 = {
  /**
   * The value is not an accepted value.
   * @see {@link https://formkit.com/essentials/validation#accepted}
   */
  accepted({ name }) {
    return `Παρακαλώ αποδεχτείτε το ${name}.`;
  },
  /**
   * The date is not after
   * @see {@link https://formkit.com/essentials/validation#date-after}
   */
  date_after({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${sentence(name)} πρέπει να είναι μετά της ${date(args[0])}.`;
    }
    return `${sentence(name)} πρέπει να είναι στο μέλλον.`;
  },
  /**
   * The value is not a letter.
   * @see {@link https://formkit.com/essentials/validation#alpha}
   */
  alpha({ name }) {
    return `${sentence(name)} μπορεί να περιέχει μόνο αλφαβητικούς χαρακτήρες.`;
  },
  /**
   * The value is not alphanumeric
   * @see {@link https://formkit.com/essentials/validation#alphanumeric}
   */
  alphanumeric({ name }) {
    return `${sentence(name)} μπορεί να περιέχει μόνο γράμματα και αριθμούς.`;
  },
  /**
   * The value is not letter and/or spaces
   * @see {@link https://formkit.com/essentials/validation#alpha-spaces}
   */
  alpha_spaces({ name }) {
    return `${sentence(name)} μπορεί να περιέχει μόνο γράμματα και κενά.`;
  },
  /**
   * The value have no letter.
   * @see {@link https://formkit.com/essentials/validation#contains_alpha}
   */
  contains_alpha({ name }) {
    return `Το ${sentence(name)} πρέπει να περιέχει αλφαβητικούς χαρακτήρες.`;
  },
  /**
   * The value have no alphanumeric
   * @see {@link https://formkit.com/essentials/validation#contains_alphanumeric}
   */
  contains_alphanumeric({ name }) {
    return `Το ${sentence(name)} πρέπει να περιέχει γράμματα ή αριθμούς.`;
  },
  /**
   * The value have no letter and/or spaces
   * @see {@link https://formkit.com/essentials/validation#contains_alpha-spaces}
   */
  contains_alpha_spaces({ name }) {
    return `${sentence(name)} πρέπει να περιέχει γράμματα ή κενά.`;
  },
  /**
   * The value have no symbol
   * @see {@link https://formkit.com/essentials/validation#contains_symbol}
   */
  contains_symbol({ name }) {
    return `Το ${sentence(name)} πρέπει να περιέχει το σύμβολο.`;
  },
  /**
   * The value have no uppercase
   * @see {@link https://formkit.com/essentials/validation#contains_uppercase}
   */
  contains_uppercase({ name }) {
    return `Το ${sentence(name)} πρέπει να περιέχει κεφαλαία γράμματα.`;
  },
  /**
   * The value have no lowercase
   * @see {@link https://formkit.com/essentials/validation#contains_lowercase}
   */
  contains_lowercase({ name }) {
    return `Το ${sentence(name)} πρέπει να περιέχει πεζά γράμματα.`;
  },
  /**
   *  The value have no numeric
   * @see {@link https://formkit.com/essentials/validation#contains_numeric}
   */
  contains_numeric({ name }) {
    return `Το ${sentence(name)} πρέπει να περιέχει αριθμούς.`;
  },
  /**
   * The value is not symbol
   * @see {@link https://formkit.com/essentials/validation#symbol}
   */
  symbol({ name }) {
    return `Το ${sentence(name)} πρέπει να είναι ένα σύμβολο.`;
  },
  /**
   * The value is not uppercase
   * @see {@link https://formkit.com/essentials/validation#uppercase}
   */
  uppercase({ name }) {
    return `Το ${sentence(name)} μπορεί να περιέχει μόνο κεφαλαία γράμματα.`;
  },
  /**
   * The value is not lowercase
   * @see {@link https://formkit.com/essentials/validation#lowercase}
   */
  lowercase({ name }) {
    return `Το ${sentence(name)} μπορεί να περιέχει μόνο πεζά γράμματα.`;
  },
  /**
   * The date is not before
   * @see {@link https://formkit.com/essentials/validation#date-before}
   */
  date_before({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${sentence(name)} πρέπει να είναι πριν της ${date(args[0])}.`;
    }
    return `${sentence(name)} πρέπει να είναι στο παρελθόν.`;
  },
  /**
   * The value is not between two numbers
   * @see {@link https://formkit.com/essentials/validation#between}
   */
  between({ name, args }) {
    if (isNaN(args[0]) || isNaN(args[1])) {
      return `Αυτό το πεδίο έχει ρυθμιστεί λανθασμένα και δεν μπορεί να υποβληθεί.`;
    }
    const [a, b] = order(args[0], args[1]);
    return `${sentence(name)} πρέπει να είναι μεταξύ ${a} και ${b}.`;
  },
  /**
   * The confirmation field does not match
   * @see {@link https://formkit.com/essentials/validation#confirm}
   */
  confirm({ name }) {
    return `${sentence(name)} δεν ταιριάζει.`;
  },
  /**
   * The value is not a valid date
   * @see {@link https://formkit.com/essentials/validation#date-format}
   */
  date_format({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${sentence(
        name
      )} δεν είναι έγυρη ημερομηνία, παρακαλώ ακολουθήστε την διαμόρφωση ${args[0]}`;
    }
    return "Αυτό το πεδίο έχει ρυθμιστεί λανθασμένα και δεν μπορεί να υποβληθεί";
  },
  /**
   * Is not within expected date range
   * @see {@link https://formkit.com/essentials/validation#date-between}
   */
  date_between({ name, args }) {
    return `${sentence(name)} πρέπει να είναι μεταξύ ${date(args[0])} και ${date(
      args[1]
    )}`;
  },
  /**
   * Shown when the user-provided value is not a valid email address.
   * @see {@link https://formkit.com/essentials/validation#email}
   */
  email: "Παρακαλώ πληκτρολογήστε μια έγκυρη email διεύθυνση. ",
  /**
   * Does not end with the specified value
   * @see {@link https://formkit.com/essentials/validation#ends-with}
   */
  ends_with({ name, args }) {
    return `${sentence(name)} δεν καταλήγει με ${list(args)}.`;
  },
  /**
   * Is not an allowed value
   * @see {@link https://formkit.com/essentials/validation#is}
   */
  is({ name }) {
    return `${sentence(name)} δεν είναι μια επιτρεπτή τιμή.`;
  },
  /**
   * Does not match specified length
   * @see {@link https://formkit.com/essentials/validation#length}
   */
  length({ name, args: [first = 0, second = Infinity] }) {
    const min = Number(first) <= Number(second) ? first : second;
    const max = Number(second) >= Number(first) ? second : first;
    if (min == 1 && max === Infinity) {
      return `${sentence(name)} πρέπει να είναι τουλάχιστον ενός χαρακτήρα.`;
    }
    if (min == 0 && max) {
      return `${sentence(name)} πρέπει να είναι λιγότεροι ή ίσοι με ${max} χαρακτήρες.`;
    }
    if (min === max) {
      return `Το ${sentence(name)} θα πρέπει να έχει μήκος ${max} χαρακτήρες.`;
    }
    if (min && max === Infinity) {
      return `${sentence(
        name
      )} πρέπει να είναι περισσότεροι ή ίσοι με ${min} χαρακτήρες.`;
    }
    return `${sentence(name)} πρέπει να είναι μεταξύ ${min} και ${max} χαρακτήρες.`;
  },
  /**
   * Value is not a match
   * @see {@link https://formkit.com/essentials/validation#matches}
   */
  matches({ name }) {
    return `${sentence(name)} δεν είναι μια επιτρεπτή τιμή.`;
  },
  /**
   * Exceeds maximum allowed value
   * @see {@link https://formkit.com/essentials/validation#max}
   */
  max({ name, node: { value }, args }) {
    if (Array.isArray(value)) {
      return `Δεν μπορεί να έχει παραπάνω από ${args[0]} ${name}.`;
    }
    return `${sentence(name)} πρέπει αν είναι λιγότερο ή ίσο με το ${args[0]}.`;
  },
  /**
   * The (field-level) value does not match specified mime type
   * @see {@link https://formkit.com/essentials/validation#mime}
   */
  mime({ name, args }) {
    if (!args[0]) {
      return "Δεν επιτρέπονται αρχεία.";
    }
    return `${sentence(name)} πρέπει να είναι τύπου: ${args[0]}`;
  },
  /**
   * Does not fulfill minimum allowed value
   * @see {@link https://formkit.com/essentials/validation#min}
   */
  min({ name, node: { value }, args }) {
    if (Array.isArray(value)) {
      return `Δεν μπορεί να είναι λιγότερο από ${args[0]} ${name}.`;
    }
    return `${sentence(name)} πρέπει να είναι τουλάχιστον ${args[0]}.`;
  },
  /**
   * Is not an allowed value
   * @see {@link https://formkit.com/essentials/validation#not}
   */
  not({ name, node: { value } }) {
    return `“${value}” δεν είναι μια επιτρεπτή ${name}.`;
  },
  /**
   *  Is not a number
   * @see {@link https://formkit.com/essentials/validation#number}
   */
  number({ name }) {
    return `${sentence(name)} πρέπει να είναι αριθμός.`;
  },
  /**
   * Require one field.
   * @see {@link https://formkit.com/essentials/validation#require-one}
   */
  require_one: ({ name, node, args: inputNames }) => {
    const labels = inputNames.map((name2) => {
      const dependentNode = node.at(name2);
      if (dependentNode) {
        return createMessageName(dependentNode);
      }
      return false;
    }).filter((name2) => !!name2);
    labels.unshift(name);
    return `${labels.join(" ή ")} απαιτείται.`;
  },
  /**
   * Required field.
   * @see {@link https://formkit.com/essentials/validation#required}
   */
  required({ name }) {
    return `${sentence(name)} είναι υποχρεωτικό.`;
  },
  /**
   * Does not start with specified value
   * @see {@link https://formkit.com/essentials/validation#starts-with}
   */
  starts_with({ name, args }) {
    return `${sentence(name)} δεν αρχίζει με ${list(args)}.`;
  },
  /**
   * Is not a url
   * @see {@link https://formkit.com/essentials/validation#url}
   */
  url() {
    return `Παρακαλώ εισάγετε ένα έγκυρο URL.`;
  },
  /**
   * Shown when the date is invalid.
   */
  invalidDate: "Η επιλεγμένη ημερομηνία δεν είναι έγκυρη."
};
var el = { ui: ui9, validation: validation9 };
var ui10 = {
  /**
   * Shown on a button for adding additional items.
   */
  add: "Add",
  /**
   * Shown when a button to remove items is visible.
   */
  remove: "Remove",
  /**
   * Shown when there are multiple items to remove at the same time.
   */
  removeAll: "Remove all",
  /**
   * Shown when all fields are not filled out correctly.
   */
  incomplete: "Sorry, not all fields are filled out correctly.",
  /**
   * Shown in a button inside a form to submit the form.
   */
  submit: "Submit",
  /**
   * Shown when no files are selected.
   */
  noFiles: "No file chosen",
  /**
   * Shown on buttons that move fields up in a list.
   */
  moveUp: "Move up",
  /**
   * Shown on buttons that move fields down in a list.
   */
  moveDown: "Move down",
  /**
   * Shown when something is actively loading.
   */
  isLoading: "Loading...",
  /**
   * Shown when there is more to load.
   */
  loadMore: "Load more",
  /**
   * Show on buttons that navigate state forward
   */
  next: "Next",
  /**
   * Show on buttons that navigate state backward
   */
  prev: "Previous",
  /**
   * Shown when adding all values.
   */
  addAllValues: "Add all values",
  /**
   * Shown when adding selected values.
   */
  addSelectedValues: "Add selected values",
  /**
   * Shown when removing all values.
   */
  removeAllValues: "Remove all values",
  /**
   * Shown when removing selected values.
   */
  removeSelectedValues: "Remove selected values",
  /**
   * Shown when there is a date to choose.
   */
  chooseDate: "Choose date",
  /**
   * Shown when there is a date to change.
   */
  changeDate: "Change date",
  /**
   * Shown above error summaries when someone attempts to submit a form with
   * errors and the developer has implemented `<FormKitSummary />`.
   */
  summaryHeader: "There were errors in your form.",
  /*
   * Shown when there is something to close
   */
  close: "Close",
  /**
   * Shown when there is something to open.
   */
  open: "Open"
};
var validation10 = {
  /**
   * The value is not an accepted value.
   * @see {@link https://formkit.com/essentials/validation#accepted}
   */
  accepted({ name }) {
    return `Please accept the ${name}.`;
  },
  /**
   * The date is not after
   * @see {@link https://formkit.com/essentials/validation#date-after}
   */
  date_after({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${sentence(name)} must be after ${date(args[0])}.`;
    }
    return `${sentence(name)} must be in the future.`;
  },
  /**
   * The value is not a letter.
   * @see {@link https://formkit.com/essentials/validation#alpha}
   */
  alpha({ name }) {
    return `${sentence(name)} can only contain alphabetical characters.`;
  },
  /**
   * The value is not alphanumeric
   * @see {@link https://formkit.com/essentials/validation#alphanumeric}
   */
  alphanumeric({ name }) {
    return `${sentence(name)} can only contain letters and numbers.`;
  },
  /**
   * The value is not letter and/or spaces
   * @see {@link https://formkit.com/essentials/validation#alpha-spaces}
   */
  alpha_spaces({ name }) {
    return `${sentence(name)} can only contain letters and spaces.`;
  },
  /**
   * The value have no letter.
   * @see {@link https://formkit.com/essentials/validation#contains_alpha}
   */
  contains_alpha({ name }) {
    return `${sentence(name)} must contain alphabetical characters.`;
  },
  /**
   * The value have no alphanumeric
   * @see {@link https://formkit.com/essentials/validation#contains_alphanumeric}
   */
  contains_alphanumeric({ name }) {
    return `${sentence(name)} must contain letters or numbers.`;
  },
  /**
   * The value have no letter and/or spaces
   * @see {@link https://formkit.com/essentials/validation#contains_alpha-spaces}
   */
  contains_alpha_spaces({ name }) {
    return `${sentence(name)} must contain letters or spaces.`;
  },
  /**
   * The value have no symbol
   * @see {@link https://formkit.com/essentials/validation#contains_symbol}
   */
  contains_symbol({ name }) {
    return `${sentence(name)} must contain a symbol.`;
  },
  /**
   * The value have no uppercase
   * @see {@link https://formkit.com/essentials/validation#contains_uppercase}
   */
  contains_uppercase({ name }) {
    return `${sentence(name)} must contain an uppercase letter.`;
  },
  /**
   * The value have no lowercase
   * @see {@link https://formkit.com/essentials/validation#contains_lowercase}
   */
  contains_lowercase({ name }) {
    return `${sentence(name)} must contain a lowercase letter.`;
  },
  /**
   *  The value have no numeric
   * @see {@link https://formkit.com/essentials/validation#contains_numeric}
   */
  contains_numeric({ name }) {
    return `${sentence(name)} must contain numbers.`;
  },
  /**
   * The value is not symbol
   * @see {@link https://formkit.com/essentials/validation#symbol}
   */
  symbol({ name }) {
    return `${sentence(name)} must be a symbol.`;
  },
  /**
   * The value is not uppercase
   * @see {@link https://formkit.com/essentials/validation#uppercase}
   */
  uppercase({ name }) {
    return `${sentence(name)} can only contain uppercase letters.`;
  },
  /**
   * The value is not lowercase
   * @see {@link https://formkit.com/essentials/validation#lowercase}
   */
  lowercase({ name, args }) {
    let postfix = "";
    if (Array.isArray(args) && args.length) {
      if (args[0] === "allow_non_alpha")
        postfix = ", numbers and symbols";
      if (args[0] === "allow_numeric")
        postfix = " and numbers";
      if (args[0] === "allow_numeric_dashes")
        postfix = ", numbers and dashes";
    }
    return `${sentence(name)} can only contain lowercase letters${postfix}.`;
  },
  /**
   * The date is not before
   * @see {@link https://formkit.com/essentials/validation#date-before}
   */
  date_before({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${sentence(name)} must be before ${date(args[0])}.`;
    }
    return `${sentence(name)} must be in the past.`;
  },
  /**
   * The value is not between two numbers
   * @see {@link https://formkit.com/essentials/validation#between}
   */
  between({ name, args }) {
    if (isNaN(args[0]) || isNaN(args[1])) {
      return `This field was configured incorrectly and can’t be submitted.`;
    }
    const [a, b] = order(args[0], args[1]);
    return `${sentence(name)} must be between ${a} and ${b}.`;
  },
  /**
   * The confirmation field does not match
   * @see {@link https://formkit.com/essentials/validation#confirm}
   */
  confirm({ name }) {
    return `${sentence(name)} does not match.`;
  },
  /**
   * The value is not a valid date
   * @see {@link https://formkit.com/essentials/validation#date-format}
   */
  date_format({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${sentence(name)} is not a valid date, please use the format ${args[0]}`;
    }
    return "This field was configured incorrectly and can’t be submitted";
  },
  /**
   * Is not within expected date range
   * @see {@link https://formkit.com/essentials/validation#date-between}
   */
  date_between({ name, args }) {
    return `${sentence(name)} must be between ${date(args[0])} and ${date(args[1])}`;
  },
  /**
   * Shown when the user-provided value is not a valid email address.
   * @see {@link https://formkit.com/essentials/validation#email}
   */
  email: "Please enter a valid email address.",
  /**
   * Does not end with the specified value
   * @see {@link https://formkit.com/essentials/validation#ends-with}
   */
  ends_with({ name, args }) {
    return `${sentence(name)} doesn’t end with ${list(args)}.`;
  },
  /**
   * Is not an allowed value
   * @see {@link https://formkit.com/essentials/validation#is}
   */
  is({ name }) {
    return `${sentence(name)} is not an allowed value.`;
  },
  /**
   * Does not match specified length
   * @see {@link https://formkit.com/essentials/validation#length}
   */
  length({ name, args: [first = 0, second = Infinity] }) {
    const min = Number(first) <= Number(second) ? first : second;
    const max = Number(second) >= Number(first) ? second : first;
    if (min == 1 && max === Infinity) {
      return `${sentence(name)} must be at least one character.`;
    }
    if (min == 0 && max) {
      return `${sentence(name)} must be less than or equal to ${max} characters.`;
    }
    if (min === max) {
      return `${sentence(name)} should be ${max} characters long.`;
    }
    if (min && max === Infinity) {
      return `${sentence(name)} must be greater than or equal to ${min} characters.`;
    }
    return `${sentence(name)} must be between ${min} and ${max} characters.`;
  },
  /**
   * Value is not a match
   * @see {@link https://formkit.com/essentials/validation#matches}
   */
  matches({ name }) {
    return `${sentence(name)} is not an allowed value.`;
  },
  /**
   * Exceeds maximum allowed value
   * @see {@link https://formkit.com/essentials/validation#max}
   */
  max({ name, node: { value }, args }) {
    if (Array.isArray(value)) {
      return `Cannot have more than ${args[0]} ${name}.`;
    }
    return `${sentence(name)} must be no more than ${args[0]}.`;
  },
  /**
   * The (field-level) value does not match specified mime type
   * @see {@link https://formkit.com/essentials/validation#mime}
   */
  mime({ name, args }) {
    if (!args[0]) {
      return "No file formats allowed.";
    }
    return `${sentence(name)} must be of the type: ${args[0]}`;
  },
  /**
   * Does not fulfill minimum allowed value
   * @see {@link https://formkit.com/essentials/validation#min}
   */
  min({ name, node: { value }, args }) {
    if (Array.isArray(value)) {
      return `Cannot have fewer than ${args[0]} ${name}.`;
    }
    return `${sentence(name)} must be at least ${args[0]}.`;
  },
  /**
   * Is not an allowed value
   * @see {@link https://formkit.com/essentials/validation#not}
   */
  not({ name, node: { value } }) {
    return `“${value}” is not an allowed ${name}.`;
  },
  /**
   *  Is not a number
   * @see {@link https://formkit.com/essentials/validation#number}
   */
  number({ name }) {
    return `${sentence(name)} must be a number.`;
  },
  /**
   * Require one field.
   * @see {@link https://formkit.com/essentials/validation#require-one}
   */
  require_one: ({ name, node, args: inputNames }) => {
    const labels = inputNames.map((name2) => {
      const dependentNode = node.at(name2);
      if (dependentNode) {
        return createMessageName(dependentNode);
      }
      return false;
    }).filter((name2) => !!name2);
    labels.unshift(name);
    return `${labels.join(" or ")} is required.`;
  },
  /**
   * Required field.
   * @see {@link https://formkit.com/essentials/validation#required}
   */
  required({ name }) {
    return `${sentence(name)} is required.`;
  },
  /**
   * Does not start with specified value
   * @see {@link https://formkit.com/essentials/validation#starts-with}
   */
  starts_with({ name, args }) {
    return `${sentence(name)} doesn’t start with ${list(args)}.`;
  },
  /**
   * Is not a url
   * @see {@link https://formkit.com/essentials/validation#url}
   */
  url() {
    return `Please enter a valid URL.`;
  },
  /**
   * Shown when the date is invalid.
   */
  invalidDate: "The selected date is invalid."
};
var en = { ui: ui10, validation: validation10 };
var ui11 = {
  /**
   * Shown on buttons for adding new items.
   */
  add: "Añadir",
  /**
   * Shown when a button to remove items is visible.
   */
  remove: "Quitar",
  /**
   * Shown when there are multiple items to remove at the same time.
   */
  removeAll: "Quitar todos",
  /**
   * Shown when all fields are not filled out correctly.
   */
  incomplete: "Discúlpe, los campos no fueron completados correctamente.",
  /**
   * Shown in a button inside a form to submit the form.
   */
  submit: "Enviar",
  /**
   * Shown when no files are selected.
   */
  noFiles: "Archivo no seleccionado",
  /**
   * Shown on buttons that move fields up in a list.
   */
  moveUp: "Moverse hacia arriba",
  /**
   * Shown on buttons that move fields down in a list.
   */
  moveDown: "Moverse hacia abajo",
  /**
   * Shown when something is actively loading.
   */
  isLoading: "Cargando...",
  /**
   * Shown when there is more to load.
   */
  loadMore: "Cargar más",
  /**
   * Shown on buttons that navigate state forward
   */
  next: "Próximo",
  /**
   * Shown on buttons that navigate state backward
   */
  prev: "Anterior",
  /**
   * Shown when adding all values.
   */
  addAllValues: "Añadir todos los valores",
  /**
   * Shown when adding selected values.
   */
  addSelectedValues: "Añadir valores seleccionados",
  /**
   * Shown when removing all values.
   */
  removeAllValues: "Eliminar todos los valores",
  /**
   * Shown when removing selected values.
   */
  removeSelectedValues: "Eliminar los valores seleccionados",
  /**
   * Shown when there is a date to choose.
   */
  chooseDate: "Elige fecha",
  /**
   * Shown when there is a date to change.
   */
  changeDate: "Cambiar fecha",
  /**
   * Shown when there is something to close
   */
  close: "Cerrar",
  /**
   * Shown when there is something to open.
   */
  open: "Abrir"
};
var validation11 = {
  /**
   * The value is not an accepted value.
   * @see {@link https://formkit.com/essentials/validation#accepted}
   */
  accepted({ name }) {
    return `Acepte el ${name} por favor.`;
  },
  /**
   * The date is not after
   * @see {@link https://formkit.com/essentials/validation#date-after}
   */
  date_after({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${sentence(name)} debe ser posterior a ${date(args[0])}.`;
    }
    return `${sentence(name)} debe ser una fecha futura.`;
  },
  /**
   * The value is not a letter.
   * @see {@link https://formkit.com/essentials/validation#alpha}
   */
  alpha({ name }) {
    return `${sentence(name)} debe contener solo caractéres alfabéticos.`;
  },
  /**
   * The value is not alphanumeric
   * @see {@link https://formkit.com/essentials/validation#alphanumeric}
   */
  alphanumeric({ name }) {
    return `${sentence(name)} debe ser alfanumérico.`;
  },
  /**
   * The value is not letter and/or spaces
   * @see {@link https://formkit.com/essentials/validation#alpha-spaces}
   */
  alpha_spaces({ name }) {
    return `${sentence(name)} espacios alfa solo pueden contener letras y espacios.`;
  },
  /**
   * The value have no letter.
   * @see {@link https://formkit.com/essentials/validation#contains_alpha}
   */
  contains_alpha({ name }) {
    return `${sentence(name)} debe contener caracteres alfabéticos.`;
  },
  /**
   * The value have no alphanumeric
   * @see {@link https://formkit.com/essentials/validation#contains_alphanumeric}
   */
  contains_alphanumeric({ name }) {
    return `${sentence(name)} debe contener letras o números.`;
  },
  /**
   * The value have no letter and/or spaces
   * @see {@link https://formkit.com/essentials/validation#contains_alpha-spaces}
   */
  contains_alpha_spaces({ name }) {
    return `${sentence(name)} debe contener letras o espacios.`;
  },
  /**
   * The value have no symbol
   * @see {@link https://formkit.com/essentials/validation#contains_symbol}
   */
  contains_symbol({ name }) {
    return `${sentence(name)} debe contener un símbolo.`;
  },
  /**
   * The value have no uppercase
   * @see {@link https://formkit.com/essentials/validation#contains_uppercase}
   */
  contains_uppercase({ name }) {
    return `${sentence(name)} debe estar en mayúsculas.`;
  },
  /**
   * The value have no lowercase
   * @see {@link https://formkit.com/essentials/validation#contains_lowercase}
   */
  contains_lowercase({ name }) {
    return `${sentence(name)} debe contener minúsculas.`;
  },
  /**
   *  The value have no numeric
   * @see {@link https://formkit.com/essentials/validation#contains_numeric}
   */
  contains_numeric({ name }) {
    return `${sentence(name)} debe contener números.`;
  },
  /**
   * The value is not symbol
   * @see {@link https://formkit.com/essentials/validation#symbol}
   */
  symbol({ name }) {
    return `${sentence(name)} debe ser un símbolo.`;
  },
  /**
   * The value is not uppercase
   * @see {@link https://formkit.com/essentials/validation#uppercase}
   */
  uppercase({ name }) {
    return `${sentence(name)} solo puede contener letras mayúsculas.`;
  },
  /**
   * The value is not lowercase
   * @see {@link https://formkit.com/essentials/validation#lowercase}
   */
  lowercase({ name }) {
    return `${sentence(name)} solo puede contener letras minúsculas.`;
  },
  /**
   * The date is not before
   * @see {@link https://formkit.com/essentials/validation#date-before}
   */
  date_before({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${sentence(name)} debe ser anterior a ${date(args[0])}.`;
    }
    return `${sentence(name)} debe ser una fecha pasada.`;
  },
  /**
   * The value is not between two numbers
   * @see {@link https://formkit.com/essentials/validation#between}
   */
  between({ name, args }) {
    if (isNaN(args[0]) || isNaN(args[1])) {
      return `El campo no fue completado correctamente y no puede ser enviado.`;
    }
    const [a, b] = order(args[0], args[1]);
    return `${sentence(name)} debe estar entre ${a} y ${b}.`;
  },
  /**
   * The confirmation field does not match
   * @see {@link https://formkit.com/essentials/validation#confirm}
   */
  confirm({ name }) {
    return `${sentence(name)} no coincide.`;
  },
  /**
   * The value is not a valid date
   * @see {@link https://formkit.com/essentials/validation#date-format}
   */
  date_format({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${sentence(name)} no es una fecha válida, por favor utilice el formato ${args[0]}`;
    }
    return "El campo no fue completado correctamente y no puede ser enviado.";
  },
  /**
   * Is not within expected date range
   * @see {@link https://formkit.com/essentials/validation#date-between}
   */
  date_between({ name, args }) {
    return `${sentence(name)} debe estar entre ${date(args[0])} y ${date(args[1])}`;
  },
  /**
   * Shown when the user-provided value is not a valid email address.
   * @see {@link https://formkit.com/essentials/validation#email}
   */
  email: "Ingrese una dirección de correo electrónico válida por favor.",
  /**
   * Does not end with the specified value
   * @see {@link https://formkit.com/essentials/validation#ends-with}
   */
  ends_with({ name, args }) {
    return `${sentence(name)} no termina con ${list(args)}.`;
  },
  /**
   * Is not an allowed value
   * @see {@link https://formkit.com/essentials/validation#is}
   */
  is({ name }) {
    return `${sentence(name)} no es un valor permitido.`;
  },
  /**
   * Does not match specified length
   * @see {@link https://formkit.com/essentials/validation#length}
   */
  length({ name, args: [first = 0, second = Infinity] }) {
    const min = Number(first) <= Number(second) ? first : second;
    const max = Number(second) >= Number(first) ? second : first;
    if (min == 1 && max === Infinity) {
      return `${sentence(name)} debe tener al menos una letra.`;
    }
    if (min == 0 && max) {
      return `${sentence(name)} debe tener como máximo ${max} caractéres.`;
    }
    if (min === max) {
      return `${sentence(name)} debe tener ${max} caracteres.`;
    }
    if (min && max === Infinity) {
      return `${sentence(name)} debe tener como mínimo ${min} caractéres.`;
    }
    return `${sentence(name)} debe tener entre ${min} y ${max} caractéres.`;
  },
  /**
   * Value is not a match
   * @see {@link https://formkit.com/essentials/validation#matches}
   */
  matches({ name }) {
    return `${sentence(name)} no es un valor permitido.`;
  },
  /**
   * Exceeds maximum allowed value
   * @see {@link https://formkit.com/essentials/validation#max}
   */
  max({ name, node: { value }, args }) {
    if (Array.isArray(value)) {
      return `No puede tener más de ${args[0]} ${name}.`;
    }
    return `${sentence(name)} debe ser menor o igual a ${args[0]}.`;
  },
  /**
   * The (field-level) value does not match specified mime type
   * @see {@link https://formkit.com/essentials/validation#mime}
   */
  mime({ name, args }) {
    if (!args[0]) {
      return "No existen formatos de archivos permitidos.";
    }
    return `${sentence(name)} debe ser del tipo: ${args[0]}`;
  },
  /**
   * Does not fulfill minimum allowed value
   * @see {@link https://formkit.com/essentials/validation#min}
   */
  min({ name, node: { value }, args }) {
    if (Array.isArray(value)) {
      return `No puede tener menos de ${args[0]} ${name}.`;
    }
    return `${sentence(name)} debe ser de al menos ${args[0]}.`;
  },
  /**
   * Is not an allowed value
   * @see {@link https://formkit.com/essentials/validation#not}
   */
  not({ name, node: { value } }) {
    return `“${value}” no es un valor permitido de ${name}.`;
  },
  /**
   *  Is not a number
   * @see {@link https://formkit.com/essentials/validation#number}
   */
  number({ name }) {
    return `${sentence(name)} debe ser un número.`;
  },
  /**
   * Require one field.
   * @see {@link https://formkit.com/essentials/validation#require-one}
   */
  require_one: ({ name, node, args: inputNames }) => {
    const labels = inputNames.map((name2) => {
      const dependentNode = node.at(name2);
      if (dependentNode) {
        return createMessageName(dependentNode);
      }
      return false;
    }).filter((name2) => !!name2);
    labels.unshift(name);
    return `${labels.join(" o ")} se requiere estar.`;
  },
  /**
   * Required field.
   * @see {@link https://formkit.com/essentials/validation#required}
   */
  required({ name }) {
    return `${sentence(name)} es requerido.`;
  },
  /**
   * Does not start with specified value
   * @see {@link https://formkit.com/essentials/validation#starts-with}
   */
  starts_with({ name, args }) {
    return `${sentence(name)} debe comenzar con ${list(args)}.`;
  },
  /**
   * Is not a url
   * @see {@link https://formkit.com/essentials/validation#url}
   */
  url() {
    return `Introduce una URL válida.`;
  },
  /**
   * Shown when the date is invalid.
   */
  invalidDate: "La fecha seleccionada no es válida."
};
var es = { ui: ui11, validation: validation11 };
var ui12 = {
  /**
   * Shown on buttons for adding new items.
   */
  add: "افزودن",
  /**
   * Shown when a button to remove items is visible.
   */
  remove: "حذف",
  /**
   * Shown when there are multiple items to remove at the same time.
   */
  removeAll: "همه را حذف کنید",
  /**
   * Shown when all fields are not filled out correctly.
   */
  incomplete: "همه فیلدها به‌درستی پر نشده‌اند",
  /**
   * Shown in a button inside a form to submit the form.
   */
  submit: "ثبت",
  /**
   * Shown when no files are selected.
   */
  noFiles: "هیچ فایلی انتخاب نشده است",
  /**
   * Shown on buttons that move fields up in a list.
   */
  moveUp: "حرکت به بالا",
  /**
   * Shown on buttons that move fields down in a list.
   */
  moveDown: "حرکت به پایین",
  /**
   * Shown when something is actively loading.
   */
  isLoading: "در حال بارگذاری...",
  /**
   * Shown when there is more to load.
   */
  loadMore: "بارگذاری بیشتر",
  /**
   * Shown on buttons that navigate state forward
   */
  next: "بعدی",
  /**
   * Shown on buttons that navigate state backward
   */
  prev: "قبلی",
  /**
   * Shown when adding all values.
   */
  addAllValues: "تمام مقادیر را اضافه کنید",
  /**
   * Shown when adding selected values.
   */
  addSelectedValues: "مقادیر انتخاب شده را اضافه کنید",
  /**
   * Shown when removing all values.
   */
  removeAllValues: "تمام مقادیر را حذف کنید",
  /**
   * Shown when removing selected values.
   */
  removeSelectedValues: "حذف مقادیر انتخاب شده",
  /**
   * Shown when there is a date to choose.
   */
  chooseDate: "تاریخ را انتخاب کنید",
  /**
   * Shown when there is a date to change.
   */
  changeDate: "تغییر تاریخ",
  /**
   * Shown when there is something to close
   */
  close: "بستن",
  /**
   * Shown when there is something to open.
   */
  open: "باز کردن"
};
var validation12 = {
  /**
   * The value is not an accepted value.
   * @see {@link https://formkit.com/essentials/validation#accepted}
   */
  accepted({ name }) {
    return `لطفاً ${name} را بپذیرید.`;
  },
  /**
   * The date is not after
   * @see {@link https://formkit.com/essentials/validation#date-after}
   */
  date_after({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${sentence(name)} باید بعد از تاریخ ${date(args[0])} باشد.`;
    }
    return `${sentence(name)} باید مربوط به آینده باشد.`;
  },
  /**
   * The value is not a letter.
   * @see {@link https://formkit.com/essentials/validation#alpha}
   */
  alpha({ name }) {
    return `${sentence(name)} فقط میتواند شامل حروف الفبا باشد.`;
  },
  /**
   * The value is not alphanumeric
   * @see {@link https://formkit.com/essentials/validation#alphanumeric}
   */
  alphanumeric({ name }) {
    return `${sentence(name)} فقط میتواند شامل حروف و اعداد باشد.`;
  },
  /**
   * The value is not letter and/or spaces
   * @see {@link https://formkit.com/essentials/validation#alpha-spaces}
   */
  alpha_spaces({ name }) {
    return `${sentence(name)} فقط می تواند شامل حروف و فاصله باشد.`;
  },
  /**
   * The value have no letter.
   * @see {@link https://formkit.com/essentials/validation#contains_alpha}
   */
  contains_alpha({ name }) {
    return `${sentence(name)} باید حاوی حروف الفبا باشد.`;
  },
  /**
   * The value have no alphanumeric
   * @see {@link https://formkit.com/essentials/validation#contains_alphanumeric}
   */
  contains_alphanumeric({ name }) {
    return `${sentence(name)} باید حاوی حروف یا اعداد باشد.`;
  },
  /**
   * The value have no letter and/or spaces
   * @see {@link https://formkit.com/essentials/validation#contains_alpha-spaces}
   */
  contains_alpha_spaces({ name }) {
    return `${sentence(name)} باید حاوی حروف یا فاصله باشد.`;
  },
  /**
   * The value have no symbol
   * @see {@link https://formkit.com/essentials/validation#contains_symbol}
   */
  contains_symbol({ name }) {
    return `${sentence(name)} باید حاوی نماد باشد.`;
  },
  /**
   * The value have no uppercase
   * @see {@link https://formkit.com/essentials/validation#contains_uppercase}
   */
  contains_uppercase({ name }) {
    return `${sentence(name)} باید دارای حروف بزرگ باشد.`;
  },
  /**
   * The value have no lowercase
   * @see {@link https://formkit.com/essentials/validation#contains_lowercase}
   */
  contains_lowercase({ name }) {
    return `${sentence(name)} باید حاوی حروف کوچک باشد.`;
  },
  /**
   *  The value have no numeric
   * @see {@link https://formkit.com/essentials/validation#contains_numeric}
   */
  contains_numeric({ name }) {
    return `${sentence(name)} باید حاوی اعداد باشد.`;
  },
  /**
   * The value is not symbol
   * @see {@link https://formkit.com/essentials/validation#symbol}
   */
  symbol({ name }) {
    return `${sentence(name)} باید یک نماد باشد.`;
  },
  /**
   * The value is not uppercase
   * @see {@link https://formkit.com/essentials/validation#uppercase}
   */
  uppercase({ name }) {
    return `${sentence(name)} تنها می‌تواند شامل حروف بزرگ باشد.`;
  },
  /**
   * The value is not lowercase
   * @see {@link https://formkit.com/essentials/validation#lowercase}
   */
  lowercase({ name }) {
    return `${sentence(name)} تنها می‌تواند شامل حروف کوچک باشد.`;
  },
  /**
   * The date is not before
   * @see {@link https://formkit.com/essentials/validation#date-before}
   */
  date_before({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${sentence(name)} باید قبل از تاریخ ${date(args[0])} باشد.`;
    }
    return `${sentence(name)} باید مربوط به گذشته باشد.`;
  },
  /**
   * The value is not between two numbers
   * @see {@link https://formkit.com/essentials/validation#between}
   */
  between({ name, args }) {
    if (isNaN(args[0]) || isNaN(args[1])) {
      return `این فیلد به اشتباه پیکربندی شده است و قابل ارسال نیست`;
    }
    return `${sentence(name)} باید بین ${args[0]} و ${args[1]} باشد.`;
  },
  /**
   * The confirmation field does not match
   * @see {@link https://formkit.com/essentials/validation#confirm}
   */
  confirm({ name }) {
    return `${sentence(name)} مطابقت ندارد.`;
  },
  /**
   * The value is not a valid date
   * @see {@link https://formkit.com/essentials/validation#date-format}
   */
  date_format({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${sentence(name)} تاریخ معتبری نیست، لطفاً از قالب ${args[0]} استفاده کنید
`;
    }
    return "این فیلد به اشتباه پیکربندی شده است و قابل ارسال نیست";
  },
  /**
   * Is not within expected date range
   * @see {@link https://formkit.com/essentials/validation#date-between}
   */
  date_between({ name, args }) {
    return `${sentence(name)} باید بین ${date(args[0])} و ${date(args[1])} باشد.`;
  },
  /**
   * Shown when the user-provided value is not a valid email address.
   * @see {@link https://formkit.com/essentials/validation#email}
   */
  email: "لطفا آدرس ایمیل معتبر وارد کنید.",
  /**
   * Does not end with the specified value
   * @see {@link https://formkit.com/essentials/validation#ends-with}
   */
  ends_with({ name, args }) {
    return `${sentence(name)} باید به ${list(args)} ختم شود.`;
  },
  /**
   * Is not an allowed value
   * @see {@link https://formkit.com/essentials/validation#is}
   */
  is({ name }) {
    return `${sentence(name)} مجاز نیست.`;
  },
  /**
   * Does not match specified length
   * @see {@link https://formkit.com/essentials/validation#length}
   */
  length({ name, args: [first = 0, second = Infinity] }) {
    const min = first <= second ? first : second;
    const max = second >= first ? second : first;
    if (min == 1 && max === Infinity) {
      return `${sentence(name)} باید حداقل یک کاراکتر باشد.`;
    }
    if (min == 0 && max) {
      return `${sentence(name)} باید کمتر یا برابر با ${max} کاراکتر باشد.`;
    }
    if (min === max) {
      return `${sentence(name)} باید ${max} کاراکتر طولانی باشد.`;
    }
    if (min && max === Infinity) {
      return `${sentence(name)} باید بزرگتر یا برابر با ${min} کاراکتر باشد.`;
    }
    return `${sentence(name)} باید بین ${min} و ${max} کاراکتر باشد.`;
  },
  /**
   * Value is not a match
   * @see {@link https://formkit.com/essentials/validation#matches}
   */
  matches({ name }) {
    return `${sentence(name)} مجاز نیست.`;
  },
  /**
   * Exceeds maximum allowed value
   * @see {@link https://formkit.com/essentials/validation#max}
   */
  max({ name, node: { value }, args }) {
    if (Array.isArray(value)) {
      return `${name} نمی تواند بیش از ${args[0]} باشد.`;
    }
    return `${sentence(name)} باید کمتر یا برابر با ${args[0]} باشد.`;
  },
  /**
   * The (field-level) value does not match specified mime type
   * @see {@link https://formkit.com/essentials/validation#mime}
   */
  mime({ name, args }) {
    if (!args[0]) {
      return "فرمت فایل مجاز نیست.";
    }
    return `${sentence(name)} باید از این نوع باشد: ${args[0]}`;
  },
  /**
   * Does not fulfill minimum allowed value
   * @see {@link https://formkit.com/essentials/validation#min}
   */
  min({ name, node: { value }, args }) {
    if (Array.isArray(value)) {
      return `${name} نمی تواند کمتر از ${args[0]} باشد.
`;
    }
    return `${sentence(name)} باید حداقل ${args[0]} باشد.`;
  },
  /**
   * Is not an allowed value
   * @see {@link https://formkit.com/essentials/validation#not}
   */
  not({ name, node: { value } }) {
    return `"${value}" یک ${name} مجاز نیست.`;
  },
  /**
   *  Is not a number
   * @see {@link https://formkit.com/essentials/validation#number}
   */
  number({ name }) {
    return `${sentence(name)} باید عدد باشد.`;
  },
  /**
   * Require one field.
   * @see {@link https://formkit.com/essentials/validation#require-one}
   */
  require_one: ({ name, node, args: inputNames }) => {
    const labels = inputNames.map((name2) => {
      const dependentNode = node.at(name2);
      if (dependentNode) {
        return createMessageName(dependentNode);
      }
      return false;
    }).filter((name2) => !!name2);
    labels.unshift(name);
    return `${labels.join(" یا ")} مورد نیاز است.`;
  },
  /**
   * Required field.
   * @see {@link https://formkit.com/essentials/validation#required}
   */
  required({ name }) {
    return `پر کردن ${sentence(name)} اجباری است.`;
  },
  /**
   * Does not start with specified value
   * @see {@link https://formkit.com/essentials/validation#starts-with}
   */
  starts_with({ name, args }) {
    return `${sentence(name)} باید با ${list(args)} شروع شود.`;
  },
  /**
   * Is not a url
   * @see {@link https://formkit.com/essentials/validation#url}
   */
  url() {
    return `لطفا یک URL معتبر وارد کنید.`;
  },
  /**
   * Shown when the date is invalid.
   */
  invalidDate: "تاریخ انتخاب شده نامعتبر است"
};
var fa = { ui: ui12, validation: validation12 };
var ui13 = {
  /**
   * Shown on buttons for adding new items.
   */
  add: "Lisää",
  /**
   * Shown when a button to remove items is visible.
   */
  remove: "Poista",
  /**
   * Shown when there are multiple items to remove at the same time.
   */
  removeAll: "Poista kaikki",
  /**
   * Shown when all fields are not filled out correctly.
   */
  incomplete: "Kaikkia kenttiä ei ole täytetty oikein.",
  /**
   * Shown in a button inside a form to submit the form.
   */
  submit: "Tallenna",
  /**
   * Shown when no files are selected.
   */
  noFiles: "Ei valittuja tiedostoja",
  /**
   * Shown on buttons that move fields up in a list.
   */
  moveUp: "Siirrä ylös",
  /**
   * Shown on buttons that move fields down in a list.
   */
  moveDown: "Siirrä alas",
  /**
   * Shown when something is actively loading.
   */
  isLoading: "Ladataan...",
  /**
   * Shown when there is more to load.
   */
  loadMore: "Lataa lisää",
  /**
   * Shown on buttons that navigate state forward
   */
  next: "Seuraava",
  /**
   * Shown on buttons that navigate state backward
   */
  prev: "Edellinen",
  /**
   * Shown when adding all values.
   */
  addAllValues: "Lisää kaikki arvot",
  /**
   * Shown when adding selected values.
   */
  addSelectedValues: "Lisää valitut arvot",
  /**
   * Shown when removing all values.
   */
  removeAllValues: "Poista kaikki arvot",
  /**
   * Shown when removing selected values.
   */
  removeSelectedValues: "Poista valitut arvot",
  /**
   * Shown when there is a date to choose.
   */
  chooseDate: "Valitse päivämäärä",
  /**
   * Shown when there is a date to change.
   */
  changeDate: "Vaihda päivämäärä",
  /**
   * Shown when there is something to close
   */
  close: "Sulje",
  /**
   * Shown when there is something to open.
   */
  open: "Avoinna"
};
var validation13 = {
  /**
   * The value is not an accepted value.
   * @see {@link https://formkit.com/essentials/validation#accepted}
   */
  accepted({ name }) {
    return `Ole hyvä ja hyväksy ${name}`;
  },
  /**
   * The date is not after
   * @see {@link https://formkit.com/essentials/validation#date-after}
   */
  date_after({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${sentence(name)} tulee olla ${date(args[0])} jälkeen.`;
    }
    return `${sentence(name)} on oltava tulevaisuudessa.`;
  },
  /**
   * The value is not a letter.
   * @see {@link https://formkit.com/essentials/validation#alpha}
   */
  alpha({ name }) {
    return `${sentence(name)} saa sisältää vain kirjaimia.`;
  },
  /**
   * The value is not alphanumeric
   * @see {@link https://formkit.com/essentials/validation#alphanumeric}
   */
  alphanumeric({ name }) {
    return `${sentence(name)} saa sisältää vain kirjaimia ja numeroita.`;
  },
  /**
   * The value is not letter and/or spaces
   * @see {@link https://formkit.com/essentials/validation#alpha-spaces}
   */
  alpha_spaces({ name }) {
    return `${sentence(name)} voivat sisältää vain kirjaimia ja välilyöntejä.`;
  },
  /**
   * The value have no letter.
   * @see {@link https://formkit.com/essentials/validation#contains_alpha}
   */
  contains_alpha({ name }) {
    return `${sentence(name)} on sisällettävä aakkoselliset merkit.`;
  },
  /**
   * The value have no alphanumeric
   * @see {@link https://formkit.com/essentials/validation#contains_alphanumeric}
   */
  contains_alphanumeric({ name }) {
    return `${sentence(name)} täytyy sisältää kirjaimia tai numeroita.`;
  },
  /**
   * The value have no letter and/or spaces
   * @see {@link https://formkit.com/essentials/validation#contains_alpha-spaces}
   */
  contains_alpha_spaces({ name }) {
    return `${sentence(name)} täytyy sisältää kirjaimia tai välilyöntejä.`;
  },
  /**
   * The value have no symbol
   * @see {@link https://formkit.com/essentials/validation#contains_symbol}
   */
  contains_symbol({ name }) {
    return `${sentence(name)} täytyy sisältää symboli.`;
  },
  /**
   * The value have no uppercase
   * @see {@link https://formkit.com/essentials/validation#contains_uppercase}
   */
  contains_uppercase({ name }) {
    return `${sentence(name)} täytyy sisältää isoja kirjaimia.`;
  },
  /**
   * The value have no lowercase
   * @see {@link https://formkit.com/essentials/validation#contains_lowercase}
   */
  contains_lowercase({ name }) {
    return `${sentence(name)} täytyy sisältää pieniä kirjaimia.`;
  },
  /**
   *  The value have no numeric
   * @see {@link https://formkit.com/essentials/validation#contains_numeric}
   */
  contains_numeric({ name }) {
    return `${sentence(name)} täytyy sisältää numeroita.`;
  },
  /**
   * The value is not symbol
   * @see {@link https://formkit.com/essentials/validation#symbol}
   */
  symbol({ name }) {
    return `${sentence(name)} on oltava symboli.`;
  },
  /**
   * The value is not uppercase
   * @see {@link https://formkit.com/essentials/validation#uppercase}
   */
  uppercase({ name }) {
    return `${sentence(name)} voi sisältää vain isoja kirjaimia.`;
  },
  /**
   * The value is not lowercase
   * @see {@link https://formkit.com/essentials/validation#lowercase}
   */
  lowercase({ name }) {
    return `${sentence(name)} voi sisältää vain pieniä kirjaimia.`;
  },
  /**
   * The date is not before
   * @see {@link https://formkit.com/essentials/validation#date-before}
   */
  date_before({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${sentence(name)} tulee olla ennen: ${date(args[0])}.`;
    }
    return `${sentence(name)} on oltava menneisyydessä.`;
  },
  /**
   * The value is not between two numbers
   * @see {@link https://formkit.com/essentials/validation#between}
   */
  between({ name, args }) {
    if (isNaN(args[0]) || isNaN(args[1])) {
      return `Tämä kenttä on täytetty virheellisesti joten sitä ei voitu lähettää.`;
    }
    const [a, b] = order(args[0], args[1]);
    return `${sentence(name)} on oltava välillä ${a} - ${b} `;
  },
  /**
   * The confirmation field does not match
   * @see {@link https://formkit.com/essentials/validation#confirm}
   */
  confirm({ name }) {
    return `${sentence(name)} ei täsmää.`;
  },
  /**
   * The value is not a valid date
   * @see {@link https://formkit.com/essentials/validation#date-format}
   */
  date_format({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${sentence(
        name
      )} ei ole validi päivämäärä, ole hyvä ja syötä muodossa: ${args[0]}`;
    }
    return "Tämä kenttä on täytetty virheellisesti joten sitä ei voitu lähettää.";
  },
  /**
   * Is not within expected date range
   * @see {@link https://formkit.com/essentials/validation#date-between}
   */
  date_between({ name, args }) {
    return `${sentence(name)} on oltava välillä ${date(args[0])} - ${date(args[1])}`;
  },
  /**
   * Shown when the user-provided value is not a valid email address.
   * @see {@link https://formkit.com/essentials/validation#email}
   */
  email: "Syötä validi sähköpostiosoite.",
  /**
   * Does not end with the specified value
   * @see {@link https://formkit.com/essentials/validation#ends-with}
   */
  ends_with({ name, args }) {
    return `${sentence(name)} tulee päättyä ${list(args)}.`;
  },
  /**
   * Is not an allowed value
   * @see {@link https://formkit.com/essentials/validation#is}
   */
  is({ name }) {
    return `${sentence(name)} ei ole sallittu vaihtoehto.`;
  },
  /**
   * Does not match specified length
   * @see {@link https://formkit.com/essentials/validation#length}
   */
  length({ name, args: [first = 0, second = Infinity] }) {
    const min = Number(first) <= Number(second) ? first : second;
    const max = Number(second) >= Number(first) ? second : first;
    if (min == 1 && max === Infinity) {
      return `${sentence(name)} on oltava vähintään yksi merkki.`;
    }
    if (min == 0 && max) {
      return `${sentence(name)} on oltava ${max} tai alle merkkiä.`;
    }
    if (min === max) {
      return `${sentence(name)} pitäisi olla ${max} merkkiä pitkä.`;
    }
    if (min && max === Infinity) {
      return `${sentence(name)} on oltava vähintään ${min} merkkiä.`;
    }
    return `${sentence(name)} on oltava vähintään ${min}, enintään ${max} merkkiä.`;
  },
  /**
   * Value is not a match
   * @see {@link https://formkit.com/essentials/validation#matches}
   */
  matches({ name }) {
    return `${sentence(name)} ei ole sallittu arvo.`;
  },
  /**
   * Exceeds maximum allowed value
   * @see {@link https://formkit.com/essentials/validation#max}
   */
  max({ name, node: { value }, args }) {
    if (Array.isArray(value)) {
      return `Valitse enintään ${args[0]} ${name} vaihtoehtoa.`;
    }
    return `${sentence(name)} on oltava ${args[0]} tai alle.`;
  },
  /**
   * The (field-level) value does not match specified mime type
   * @see {@link https://formkit.com/essentials/validation#mime}
   */
  mime({ name, args }) {
    if (!args[0]) {
      return "Tiedostoja ei sallita.";
    }
    return `${sentence(name)} tulee olla ${args[0]}-tiedostotyyppiä.`;
  },
  /**
   * Does not fulfill minimum allowed value
   * @see {@link https://formkit.com/essentials/validation#min}
   */
  min({ name, node: { value }, args }) {
    if (Array.isArray(value)) {
      return `Valitse vähintään ${args[0]} ${name} vaihtoehtoa.`;
    }
    return `${sentence(name)} tulee olla ${args[0]} tai suurempi.`;
  },
  /**
   * Is not an allowed value
   * @see {@link https://formkit.com/essentials/validation#not}
   */
  not({ name, node: { value } }) {
    return `“${value}” ei ole sallittu ${name}.`;
  },
  /**
   *  Is not a number
   * @see {@link https://formkit.com/essentials/validation#number}
   */
  number({ name }) {
    return `Kentän ${sentence(name)} tulee olla numero.`;
  },
  /**
   * Require one field.
   * @see {@link https://formkit.com/essentials/validation#require-one}
   */
  require_one: ({ name, node, args: inputNames }) => {
    const labels = inputNames.map((name2) => {
      const dependentNode = node.at(name2);
      if (dependentNode) {
        return createMessageName(dependentNode);
      }
      return false;
    }).filter((name2) => !!name2);
    labels.unshift(name);
    return `${labels.join(" tai ")} vaaditaan.`;
  },
  /**
   * Required field.
   * @see {@link https://formkit.com/essentials/validation#required}
   */
  required({ name }) {
    return `${sentence(name)} vaaditaan.`;
  },
  /**
   * Does not start with specified value
   * @see {@link https://formkit.com/essentials/validation#starts-with}
   */
  starts_with({ name, args }) {
    return `${sentence(name)} on alettava ${list(args)}.`;
  },
  /**
   * Is not a url
   * @see {@link https://formkit.com/essentials/validation#url}
   */
  url() {
    return `Anna kelvollinen URL-osoite.`;
  },
  /**
   * Shown when the date is invalid.
   */
  invalidDate: "Valittu päivämäärä on virheellinen."
};
var fi = { ui: ui13, validation: validation13 };
var ui14 = {
  /**
   * Shown on buttons for adding new items.
   */
  add: "Ajouter",
  /**
   * Shown when a button to remove items is visible.
   */
  remove: "Supprimer",
  /**
   * Shown when there are multiple items to remove at the same time.
   */
  removeAll: "Enlever tout",
  /**
   * Shown when all fields are not filled out correctly.
   */
  incomplete: "Désolé, tous les champs ne sont pas remplis correctement.",
  /**
   * Shown in a button inside a form to submit the form.
   */
  submit: "Valider",
  /**
   * Shown when no files are selected.
   */
  noFiles: "Aucun fichier choisi",
  /**
   * Shown on buttons that move fields up in a list.
   */
  moveUp: "Déplacez-vous",
  /**
   * Shown on buttons that move fields down in a list.
   */
  moveDown: "Déplacez-vous",
  /**
   * Shown when something is actively loading.
   */
  isLoading: "Chargement...",
  /**
   * Shown when there is more to load.
   */
  loadMore: "Chargez plus",
  /**
   * Shown on buttons that navigate state forward
   */
  next: "Suivant",
  /**
   * Shown on buttons that navigate state backward
   */
  prev: "Précédent",
  /**
   * Shown when adding all values.
   */
  addAllValues: "Ajouter toutes les valeurs",
  /**
   * Shown when adding selected values.
   */
  addSelectedValues: "Ajouter les valeurs sélectionnées",
  /**
   * Shown when removing all values.
   */
  removeAllValues: "Supprimer toutes les valeurs",
  /**
   * Shown when removing selected values.
   */
  removeSelectedValues: "Supprimer les valeurs sélectionnées",
  /**
   * Shown when there is a date to choose.
   */
  chooseDate: "Choisissez la date",
  /**
   * Shown when there is a date to change.
   */
  changeDate: "Modifier la date",
  /**
   * Shown when there is something to close
   */
  close: "Fermer",
  /**
   * Shown when there is something to open.
   */
  open: "Ouvrir"
};
var validation14 = {
  /**
   * The value is not an accepted value.
   * @see {@link https://formkit.com/essentials/validation#accepted}
   */
  accepted({ name }) {
    return `Veuillez accepter le ${name}.`;
  },
  /**
   * The date is not after
   * @see {@link https://formkit.com/essentials/validation#date-after}
   */
  date_after({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${sentence(name)} doit être postérieure au ${date(args[0])}.`;
    }
    return `${sentence(name)} doit être dans le futur.`;
  },
  /**
   * The value is not a letter.
   * @see {@link https://formkit.com/essentials/validation#alpha}
   */
  alpha({ name }) {
    return `${sentence(name)} ne peut contenir que des caractères alphabétiques.`;
  },
  /**
   * The value is not alphanumeric
   * @see {@link https://formkit.com/essentials/validation#alphanumeric}
   */
  alphanumeric({ name }) {
    return `${sentence(name)} ne peut contenir que des lettres et des chiffres.`;
  },
  /**
   * The value is not letter and/or spaces
   * @see {@link https://formkit.com/essentials/validation#alpha-spaces}
   */
  alpha_spaces({ name }) {
    return `${sentence(name)} ne peuvent contenir que des lettres et des espaces.`;
  },
  /**
   * The value have no letter.
   * @see {@link https://formkit.com/essentials/validation#contains_alpha}
   */
  contains_alpha({ name }) {
    return `${sentence(name)} doit contenir des caractères alphabétiques.`;
  },
  /**
   * The value have no alphanumeric
   * @see {@link https://formkit.com/essentials/validation#contains_alphanumeric}
   */
  contains_alphanumeric({ name }) {
    return `${sentence(name)} doit contenir au moins un lettre ou nombre.`;
  },
  /**
   * The value have no letter and/or spaces
   * @see {@link https://formkit.com/essentials/validation#contains_alpha-spaces}
   */
  contains_alpha_spaces({ name }) {
    return `${sentence(name)} doit contenir des lettres ou des espaces.`;
  },
  /**
   * The value have no symbol
   * @see {@link https://formkit.com/essentials/validation#contains_symbol}
   */
  contains_symbol({ name }) {
    return `${sentence(name)} doit contenir un symbole.`;
  },
  /**
   * The value have no uppercase
   * @see {@link https://formkit.com/essentials/validation#contains_uppercase}
   */
  contains_uppercase({ name }) {
    return `${sentence(name)} doit contenir au moins une majuscule.`;
  },
  /**
   * The value have no lowercase
   * @see {@link https://formkit.com/essentials/validation#contains_lowercase}
   */
  contains_lowercase({ name }) {
    return `${sentence(name)} doit contenir au moins une minuscule.`;
  },
  /**
   *  The value have no numeric
   * @see {@link https://formkit.com/essentials/validation#contains_numeric}
   */
  contains_numeric({ name }) {
    return `${sentence(name)} doit contenir des chiffres.`;
  },
  /**
   * The value is not symbol
   * @see {@link https://formkit.com/essentials/validation#symbol}
   */
  symbol({ name }) {
    return `${sentence(name)} doit être un symbole.`;
  },
  /**
   * The value is not uppercase
   * @see {@link https://formkit.com/essentials/validation#uppercase}
   */
  uppercase({ name }) {
    return `${sentence(name)} ne peuvent contenir que des majuscules.`;
  },
  /**
   * The value is not lowercase
   * @see {@link https://formkit.com/essentials/validation#lowercase}
   */
  lowercase({ name }) {
    return `${sentence(name)} ne peut contenir que des lettres minuscules.`;
  },
  /**
   * The date is not before
   * @see {@link https://formkit.com/essentials/validation#date-before}
   */
  date_before({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${sentence(name)} doit être antérieure au ${date(args[0])}.`;
    }
    return `${sentence(name)} doit être dans le passé.`;
  },
  /**
   * The value is not between two numbers
   * @see {@link https://formkit.com/essentials/validation#between}
   */
  between({ name, args }) {
    if (isNaN(args[0]) || isNaN(args[1])) {
      return `Ce champ a été configuré de manière incorrecte et ne peut pas être soumis.`;
    }
    const [a, b] = order(args[0], args[1]);
    return `${sentence(name)} doit être comprise entre ${a} et ${b}.`;
  },
  /**
   * The confirmation field does not match
   * @see {@link https://formkit.com/essentials/validation#confirm}
   */
  confirm({ name }) {
    return `${sentence(name)} ne correspond pas.`;
  },
  /**
   * The value is not a valid date
   * @see {@link https://formkit.com/essentials/validation#date-format}
   */
  date_format({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${sentence(
        name
      )} n'est pas une date valide, veuillez utiliser le format ${args[0]}`;
    }
    return "Ce champ a été configuré de manière incorrecte et ne peut pas être soumis.";
  },
  /**
   * Is not within expected date range
   * @see {@link https://formkit.com/essentials/validation#date-between}
   */
  date_between({ name, args }) {
    return `${sentence(name)} doit être comprise entre ${date(args[0])} et ${date(
      args[1]
    )}`;
  },
  /**
   * Shown when the user-provided value is not a valid email address.
   * @see {@link https://formkit.com/essentials/validation#email}
   */
  email: "Veuillez saisir une adresse email valide.",
  /**
   * Does not end with the specified value
   * @see {@link https://formkit.com/essentials/validation#ends-with}
   */
  ends_with({ name, args }) {
    return `${sentence(name)} ne se termine pas par ${list(args)}.`;
  },
  /**
   * Is not an allowed value
   * @see {@link https://formkit.com/essentials/validation#is}
   */
  is({ name }) {
    return `${sentence(name)} n'est pas une valeur autorisée.`;
  },
  /**
   * Does not match specified length
   * @see {@link https://formkit.com/essentials/validation#length}
   */
  length({ name, args: [first = 0, second = Infinity] }) {
    const min = Number(first) <= Number(second) ? first : second;
    const max = Number(second) >= Number(first) ? second : first;
    if (min == 1 && max === Infinity) {
      return `${sentence(name)} doit comporter au moins un caractère.`;
    }
    if (min == 0 && max) {
      return `${sentence(name)} doit être inférieur ou égal à ${max} caractères.`;
    }
    if (min === max) {
      return `${sentence(name)} doit contenir ${max} caractères.`;
    }
    if (min && max === Infinity) {
      return `${sentence(name)} doit être supérieur ou égal à ${min} caractères.`;
    }
    return `${sentence(name)} doit être comprise entre ${min} et ${max} caractères.`;
  },
  /**
   * Value is not a match
   * @see {@link https://formkit.com/essentials/validation#matches}
   */
  matches({ name }) {
    return `${sentence(name)} n'est pas une valeur autorisée.`;
  },
  /**
   * Exceeds maximum allowed value
   * @see {@link https://formkit.com/essentials/validation#max}
   */
  max({ name, node: { value }, args }) {
    if (Array.isArray(value)) {
      return `Ne peut pas avoir plus de ${args[0]} ${name}.`;
    }
    return `${sentence(name)} doit être inférieur ou égal à ${args[0]}.`;
  },
  /**
   * The (field-level) value does not match specified mime type
   * @see {@link https://formkit.com/essentials/validation#mime}
   */
  mime({ name, args }) {
    if (!args[0]) {
      return "Aucun format de fichier n’est autorisé";
    }
    return `${sentence(name)} doit être du type: ${args[0]}`;
  },
  /**
   * Does not fulfill minimum allowed value
   * @see {@link https://formkit.com/essentials/validation#min}
   */
  min({ name, node: { value }, args }) {
    if (Array.isArray(value)) {
      return `Ne peut pas avoir moins de ${args[0]} ${name}.`;
    }
    return `${sentence(name)} doit être au moins de ${args[0]}.`;
  },
  /**
   * Is not an allowed value
   * @see {@link https://formkit.com/essentials/validation#not}
   */
  not({ name, node: { value } }) {
    return `“${value}” n'est pas un ${name} autorisé.`;
  },
  /**
   *  Is not a number
   * @see {@link https://formkit.com/essentials/validation#number}
   */
  number({ name }) {
    return `${sentence(name)} doit être un nombre.`;
  },
  /**
   * Require one field.
   * @see {@link https://formkit.com/essentials/validation#require-one}
   */
  require_one: ({ name, node, args: inputNames }) => {
    const labels = inputNames.map((name2) => {
      const dependentNode = node.at(name2);
      if (dependentNode) {
        return createMessageName(dependentNode);
      }
      return false;
    }).filter((name2) => !!name2);
    labels.unshift(name);
    return `${labels.join(" ou ")} est requis.`;
  },
  /**
   * Required field.
   * @see {@link https://formkit.com/essentials/validation#required}
   */
  required({ name }) {
    return `${sentence(name)} est requis.`;
  },
  /**
   * Does not start with specified value
   * @see {@link https://formkit.com/essentials/validation#starts-with}
   */
  starts_with({ name, args }) {
    return `${sentence(name)} ne commence pas par ${list(args)}.`;
  },
  /**
   * Is not a url
   * @see {@link https://formkit.com/essentials/validation#url}
   */
  url() {
    return `Entrez une URL valide.`;
  },
  /**
   * Shown when the date is invalid.
   */
  invalidDate: `La date sélectionnée n'est pas valide.`
};
var fr = { ui: ui14, validation: validation14 };
var ui15 = {
  /**
   * Shown on a button for adding additional items.
   */
  add: "Foeg ta",
  /**
   * Shown when a button to remove items is visible.
   */
  remove: "Ferwider",
  /**
   * Shown when there are multiple items to remove at the same time.
   */
  removeAll: "Ferwider alles",
  /**
   * Shown when all fields are not filled out correctly.
   */
  incomplete: "Sorry, net alle fjilden binne korrekt ynfolle.",
  /**
   * Shown in a button inside a form to submit the form.
   */
  submit: "Ferstjoere",
  /**
   * Shown when no files are selected.
   */
  noFiles: "Gjin bestân keazen",
  /**
   * Shown on buttons that move fields up in a list.
   */
  moveUp: "Gean omheech",
  /**
   * Shown on buttons that move fields down in a list.
   */
  moveDown: "Nei ûnderen",
  /**
   * Shown when something is actively loading.
   */
  isLoading: "Lade…",
  /**
   * Shown when there is more to load.
   */
  loadMore: "Mear lade",
  /**
   * Show on buttons that navigate state forward
   */
  next: "Folgende",
  /**
   * Show on buttons that navigate state backward
   */
  prev: "Foarige",
  /**
   * Shown when adding all values.
   */
  addAllValues: "Foegje alle wearden ta",
  /**
   * Shown when adding selected values.
   */
  addSelectedValues: "Foegje selektearre wearden ta",
  /**
   * Shown when removing all values.
   */
  removeAllValues: "Fuortsmite alle wearden",
  /**
   * Shown when removing selected values.
   */
  removeSelectedValues: "Fuortsmite selektearre wearden",
  /**
   * Shown when there is a date to choose.
   */
  chooseDate: "Kies datum",
  /**
   * Shown when there is a date to change.
   */
  changeDate: "Feroarje datum"
};
var validation15 = {
  /**
   * The value is not an accepted value.
   * @see {@link https://formkit.com/essentials/validation#accepted}
   */
  accepted({ name }) {
    return `Akseptearje de ${name}.`;
  },
  /**
   * The date is not after
   * @see {@link https://formkit.com/essentials/validation#date-after}
   */
  date_after({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${sentence(name)} moat nei ${date(args[0])} wêze.`;
    }
    return `${sentence(name)} moat yn de takomst lizze.`;
  },
  /**
   * The value is not a letter.
   * @see {@link https://formkit.com/essentials/validation#alpha}
   */
  alpha({ name }) {
    return `${sentence(name)} mei allinne alfabetyske tekens befetsje.`;
  },
  /**
   * The value is not alphanumeric
   * @see {@link https://formkit.com/essentials/validation#alphanumeric}
   */
  alphanumeric({ name }) {
    return `${sentence(name)} mei allinne letters en sifers befetsje.`;
  },
  /**
   * The value is not letter and/or spaces
   * @see {@link https://formkit.com/essentials/validation#alpha-spaces}
   */
  alpha_spaces({ name }) {
    return `${sentence(name)} mei allinne letters en spaasjes befetsje.`;
  },
  /**
   * The value have no letter.
   * @see {@link https://formkit.com/essentials/validation#contains_alpha}
   */
  contains_alpha({ name }) {
    return `${sentence(name)} must contain alphabetical characters.`;
  },
  /**
   * The value have no alphanumeric
   * @see {@link https://formkit.com/essentials/validation#contains_alphanumeric}
   */
  contains_alphanumeric({ name }) {
    return `${sentence(name)} must contain letters and numbers.`;
  },
  /**
   * The value have no letter and/or spaces
   * @see {@link https://formkit.com/essentials/validation#contains_alpha-spaces}
   */
  contains_alpha_spaces({ name }) {
    return `${sentence(name)} must contain letters and spaces.`;
  },
  /**
   * The value have no symbol
   * @see {@link https://formkit.com/essentials/validation#contains_symbol}
   */
  contains_symbol({ name }) {
    return `${sentence(name)} must contain symbol.`;
  },
  /**
   * The value have no uppercase
   * @see {@link https://formkit.com/essentials/validation#contains_uppercase}
   */
  contains_uppercase({ name }) {
    return `${sentence(name)} must contain uppercase.`;
  },
  /**
   * The value have no lowercase
   * @see {@link https://formkit.com/essentials/validation#contains_lowercase}
   */
  contains_lowercase({ name }) {
    return `${sentence(name)} must contain lowercase.`;
  },
  /**
   *  The value have no numeric
   * @see {@link https://formkit.com/essentials/validation#contains_numeric}
   */
  contains_numeric({ name }) {
    return `${sentence(name)} must contain number.`;
  },
  /**
   * The value is not symbol
   * @see {@link https://formkit.com/essentials/validation#symbol}
   */
  symbol({ name }) {
    return `${sentence(name)} can only contain symbol.`;
  },
  /**
   * The value is not uppercase
   * @see {@link https://formkit.com/essentials/validation#uppercase}
   */
  uppercase({ name }) {
    return `${sentence(name)} can only contain uppercase.`;
  },
  /**
   * The value is not lowercase
   * @see {@link https://formkit.com/essentials/validation#lowercase}
   */
  lowercase({ name }) {
    return `${sentence(name)} can only contain lowercase.`;
  },
  /**
   * The date is not before
   * @see {@link https://formkit.com/essentials/validation#date-before}
   */
  date_before({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${sentence(name)} moat foar ${date(args[0])} falle.`;
    }
    return `${sentence(name)} moat yn it ferline wêze.`;
  },
  /**
   * The value is not between two numbers
   * @see {@link https://formkit.com/essentials/validation#between}
   */
  between({ name, args }) {
    if (isNaN(args[0]) || isNaN(args[1])) {
      return `Dit fjild is ferkeard konfigurearre en kin net ferstjoerd wurde.`;
    }
    const [a, b] = order(args[0], args[1]);
    return `${sentence(name)} moat tusken ${a} en ${b} lizze.`;
  },
  /**
   * The confirmation field does not match
   * @see {@link https://formkit.com/essentials/validation#confirm}
   */
  confirm({ name }) {
    return `${sentence(name)} komt net oerien.`;
  },
  /**
   * The value is not a valid date
   * @see {@link https://formkit.com/essentials/validation#date-format}
   */
  date_format({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${sentence(name)} is gjin jildige datum, brûk de notaasje ${args[0]}`;
    }
    return "Dit fjild is ferkeard konfigurearre en kin net ferstjoerd wurde";
  },
  /**
   * Is not within expected date range
   * @see {@link https://formkit.com/essentials/validation#date-between}
   */
  date_between({ name, args }) {
    return `${sentence(name)} moat tusken ${date(args[0])} en ${date(args[1])} lizze`;
  },
  /**
   * Shown when the user-provided value is not a valid email address.
   * @see {@link https://formkit.com/essentials/validation#email}
   */
  email: "Folje in jildich e-mailadres yn.",
  /**
   * Does not end with the specified value
   * @see {@link https://formkit.com/essentials/validation#ends-with}
   */
  ends_with({ name, args }) {
    return `${sentence(name)} einiget net mei ${list(args)}.`;
  },
  /**
   * Is not an allowed value
   * @see {@link https://formkit.com/essentials/validation#is}
   */
  is({ name }) {
    return `${sentence(name)} is gjin tastiene wearde.`;
  },
  /**
   * Does not match specified length
   * @see {@link https://formkit.com/essentials/validation#length}
   */
  length({ name, args: [first = 0, second = Infinity] }) {
    const min = Number(first) <= Number(second) ? first : second;
    const max = Number(second) >= Number(first) ? second : first;
    if (min == 1 && max === Infinity) {
      return `${sentence(name)} moat minimaal ien teken wêze.`;
    }
    if (min == 0 && max) {
      return `${sentence(name)} moat lytser wêze as of gelyk wêze oan ${max} tekens.`;
    }
    if (min === max) {
      return `${sentence(name)} moat ${max} tekens lang wêze.`;
    }
    if (min && max === Infinity) {
      return `${sentence(name)} moat grutter wêze as of gelyk wêze oan ${min} tekens.`;
    }
    return `${sentence(name)} moat tusken de ${min} en ${max} tekens befetsje.`;
  },
  /**
   * Value is not a match
   * @see {@link https://formkit.com/essentials/validation#matches}
   */
  matches({ name }) {
    return `${sentence(name)} is gjin tastiene wearde.`;
  },
  /**
   * Exceeds maximum allowed value
   * @see {@link https://formkit.com/essentials/validation#max}
   */
  max({ name, node: { value }, args }) {
    if (Array.isArray(value)) {
      return `Mei net mear as ${args[0]} ${name} hawwe.`;
    }
    return `${sentence(name)} moat lytser wêze as of gelyk wêze oan ${args[0]}.`;
  },
  /**
   * The (field-level) value does not match specified mime type
   * @see {@link https://formkit.com/essentials/validation#mime}
   */
  mime({ name, args }) {
    if (!args[0]) {
      return "Gjin bestânsnotaasjes tastien.";
    }
    return `${sentence(name)} moat fan it type: ${args[0]} wêze`;
  },
  /**
   * Does not fulfill minimum allowed value
   * @see {@link https://formkit.com/essentials/validation#min}
   */
  min({ name, node: { value }, args }) {
    if (Array.isArray(value)) {
      return `Mei net minder as ${args[0]} ${name} hawwe.`;
    }
    return `${sentence(name)} moat minimaal ${args[0]} wêze.`;
  },
  /**
   * Is not an allowed value
   * @see {@link https://formkit.com/essentials/validation#not}
   */
  not({ name, node: { value } }) {
    return `"${value}" is gjin tastiene ${name}.`;
  },
  /**
   *  Is not a number
   * @see {@link https://formkit.com/essentials/validation#number}
   */
  number({ name }) {
    return `${sentence(name)} moat in getal wêze.`;
  },
  /**
   * Require one field.
   * @see {@link https://formkit.com/essentials/validation#require-one}
   */
  require_one: ({ name, node, args: inputNames }) => {
    const labels = inputNames.map((name2) => {
      const dependentNode = node.at(name2);
      if (dependentNode) {
        return createMessageName(dependentNode);
      }
      return false;
    }).filter((name2) => !!name2);
    labels.unshift(name);
    return `${labels.join(" of ")} is ferplichte.`;
  },
  /**
   * Required field.
   * @see {@link https://formkit.com/essentials/validation#required}
   */
  required({ name }) {
    return `${sentence(name)} is ferplicht.`;
  },
  /**
   * Does not start with specified value
   * @see {@link https://formkit.com/essentials/validation#starts-with}
   */
  starts_with({ name, args }) {
    return `${sentence(name)} begjint net mei ${list(args)}.`;
  },
  /**
   * Is not a url
   * @see {@link https://formkit.com/essentials/validation#url}
   */
  url() {
    return `Doch der in jildige url by.`;
  },
  /**
   * Shown when the date is invalid.
   */
  invalidDate: "De selektearre datum is ûnjildich."
};
var fy = { ui: ui15, validation: validation15 };
var ui16 = {
  /**
   * Shown on a button for adding additional items.
   */
  add: "הוסף",
  /**
   * Shown when a button to remove items is visible.
   */
  remove: "מחק",
  /**
   * Shown when there are multiple items to remove at the same time.
   */
  removeAll: "מחק הכל",
  /**
   * Shown when all fields are not filled out correctly.
   */
  incomplete: "שים לב, לא כל השדות מלאים כראוי.",
  /**
   * Shown in a button inside a form to submit the form.
   */
  submit: "שלח",
  /**
   * Shown when no files are selected.
   */
  noFiles: "לא נבחר קובץ..",
  /**
   * Shown on buttons that move fields up in a list.
   */
  moveUp: "הזז למעלה",
  /**
   * Shown on buttons that move fields down in a list.
   */
  moveDown: "הזז למטה",
  /**
   * Shown when something is actively loading.
   */
  isLoading: "טוען...",
  /**
   * Shown when there is more to load.
   */
  loadMore: "טען יותר",
  /**
   * Shown on buttons that navigate state forward
   */
  next: "הבא",
  /**
   * Shown on buttons that navigate state backward
   */
  prev: "הקודם",
  /**
   * Shown when adding all values.
   */
  addAllValues: "הוסף את כל הערכים",
  /**
   * Shown when adding selected values.
   */
  addSelectedValues: "הוספת ערכים נבחרים",
  /**
   * Shown when removing all values.
   */
  removeAllValues: "הסר את כל הערכים",
  /**
   * Shown when removing selected values.
   */
  removeSelectedValues: "הסר ערכים נבחרים",
  /**
   * Shown when there is a date to choose.
   */
  chooseDate: "בחר תאריך",
  /**
   * Shown when there is a date to change.
   */
  changeDate: "שינוי תאריך",
  /**
   * Shown when there is something to close
   */
  close: "סגור",
  /**
   * Shown when there is something to open.
   */
  open: "פתוח"
};
var validation16 = {
  /**
   * The value is not an accepted value.
   * @see {@link https://formkit.com/essentials/validation#accepted}
   */
  accepted({ name }) {
    return `אנא אשר את ${name}.`;
  },
  /**
   * The date is not after
   * @see {@link https://formkit.com/essentials/validation#date-after}
   */
  date_after({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${sentence(name)} חייב להיות אחרי ${date(args[0])}.`;
    }
    return `${sentence(name)} חייב להיות בעתיד.`;
  },
  /**
   * The value is not a letter.
   * @see {@link https://formkit.com/essentials/validation#alpha}
   */
  alpha({ name }) {
    return `${sentence(name)} חייב להכיל אותיות אלפבת.`;
  },
  /**
   * The value is not alphanumeric
   * @see {@link https://formkit.com/essentials/validation#alphanumeric}
   */
  alphanumeric({ name }) {
    return `${sentence(name)} יכול להכיל רק מספרים ואותיות.`;
  },
  /**
   * The value is not letter and/or spaces
   * @see {@link https://formkit.com/essentials/validation#alpha-spaces}
   */
  alpha_spaces({ name }) {
    return `${sentence(name)} יכול להכיל רק אותיות ורווחים.`;
  },
  /**
   * The value have no letter.
   * @see {@link https://formkit.com/essentials/validation#contains_alpha}
   */
  contains_alpha({ name }) {
    return `${sentence(name)} חייב להכיל תווים אלפביתיים.`;
  },
  /**
   * The value have no alphanumeric
   * @see {@link https://formkit.com/essentials/validation#contains_alphanumeric}
   */
  contains_alphanumeric({ name }) {
    return `${sentence(name)} חייב להכיל אותיות או מספרים.`;
  },
  /**
   * The value have no letter and/or spaces
   * @see {@link https://formkit.com/essentials/validation#contains_alpha-spaces}
   */
  contains_alpha_spaces({ name }) {
    return `${sentence(name)} חייב להכיל אותיות או רווחים.`;
  },
  /**
   * The value have no symbol
   * @see {@link https://formkit.com/essentials/validation#contains_symbol}
   */
  contains_symbol({ name }) {
    return `${sentence(name)} חייב להכיל סמל.`;
  },
  /**
   * The value have no uppercase
   * @see {@link https://formkit.com/essentials/validation#contains_uppercase}
   */
  contains_uppercase({ name }) {
    return `${sentence(name)} חייב להכיל אותיות רישיות.`;
  },
  /**
   * The value have no lowercase
   * @see {@link https://formkit.com/essentials/validation#contains_lowercase}
   */
  contains_lowercase({ name }) {
    return `${sentence(name)} חייב להכיל אותיות קטנות.`;
  },
  /**
   *  The value have no numeric
   * @see {@link https://formkit.com/essentials/validation#contains_numeric}
   */
  contains_numeric({ name }) {
    return `${sentence(name)} חייב להכיל מספרים.`;
  },
  /**
   * The value is not symbol
   * @see {@link https://formkit.com/essentials/validation#symbol}
   */
  symbol({ name }) {
    return `${sentence(name)} חייב להיות סמל.`;
  },
  /**
   * The value is not uppercase
   * @see {@link https://formkit.com/essentials/validation#uppercase}
   */
  uppercase({ name }) {
    return `${sentence(name)} יכול להכיל אותיות רישיות בלבד.`;
  },
  /**
   * The value is not lowercase
   * @see {@link https://formkit.com/essentials/validation#lowercase}
   */
  lowercase({ name }) {
    return `${sentence(name)} יכול להכיל רק אותיות קטנות.`;
  },
  /**
   * The date is not before
   * @see {@link https://formkit.com/essentials/validation#date-before}
   */
  date_before({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${sentence(name)} חייב להיות לפני ${date(args[0])}.`;
    }
    return `${sentence(name)} חייב להיות בעבר`;
  },
  /**
   * The value is not between two numbers
   * @see {@link https://formkit.com/essentials/validation#between}
   */
  between({ name, args }) {
    if (isNaN(args[0]) || isNaN(args[1])) {
      return `שדה זה לא הוגדר כראוי ולא יכול להישלח.`;
    }
    const [a, b] = order(args[0], args[1]);
    return `${sentence(name)} חייב להיות בין ${a} ו- ${b}.`;
  },
  /**
   * The confirmation field does not match
   * @see {@link https://formkit.com/essentials/validation#confirm}
   */
  confirm({ name }) {
    return `${sentence(name)} לא מתאים.`;
  },
  /**
   * The value is not a valid date
   * @see {@link https://formkit.com/essentials/validation#date-format}
   */
  date_format({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${sentence(name)} הוא לא תאריך תקין, אנא השתמש בפורמט ${args[0]}`;
    }
    return "שדה זה לא הוגדר כראוי ולא יכול להישלח.";
  },
  /**
   * Is not within expected date range
   * @see {@link https://formkit.com/essentials/validation#date-between}
   */
  date_between({ name, args }) {
    return `${sentence(name)} חייב להיות בין ${date(args[0])} ו- ${date(args[1])}`;
  },
  /**
   * Shown when the user-provided value is not a valid email address.
   * @see {@link https://formkit.com/essentials/validation#email}
   */
  email: "אנא הקלד אימייל תקין.",
  /**
   * Does not end with the specified value
   * @see {@link https://formkit.com/essentials/validation#ends-with}
   */
  ends_with({ name, args }) {
    return `${sentence(name)} לא מסתיים ב- ${list(args)}.`;
  },
  /**
   * Is not an allowed value
   * @see {@link https://formkit.com/essentials/validation#is}
   */
  is({ name }) {
    return `${sentence(name)} הוא לא ערך מורשה.`;
  },
  /**
   * Does not match specified length
   * @see {@link https://formkit.com/essentials/validation#length}
   */
  length({ name, args: [first = 0, second = Infinity] }) {
    const min = Number(first) <= Number(second) ? first : second;
    const max = Number(second) >= Number(first) ? second : first;
    if (min == 1 && max === Infinity) {
      return `${sentence(name)} חייב להיות לפחות תו אחד.`;
    }
    if (min == 0 && max) {
      return `${sentence(name)} חייב להיות פחות או שווה ל- ${max} תווים.`;
    }
    if (min === max) {
      return `${sentence(name)} צריך להיות ${max} תווים ארוכים.`;
    }
    if (min && max === Infinity) {
      return `${sentence(name)} חייב להיות גדול או שווה ל- ${min} תווים.`;
    }
    return `${sentence(name)} חייב להיות בין ${min} ו- ${max} תווים.`;
  },
  /**
   * Value is not a match
   * @see {@link https://formkit.com/essentials/validation#matches}
   */
  matches({ name }) {
    return `${sentence(name)} הוא לא ערך תקין.`;
  },
  /**
   * Exceeds maximum allowed value
   * @see {@link https://formkit.com/essentials/validation#max}
   */
  max({ name, node: { value }, args }) {
    if (Array.isArray(value)) {
      return `${name} לא יכול להיות עם יותר מ- ${args[0]}.`;
    }
    return `${sentence(name)} חייב להיות פחות או שווה ל- ${args[0]}.`;
  },
  /**
   * The (field-level) value does not match specified mime type
   * @see {@link https://formkit.com/essentials/validation#mime}
   */
  mime({ name, args }) {
    if (!args[0]) {
      return "פורמט הקובץ לא מורשה.";
    }
    return `${sentence(name)} חייב להיות מסוג: ${args[0]}`;
  },
  /**
   * Does not fulfill minimum allowed value
   * @see {@link https://formkit.com/essentials/validation#min}
   */
  min({ name, node: { value }, args }) {
    if (Array.isArray(value)) {
      return `${name} לא יכול להיות עם פחות מ- ${args[0]}.`;
    }
    return `${sentence(name)} חייב להיות לפחות ${args[0]}.`;
  },
  /**
   * Is not an allowed value
   * @see {@link https://formkit.com/essentials/validation#not}
   */
  not({ name, node: { value } }) {
    return `“${value}” לא מתאים ל- ${name}.`;
  },
  /**
   *  Is not a number
   * @see {@link https://formkit.com/essentials/validation#number}
   */
  number({ name }) {
    return `${sentence(name)} חייב להיות מספר.`;
  },
  /**
   * Require one field.
   * @see {@link https://formkit.com/essentials/validation#require-one}
   */
  require_one: ({ name, node, args: inputNames }) => {
    const labels = inputNames.map((name2) => {
      const dependentNode = node.at(name2);
      if (dependentNode) {
        return createMessageName(dependentNode);
      }
      return false;
    }).filter((name2) => !!name2);
    labels.unshift(name);
    return `${labels.join(" או ")} נדרש.`;
  },
  /**
   * Required field.
   * @see {@link https://formkit.com/essentials/validation#required}
   */
  required({ name }) {
    return `${sentence(name)} הינו חובה.`;
  },
  /**
   * Does not start with specified value
   * @see {@link https://formkit.com/essentials/validation#starts-with}
   */
  starts_with({ name, args }) {
    return `${sentence(name)} לא מתחיל ב- ${list(args)}.`;
  },
  /**
   * Is not a url
   * @see {@link https://formkit.com/essentials/validation#url}
   */
  url() {
    return `הזן כתובת URL חוקית.`;
  },
  /**
   * Shown when the date is invalid.
   */
  invalidDate: "התאריך שנבחר אינו חוקי."
};
var he = { ui: ui16, validation: validation16 };
var ui17 = {
  /**
   * Shown on buttons for adding new items.
   */
  add: "Dodaj",
  /**
   * Shown when a button to remove items is visible.
   */
  remove: "Ukloni",
  /**
   * Shown when all fields are not filled out correctly.
   */
  incomplete: "Pojedina polja nisu ispravno ispunjena.",
  /**
   * Shown in a button inside a form to submit the form.
   */
  submit: "Predaj",
  /**
   * Shown on buttons that move fields up in a list.
   */
  moveUp: "Pomaknite se gore",
  /**
   * Shown on buttons that move fields down in a list.
   */
  moveDown: "Pomakni se dolje",
  /**
   * Shown when something is actively loading.
   */
  isLoading: "Učitavanje...",
  /**
   * Shown when there is more to load.
   */
  loadMore: "Učitaj više",
  /**
   * Shown on buttons that navigate state forward
   */
  next: "Sljedeći",
  /**
   * Shown on buttons that navigate state backward
   */
  prev: "prijašnji",
  /**
   * Shown when adding all values.
   */
  addAllValues: "Dodajte sve vrijednosti",
  /**
   * Shown when adding selected values.
   */
  addSelectedValues: "Dodavanje odabranih vrijednosti",
  /**
   * Shown when removing all values.
   */
  removeAllValues: "Ukloni sve vrijednosti",
  /**
   * Shown when removing selected values.
   */
  removeSelectedValues: "Ukloni odabrane vrijednosti",
  /**
   * Shown when there is a date to choose.
   */
  chooseDate: "Odaberite datum",
  /**
   * Shown when there is a date to change.
   */
  changeDate: "Promijeni datum",
  /**
   * Shown when there is something to close
   */
  close: "Zatvoriti",
  /**
   * Shown when there is something to open.
   */
  open: "Otvori"
};
var validation17 = {
  /**
   * The value is not an accepted value.
   * @see {@link https://formkit.com/essentials/validation#accepted}
   */
  accepted({ name }) {
    return `Potrebno je potvrditi ${name}.`;
  },
  /**
   * The date is not after
   * @see {@link https://formkit.com/essentials/validation#date-after}
   */
  date_after({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${sentence(name)} mora biti u periodu poslije ${date(args[0])}.`;
    }
    return `${sentence(name)} mora biti u budućnosti.`;
  },
  /**
   * The value is not a letter.
   * @see {@link https://formkit.com/essentials/validation#alpha}
   */
  alpha({ name }) {
    return `${sentence(name)} mora sadržavati samo slova.`;
  },
  /**
   * The value is not alphanumeric
   * @see {@link https://formkit.com/essentials/validation#alphanumeric}
   */
  alphanumeric({ name }) {
    return `${sentence(name)} mora sadržavati slova i brojeve.`;
  },
  /**
   * The value is not letter and/or spaces
   * @see {@link https://formkit.com/essentials/validation#alpha-spaces}
   */
  alpha_spaces({ name }) {
    return `${sentence(name)} mogu sadržavati samo slova i razmake..`;
  },
  /**
   * The value have no letter.
   * @see {@link https://formkit.com/essentials/validation#contains_alpha}
   */
  contains_alpha({ name }) {
    return `${sentence(name)} mora sadržavati abecedne znakove.`;
  },
  /**
   * The value have no alphanumeric
   * @see {@link https://formkit.com/essentials/validation#contains_alphanumeric}
   */
  contains_alphanumeric({ name }) {
    return `${sentence(name)} mora sadržavati slova ili brojeve.`;
  },
  /**
   * The value have no letter and/or spaces
   * @see {@link https://formkit.com/essentials/validation#contains_alpha-spaces}
   */
  contains_alpha_spaces({ name }) {
    return `${sentence(name)} mora sadržavati slova ili razmake.`;
  },
  /**
   * The value have no symbol
   * @see {@link https://formkit.com/essentials/validation#contains_symbol}
   */
  contains_symbol({ name }) {
    return `${sentence(name)} mora sadržavati simbol.`;
  },
  /**
   * The value have no uppercase
   * @see {@link https://formkit.com/essentials/validation#contains_uppercase}
   */
  contains_uppercase({ name }) {
    return `${sentence(name)} mora sadržavati velika slova.`;
  },
  /**
   * The value have no lowercase
   * @see {@link https://formkit.com/essentials/validation#contains_lowercase}
   */
  contains_lowercase({ name }) {
    return `${sentence(name)} mora sadržavati mala slova.`;
  },
  /**
   *  The value have no numeric
   * @see {@link https://formkit.com/essentials/validation#contains_numeric}
   */
  contains_numeric({ name }) {
    return `${sentence(name)} mora sadržavati brojeve.`;
  },
  /**
   * The value is not symbol
   * @see {@link https://formkit.com/essentials/validation#symbol}
   */
  symbol({ name }) {
    return `${sentence(name)} mora biti simbol.`;
  },
  /**
   * The value is not uppercase
   * @see {@link https://formkit.com/essentials/validation#uppercase}
   */
  uppercase({ name }) {
    return `${sentence(name)} može sadržavati samo velika slova.`;
  },
  /**
   * The value is not lowercase
   * @see {@link https://formkit.com/essentials/validation#lowercase}
   */
  lowercase({ name }) {
    return `${sentence(name)} može sadržavati samo mala slova.`;
  },
  /**
   * The date is not before
   * @see {@link https://formkit.com/essentials/validation#date-before}
   */
  date_before({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${sentence(name)} mora biti prije ${date(args[0])}.`;
    }
    return `${sentence(name)} mora biti u prošlosti.`;
  },
  /**
   * The value is not between two numbers
   * @see {@link https://formkit.com/essentials/validation#between}
   */
  between({ name, args }) {
    if (isNaN(args[0]) || isNaN(args[1])) {
      return `Format sadržaja nije ispravan i ne može biti predan.`;
    }
    return `${sentence(name)} mora biti između ${args[0]} i ${args[1]}.`;
  },
  /**
   * The confirmation field does not match
   * @see {@link https://formkit.com/essentials/validation#confirm}
   */
  confirm({ name }) {
    return `${sentence(name)} ne odgovara zadanoj vrijednosti.`;
  },
  /**
   * The value is not a valid date
   * @see {@link https://formkit.com/essentials/validation#date-format}
   */
  date_format({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${sentence(
        name
      )} nije ispravan format datuma. Molimo koristite sljedeći format: ${args[0]}`;
    }
    return "Ovo polje nije ispravno postavljeno i ne može biti predano.";
  },
  /**
   * Is not within expected date range
   * @see {@link https://formkit.com/essentials/validation#date-between}
   */
  date_between({ name, args }) {
    return `${sentence(name)} mora biti vrijednost između ${date(args[0])} i ${date(
      args[1]
    )}`;
  },
  /**
   * Shown when the user-provided value is not a valid email address.
   * @see {@link https://formkit.com/essentials/validation#email}
   */
  email: "Molimo upišite ispravnu email adresu.",
  /**
   * Does not end with the specified value
   * @see {@link https://formkit.com/essentials/validation#ends-with}
   */
  ends_with({ name, args }) {
    return `${sentence(name)} ne završava s ${list(args)}.`;
  },
  /**
   * Is not an allowed value
   * @see {@link https://formkit.com/essentials/validation#is}
   */
  is({ name }) {
    return `${sentence(name)} nije dopuštena vrijednost.`;
  },
  /**
   * Does not match specified length
   * @see {@link https://formkit.com/essentials/validation#length}
   */
  length({ name, args: [first = 0, second = Infinity] }) {
    const min = first <= second ? first : second;
    const max = second >= first ? second : first;
    if (min == 1 && max === Infinity) {
      return `${sentence(name)} mora sadržavati barem jedan znak.`;
    }
    if (min == 0 && max) {
      return `${sentence(name)} mora imati ${max} ili manje znakova.`;
    }
    if (min === max) {
      return `${sentence(name)} trebao bi biti dugačak ${max} znakova.`;
    }
    if (min && max === Infinity) {
      return `${sentence(name)} mora imati barem ${min} znakova.`;
    }
    return `Broj znakova za polje ${sentence(name)} mora biti između ${min} i ${max}.`;
  },
  /**
   * Value is not a match
   * @see {@link https://formkit.com/essentials/validation#matches}
   */
  matches({ name }) {
    return `${sentence(name)} nije dozvoljena vrijednost.`;
  },
  /**
   * Exceeds maximum allowed value
   * @see {@link https://formkit.com/essentials/validation#max}
   */
  max({ name, node: { value }, args }) {
    if (Array.isArray(value)) {
      return `Ne smije imati više od ${args[0]} ${name} polja.`;
    }
    return `${sentence(name)} mora imati vrijednost manju ili jednaku ${args[0]}.`;
  },
  /**
   * The (field-level) value does not match specified mime type
   * @see {@link https://formkit.com/essentials/validation#mime}
   */
  mime({ name, args }) {
    if (!args[0]) {
      return "Format datoteke nije dozvoljen.";
    }
    return `Format datoteke na polju ${sentence(name)} mora odgovarati: ${args[0]}`;
  },
  /**
   * Does not fulfill minimum allowed value
   * @see {@link https://formkit.com/essentials/validation#min}
   */
  min({ name, node: { value }, args }) {
    if (Array.isArray(value)) {
      return `Broj upisanih vrijednosti na polju ${name} mora biti barem ${args[0]}.`;
    }
    return `${sentence(name)} mora biti barem ${args[0]}.`;
  },
  /**
   * Is not an allowed value
   * @see {@link https://formkit.com/essentials/validation#not}
   */
  not({ name, node: { value } }) {
    return `“${value}” nije dozvoljena vrijednost na polju ${name}.`;
  },
  /**
   *  Is not a number
   * @see {@link https://formkit.com/essentials/validation#number}
   */
  number({ name }) {
    return `${sentence(name)} mora biti broj.`;
  },
  /**
   * Require one field.
   * @see {@link https://formkit.com/essentials/validation#require-one}
   */
  require_one: ({ name, node, args: inputNames }) => {
    const labels = inputNames.map((name2) => {
      const dependentNode = node.at(name2);
      if (dependentNode) {
        return createMessageName(dependentNode);
      }
      return false;
    }).filter((name2) => !!name2);
    labels.unshift(name);
    return `${labels.join(" ili ")} je potreban.`;
  },
  /**
   * Required field.
   * @see {@link https://formkit.com/essentials/validation#required}
   */
  required({ name }) {
    return `${sentence(name)} je obavezno.`;
  },
  /**
   * Does not start with specified value
   * @see {@link https://formkit.com/essentials/validation#starts-with}
   */
  starts_with({ name, args }) {
    return `${sentence(name)} ne počinje s ${list(args)}.`;
  },
  /**
   * Is not a url
   * @see {@link https://formkit.com/essentials/validation#url}
   */
  url() {
    return `Unesite valjanu URL adresu.`;
  },
  /**
   * Shown when the date is invalid.
   */
  invalidDate: "Odabrani datum je nevažeći."
};
var hr = { ui: ui17, validation: validation17 };
var ui18 = {
  /**
   * Shown on a button for adding additional items.
   */
  add: "Hozzáadás",
  /**
   * Shown when a button to remove items is visible.
   */
  remove: "Eltávolítás",
  /**
   * Shown when there are multiple items to remove at the same time.
   */
  removeAll: "Összes eltávolítása",
  /**
   * Shown when all fields are not filled out correctly.
   */
  incomplete: "Sajnáljuk, nem minden mező lett helyesen kitöltve.",
  /**
   * Shown in a button inside a form to submit the form.
   */
  submit: "Beküldés",
  /**
   * Shown when no files are selected.
   */
  noFiles: "Nincs fájl kiválasztva",
  /**
   * Shown on buttons that move fields up in a list.
   */
  moveUp: "Mozgás felfelé",
  /**
   * Shown on buttons that move fields down in a list.
   */
  moveDown: "Mozgás lefelé",
  /**
   * Shown when something is actively loading.
   */
  isLoading: "Betöltés...",
  /**
   * Shown when there is more to load.
   */
  loadMore: "Töltsön be többet",
  /**
   * Shown on buttons that navigate state forward
   */
  next: "Következő",
  /**
   * Shown on buttons that navigate state backward
   */
  prev: "Előző",
  /**
   * Shown when adding all values.
   */
  addAllValues: "Adja hozzá az összes értéket",
  /**
   * Shown when adding selected values.
   */
  addSelectedValues: "Kiválasztott értékek hozzáadása",
  /**
   * Shown when removing all values.
   */
  removeAllValues: "Távolítsa el az összes értéket",
  /**
   * Shown when removing selected values.
   */
  removeSelectedValues: "A kiválasztott értékek eltávolítása",
  /**
   * Shown when there is a date to choose.
   */
  chooseDate: "Válassza ki a dátumot",
  /**
   * Shown when there is a date to change.
   */
  changeDate: "Dátum módosítása",
  /**
   * Shown when there is something to close
   */
  close: "Bezárás",
  /**
   * Shown when there is something to open.
   */
  open: "Nyitott"
};
var validation18 = {
  /**
   * The value is not an accepted value.
   * @see {@link https://formkit.com/essentials/validation#accepted}
   */
  accepted({ name }) {
    return `Fogadja el a ${name} mezőt.`;
  },
  /**
   * The date is not after
   * @see {@link https://formkit.com/essentials/validation#date-after}
   */
  date_after({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${sentence(name)} mezőnek ${date(args[0])} után kell lennie.`;
    }
    return `${sentence(name)} mezőnek a jövőben kell lennie.`;
  },
  /**
   * The value is not a letter.
   * @see {@link https://formkit.com/essentials/validation#alpha}
   */
  alpha({ name }) {
    return `${sentence(name)} csak alfanumerikus karaktereket tartalmazhat.`;
  },
  /**
   * The value is not alphanumeric
   * @see {@link https://formkit.com/essentials/validation#alphanumeric}
   */
  alphanumeric({ name }) {
    return `${sentence(name)} csak betűket és számokat tartalmazhat.`;
  },
  /**
   * The value is not letter and/or spaces
   * @see {@link https://formkit.com/essentials/validation#alpha-spaces}
   */
  alpha_spaces({ name }) {
    return `${sentence(name)} csak betűket és szóközöket tartalmazhat.`;
  },
  /**
   * The value have no letter.
   * @see {@link https://formkit.com/essentials/validation#contains_alpha}
   */
  contains_alpha({ name }) {
    return `A ${sentence(name)} betűrendes karaktereket kell tartalmaznia.`;
  },
  /**
   * The value have no alphanumeric
   * @see {@link https://formkit.com/essentials/validation#contains_alphanumeric}
   */
  contains_alphanumeric({ name }) {
    return `A ${sentence(name)} betűket vagy számokat kell tartalmaznia.`;
  },
  /**
   * The value have no letter and/or spaces
   * @see {@link https://formkit.com/essentials/validation#contains_alpha-spaces}
   */
  contains_alpha_spaces({ name }) {
    return `A ${sentence(name)} betűket vagy szóközöket kell tartalmaznia.`;
  },
  /**
   * The value have no symbol
   * @see {@link https://formkit.com/essentials/validation#contains_symbol}
   */
  contains_symbol({ name }) {
    return `A ${sentence(name)} szimbólumot kell tartalmaznia.`;
  },
  /**
   * The value have no uppercase
   * @see {@link https://formkit.com/essentials/validation#contains_uppercase}
   */
  contains_uppercase({ name }) {
    return `A ${sentence(name)} nagybetűt kell tartalmaznia.`;
  },
  /**
   * The value have no lowercase
   * @see {@link https://formkit.com/essentials/validation#contains_lowercase}
   */
  contains_lowercase({ name }) {
    return `A ${sentence(name)} kisbetűt kell tartalmaznia.`;
  },
  /**
   *  The value have no numeric
   * @see {@link https://formkit.com/essentials/validation#contains_numeric}
   */
  contains_numeric({ name }) {
    return `A ${sentence(name)} számot kell tartalmaznia.`;
  },
  /**
   * The value is not symbol
   * @see {@link https://formkit.com/essentials/validation#symbol}
   */
  symbol({ name }) {
    return `A ${sentence(name)} szimbólumnak kell lennie.`;
  },
  /**
   * The value is not uppercase
   * @see {@link https://formkit.com/essentials/validation#uppercase}
   */
  uppercase({ name }) {
    return `A ${sentence(name)} csak nagybetűket tartalmazhat.`;
  },
  /**
   * The value is not lowercase
   * @see {@link https://formkit.com/essentials/validation#lowercase}
   */
  lowercase({ name }) {
    return `A ${sentence(name)} csak kisbetűket tartalmazhat.`;
  },
  /**
   * The date is not before
   * @see {@link https://formkit.com/essentials/validation#date-before}
   */
  date_before({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${sentence(name)} mezőnek ${date(args[0])} előtt kell lennie.`;
    }
    return `${sentence(name)} mezőnek a múltban kell lennie.`;
  },
  /**
   * The value is not between two numbers
   * @see {@link https://formkit.com/essentials/validation#between}
   */
  between({ name, args }) {
    if (isNaN(args[0]) || isNaN(args[1])) {
      return `Ez a mező hibásan lett konfigurálva, így nem lehet beküldeni.`;
    }
    const [a, b] = order(args[0], args[1]);
    return `A ${sentence(name)} mezőnek ${a} és ${b} között kell lennie.`;
  },
  /**
   * The confirmation field does not match
   * @see {@link https://formkit.com/essentials/validation#confirm}
   */
  confirm({ name }) {
    return `${sentence(name)} nem egyezik.`;
  },
  /**
   * The value is not a valid date
   * @see {@link https://formkit.com/essentials/validation#date-format}
   */
  date_format({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${sentence(name)} nem érvényes dátum, ${args[0]} formátumot használj`;
    }
    return "Ez a mező hibásan lett konfigurálva, így nem lehet beküldeni.";
  },
  /**
   * Is not within expected date range
   * @see {@link https://formkit.com/essentials/validation#date-between}
   */
  date_between({ name, args }) {
    return `${sentence(name)} mezőnek ${date(args[0])} és ${args[1]} között kell lennie`;
  },
  /**
   * Shown when the user-provided value is not a valid email address.
   * @see {@link https://formkit.com/essentials/validation#email}
   */
  email: "Kérjük, érvényes email címet adjon meg.",
  /**
   * Does not end with the specified value
   * @see {@link https://formkit.com/essentials/validation#ends-with}
   */
  ends_with({ name, args }) {
    return `${sentence(name)} mező nem a kijelölt (${list(args)}) módon ér véget.`;
  },
  /**
   * Is not an allowed value
   * @see {@link https://formkit.com/essentials/validation#is}
   */
  is({ name }) {
    return `${sentence(name)} nem engedélyezett érték.`;
  },
  /**
   * Does not match specified length
   * @see {@link https://formkit.com/essentials/validation#length}
   */
  length({ name, args: [first = 0, second = Infinity] }) {
    const min = Number(first) <= Number(second) ? first : second;
    const max = Number(second) >= Number(first) ? second : first;
    if (min == 1 && max === Infinity) {
      return `${sentence(name)} mezőnek legalább egy karakteresnek kell lennie.`;
    }
    if (min == 0 && max) {
      return `${sentence(name)} mezőnek maximum ${max} karakteresnek kell lennie.`;
    }
    if (min === max) {
      return `${sentence(name)} ${max} karakter hosszúnak kell lennie.`;
    }
    if (min && max === Infinity) {
      return `${sentence(name)} mezőnek minimum ${min} karakteresnek kell lennie.`;
    }
    return `${sentence(name)} mezőnek ${min} és ${max} karakter között kell lennie.`;
  },
  /**
   * Value is not a match
   * @see {@link https://formkit.com/essentials/validation#matches}
   */
  matches({ name }) {
    return `${sentence(name)} nem engedélyezett érték.`;
  },
  /**
   * Exceeds maximum allowed value
   * @see {@link https://formkit.com/essentials/validation#max}
   */
  max({ name, node: { value }, args }) {
    if (Array.isArray(value)) {
      return `Nem lehet több mint ${args[0]} ${name}.`;
    }
    return `${sentence(name)} nem lehet nagyobb, mint ${args[0]}.`;
  },
  /**
   * The (field-level) value does not match specified mime type
   * @see {@link https://formkit.com/essentials/validation#mime}
   */
  mime({ name, args }) {
    if (!args[0]) {
      return "Nincsenek támogatott fájlformátumok.";
    }
    return `${sentence(name)}-nak/nek a következőnek kell lennie: ${args[0]}`;
  },
  /**
   * Does not fulfill minimum allowed value
   * @see {@link https://formkit.com/essentials/validation#min}
   */
  min({ name, node: { value }, args }) {
    if (Array.isArray(value)) {
      return `Nem lehet kevesebb, mint ${args[0]} ${name}.`;
    }
    return `${sentence(name)}-nak/nek minimum ${args[0]}-nak/nek kell lennie.`;
  },
  /**
   * Is not an allowed value
   * @see {@link https://formkit.com/essentials/validation#not}
   */
  not({ name, node: { value } }) {
    return `"${value}" nem engedélyezett ${name}.`;
  },
  /**
   *  Is not a number
   * @see {@link https://formkit.com/essentials/validation#number}
   */
  number({ name }) {
    return `${sentence(name)} mezőnek számnak kell lennie.`;
  },
  /**
   * Require one field.
   * @see {@link https://formkit.com/essentials/validation#require-one}
   */
  require_one: ({ name, node, args: inputNames }) => {
    const labels = inputNames.map((name2) => {
      const dependentNode = node.at(name2);
      if (dependentNode) {
        return createMessageName(dependentNode);
      }
      return false;
    }).filter((name2) => !!name2);
    labels.unshift(name);
    return `${labels.join(" vagy ")} szükséges.`;
  },
  /**
   * Required field.
   * @see {@link https://formkit.com/essentials/validation#required}
   */
  required({ name }) {
    return `${sentence(name)} mező kötelező.`;
  },
  /**
   * Does not start with specified value
   * @see {@link https://formkit.com/essentials/validation#starts-with}
   */
  starts_with({ name, args }) {
    return `${sentence(name)} nem a következővel kezdődik: ${list(args)}.`;
  },
  /**
   * Is not a url
   * @see {@link https://formkit.com/essentials/validation#url}
   */
  url() {
    return `Kérjük, adjon meg egy érvényes URL-t.`;
  },
  /**
   * Shown when the date is invalid.
   */
  invalidDate: "A kiválasztott dátum érvénytelen."
};
var hu = { ui: ui18, validation: validation18 };
var ui19 = {
  /**
   * Shown on buttons for adding new items.
   */
  add: "Tambah",
  /**
   * Shown when a button to remove items is visible.
   */
  remove: "Hapus",
  /**
   * Shown when there are multiple items to remove at the same time.
   */
  removeAll: "Hapus semua",
  /**
   * Shown when all fields are not filled out correctly.
   */
  incomplete: "Maaf, tidak semua bidang formulir terisi dengan benar",
  /**
   * Shown in a button inside a form to submit the form.
   */
  submit: "Kirim",
  /**
   * Shown when no files are selected.
   */
  noFiles: "Tidak ada file yang dipilih",
  /**
   * Shown on buttons that move fields up in a list.
   */
  moveUp: "Pindah ke atas",
  /**
   * Shown on buttons that move fields down in a list.
   */
  moveDown: "Pindah ke bawah",
  /**
   * Shown when something is actively loading.
   */
  isLoading: "Memuat...",
  /**
   * Shown when there is more to load.
   */
  loadMore: "Muat lebih",
  /**
   * Shown on buttons that navigate state forward
   */
  next: "Berikutnya",
  /**
   * Shown on buttons that navigate state backward
   */
  prev: "Sebelumnya",
  /**
   * Shown when adding all values.
   */
  addAllValues: "Tambahkan semua nilai",
  /**
   * Shown when adding selected values.
   */
  addSelectedValues: "Tambahkan nilai yang dipilih",
  /**
   * Shown when removing all values.
   */
  removeAllValues: "Hapus semua nilai",
  /**
   * Shown when removing selected values.
   */
  removeSelectedValues: "Hapus nilai yang dipilih",
  /**
   * Shown when there is a date to choose.
   */
  chooseDate: "Pilih tanggal",
  /**
   * Shown when there is a date to change.
   */
  changeDate: "Ubah tanggal",
  /**
   * Shown when there is something to close
   */
  close: "Tutup",
  /**
   * Shown when there is something to open.
   */
  open: "Buka"
};
var validation19 = {
  /**
   * The value is not an accepted value.
   * @see {@link https://formkit.com/essentials/validation#accepted}
   */
  accepted({ name }) {
    return `Tolong terima kolom ${name}.`;
  },
  /**
   * The date is not after
   * @see {@link https://formkit.com/essentials/validation#date-after}
   */
  date_after({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${sentence(name)} nilainya harus lebih dari waktu ${date(args[0])}.`;
    }
    return `${sentence(name)} harus berisi waktu di masa depan.`;
  },
  /**
   * The value is not a letter.
   * @see {@link https://formkit.com/essentials/validation#alpha}
   */
  alpha({ name }) {
    return `${sentence(name)} hanya bisa diisi huruf alfabet.`;
  },
  /**
   * The value is not alphanumeric
   * @see {@link https://formkit.com/essentials/validation#alphanumeric}
   */
  alphanumeric({ name }) {
    return `${sentence(name)} hanya bisa diisi huruf dan angka.`;
  },
  /**
   * The value is not letter and/or spaces
   * @see {@link https://formkit.com/essentials/validation#alpha-spaces}
   */
  alpha_spaces({ name }) {
    return `${sentence(name)} hanya boleh berisi huruf dan spasi..`;
  },
  /**
   * The value have no letter.
   * @see {@link https://formkit.com/essentials/validation#contains_alpha}
   */
  contains_alpha({ name }) {
    return `${sentence(name)} harus berisi karakter abjad.`;
  },
  /**
   * The value have no alphanumeric
   * @see {@link https://formkit.com/essentials/validation#contains_alphanumeric}
   */
  contains_alphanumeric({ name }) {
    return `${sentence(name)} harus mengandung huruf atau angka.`;
  },
  /**
   * The value have no letter and/or spaces
   * @see {@link https://formkit.com/essentials/validation#contains_alpha-spaces}
   */
  contains_alpha_spaces({ name }) {
    return `${sentence(name)} harus berisi huruf atau spasi.`;
  },
  /**
   * The value have no symbol
   * @see {@link https://formkit.com/essentials/validation#contains_symbol}
   */
  contains_symbol({ name }) {
    return `${sentence(name)} harus berisi simbol.`;
  },
  /**
   * The value have no uppercase
   * @see {@link https://formkit.com/essentials/validation#contains_uppercase}
   */
  contains_uppercase({ name }) {
    return `${sentence(name)} harus berisi huruf besar.`;
  },
  /**
   * The value have no lowercase
   * @see {@link https://formkit.com/essentials/validation#contains_lowercase}
   */
  contains_lowercase({ name }) {
    return `${sentence(name)} harus berisi huruf kecil.`;
  },
  /**
   *  The value have no numeric
   * @see {@link https://formkit.com/essentials/validation#contains_numeric}
   */
  contains_numeric({ name }) {
    return `${sentence(name)} harus berisi angka.`;
  },
  /**
   * The value is not symbol
   * @see {@link https://formkit.com/essentials/validation#symbol}
   */
  symbol({ name }) {
    return `${sentence(name)} harus berupa simbol.`;
  },
  /**
   * The value is not uppercase
   * @see {@link https://formkit.com/essentials/validation#uppercase}
   */
  uppercase({ name }) {
    return `${sentence(name)} hanya dapat berisi huruf besar.`;
  },
  /**
   * The value is not lowercase
   * @see {@link https://formkit.com/essentials/validation#lowercase}
   */
  lowercase({ name }) {
    return `${sentence(name)} hanya dapat berisi huruf kecil.`;
  },
  /**
   * The date is not before
   * @see {@link https://formkit.com/essentials/validation#date-before}
   */
  date_before({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${sentence(name)} nilainya harus kurang dari waktu ${date(args[0])}.`;
    }
    return `${sentence(name)} harus berisi waktu yang sudah lampau.`;
  },
  /**
   * The value is not between two numbers
   * @see {@link https://formkit.com/essentials/validation#between}
   */
  between({ name, args }) {
    if (isNaN(args[0]) || isNaN(args[1])) {
      return `Kolom ini tidak diisi dengan benar sehingga tidak bisa dikirim`;
    }
    const [a, b] = order(args[0], args[1]);
    return `${sentence(name)} harus bernilai diantara ${a} dan ${b}.`;
  },
  /**
   * The confirmation field does not match
   * @see {@link https://formkit.com/essentials/validation#confirm}
   */
  confirm({ name }) {
    return `${sentence(name)} nilainya tidak cocok.`;
  },
  /**
   * The value is not a valid date
   * @see {@link https://formkit.com/essentials/validation#date-format}
   */
  date_format({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${sentence(name)} waktu tidak cocok, mohon gunakan format waktu ${args[0]}`;
    }
    return "Kolom ini tidak diisi dengan benar sehingga tidak bisa dikirim";
  },
  /**
   * Is not within expected date range
   * @see {@link https://formkit.com/essentials/validation#date-between}
   */
  date_between({ name, args }) {
    return `${sentence(name)} harus diantara waktu ${date(args[0])} dan waktu ${date(
      args[1]
    )}`;
  },
  /**
   * Shown when the user-provided value is not a valid email address.
   * @see {@link https://formkit.com/essentials/validation#email}
   */
  email: "Tolong tulis alamat email yang benar.",
  /**
   * Does not end with the specified value
   * @see {@link https://formkit.com/essentials/validation#ends-with}
   */
  ends_with({ name, args }) {
    return `${sentence(name)} nilainya tidak berakhiran dengan ${list(args)}.`;
  },
  /**
   * Is not an allowed value
   * @see {@link https://formkit.com/essentials/validation#is}
   */
  is({ name }) {
    return `${sentence(name)} adalah nilai yang tidak diizinkan.`;
  },
  /**
   * Does not match specified length
   * @see {@link https://formkit.com/essentials/validation#length}
   */
  length({ name, args: [first = 0, second = Infinity] }) {
    const min = Number(first) <= Number(second) ? first : second;
    const max = Number(second) >= Number(first) ? second : first;
    if (min == 1 && max === Infinity) {
      return `${sentence(name)} nilainya setidaknya berisi satu karakter.`;
    }
    if (min == 0 && max) {
      return `${sentence(
        name
      )} jumlah karakternya harus kurang dari atau sama dengan ${max} karakter.`;
    }
    if (min === max) {
      return `${sentence(name)} harus ${max} karakter panjang.`;
    }
    if (min && max === Infinity) {
      return `${sentence(
        name
      )} jumlah karakternya harus lebih dari atau sama dengan ${min} karakter.`;
    }
    return `${sentence(
      name
    )} jumlah karakternya hanya bisa antara ${min} dan ${max} karakter.`;
  },
  /**
   * Value is not a match
   * @see {@link https://formkit.com/essentials/validation#matches}
   */
  matches({ name }) {
    return `${sentence(name)} nilainya tidak diizinkan.`;
  },
  /**
   * Exceeds maximum allowed value
   * @see {@link https://formkit.com/essentials/validation#max}
   */
  max({ name, node: { value }, args }) {
    if (Array.isArray(value)) {
      return `Tidak bisa memiliki lebih dari ${args[0]} ${name}.`;
    }
    return `${sentence(name)} harus lebih kecil atau sama dengan ${args[0]}.`;
  },
  /**
   * The (field-level) value does not match specified mime type
   * @see {@link https://formkit.com/essentials/validation#mime}
   */
  mime({ name, args }) {
    if (!args[0]) {
      return "Format file tidak diizinkan";
    }
    return `${sentence(name)} hanya bisa bertipe: ${args[0]}`;
  },
  /**
   * Does not fulfill minimum allowed value
   * @see {@link https://formkit.com/essentials/validation#min}
   */
  min({ name, node: { value }, args }) {
    if (Array.isArray(value)) {
      return `Tidak boleh kurang dari ${args[0]} ${name}.`;
    }
    return `${sentence(name)} setidaknya harus berisi ${args[0]}.`;
  },
  /**
   * Is not an allowed value
   * @see {@link https://formkit.com/essentials/validation#not}
   */
  not({ name, node: { value } }) {
    return `“${value}” adalah nilai yang tidak diperbolehkan untuk ${name}.`;
  },
  /**
   *  Is not a number
   * @see {@link https://formkit.com/essentials/validation#number}
   */
  number({ name }) {
    return `${sentence(name)} harus berupa angka.`;
  },
  /**
   * Require one field.
   * @see {@link https://formkit.com/essentials/validation#require-one}
   */
  require_one: ({ name, node, args: inputNames }) => {
    const labels = inputNames.map((name2) => {
      const dependentNode = node.at(name2);
      if (dependentNode) {
        return createMessageName(dependentNode);
      }
      return false;
    }).filter((name2) => !!name2);
    labels.unshift(name);
    return `${labels.join(" atau ")} diperlukan`;
  },
  /**
   * Required field.
   * @see {@link https://formkit.com/essentials/validation#required}
   */
  required({ name }) {
    return `${sentence(name)} harus diisi.`;
  },
  /**
   * Does not start with specified value
   * @see {@link https://formkit.com/essentials/validation#starts-with}
   */
  starts_with({ name, args }) {
    return `${sentence(name)} tidak dimulai dengan ${list(args)}.`;
  },
  /**
   * Is not a url
   * @see {@link https://formkit.com/essentials/validation#url}
   */
  url() {
    return `Harap masukkan URL yang valid.`;
  },
  /**
   * Shown when the date is invalid.
   */
  invalidDate: "Tanggal yang dipilih tidak valid."
};
var id = { ui: ui19, validation: validation19 };
var ui20 = {
  /**
   * Shown on a button for adding additional items.
   */
  add: "Bæta við",
  /**
   * Shown when a button to remove items is visible.
   */
  remove: "Fjarlægja",
  /**
   * Shown when there are multiple items to remove at the same time.
   */
  removeAll: "Fjarlægja allt",
  /**
   * Shown when all fields are not filled out correctly.
   */
  incomplete: "Því miður, það er ekki búið að fylla rétt inn í alla reiti.",
  /**
   * Shown in a button inside a form to submit the form.
   */
  submit: "Senda",
  /**
   * Shown when no files are selected.
   */
  noFiles: "Engin skrá valin",
  /**
   * Shown on buttons that move fields up in a list.
   */
  moveUp: "Færa upp",
  /**
   * Shown on buttons that move fields down in a list.
   */
  moveDown: "Færa niður",
  /**
   * Shown when something is actively loading.
   */
  isLoading: "Hleðsla...",
  /**
   * Shown when there is more to load.
   */
  loadMore: "Sækja meira",
  /**
   * Show on buttons that navigate state forward
   */
  next: "Áfram",
  /**
   * Show on buttons that navigate state backward
   */
  prev: "Til baka",
  /**
   * Shown when adding all values.
   */
  addAllValues: "Bæta við öllum gildum",
  /**
   * Shown when adding selected values.
   */
  addSelectedValues: "Bæta við völdum gildum",
  /**
   * Shown when removing all values.
   */
  removeAllValues: "Fjarlægja öll gildi",
  /**
   * Shown when removing selected values.
   */
  removeSelectedValues: "Fjarlægja valin gildi",
  /**
   * Shown when there is a date to choose.
   */
  chooseDate: "Velja dagsetningu",
  /**
   * Shown when there is a date to change.
   */
  changeDate: "Breyta dagsetningu",
  /**
   * Shown when there is something to close
   */
  close: "Loka",
  /**
   * Shown when there is something to open.
   */
  open: "Opið"
};
var validation20 = {
  /**
   * The value is not an accepted value.
   * @see {@link https://formkit.com/essentials/validation#accepted}
   */
  accepted({ name }) {
    return `Vinsamlegast samþykktu ${name}`;
  },
  /**
   * The date is not after
   * @see {@link https://formkit.com/essentials/validation#date-after}
   */
  date_after({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${sentence(name)} þarf að vera eftir ${date(args[0])}.`;
    }
    return `${sentence(name)} þarf að vera í framtíðinni.`;
  },
  /**
   * The value is not a letter.
   * @see {@link https://formkit.com/essentials/validation#alpha}
   */
  alpha({ name }) {
    return `${sentence(name)} má einungis innihalda bókstafi.`;
  },
  /**
   * The value is not alphanumeric
   * @see {@link https://formkit.com/essentials/validation#alphanumeric}
   */
  alphanumeric({ name }) {
    return `${sentence(name)} má einungis innihalda bókstafi og tölur.`;
  },
  /**
   * The value is not letter and/or spaces
   * @see {@link https://formkit.com/essentials/validation#alpha-spaces}
   */
  alpha_spaces({ name }) {
    return `${sentence(name)} má einungis innihalda bókstafi og bil.`;
  },
  /**
   * The value have no letter.
   * @see {@link https://formkit.com/essentials/validation#contains_alpha}
   */
  contains_alpha({ name }) {
    return `${sentence(name)} verður að innihalda bókstafi.`;
  },
  /**
   * The value have no alphanumeric
   * @see {@link https://formkit.com/essentials/validation#contains_alphanumeric}
   */
  contains_alphanumeric({ name }) {
    return `${sentence(name)} verður að innihalda bókstafi eða tölur.`;
  },
  /**
   * The value have no letter and/or spaces
   * @see {@link https://formkit.com/essentials/validation#contains_alpha-spaces}
   */
  contains_alpha_spaces({ name }) {
    return `${sentence(name)} verður að innihalda bókstafi eða bil.`;
  },
  /**
   * The value have no symbol
   * @see {@link https://formkit.com/essentials/validation#contains_symbol}
   */
  contains_symbol({ name }) {
    return `${sentence(name)} verður að innihalda tákn.`;
  },
  /**
   * The value have no uppercase
   * @see {@link https://formkit.com/essentials/validation#contains_uppercase}
   */
  contains_uppercase({ name }) {
    return `${sentence(name)} verður að innihalda hástaf.`;
  },
  /**
   * The value have no lowercase
   * @see {@link https://formkit.com/essentials/validation#contains_lowercase}
   */
  contains_lowercase({ name }) {
    return `${sentence(name)} verður að innihalda lágstaf.`;
  },
  /**
   *  The value have no numeric
   * @see {@link https://formkit.com/essentials/validation#contains_numeric}
   */
  contains_numeric({ name }) {
    return `${sentence(name)} verður að innihalda tölur.`;
  },
  /**
   * The value is not symbol
   * @see {@link https://formkit.com/essentials/validation#symbol}
   */
  symbol({ name }) {
    return `${sentence(name)} verður að vera tákn.`;
  },
  /**
   * The value is not uppercase
   * @see {@link https://formkit.com/essentials/validation#uppercase}
   */
  uppercase({ name }) {
    return `${sentence(name)} má einungis innihalda hástafi.`;
  },
  /**
   * The value is not lowercase
   * @see {@link https://formkit.com/essentials/validation#lowercase}
   */
  lowercase({ name }) {
    return `${sentence(name)} má einungis innihalda lágstafi.`;
  },
  /**
   * The date is not before
   * @see {@link https://formkit.com/essentials/validation#date-before}
   */
  date_before({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${sentence(name)} þarf að vera á undan ${date(args[0])}.`;
    }
    return `${sentence(name)} þarf að vera liðin.`;
  },
  /**
   * The value is not between two numbers
   * @see {@link https://formkit.com/essentials/validation#between}
   */
  between({ name, args }) {
    if (isNaN(args[0]) || isNaN(args[1])) {
      return `Þessi reitur var ekki rétt stilltur.`;
    }
    const [a, b] = order(args[0], args[1]);
    return `${sentence(name)} þarf að vera á milli ${a} og ${b}.`;
  },
  /**
   * The confirmation field does not match
   * @see {@link https://formkit.com/essentials/validation#confirm}
   */
  confirm({ name }) {
    return `${sentence(name)} passar ekki.`;
  },
  /**
   * The value is not a valid date
   * @see {@link https://formkit.com/essentials/validation#date-format}
   */
  date_format({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${sentence(
        name
      )} er ekki gild dagsetning, vinsamlegast hafið dagsetninguna í formi ${args[0]}`;
    }
    return "Þessi reitur var ekki rétt stilltur";
  },
  /**
   * Is not within expected date range
   * @see {@link https://formkit.com/essentials/validation#date-between}
   */
  date_between({ name, args }) {
    return `${sentence(name)} þarf að vera á milli ${date(args[0])} og ${date(
      args[1]
    )}`;
  },
  /**
   * Shown when the user-provided value is not a valid email address.
   * @see {@link https://formkit.com/essentials/validation#email}
   */
  email: "Vinsamlegast sláðu inn gilt netfang.",
  /**
   * Does not end with the specified value
   * @see {@link https://formkit.com/essentials/validation#ends-with}
   */
  ends_with({ name, args }) {
    return `${sentence(name)} endar ekki á ${list(args)}.`;
  },
  /**
   * Is not an allowed value
   * @see {@link https://formkit.com/essentials/validation#is}
   */
  is({ name }) {
    return `${sentence(name)} er ekki leyfilegt gildi.`;
  },
  /**
   * Does not match specified length
   * @see {@link https://formkit.com/essentials/validation#length}
   */
  length({ name, args: [first = 0, second = Infinity] }) {
    const min = Number(first) <= Number(second) ? first : second;
    const max = Number(second) >= Number(first) ? second : first;
    if (min == 1 && max === Infinity) {
      return `${sentence(name)} þarf að vera að minnsta kosti einn stafur.`;
    }
    if (min == 0 && max) {
      return `${sentence(name)} þarf að vera færri en eða nákvæmlega ${max} stafir.`;
    }
    if (min === max) {
      return `${sentence(name)} þarf að vera ${max} stafir að lengd.`;
    }
    if (min && max === Infinity) {
      return `${sentence(name)} þarf að vera fleiri en eða nákvæmlega ${min} stafir.`;
    }
    return `${sentence(name)} þarf að vera á milli ${min} og ${max} stafir.`;
  },
  /**
   * Value is not a match
   * @see {@link https://formkit.com/essentials/validation#matches}
   */
  matches({ name }) {
    return `${sentence(name)} er ekki leyfilegt gildi.`;
  },
  /**
   * Exceeds maximum allowed value
   * @see {@link https://formkit.com/essentials/validation#max}
   */
  max({ name, node: { value }, args }) {
    if (Array.isArray(value)) {
      return `Ekki hægt að hafa fleiri en ${args[0]} ${name}.`;
    }
    return `${sentence(name)} þarf að vera minna en eða nákvæmlega ${args[0]}.`;
  },
  /**
   * The (field-level) value does not match specified mime type
   * @see {@link https://formkit.com/essentials/validation#mime}
   */
  mime({ name, args }) {
    if (!args[0]) {
      return "Ekki leyfileg tegund skráar.";
    }
    return `${sentence(name)} þarf að vera af tegundinni: ${args[0]}`;
  },
  /**
   * Does not fulfill minimum allowed value
   * @see {@link https://formkit.com/essentials/validation#min}
   */
  min({ name, node: { value }, args }) {
    if (Array.isArray(value)) {
      return `Ekki hægt að hafa færri en ${args[0]} ${name}.`;
    }
    return `Þarf að vera að minnsta kosti ${args[0]} ${name}.`;
  },
  /**
   * Is not an allowed value
   * @see {@link https://formkit.com/essentials/validation#not}
   */
  not({ name, node: { value } }) {
    return `“${value}” er ekki leyfilegt fyrir ${name}.`;
  },
  /**
   *  Is not a number
   * @see {@link https://formkit.com/essentials/validation#number}
   */
  number({ name }) {
    return `${sentence(name)} þarf að vera tala.`;
  },
  /**
   * Require one field.
   * @see {@link https://formkit.com/essentials/validation#require-one}
   */
  require_one: ({ name, node, args: inputNames }) => {
    const labels = inputNames.map((name2) => {
      const dependentNode = node.at(name2);
      if (dependentNode) {
        return createMessageName(dependentNode);
      }
      return false;
    }).filter((name2) => !!name2);
    labels.unshift(name);
    return `${labels.join(" or ")} is required.`;
  },
  /**
   * Required field.
   * @see {@link https://formkit.com/essentials/validation#required}
   */
  required({ name }) {
    return `${sentence(name)} er skilyrt.`;
  },
  /**
   * Does not start with specified value
   * @see {@link https://formkit.com/essentials/validation#starts-with}
   */
  starts_with({ name, args }) {
    return `${sentence(name)} byrjar ekki á ${list(args)}.`;
  },
  /**
   * Is not a url
   * @see {@link https://formkit.com/essentials/validation#url}
   */
  url() {
    return `Vinsamlegast sláðu inn gilda slóð.`;
  },
  /**
   * Shown when the date is invalid.
   */
  invalidDate: "Valin dagsetning er ógild"
};
var is = { ui: ui20, validation: validation20 };
var ui21 = {
  /**
   * Shown on buttons for adding new items.
   */
  add: "Inserisci",
  /**
   * Shown when a button to remove items is visible.
   */
  remove: "Rimuovi",
  /**
   * Shown when there are multiple items to remove at the same time.
   */
  removeAll: "Rimuovi tutti",
  /**
   * Shown when all fields are not filled out correctly.
   */
  incomplete: "Ci dispiace, non tutti i campi sono compilati correttamente.",
  /**
   * Shown in a button inside a form to submit the form.
   */
  submit: "Invia",
  /**
   * Shown when no files are selected.
   */
  noFiles: "Nessun file selezionato",
  /**
   * Shown on buttons that move fields up in a list.
   */
  moveUp: "Sposta in alto",
  /**
   * Shown on buttons that move fields down in a list.
   */
  moveDown: "Sposta giù",
  /**
   * Shown when something is actively loading.
   */
  isLoading: "Caricamento...",
  /**
   * Shown when there is more to load.
   */
  loadMore: "Carica altro",
  /**
   * Shown on buttons that navigate state forward
   */
  next: "Prossimo",
  /**
   * Shown on buttons that navigate state backward
   */
  prev: "Precedente",
  /**
   * Shown when adding all values.
   */
  addAllValues: "Aggiungi tutti i valori",
  /**
   * Shown when adding selected values.
   */
  addSelectedValues: "Aggiungi valori selezionati",
  /**
   * Shown when removing all values.
   */
  removeAllValues: "Rimuovi tutti i valori",
  /**
   * Shown when removing selected values.
   */
  removeSelectedValues: "Rimuovi i valori selezionati",
  /**
   * Shown when there is a date to choose.
   */
  chooseDate: "Scegli la data",
  /**
   * Shown when there is a date to change.
   */
  changeDate: "Cambia data",
  /**
   * Shown when there is something to close
   */
  close: "Chiudi",
  /**
   * Shown when there is something to open.
   */
  open: "Aperta"
};
var validation21 = {
  /**
   * The value is not an accepted value.
   * @see {@link https://formkit.com/essentials/validation#accepted}
   */
  accepted({ name }) {
    return `Si prega di accettare ${name}.`;
  },
  /**
   * The date is not after
   * @see {@link https://formkit.com/essentials/validation#date-after}
   */
  date_after({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `la data ${sentence(name)} deve essere successiva ${date(args[0])}.`;
    }
    return `la data ${sentence(name)} deve essere nel futuro.`;
  },
  /**
   * The value is not a letter.
   * @see {@link https://formkit.com/essentials/validation#alpha}
   */
  alpha({ name }) {
    return `${sentence(name)} può contenere solo caratteri alfanumerici.`;
  },
  /**
   * The value is not alphanumeric
   * @see {@link https://formkit.com/essentials/validation#alphanumeric}
   */
  alphanumeric({ name }) {
    return `${sentence(name)} può contenere solo lettere e numeri.`;
  },
  /**
   * The value is not letter and/or spaces
   * @see {@link https://formkit.com/essentials/validation#alpha-spaces}
   */
  alpha_spaces({ name }) {
    return `${sentence(name)} può contenere solo lettere e spazi.`;
  },
  /**
   * The value have no letter.
   * @see {@link https://formkit.com/essentials/validation#contains_alpha}
   */
  contains_alpha({ name }) {
    return `${sentence(name)} deve contenere caratteri alfabetici.`;
  },
  /**
   * The value have no alphanumeric
   * @see {@link https://formkit.com/essentials/validation#contains_alphanumeric}
   */
  contains_alphanumeric({ name }) {
    return `${sentence(name)} deve contenere lettere o numeri.`;
  },
  /**
   * The value have no letter and/or spaces
   * @see {@link https://formkit.com/essentials/validation#contains_alpha-spaces}
   */
  contains_alpha_spaces({ name }) {
    return `${sentence(name)} deve contenere lettere o spazi.`;
  },
  /**
   * The value have no symbol
   * @see {@link https://formkit.com/essentials/validation#contains_symbol}
   */
  contains_symbol({ name }) {
    return `${sentence(name)} deve contenere un simbolo.`;
  },
  /**
   * The value have no uppercase
   * @see {@link https://formkit.com/essentials/validation#contains_uppercase}
   */
  contains_uppercase({ name }) {
    return `${sentence(name)} must contain uppercase.`;
  },
  /**
   * The value have no lowercase
   * @see {@link https://formkit.com/essentials/validation#contains_lowercase}
   */
  contains_lowercase({ name }) {
    return `${sentence(name)} deve contenere lettere minuscole.`;
  },
  /**
   *  The value have no numeric
   * @see {@link https://formkit.com/essentials/validation#contains_numeric}
   */
  contains_numeric({ name }) {
    return `${sentence(name)} deve contenere numeri.`;
  },
  /**
   * The value is not symbol
   * @see {@link https://formkit.com/essentials/validation#symbol}
   */
  symbol({ name }) {
    return `${sentence(name)} deve essere un simbolo.`;
  },
  /**
   * The value is not uppercase
   * @see {@link https://formkit.com/essentials/validation#uppercase}
   */
  uppercase({ name }) {
    return `${sentence(name)} può contenere solo lettere maiuscole.`;
  },
  /**
   * The value is not lowercase
   * @see {@link https://formkit.com/essentials/validation#lowercase}
   */
  lowercase({ name }) {
    return `${sentence(name)} può contenere solo lettere minuscole.`;
  },
  /**
   * The date is not before
   * @see {@link https://formkit.com/essentials/validation#date-before}
   */
  date_before({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `la data ${sentence(name)} deve essere antecedente ${date(args[0])}.`;
    }
    return `${sentence(name)} deve essere nel passato.`;
  },
  /**
   * The value is not between two numbers
   * @see {@link https://formkit.com/essentials/validation#between}
   */
  between({ name, args }) {
    if (isNaN(args[0]) || isNaN(args[1])) {
      return `Questo campo è stato configurato male e non può essere inviato.`;
    }
    const [a, b] = order(args[0], args[1]);
    return `${sentence(name)} deve essere tra ${a} e ${b}.`;
  },
  /**
   * The confirmation field does not match
   * @see {@link https://formkit.com/essentials/validation#confirm}
   */
  confirm({ name }) {
    return `${sentence(name)} non corrisponde.`;
  },
  /**
   * The value is not a valid date
   * @see {@link https://formkit.com/essentials/validation#date-format}
   */
  date_format({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${sentence(name)} non è una data valida, per favore usa il formato ${args[0]}`;
    }
    return "Questo campo è stato configurato in modo errato e non può essere inviato.";
  },
  /**
   * Is not within expected date range
   * @see {@link https://formkit.com/essentials/validation#date-between}
   */
  date_between({ name, args }) {
    return `${sentence(name)} deve essere tra ${date(args[0])} e ${date(args[1])}`;
  },
  /**
   * Shown when the user-provided value is not a valid email address.
   * @see {@link https://formkit.com/essentials/validation#email}
   */
  email: "Per favore inserire un indirizzo email valido.",
  /**
   * Does not end with the specified value
   * @see {@link https://formkit.com/essentials/validation#ends-with}
   */
  ends_with({ name, args }) {
    return `${sentence(name)} non termina con ${list(args)}.`;
  },
  /**
   * Is not an allowed value
   * @see {@link https://formkit.com/essentials/validation#is}
   */
  is({ name }) {
    return `${sentence(name)} non è un valore consentito.`;
  },
  /**
   * Does not match specified length
   * @see {@link https://formkit.com/essentials/validation#length}
   */
  length({ name, args: [first = 0, second = Infinity] }) {
    const min = Number(first) <= Number(second) ? first : second;
    const max = Number(second) >= Number(first) ? second : first;
    if (min == 1 && max === Infinity) {
      return `${sentence(name)} deve contenere almeno un carattere.`;
    }
    if (min == 0 && max) {
      return `${sentence(name)} deve essere minore o uguale a ${max} caratteri.`;
    }
    if (min === max) {
      return `${sentence(name)} deve contenere ${max} caratteri.`;
    }
    if (min && max === Infinity) {
      return `${sentence(name)} deve essere maggiore o uguale a ${min} caratteri.`;
    }
    return `${sentence(name)} deve essere tra ${min} e ${max} caratteri.`;
  },
  /**
   * Value is not a match
   * @see {@link https://formkit.com/essentials/validation#matches}
   */
  matches({ name }) {
    return `${sentence(name)} non è un valore consentito.`;
  },
  /**
   * Exceeds maximum allowed value
   * @see {@link https://formkit.com/essentials/validation#max}
   */
  max({ name, node: { value }, args }) {
    if (Array.isArray(value)) {
      return `Non può avere più di ${args[0]} ${name}.`;
    }
    return `${sentence(name)} deve essere minore o uguale a ${args[0]}.`;
  },
  /**
   * The (field-level) value does not match specified mime type
   * @see {@link https://formkit.com/essentials/validation#mime}
   */
  mime({ name, args }) {
    if (!args[0]) {
      return "Formato file non consentito.";
    }
    return `${sentence(name)} deve essere di tipo: ${args[0]}`;
  },
  /**
   * Does not fulfill minimum allowed value
   * @see {@link https://formkit.com/essentials/validation#min}
   */
  min({ name, node: { value }, args }) {
    if (Array.isArray(value)) {
      return `Non può avere meno di ${args[0]} ${name}.`;
    }
    return `${sentence(name)} deve essere almeno ${args[0]}.`;
  },
  /**
   * Is not an allowed value
   * @see {@link https://formkit.com/essentials/validation#not}
   */
  not({ name, node: { value } }) {
    return `"${value}" non è un ${name} consentito.`;
  },
  /**
   *  Is not a number
   * @see {@link https://formkit.com/essentials/validation#number}
   */
  number({ name }) {
    return `${sentence(name)} deve essere un numero.`;
  },
  /**
   * Require one field.
   * @see {@link https://formkit.com/essentials/validation#require-one}
   */
  require_one: ({ name, node, args: inputNames }) => {
    const labels = inputNames.map((name2) => {
      const dependentNode = node.at(name2);
      if (dependentNode) {
        return createMessageName(dependentNode);
      }
      return false;
    }).filter((name2) => !!name2);
    labels.unshift(name);
    return `${labels.join(" o ")} è richiesto.`;
  },
  /**
   * Required field.
   * @see {@link https://formkit.com/essentials/validation#required}
   */
  required({ name }) {
    return `${sentence(name)} è richiesto.`;
  },
  /**
   * Does not start with specified value
   * @see {@link https://formkit.com/essentials/validation#starts-with}
   */
  starts_with({ name, args }) {
    return `${sentence(name)} non inizia con ${list(args)}.`;
  },
  /**
   * Is not a url
   * @see {@link https://formkit.com/essentials/validation#url}
   */
  url() {
    return `Inserisci un URL valido.`;
  },
  /**
   * Shown when the date is invalid.
   */
  invalidDate: "La data selezionata non è valida."
};
var it = { ui: ui21, validation: validation21 };
var ui22 = {
  /**
   * Shown on buttons for adding new items.
   */
  add: "追加",
  /**
   * Shown when a button to remove items is visible.
   */
  remove: "削除",
  /**
   * Shown when there are multiple items to remove at the same time.
   */
  removeAll: "全て削除",
  /**
   * Shown when all fields are not filled out correctly.
   */
  incomplete: "項目が正しく入力されていません。",
  /**
   * Shown in a button inside a form to submit the form.
   */
  submit: "送信",
  /**
   * Shown when no files are selected.
   */
  noFiles: "ファイルが選択されていません",
  /**
   * Shown on buttons that move fields up in a list.
   */
  moveUp: "上に移動",
  /**
   * Shown on buttons that move fields down in a list.
   */
  moveDown: "下へ移動",
  /**
   * Shown when something is actively loading.
   */
  isLoading: "読み込み中...",
  /**
   * Shown when there is more to load.
   */
  loadMore: "さらに読み込む",
  /**
   * Shown on buttons that navigate state forward
   */
  next: "[次へ]",
  /**
   * Shown on buttons that navigate state backward
   */
  prev: "前へ",
  /**
   * Shown when adding all values.
   */
  addAllValues: "すべての値を追加",
  /**
   * Shown when adding selected values.
   */
  addSelectedValues: "選択した値を追加",
  /**
   * Shown when removing all values.
   */
  removeAllValues: "すべての値を削除",
  /**
   * Shown when removing selected values.
   */
  removeSelectedValues: "選択した値を削除",
  /**
   * Shown when there is a date to choose.
   */
  chooseDate: "日付を選択",
  /**
   * Shown when there is a date to change.
   */
  changeDate: "日付を変更",
  /**
   * Shown when there is something to close
   */
  close: "閉じる",
  /**
   * Shown when there is something to open.
   */
  open: "[開く]"
};
var validation22 = {
  /**
   * The value is not an accepted value.
   * @see {@link https://formkit.com/essentials/validation#accepted}
   */
  accepted({ name }) {
    return `${name}の同意が必要です。`;
  },
  /**
   * The date is not after
   * @see {@link https://formkit.com/essentials/validation#date-after}
   */
  date_after({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${sentence(name)}は${date(args[0])}より後の日付である必要があります。`;
    }
    return `${sentence(name)}は将来の日付でなければなりません。`;
  },
  /**
   * The value is not a letter.
   * @see {@link https://formkit.com/essentials/validation#alpha}
   */
  alpha({ name }) {
    return `${sentence(name)}には英字のみを含めることができます。`;
  },
  /**
   * The value is not alphanumeric
   * @see {@link https://formkit.com/essentials/validation#alphanumeric}
   */
  alphanumeric({ name }) {
    return `${sentence(name)}には、文字と数字のみを含めることができます。`;
  },
  /**
   * The value is not letter and/or spaces
   * @see {@link https://formkit.com/essentials/validation#alpha-spaces}
   */
  alpha_spaces({ name }) {
    return `${sentence(name)}には、文字とスペースのみを含めることができます。`;
  },
  /**
   * The value have no letter.
   * @see {@link https://formkit.com/essentials/validation#contains_alpha}
   */
  contains_alpha({ name }) {
    return `${sentence(name)} にはアルファベット文字が含まれている必要があります。`;
  },
  /**
   * The value have no alphanumeric
   * @see {@link https://formkit.com/essentials/validation#contains_alphanumeric}
   */
  contains_alphanumeric({ name }) {
    return `${sentence(name)} には文字または数字を含める必要があります。`;
  },
  /**
   * The value have no letter and/or spaces
   * @see {@link https://formkit.com/essentials/validation#contains_alpha-spaces}
   */
  contains_alpha_spaces({ name }) {
    return `${sentence(name)} には文字またはスペースを含める必要があります。`;
  },
  /**
   * The value have no symbol
   * @see {@link https://formkit.com/essentials/validation#contains_symbol}
   */
  contains_symbol({ name }) {
    return `${sentence(name)} には記号が含まれている必要があります。`;
  },
  /**
   * The value have no uppercase
   * @see {@link https://formkit.com/essentials/validation#contains_uppercase}
   */
  contains_uppercase({ name }) {
    return `${sentence(name)} には大文字を含める必要があります。`;
  },
  /**
   * The value have no lowercase
   * @see {@link https://formkit.com/essentials/validation#contains_lowercase}
   */
  contains_lowercase({ name }) {
    return `${sentence(name)} には小文字を含める必要があります。`;
  },
  /**
   *  The value have no numeric
   * @see {@link https://formkit.com/essentials/validation#contains_numeric}
   */
  contains_numeric({ name }) {
    return `${sentence(name)} には数字が含まれている必要があります。`;
  },
  /**
   * The value is not symbol
   * @see {@link https://formkit.com/essentials/validation#symbol}
   */
  symbol({ name }) {
    return `${sentence(name)} はシンボルでなければなりません。`;
  },
  /**
   * The value is not uppercase
   * @see {@link https://formkit.com/essentials/validation#uppercase}
   */
  uppercase({ name }) {
    return `${sentence(name)} には大文字しか使用できません`;
  },
  /**
   * The value is not lowercase
   * @see {@link https://formkit.com/essentials/validation#lowercase}
   */
  lowercase({ name }) {
    return `${sentence(name)} には小文字しか使用できません。`;
  },
  /**
   * The date is not before
   * @see {@link https://formkit.com/essentials/validation#date-before}
   */
  date_before({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${sentence(name)}は${date(args[0])}より前の日付である必要があります。`;
    }
    return `${sentence(name)}は過去の日付である必要があります。`;
  },
  /**
   * The value is not between two numbers
   * @see {@link https://formkit.com/essentials/validation#between}
   */
  between({ name, args }) {
    if (isNaN(args[0]) || isNaN(args[1])) {
      return `このフィールドは正しく構成されていないため、送信できません。`;
    }
    const [a, b] = order(args[0], args[1]);
    return `${sentence(name)}は${a}と${b}の間にある必要があります。`;
  },
  /**
   * The confirmation field does not match
   * @see {@link https://formkit.com/essentials/validation#confirm}
   */
  confirm({ name }) {
    return `${sentence(name)}が一致しません。`;
  },
  /**
   * The value is not a valid date
   * @see {@link https://formkit.com/essentials/validation#date-format}
   */
  date_format({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${sentence(name)}は有効な日付ではありません。${args[0]}の形式を使用してください。`;
    }
    return "このフィールドは正しく構成されておらず、送信できません。";
  },
  /**
   * Is not within expected date range
   * @see {@link https://formkit.com/essentials/validation#date-between}
   */
  date_between({ name, args }) {
    return `${sentence(name)}は${date(args[0])}と${date(
      args[1]
    )}の間にある必要があります。`;
  },
  /**
   * Shown when the user-provided value is not a valid email address.
   * @see {@link https://formkit.com/essentials/validation#email}
   */
  email: "有効なメールアドレスを入力してください。",
  /**
   * Does not end with the specified value
   * @see {@link https://formkit.com/essentials/validation#ends-with}
   */
  ends_with({ name, args }) {
    return `${sentence(name)}は${list(args)}で終わっていません。`;
  },
  /**
   * Is not an allowed value
   * @see {@link https://formkit.com/essentials/validation#is}
   */
  is({ name }) {
    return `${sentence(name)}は許可された値ではありません。`;
  },
  /**
   * Does not match specified length
   * @see {@link https://formkit.com/essentials/validation#length}
   */
  length({ name, args: [first = 0, second = Infinity] }) {
    const min = Number(first) <= Number(second) ? first : second;
    const max = Number(second) >= Number(first) ? second : first;
    if (min == 1 && max === Infinity) {
      return `${sentence(name)}は少なくとも1文字である必要があります。`;
    }
    if (min == 0 && max) {
      return `${sentence(name)}は${max}文字以下である必要があります。`;
    }
    if (min === max) {
      return `${sentence(name)} の長さは ${max} 文字でなければなりません。`;
    }
    if (min && max === Infinity) {
      return `${sentence(name)}は${min}文字以上である必要があります。`;
    }
    return `${sentence(name)}は${min}から${max}文字の間でなければなりません。`;
  },
  /**
   * Value is not a match
   * @see {@link https://formkit.com/essentials/validation#matches}
   */
  matches({ name }) {
    return `${sentence(name)}は許可された値ではありません。`;
  },
  /**
   * Exceeds maximum allowed value
   * @see {@link https://formkit.com/essentials/validation#max}
   */
  max({ name, node: { value }, args }) {
    if (Array.isArray(value)) {
      return `${name}は${args[0]}を超えることはできません。`;
    }
    return `${sentence(name)}は${args[0]}以下である必要があります。`;
  },
  /**
   * The (field-level) value does not match specified mime type
   * @see {@link https://formkit.com/essentials/validation#mime}
   */
  mime({ name, args }) {
    if (!args[0]) {
      return "ファイル形式は許可されていません。";
    }
    return `${sentence(name)}は${args[0]}である必要があります。`;
  },
  /**
   * Does not fulfill minimum allowed value
   * @see {@link https://formkit.com/essentials/validation#min}
   */
  min({ name, node: { value }, args }) {
    if (Array.isArray(value)) {
      return `${name}は${args[0]}未満にすることはできません。`;
    }
    return `${sentence(name)}は少なくとも${args[0]}である必要があります。`;
  },
  /**
   * Is not an allowed value
   * @see {@link https://formkit.com/essentials/validation#not}
   */
  not({ name, node: { value } }) {
    return `“${value}”は許可された${name}ではありません。`;
  },
  /**
   *  Is not a number
   * @see {@link https://formkit.com/essentials/validation#number}
   */
  number({ name }) {
    return `${sentence(name)}は数値でなければなりません。`;
  },
  /**
   * Require one field.
   * @see {@link https://formkit.com/essentials/validation#require-one}
   */
  require_one: ({ name, node, args: inputNames }) => {
    const labels = inputNames.map((name2) => {
      const dependentNode = node.at(name2);
      if (dependentNode) {
        return createMessageName(dependentNode);
      }
      return false;
    }).filter((name2) => !!name2);
    labels.unshift(name);
    return `${labels.join("または")}${labels}が必要です。`;
  },
  /**
   * Required field.
   * @see {@link https://formkit.com/essentials/validation#required}
   */
  required({ name }) {
    return `${sentence(name)}は必須です。`;
  },
  /**
   * Does not start with specified value
   * @see {@link https://formkit.com/essentials/validation#starts-with}
   */
  starts_with({ name, args }) {
    return `${sentence(name)}は${list(args)}で始まっていません。`;
  },
  /**
   * Is not a url
   * @see {@link https://formkit.com/essentials/validation#url}
   */
  url() {
    return `有効な URL を入力してください。`;
  },
  /**
   * Shown when the date is invalid.
   */
  invalidDate: "選択した日付は無効です。"
};
var ja = { ui: ui22, validation: validation22 };
var ui23 = {
  /**
   * Shown on a button for adding additional items.
   */
  add: "қосу",
  /**
   * Shown when a button to remove items is visible.
   */
  remove: "Жою",
  /**
   * Shown when there are multiple items to remove at the same time.
   */
  removeAll: "Барлығын жою",
  /**
   * Shown when all fields are not filled out correctly.
   */
  incomplete: "Кешіріңіз, барлық өрістер дұрыс толтырылмаған.",
  /**
   * Shown in a button inside a form to submit the form.
   */
  submit: "Жіберу",
  /**
   * Shown when no files are selected.
   */
  noFiles: "Ешбір файл таңдалмады",
  /**
   * Shown on buttons that move fields up in a list.
   */
  moveUp: "Жоғары жылжу",
  /**
   * Shown on buttons that move fields down in a list.
   */
  moveDown: "Төмен жылжытыңыз",
  /**
   * Shown when something is actively loading.
   */
  isLoading: "Жүктеу...",
  /**
   * Shown when there is more to load.
   */
  loadMore: "Көбірек жүктеңіз",
  /**
   * Shown on buttons that navigate state forward
   */
  next: "Келесі",
  /**
   * Shown on buttons that navigate state backward
   */
  prev: "Алдыңғы",
  /**
   * Shown when adding all values.
   */
  addAllValues: "Барлық мәндерді қосыңыз",
  /**
   * Shown when adding selected values.
   */
  addSelectedValues: "Таңдалған мәндерді қосыңыз",
  /**
   * Shown when removing all values.
   */
  removeAllValues: "Барлық мәндерді алып тастаңыз",
  /**
   * Shown when removing selected values.
   */
  removeSelectedValues: "Таңдалған мәндерді алып тастаңыз",
  /**
   * Shown when there is a date to choose.
   */
  chooseDate: "Күнді таңдаңыз",
  /**
   * Shown when there is a date to change.
   */
  changeDate: "Өзгерту күні",
  /**
   * Shown when there is something to close
   */
  close: "Жабу",
  /**
   * Shown when there is something to open.
   */
  open: "Ашық"
};
var validation23 = {
  /**
   * The value is not an accepted value.
   * @see {@link https://formkit.com/essentials/validation#accepted}
   */
  accepted({ name }) {
    return `қабылдаңыз ${name}.`;
  },
  /**
   * The date is not after
   * @see {@link https://formkit.com/essentials/validation#date-after}
   */
  date_after({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${sentence(name)} кейін болуы керек ${date(args[0])}.`;
    }
    return `${sentence(name)} болашақта болуы керек.`;
  },
  /**
   * The value is not a letter.
   * @see {@link https://formkit.com/essentials/validation#alpha}
   */
  alpha({ name }) {
    return `${sentence(name)} тек алфавиттік таңбаларды қамтуы мүмкін.`;
  },
  /**
   * The value is not alphanumeric
   * @see {@link https://formkit.com/essentials/validation#alphanumeric}
   */
  alphanumeric({ name }) {
    return `${sentence(name)} тек әріптер мен сандардан тұруы мүмкін.`;
  },
  /**
   * The value is not letter and/or spaces
   * @see {@link https://formkit.com/essentials/validation#alpha-spaces}
   */
  alpha_spaces({ name }) {
    return `${sentence(name)} тек әріптер мен бос орындар болуы мүмкін.`;
  },
  /**
   * The value have no letter.
   * @see {@link https://formkit.com/essentials/validation#contains_alpha}
   */
  contains_alpha({ name }) {
    return `${sentence(name)} алфавиттік таңбалардан тұруы керек.`;
  },
  /**
   * The value have no alphanumeric
   * @see {@link https://formkit.com/essentials/validation#contains_alphanumeric}
   */
  contains_alphanumeric({ name }) {
    return `${sentence(name)} құрамында әріптер немесе сандар болуы керек.`;
  },
  /**
   * The value have no letter and/or spaces
   * @see {@link https://formkit.com/essentials/validation#contains_alpha-spaces}
   */
  contains_alpha_spaces({ name }) {
    return `${sentence(name)} құрамында әріптер немесе бос орындар болуы керек.`;
  },
  /**
   * The value have no symbol
   * @see {@link https://formkit.com/essentials/validation#contains_symbol}
   */
  contains_symbol({ name }) {
    return `${sentence(name)} символы болуы керек.`;
  },
  /**
   * The value have no uppercase
   * @see {@link https://formkit.com/essentials/validation#contains_uppercase}
   */
  contains_uppercase({ name }) {
    return `${sentence(name)} құрамында бас әріптер болуы керек.`;
  },
  /**
   * The value have no lowercase
   * @see {@link https://formkit.com/essentials/validation#contains_lowercase}
   */
  contains_lowercase({ name }) {
    return `${sentence(name)} кіші әріп болуы керек.`;
  },
  /**
   *  The value have no numeric
   * @see {@link https://formkit.com/essentials/validation#contains_numeric}
   */
  contains_numeric({ name }) {
    return `${sentence(name)} сандардан тұруы керек.`;
  },
  /**
   * The value is not symbol
   * @see {@link https://formkit.com/essentials/validation#symbol}
   */
  symbol({ name }) {
    return `${sentence(name)} символы болуы керек.`;
  },
  /**
   * The value is not uppercase
   * @see {@link https://formkit.com/essentials/validation#uppercase}
   */
  uppercase({ name }) {
    return `${sentence(name)} тек бас әріптерден тұруы мүмкін.`;
  },
  /**
   * The value is not lowercase
   * @see {@link https://formkit.com/essentials/validation#lowercase}
   */
  lowercase({ name }) {
    return `${sentence(name)} құрамында тек кіші әріптер болуы мүмкін.`;
  },
  /**
   * The date is not before
   * @see {@link https://formkit.com/essentials/validation#date-before}
   */
  date_before({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${sentence(name)} бұрын болуы керек ${date(args[0])}.`;
    }
    return `${sentence(name)} өткенде болуы керек.`;
  },
  /**
   * The value is not between two numbers
   * @see {@link https://formkit.com/essentials/validation#between}
   */
  between({ name, args }) {
    if (isNaN(args[0]) || isNaN(args[1])) {
      return `Бұл өріс қате конфигурацияланған және оны жіберу мүмкін емес.`;
    }
    const [a, b] = order(args[0], args[1]);
    return `${sentence(name)} арасында болуы керек ${a} және ${b}.`;
  },
  /**
   * The confirmation field does not match
   * @see {@link https://formkit.com/essentials/validation#confirm}
   */
  confirm({ name }) {
    return `${sentence(name)} сәйкес келмейді.`;
  },
  /**
   * The value is not a valid date
   * @see {@link https://formkit.com/essentials/validation#date-format}
   */
  date_format({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${sentence(name)} жарамды күн емес, пішімді пайдаланыңыз ${args[0]}`;
    }
    return "Бұл өріс қате конфигурацияланған және оны жіберу мүмкін емес";
  },
  /**
   * Is not within expected date range
   * @see {@link https://formkit.com/essentials/validation#date-between}
   */
  date_between({ name, args }) {
    return `${sentence(name)} арасында болуы керек ${date(args[0])} және ${date(
      args[1]
    )}`;
  },
  /**
   * Shown when the user-provided value is not a valid email address.
   * @see {@link https://formkit.com/essentials/validation#email}
   */
  email: "Өтінеміз қолданыстағы электронды пошта адресін енгізіңіз.",
  /**
   * Does not end with the specified value
   * @see {@link https://formkit.com/essentials/validation#ends-with}
   */
  ends_with({ name, args }) {
    return `${sentence(name)} -мен бітпейді ${list(args)}.`;
  },
  /**
   * Is not an allowed value
   * @see {@link https://formkit.com/essentials/validation#is}
   */
  is({ name }) {
    return `${sentence(name)} рұқсат етілген мән емес.`;
  },
  /**
   * Does not match specified length
   * @see {@link https://formkit.com/essentials/validation#length}
   */
  length({ name, args: [first = 0, second = Infinity] }) {
    const min = Number(first) <= Number(second) ? first : second;
    const max = Number(second) >= Number(first) ? second : first;
    if (min == 1 && max === Infinity) {
      return `${sentence(name)} кем дегенде бір таңба болуы керек.`;
    }
    if (min == 0 && max) {
      return `${sentence(name)} кем немесе тең болуы керек ${max} кейіпкерлер.`;
    }
    if (min === max) {
      return `${sentence(name)} ${max} таңбалары болуы керек.`;
    }
    if (min && max === Infinity) {
      return `${sentence(name)} артық немесе тең болуы керек ${min} кейіпкерлер.`;
    }
    return `${sentence(name)} арасында болуы керек ${min} және ${max} кейіпкерлер.`;
  },
  /**
   * Value is not a match
   * @see {@link https://formkit.com/essentials/validation#matches}
   */
  matches({ name }) {
    return `${sentence(name)} рұқсат етілген мән емес.`;
  },
  /**
   * Exceeds maximum allowed value
   * @see {@link https://formkit.com/essentials/validation#max}
   */
  max({ name, node: { value }, args }) {
    if (Array.isArray(value)) {
      return `артық болуы мүмкін емес ${args[0]} ${name}.`;
    }
    return `${sentence(name)} кем немесе тең болуы керек ${args[0]}.`;
  },
  /**
   * The (field-level) value does not match specified mime type
   * @see {@link https://formkit.com/essentials/validation#mime}
   */
  mime({ name, args }) {
    if (!args[0]) {
      return "Файл пішімдері рұқсат етілмейді.";
    }
    return `${sentence(name)} типте болуы керек: ${args[0]}`;
  },
  /**
   * Does not fulfill minimum allowed value
   * @see {@link https://formkit.com/essentials/validation#min}
   */
  min({ name, node: { value }, args }) {
    if (Array.isArray(value)) {
      return `кем болуы мүмкін емес ${args[0]} ${name}.`;
    }
    return `${sentence(name)} кем дегенде болуы керек ${args[0]}.`;
  },
  /**
   * Is not an allowed value
   * @see {@link https://formkit.com/essentials/validation#not}
   */
  not({ name, node: { value } }) {
    return `“${value}” рұқсат етілмейді ${name}.`;
  },
  /**
   *  Is not a number
   * @see {@link https://formkit.com/essentials/validation#number}
   */
  number({ name }) {
    return `${sentence(name)} сан болуы керек.`;
  },
  /**
   * Require one field.
   * @see {@link https://formkit.com/essentials/validation#require-one}
   */
  require_one: ({ name, node, args: inputNames }) => {
    const labels = inputNames.map((name2) => {
      const dependentNode = node.at(name2);
      if (dependentNode) {
        return createMessageName(dependentNode);
      }
      return false;
    }).filter((name2) => !!name2);
    labels.unshift(name);
    return `${labels.join(" не ")} қажет.`;
  },
  /**
   * Required field.
   * @see {@link https://formkit.com/essentials/validation#required}
   */
  required({ name }) {
    return `${sentence(name)} талап етіледі.`;
  },
  /**
   * Does not start with specified value
   * @see {@link https://formkit.com/essentials/validation#starts-with}
   */
  starts_with({ name, args }) {
    return `${sentence(name)} -ден басталмайды ${list(args)}.`;
  },
  /**
   * Is not a url
   * @see {@link https://formkit.com/essentials/validation#url}
   */
  url() {
    return `Жарамды URL мекенжайын енгізіңіз.`;
  },
  /**
   * Shown when the date is invalid.
   */
  invalidDate: "Таңдалған күн жарамсыз."
};
var kk = { ui: ui23, validation: validation23 };
var ui24 = {
  /**
   * Shown on buttons for adding new items.
   */
  add: "추가",
  /**
   * Shown when a button to remove items is visible.
   */
  remove: "제거",
  /**
   * Shown when there are multiple items to remove at the same time.
   */
  removeAll: "모두 제거",
  /**
   * Shown when all fields are not filled out correctly.
   */
  incomplete: "모든 값을 채워주세요",
  /**
   * Shown in a button inside a form to submit the form.
   */
  submit: "제출하기",
  /**
   * Shown when no files are selected.
   */
  noFiles: "선택된 파일이 없습니다",
  /**
   * Shown on buttons that move fields up in a list.
   */
  moveUp: "위로 이동",
  /**
   * Shown on buttons that move fields down in a list.
   */
  moveDown: "아래로 이동",
  /**
   * Shown when something is actively loading.
   */
  isLoading: "로드 중...",
  /**
   * Shown when there is more to load.
   */
  loadMore: "더 불러오기",
  /**
   * Shown on buttons that navigate state forward
   */
  next: "다음",
  /**
   * Shown on buttons that navigate state backward
   */
  prev: "이전",
  /**
   * Shown when adding all values.
   */
  addAllValues: "모든 값 추가",
  /**
   * Shown when adding selected values.
   */
  addSelectedValues: "선택한 값 추가",
  /**
   * Shown when removing all values.
   */
  removeAllValues: "모든 값 제거",
  /**
   * Shown when removing selected values.
   */
  removeSelectedValues: "선택한 값 제거",
  /**
   * Shown when there is a date to choose.
   */
  chooseDate: "날짜 선택",
  /**
   * Shown when there is a date to change.
   */
  changeDate: "날짜 변경",
  /**
   * Shown when there is something to close
   */
  close: "닫기",
  /**
   * Shown when there is something to open.
   */
  open: "열기"
};
var validation24 = {
  /**
   * The value is not an accepted value.
   * @see {@link https://formkit.com/essentials/validation#accepted}
   */
  accepted({ name }) {
    return `${name} 올바른 값을 선택 해주세요`;
  },
  /**
   * The date is not after
   * @see {@link https://formkit.com/essentials/validation#date-after}
   */
  date_after({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${sentence(name)} ${date(args[0])} 이후여야 합니다`;
    }
    return `${sentence(name)} 미래의 날짜여야합니다`;
  },
  /**
   * The value is not a letter.
   * @see {@link https://formkit.com/essentials/validation#alpha}
   */
  alpha({ name }) {
    return `${sentence(name)} 알파벳 문자만 포함할 수 있습니다`;
  },
  /**
   * The value is not alphanumeric
   * @see {@link https://formkit.com/essentials/validation#alphanumeric}
   */
  alphanumeric({ name }) {
    return `${sentence(name)} 문자와 숫자만 포함될 수 있습니다`;
  },
  /**
   * The value is not letter and/or spaces
   * @see {@link https://formkit.com/essentials/validation#alpha-spaces}
   */
  alpha_spaces({ name }) {
    return `${sentence(name)} 문자와 공백만 포함할 수 있습니다.`;
  },
  /**
   * The value have no letter.
   * @see {@link https://formkit.com/essentials/validation#contains_alpha}
   */
  contains_alpha({ name }) {
    return `${sentence(name)} 에는 알파벳 문자가 포함되어야 합니다.`;
  },
  /**
   * The value have no alphanumeric
   * @see {@link https://formkit.com/essentials/validation#contains_alphanumeric}
   */
  contains_alphanumeric({ name }) {
    return `${sentence(name)} 에는 문자나 숫자가 포함되어야 합니다.`;
  },
  /**
   * The value have no letter and/or spaces
   * @see {@link https://formkit.com/essentials/validation#contains_alpha-spaces}
   */
  contains_alpha_spaces({ name }) {
    return `${sentence(name)} 에는 문자나 공백이 포함되어야 합니다.`;
  },
  /**
   * The value have no symbol
   * @see {@link https://formkit.com/essentials/validation#contains_symbol}
   */
  contains_symbol({ name }) {
    return `${sentence(name)} 에는 기호를 포함해야 합니다.`;
  },
  /**
   * The value have no uppercase
   * @see {@link https://formkit.com/essentials/validation#contains_uppercase}
   */
  contains_uppercase({ name }) {
    return `${sentence(name)} 는 대문자를 포함해야 합니다.`;
  },
  /**
   * The value have no lowercase
   * @see {@link https://formkit.com/essentials/validation#contains_lowercase}
   */
  contains_lowercase({ name }) {
    return `${sentence(name)} 는 소문자를 포함해야 합니다.`;
  },
  /**
   *  The value have no numeric
   * @see {@link https://formkit.com/essentials/validation#contains_numeric}
   */
  contains_numeric({ name }) {
    return `${sentence(name)} 에는 숫자가 포함되어야 합니다.`;
  },
  /**
   * The value is not symbol
   * @see {@link https://formkit.com/essentials/validation#symbol}
   */
  symbol({ name }) {
    return `${sentence(name)} 는 기호여야 합니다.`;
  },
  /**
   * The value is not uppercase
   * @see {@link https://formkit.com/essentials/validation#uppercase}
   */
  uppercase({ name }) {
    return `${sentence(name)} 는 대문자만 포함할 수 있습니다.`;
  },
  /**
   * The value is not lowercase
   * @see {@link https://formkit.com/essentials/validation#lowercase}
   */
  lowercase({ name }) {
    return `${sentence(name)} 는 소문자만 포함할 수 있습니다.`;
  },
  /**
   * The date is not before
   * @see {@link https://formkit.com/essentials/validation#date-before}
   */
  date_before({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${sentence(name)} ${date(args[0])} 이전여야 합니다`;
    }
    return `${sentence(name)} 과거의 날짜여야합니다`;
  },
  /**
   * The value is not between two numbers
   * @see {@link https://formkit.com/essentials/validation#between}
   */
  between({ name, args }) {
    if (isNaN(args[0]) || isNaN(args[1])) {
      return `잘못된 구성으로 제출할 수 없습니다`;
    }
    const [a, b] = order(args[0], args[1]);
    return `${sentence(name)} ${a}와 ${b} 사이여야 합니다`;
  },
  /**
   * The confirmation field does not match
   * @see {@link https://formkit.com/essentials/validation#confirm}
   */
  confirm({ name }) {
    return `${sentence(name)} 일치하지 않습니다`;
  },
  /**
   * The value is not a valid date
   * @see {@link https://formkit.com/essentials/validation#date-format}
   */
  date_format({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${sentence(name)} 유효한 날짜가 아닙니다. ${args[0]}과 같은 형식을 사용해주세요`;
    }
    return "잘못된 구성으로 제출할 수 없습니다";
  },
  /**
   * Is not within expected date range
   * @see {@link https://formkit.com/essentials/validation#date-between}
   */
  date_between({ name, args }) {
    return `${sentence(name)} ${date(args[0])}에서 ${date(args[1])} 사이여야 합니다`;
  },
  /**
   * Shown when the user-provided value is not a valid email address.
   * @see {@link https://formkit.com/essentials/validation#email}
   */
  email: "올바른 이메일 주소를 입력해주세요",
  /**
   * Does not end with the specified value
   * @see {@link https://formkit.com/essentials/validation#ends-with}
   */
  ends_with({ name, args }) {
    return `${sentence(name)} ${list(args)}로 끝나지 않습니다`;
  },
  /**
   * Is not an allowed value
   * @see {@link https://formkit.com/essentials/validation#is}
   */
  is({ name }) {
    return `${sentence(name)} 허용되는 값이 아닙니다`;
  },
  /**
   * Does not match specified length
   * @see {@link https://formkit.com/essentials/validation#length}
   */
  length({ name, args: [first = 0, second = Infinity] }) {
    const min = Number(first) <= Number(second) ? first : second;
    const max = Number(second) >= Number(first) ? second : first;
    if (min == 1 && max === Infinity) {
      return `${sentence(name)} 하나 이상의 문자여야 합니다`;
    }
    if (min == 0 && max) {
      return `${sentence(name)} ${max}자 이하여야 합니다`;
    }
    if (min === max) {
      return `${sentence(name)} 는 ${max} 자 길이여야 합니다.`;
    }
    if (min && max === Infinity) {
      return `${sentence(name)} ${min} 문자보다 크거나 같아야 합니다`;
    }
    return `${sentence(name)} ${min}에서 ${max}자 사이여야 합니다`;
  },
  /**
   * Value is not a match
   * @see {@link https://formkit.com/essentials/validation#matches}
   */
  matches({ name }) {
    return `${sentence(name)} 허용되는 값이 아닙니다`;
  },
  /**
   * Exceeds maximum allowed value
   * @see {@link https://formkit.com/essentials/validation#max}
   */
  max({ name, node: { value }, args }) {
    if (Array.isArray(value)) {
      return `${args[0]} ${name} 초과할 수 없습니다`;
    }
    return `${sentence(name)} ${args[0]}보다 작거나 같아야 합니다`;
  },
  /**
   * The (field-level) value does not match specified mime type
   * @see {@link https://formkit.com/essentials/validation#mime}
   */
  mime({ name, args }) {
    if (!args[0]) {
      return "파일 형식이 허용되지 않습니다";
    }
    return `${sentence(name)} ${args[0]} 유형이어야 합니다`;
  },
  /**
   * Does not fulfill minimum allowed value
   * @see {@link https://formkit.com/essentials/validation#min}
   */
  min({ name, node: { value }, args }) {
    if (Array.isArray(value)) {
      return `${args[0]} ${name}보다 작을 수 없습니다`;
    }
    return `${sentence(name)} ${args[0]} 이상이어야 합니다`;
  },
  /**
   * Is not an allowed value
   * @see {@link https://formkit.com/essentials/validation#not}
   */
  not({ name, node: { value } }) {
    return `${value}" 허용되지 않는 ${name}입니다`;
  },
  /**
   *  Is not a number
   * @see {@link https://formkit.com/essentials/validation#number}
   */
  number({ name }) {
    return `${sentence(name)} 숫자여야 합니다`;
  },
  /**
   * Require one field.
   * @see {@link https://formkit.com/essentials/validation#require-one}
   */
  require_one: ({ name, node, args: inputNames }) => {
    const labels = inputNames.map((name2) => {
      const dependentNode = node.at(name2);
      if (dependentNode) {
        return createMessageName(dependentNode);
      }
      return false;
    }).filter((name2) => !!name2);
    labels.unshift(name);
    return `${labels.join(" 또는 ")}가 필요합니다.`;
  },
  /**
   * Required field.
   * @see {@link https://formkit.com/essentials/validation#required}
   */
  required({ name }) {
    return `${sentence(name)} 필수 값입니다`;
  },
  /**
   * Does not start with specified value
   * @see {@link https://formkit.com/essentials/validation#starts-with}
   */
  starts_with({ name, args }) {
    return `${sentence(name)} ${list(args)}로 시작하지 않습니다`;
  },
  /**
   * Is not a url
   * @see {@link https://formkit.com/essentials/validation#url}
   */
  url() {
    return `유효한 URL을 입력하십시오.`;
  },
  /**
   * Shown when the date is invalid.
   */
  invalidDate: "선택한 날짜가 잘못되었습니다."
};
var ko = { ui: ui24, validation: validation24 };
function getByQuantity(quantity, vienetas, vienetai, vienetu) {
  const lastTwoDigits = quantity.toString().slice(-2);
  const parsedQuantity = parseInt(lastTwoDigits);
  if (parsedQuantity > 10 && parsedQuantity < 20 || parsedQuantity % 10 === 0) {
    return vienetu;
  }
  if (parsedQuantity === 1 || parsedQuantity % 10 === 1) {
    return vienetas;
  }
  return vienetai;
}
var ui25 = {
  /**
   * Shown on a button for adding additional items.
   */
  add: "Pridėti",
  /**
   * Shown when a button to remove items is visible.
   */
  remove: "Pašalinti",
  /**
   * Shown when there are multiple items to remove at the same time.
   */
  removeAll: "Pašalinti visus",
  /**
   * Shown when all fields are not filled out correctly.
   */
  incomplete: "Atsiprašome, ne visi laukai užpildyti teisingai.",
  /**
   * Shown in a button inside a form to submit the form.
   */
  submit: "Pateikti",
  /**
   * Shown when no files are selected.
   */
  noFiles: "Nepasirinktas joks failas",
  /**
   * Shown on buttons that move fields up in a list.
   */
  moveUp: "Aukštyn",
  /**
   * Shown on buttons that move fields down in a list.
   */
  moveDown: "Žemyn",
  /**
   * Shown when something is actively loading.
   */
  isLoading: "Kraunama...",
  /**
   * Shown when there is more to load.
   */
  loadMore: "Daugiau",
  /**
   * Show on buttons that navigate state forward
   */
  next: "Kitas",
  /**
   * Show on buttons that navigate state backward
   */
  prev: "Ankstesnis",
  /**
   * Shown when adding all values.
   */
  addAllValues: "Pridėti visas reikšmes",
  /**
   * Shown when adding selected values.
   */
  addSelectedValues: "Pridėti pasirinktas reikšmes",
  /**
   * Shown when removing all values.
   */
  removeAllValues: "Pašalinti visas reikšmes",
  /**
   * Shown when removing selected values.
   */
  removeSelectedValues: "Pašalinti pasirinktas reikšmes",
  /**
   * Shown when there is a date to choose.
   */
  chooseDate: "Pasirinkti datą",
  /**
   * Shown when there is a date to change.
   */
  changeDate: "Pakeisti datą",
  /**
   * Shown when there is something to close
   */
  close: "Uždaryti",
  /**
   * Shown when there is something to open.
   */
  open: "Atidaryti"
};
var validation25 = {
  /**
   * The value is not an accepted value.
   * @see {@link https://formkit.com/essentials/validation#accepted}
   */
  accepted({ name }) {
    return `Prašome priimti ${name}.`;
  },
  /**
   * The date is not after
   * @see {@link https://formkit.com/essentials/validation#date-after}
   */
  date_after({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${sentence(name)} turi būti po ${date(args[0])}.`;
    }
    return `${sentence(name)} turi būti ateityje.`;
  },
  /**
   * The value is not a letter.
   * @see {@link https://formkit.com/essentials/validation#alpha}
   */
  alpha({ name }) {
    return `${sentence(name)} gali būti tik abėcėlės simboliai.`;
  },
  /**
   * The value is not alphanumeric
   * @see {@link https://formkit.com/essentials/validation#alphanumeric}
   */
  alphanumeric({ name }) {
    return `${sentence(name)} gali būti tik raidės ir skaičiai.`;
  },
  /**
   * The value is not letter and/or spaces
   * @see {@link https://formkit.com/essentials/validation#alpha-spaces}
   */
  alpha_spaces({ name }) {
    return `${sentence(name)} gali būti tik raidės ir tarpai.`;
  },
  /**
   * The value have no letter.
   * @see {@link https://formkit.com/essentials/validation#contains_alpha}
   */
  contains_alpha({ name }) {
    return `${sentence(name)} turi būti abėcėlės simbolių.`;
  },
  /**
   * The value have no alphanumeric
   * @see {@link https://formkit.com/essentials/validation#contains_alphanumeric}
   */
  contains_alphanumeric({ name }) {
    return `${sentence(name)} turi būti raidžių arba skaičių.`;
  },
  /**
   * The value have no letter and/or spaces
   * @see {@link https://formkit.com/essentials/validation#contains_alpha-spaces}
   */
  contains_alpha_spaces({ name }) {
    return `${sentence(name)} turi būti raidžių arba tarpų.`;
  },
  /**
   * The value have no symbol
   * @see {@link https://formkit.com/essentials/validation#contains_symbol}
   */
  contains_symbol({ name }) {
    return `${sentence(name)} turi būti simbolių.`;
  },
  /**
   * The value have no uppercase
   * @see {@link https://formkit.com/essentials/validation#contains_uppercase}
   */
  contains_uppercase({ name }) {
    return `${sentence(name)} turi būti didžioji raidė.`;
  },
  /**
   * The value have no lowercase
   * @see {@link https://formkit.com/essentials/validation#contains_lowercase}
   */
  contains_lowercase({ name }) {
    return `${sentence(name)} turi būti mažoji raidė.`;
  },
  /**
   *  The value have no numeric
   * @see {@link https://formkit.com/essentials/validation#contains_numeric}
   */
  contains_numeric({ name }) {
    return `${sentence(name)} turi būti skaičių.`;
  },
  /**
   * The value is not symbol
   * @see {@link https://formkit.com/essentials/validation#symbol}
   */
  symbol({ name }) {
    return `${sentence(name)} turi būti simbolis.`;
  },
  /**
   * The value is not uppercase
   * @see {@link https://formkit.com/essentials/validation#uppercase}
   */
  uppercase({ name }) {
    return `${sentence(name)} turi būti tik didžiosios raidės.`;
  },
  /**
   * The value is not lowercase
   * @see {@link https://formkit.com/essentials/validation#lowercase}
   */
  lowercase({ name }) {
    return `${sentence(name)} turi būti tik mažosios raidės.`;
  },
  /**
   * The date is not before
   * @see {@link https://formkit.com/essentials/validation#date-before}
   */
  date_before({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${sentence(name)} turi būti prieš ${date(args[0])}.`;
    }
    return `${sentence(name)} turi būti praeityje.`;
  },
  /**
   * The value is not between two numbers
   * @see {@link https://formkit.com/essentials/validation#between}
   */
  between({ name, args }) {
    if (isNaN(args[0]) || isNaN(args[1])) {
      return `Šis laukas buvo sukonfigūruotas neteisingai ir jo negalima pateikti.`;
    }
    const [a, b] = order(args[0], args[1]);
    return `${sentence(name)} turi būti tarp ${a} ir ${b}.`;
  },
  /**
   * The confirmation field does not match
   * @see {@link https://formkit.com/essentials/validation#confirm}
   */
  confirm({ name }) {
    return `${sentence(name)} nesutampa.`;
  },
  /**
   * The value is not a valid date
   * @see {@link https://formkit.com/essentials/validation#date-format}
   */
  date_format({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${sentence(name)} nėra tinkama data, naudokite formatą ${args[0]}`;
    }
    return "Šis laukas buvo sukonfigūruotas neteisingai ir jo negalima pateikti";
  },
  /**
   * Is not within expected date range
   * @see {@link https://formkit.com/essentials/validation#date-between}
   */
  date_between({ name, args }) {
    return `${sentence(name)} turi būti tarp ${date(args[0])} ir ${date(args[1])}`;
  },
  /**
   * Shown when the user-provided value is not a valid email address.
   * @see {@link https://formkit.com/essentials/validation#email}
   */
  email: "Įveskite teisingą el. pašto adresą.",
  /**
   * Does not end with the specified value
   * @see {@link https://formkit.com/essentials/validation#ends-with}
   */
  ends_with({ name, args }) {
    return `${sentence(name)} nesibaigia su ${list(args)}.`;
  },
  /**
   * Is not an allowed value
   * @see {@link https://formkit.com/essentials/validation#is}
   */
  is({ name }) {
    return `${sentence(name)} nėra leistina reikšmė.`;
  },
  /**
   * Does not match specified length
   * @see {@link https://formkit.com/essentials/validation#length}
   */
  length({ name, args: [first = 0, second = Infinity] }) {
    const min = Number(first) <= Number(second) ? first : second;
    const max = Number(second) >= Number(first) ? second : first;
    if (min == 1 && max === Infinity) {
      return `${sentence(name)} turi būti bent vienas simbolis.`;
    }
    if (min == 0 && max) {
      return `${sentence(name)} turi būti mažiau arba lygiai ${max} ${getByQuantity(
        max,
        "simbolis",
        "simboliai",
        "simbolių"
      )}.`;
    }
    if (min === max) {
      return `${sentence(name)} turi būti iš ${max} ${getByQuantity(
        max,
        "simbolio",
        "simbolių",
        "simbolių"
      )}.`;
    }
    if (min && max === Infinity) {
      return `${sentence(name)} turi būti daugiau arba lygiai ${min} ${getByQuantity(
        min,
        "simbolis",
        "simboliai",
        "simbolių"
      )}.`;
    }
    return `${sentence(name)} turi būti tarp ${min} ir ${max} simbolių.`;
  },
  /**
   * Value is not a match
   * @see {@link https://formkit.com/essentials/validation#matches}
   */
  matches({ name }) {
    return `${sentence(name)} nėra leistina reikšmė.`;
  },
  /**
   * Exceeds maximum allowed value
   * @see {@link https://formkit.com/essentials/validation#max}
   */
  max({ name, node: { value }, args }) {
    if (Array.isArray(value)) {
      return `Negali turėti daugiau nei ${args[0]} ${name}.`;
    }
    return `${sentence(name)} turi būti mažiau arba lygiai ${args[0]}.`;
  },
  /**
   * The (field-level) value does not match specified mime type
   * @see {@link https://formkit.com/essentials/validation#mime}
   */
  mime({ name, args }) {
    if (!args[0]) {
      return "Neleidžiami jokie failų formatai.";
    }
    return `${sentence(name)} turi būti tokio tipo: ${args[0]}`;
  },
  /**
   * Does not fulfill minimum allowed value
   * @see {@link https://formkit.com/essentials/validation#min}
   */
  min({ name, node: { value }, args }) {
    if (Array.isArray(value)) {
      return `Negali turėti mažiau nei ${args[0]} ${name}.`;
    }
    return `Turi būti bent ${args[0]} ${name} .`;
  },
  /**
   * Is not an allowed value
   * @see {@link https://formkit.com/essentials/validation#not}
   */
  not({ name, node: { value } }) {
    return `“${value}” nėra leidžiamas ${name}.`;
  },
  /**
   *  Is not a number
   * @see {@link https://formkit.com/essentials/validation#number}
   */
  number({ name }) {
    return `${sentence(name)} turi būti skaičius.`;
  },
  /**
   * Require one field.
   * @see {@link https://formkit.com/essentials/validation#require-one}
   */
  require_one: ({ name, node, args: inputNames }) => {
    const labels = inputNames.map((name2) => {
      const dependentNode = node.at(name2);
      if (dependentNode) {
        return createMessageName(dependentNode);
      }
      return false;
    }).filter((name2) => !!name2);
    labels.unshift(name);
    return `${labels.join(" arba ")} yra privaloma.`;
  },
  /**
   * Required field.
   * @see {@link https://formkit.com/essentials/validation#required}
   */
  required({ name }) {
    return `${sentence(name)} yra privaloma.`;
  },
  /**
   * Does not start with specified value
   * @see {@link https://formkit.com/essentials/validation#starts-with}
   */
  starts_with({ name, args }) {
    return `${sentence(name)} neprasideda su ${list(args)}.`;
  },
  /**
   * Is not a url
   * @see {@link https://formkit.com/essentials/validation#url}
   */
  url() {
    return `Įveskite teisingą URL.`;
  },
  /**
   * Shown when the date is invalid.
   */
  invalidDate: "Pasirinkta data yra netinkama."
};
var lt = { ui: ui25, validation: validation25 };

// packages/i18n/src/locales/lv.ts
var ui26 = {
  /**
   * Shown on a button for adding additional items.
   */
  add: "Pievienot",
  /**
   * Shown when a button to remove items is visible.
   */
  remove: "Noņemt",
  /**
   * Shown when there are multiple items to remove at the same time.
   */
  removeAll: "Noņemt visus",
  /**
   * Shown when all fields are not filled out correctly.
   */
  incomplete: "Piedodiet, visi lauki nav aizpildīti.",
  /**
   * Shown in a button inside a form to submit the form.
   */
  submit: "Iesniegt",
  /**
   * Shown when no files are selected.
   */
  noFiles: "Nav izvēlēts fails",
  /**
   * Shown on buttons that move fields up in a list.
   */
  moveUp: "Uz augšu",
  /**
   * Shown on buttons that move fields down in a list.
   */
  moveDown: "Uz leju",
  /**
   * Shown when something is actively loading.
   */
  isLoading: "Ielādējas...",
  /**
   * Shown when there is more to load.
   */
  loadMore: "Ielādēt vēl",
  /**
   * Show on buttons that navigate state forward
   */
  next: "Tālāk",
  /**
   * Show on buttons that navigate state backward
   */
  prev: "Atpakaļ",
  /**
   * Shown when adding all values.
   */
  addAllValues: "Pievienot visas vērtības",
  /**
   * Shown when adding selected values.
   */
  addSelectedValues: "Pievienojiet izvēlēto vērtību",
  /**
   * Shown when removing all values.
   */
  removeAllValues: "Noņemt visas vērtības",
  /**
   * Shown when removing selected values.
   */
  removeSelectedValues: "Noņemt izvēlētās vērtības",
  /**
   * Shown when there is a date to choose.
   */
  chooseDate: "Izvēlieties datumu",
  /**
   * Shown when there is a date to change.
   */
  changeDate: "Mainīt datumu",
  /**
   * Shown when there is something to close
   */
  close: "Aizvērt",
  /**
   * Shown when there is something to open.
   */
  open: "Atvērt"
};
var validation26 = {
  /**
   * The value is not an accepted value.
   * @see {@link https://formkit.com/essentials/validation#accepted}
   */
  accepted({ name }) {
    return `Lūdzu apstipriniet ${name}`;
  },
  /**
   * The date is not after
   * @see {@link https://formkit.com/essentials/validation#date-after}
   */
  date_after({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${name} jābūt pēc ${date(args[0])}.`;
    }
    return `${name} jābūt pēc šodienas datuma.`;
  },
  /**
   * The value is not a letter.
   * @see {@link https://formkit.com/essentials/validation#alpha}
   */
  alpha({ name }) {
    return `${name} var saturēt tikai alfabētiskās rakstzīmes.`;
  },
  /**
   * The value is not alphanumeric
   * @see {@link https://formkit.com/essentials/validation#alphanumeric}
   */
  alphanumeric({ name }) {
    return `${name} var saturēt tikai burtus un ciparus.`;
  },
  /**
   * The value is not letter and/or spaces
   * @see {@link https://formkit.com/essentials/validation#alpha-spaces}
   */
  alpha_spaces({ name }) {
    return `${name} var saturēt tikai burtus un atstarpes.`;
  },
  /**
   * The date is not before
   * @see {@link https://formkit.com/essentials/validation#date-before}
   */
  date_before({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${name} jābūt pirms ${date(args[0])}.`;
    }
    return `${name} jābūt pirms šodienas datuma.`;
  },
  /**
   * The value is not between two numbers
   * @see {@link https://formkit.com/essentials/validation#between}
   */
  between({ name, args }) {
    if (isNaN(args[0]) || isNaN(args[1])) {
      return `Šis lauks tika aizpildīts nepareizi un nevar tikt iesniegts.`;
    }
    const [a, b] = order(args[0], args[1]);
    return `${name} jābūt starp ${a} un ${b}.`;
  },
  /**
   * The confirmation field does not match
   * @see {@link https://formkit.com/essentials/validation#confirm}
   */
  confirm({ name }) {
    return `${name} nesakrīt.`;
  },
  /**
   * The value is not a valid date
   * @see {@link https://formkit.com/essentials/validation#date-format}
   */
  date_format({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${name} nav pareizs datums, lūdzu lietojiet formātu ${args[0]}`;
    }
    return "Šis lauks tika aizpildīts nepareizi un nevar tikt iesniegts.";
  },
  /**
   * Is not within expected date range
   * @see {@link https://formkit.com/essentials/validation#date-between}
   */
  date_between({ name, args }) {
    return `${name} jābūt starp ${date(args[0])} un ${date(args[1])}`;
  },
  /**
   * Shown when the user-provided value is not a valid email address.
   * @see {@link https://formkit.com/essentials/validation#email}
   */
  email: "Lūdzu ierakstiet pareizu e-pasta adresi.",
  /**
   * Does not end with the specified value
   * @see {@link https://formkit.com/essentials/validation#ends-with}
   */
  ends_with({ name, args }) {
    return `${name} nebeidzas ar ${list(args)}.`;
  },
  /**
   * Is not an allowed value
   * @see {@link https://formkit.com/essentials/validation#is}
   */
  is({ name }) {
    return `${name} nav atļauta vērtība.`;
  },
  /**
   * Does not match specified length
   * @see {@link https://formkit.com/essentials/validation#length}
   */
  length({ name, args: [first = 0, second = Infinity] }) {
    const min = Number(first) <= Number(second) ? first : second;
    const max = Number(second) >= Number(first) ? second : first;
    if (min == 1 && max === Infinity) {
      return `${name} jābūt vismaz vienam simbolam.`;
    }
    if (min == 0 && max) {
      return `${name} jābūt mazāk par vai ${max} simboliem.`;
    }
    if (min === max) {
      return `${name} jābūt ${max} simbolu garumā.`;
    }
    if (min && max === Infinity) {
      return `${name} jābūt vismaz ${min} simboliem.`;
    }
    return `${name} jābūt starp ${min} un ${max} simboliem.`;
  },
  /**
   * Value is not a match
   * @see {@link https://formkit.com/essentials/validation#matches}
   */
  matches({ name }) {
    return `${name} nav atļauta vērtība.`;
  },
  /**
   * Exceeds maximum allowed value
   * @see {@link https://formkit.com/essentials/validation#max}
   */
  max({ name, node: { value }, args }) {
    if (Array.isArray(value)) {
      return `Nevar būt vairāk par ${args[0]} ${name}.`;
    }
    return `${name} nevar būt mazāk par ${args[0]} vai ${args[0]}.`;
  },
  /**
   * The (field-level) value does not match specified mime type
   * @see {@link https://formkit.com/essentials/validation#mime}
   */
  mime({ name, args }) {
    if (!args[0]) {
      return "Atļauti nenoteikti faila formāti.";
    }
    return `${sentence(name)} faila formāti var būt šādi: ${args[0]}`;
  },
  /**
   * Does not fulfill minimum allowed value
   * @see {@link https://formkit.com/essentials/validation#min}
   */
  min({ name, node: { value }, args }) {
    if (Array.isArray(value)) {
      return `Nevar būt mazāk par ${args[0]} ${name}.`;
    }
    return `Jābūt vismaz ${args[0]} ${name}.`;
  },
  /**
   * Is not an allowed value
   * @see {@link https://formkit.com/essentials/validation#not}
   */
  not({ name, node: { value } }) {
    return `“${value}” nav atļauta vērtība iekš ${name}.`;
  },
  /**
   *  Is not a number
   * @see {@link https://formkit.com/essentials/validation#number}
   */
  number({ name }) {
    return `${name} jābūt ciparam.`;
  },
  /**
   * Required field.
   * @see {@link https://formkit.com/essentials/validation#required}
   */
  required({ name }) {
    return `${name} ir obligāti jāaizpilda`;
  },
  /**
   * Does not start with specified value
   * @see {@link https://formkit.com/essentials/validation#starts-with}
   */
  starts_with({ name, args }) {
    return `${name} nesākas ar ${list(args)}.`;
  },
  /**
   * Is not a url
   * @see {@link https://formkit.com/essentials/validation#url}
   */
  url() {
    return `Lūdzu pievienojiet pareizu URL.`;
  },
  /**
   * Shown when the date is invalid.
   */
  invalidDate: "Izvēlētais datums ir nepareizs."
};
var lv = { ui: ui26, validation: validation26 };

// packages/i18n/src/locales/mn.ts
var ui27 = {
  /**
   * Shown on a button for adding additional items.
   */
  add: "Нэмэх",
  /**
   * Shown when a button to remove items is visible.
   */
  remove: "Хасах",
  /**
   * Shown when there are multiple items to remove at the same time.
   */
  removeAll: "Бүгдийг хасах",
  /**
   * Shown when all fields are not filled out correctly.
   */
  incomplete: "Уучлраарай, зарим нүдэн дахь өгөгдөл дутуу байна.",
  /**
   * Shown in a button inside a form to submit the form.
   */
  submit: "Илгээх",
  /**
   * Shown when no files are selected.
   */
  noFiles: "Файл сонгоогүй байна",
  /**
   * Shown on buttons that move fields up in a list.
   */
  moveUp: "Дээшээ",
  /**
   * Shown on buttons that move fields down in a list.
   */
  moveDown: "Доошоо",
  /**
   * Shown when something is actively loading.
   */
  isLoading: "Ачааллаж байна...",
  /**
   * Shown when there is more to load.
   */
  loadMore: "Нэмж ачааллах",
  /**
   * Show on buttons that navigate state forward
   */
  next: "Дараагийн",
  /**
   * Show on buttons that navigate state backward
   */
  prev: "Өмнөх",
  /**
   * Shown when adding all values.
   */
  addAllValues: "Бүх утгуудыг нэмэх",
  /**
   * Shown when adding selected values.
   */
  addSelectedValues: "Сонгогдсон утгуудыг нэмэх",
  /**
   * Shown when removing all values.
   */
  removeAllValues: "Бүх утгуудыг устгах",
  /**
   * Shown when removing selected values.
   */
  removeSelectedValues: "Сонгогдсон утгуудыг хасах",
  /**
   * Shown when there is a date to choose.
   */
  chooseDate: "Огноо сонгох",
  /**
   * Shown when there is a date to change.
   */
  changeDate: "Огноо өөрчлөх",
  /**
   * Shown when there is something to close
   */
  close: "Хаах",
  /**
   * Shown when there is something to open.
   */
  open: "Нээлттэй"
};
var validation27 = {
  /**
   * The value is not an accepted value.
   * @see {@link https://formkit.com/essentials/validation#accepted}
   */
  accepted({ name }) {
    return `${name} утгыг зөвшөөрнө үү.`;
  },
  /**
   * The date is not after
   * @see {@link https://formkit.com/essentials/validation#date-after}
   */
  date_after({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${sentence(name)} нь ${date(args[0])}-ны дараа орох ёстой.`;
    }
    return `${sentence(name)} утга ирээдүйг заах ёстой.`;
  },
  /**
   * The value is not a letter.
   * @see {@link https://formkit.com/essentials/validation#alpha}
   */
  alpha({ name }) {
    return `${sentence(name)} зөвхөн үсэг агуулах ёстой.`;
  },
  /**
   * The value is not alphanumeric
   * @see {@link https://formkit.com/essentials/validation#alphanumeric}
   */
  alphanumeric({ name }) {
    return `${sentence(name)} зөвхөн үсэг болон тоог агуулах ёстой.`;
  },
  /**
   * The value is not letter and/or spaces
   * @see {@link https://formkit.com/essentials/validation#alpha-spaces}
   */
  alpha_spaces({ name }) {
    return `${sentence(name)} зөвхөн үсэг болон зай агуулах ёстой.`;
  },
  /**
   * The date is not before
   * @see {@link https://formkit.com/essentials/validation#date-before}
   */
  date_before({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${sentence(name)} нь ${date(args[0])}-ны өмнө байх ёстой.`;
    }
    return `${sentence(name)} өнгөрсөн огноо байх ёстой.`;
  },
  /**
   * The value is not between two numbers
   * @see {@link https://formkit.com/essentials/validation#between}
   */
  between({ name, args }) {
    if (isNaN(args[0]) || isNaN(args[1])) {
      return `Энэ нүдэн дэхь өгөгдөл буруу учраас илгээх боломжгүй.`;
    }
    const [a, b] = order(args[0], args[1]);
    return `${sentence(name)} нь заавал ${a}, ${b} хоёрын дунд байх ёстой.`;
  },
  /**
   * The confirmation field does not match
   * @see {@link https://formkit.com/essentials/validation#confirm}
   */
  confirm({ name }) {
    return `${sentence(name)} таарахгүй байна.`;
  },
  /**
   * The value is not a valid date
   * @see {@link https://formkit.com/essentials/validation#date-format}
   */
  date_format({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${sentence(name)} нь хүчинтэй огноо биш тул ${args[0]} гэсэн огноог ашиглаарай.`;
    }
    return "Энэхүү нүд буруу тул цааш илгээх боломжгүй.";
  },
  /**
   * Is not within expected date range
   * @see {@link https://formkit.com/essentials/validation#date-between}
   */
  date_between({ name, args }) {
    return `${sentence(name)} нь заавал ${date(args[0])}, ${date(
      args[1]
    )} хоёр огноон дунд байх ёстой.`;
  },
  /**
   * Shown when the user-provided value is not a valid email address.
   * @see {@link https://formkit.com/essentials/validation#email}
   */
  email: "Та хүчинтэй имейл хаягаа оруулна уу.",
  /**
   * Does not end with the specified value
   * @see {@link https://formkit.com/essentials/validation#ends-with}
   */
  ends_with({ name, args }) {
    return `${sentence(name)} нь ${list(args)} гэсэн утгаар төгсөөгүй байна.`;
  },
  /**
   * Is not an allowed value
   * @see {@link https://formkit.com/essentials/validation#is}
   */
  is({ name }) {
    return `${sentence(name)} нь зөвшөөрөгдөх утга биш.`;
  },
  /**
   * Does not match specified length
   * @see {@link https://formkit.com/essentials/validation#length}
   */
  length({ name, args: [first = 0, second = Infinity] }) {
    const min = Number(first) <= Number(second) ? first : second;
    const max = Number(second) >= Number(first) ? second : first;
    if (min == 1 && max === Infinity) {
      return `${sentence(name)} дээр хаяж нэг үсэг байх ёстой`;
    }
    if (min == 0 && max) {
      return `${sentence(name)}-н урт нь ${max}-ээс ихгүй байх ёстой.`;
    }
    if (min === max) {
      return `${sentence(name)} нь ${max} урт байвал зүгээр.`;
    }
    if (min && max === Infinity) {
      return `${sentence(name)}-н урт нь ${min}-ээс их буюу тэнцүү байж болно.`;
    }
    return `${sentence(name)}-н урт нь ${min}, ${max} хоёрын дунд байх ёстой.`;
  },
  /**
   * Value is not a match
   * @see {@link https://formkit.com/essentials/validation#matches}
   */
  matches({ name }) {
    return `${sentence(name)} нь зөвшөөрөгдөх утга биш.`;
  },
  /**
   * Exceeds maximum allowed value
   * @see {@link https://formkit.com/essentials/validation#max}
   */
  max({ name, node: { value }, args }) {
    if (Array.isArray(value)) {
      return `${name} нь ${args[0]}-аас их байж болохгүй.`;
    }
    return `${sentence(name)} нь ${args[0]}-тай тэнцүү эсвэл бага байх ёстой.`;
  },
  /**
   * The (field-level) value does not match specified mime type
   * @see {@link https://formkit.com/essentials/validation#mime}
   */
  mime({ name, args }) {
    if (!args[0]) {
      return "Файлын формат буруу.";
    }
    return `${sentence(name)} төрөл нь ${args[0]} байх ёстой.`;
  },
  /**
   * Does not fulfill minimum allowed value
   * @see {@link https://formkit.com/essentials/validation#min}
   */
  min({ name, node: { value }, args }) {
    if (Array.isArray(value)) {
      return `${name} нь ${args[0]}-аас их байж болохгүй.`;
    }
    return `${name} нь дор хаяж ${args[0]}-тай тэнцүү байх ёстой.`;
  },
  /**
   * Is not an allowed value
   * @see {@link https://formkit.com/essentials/validation#not}
   */
  not({ name, node: { value } }) {
    return `“${value}” бол зөвшөөрөгдөх ${name} гэсэн утга биш.`;
  },
  /**
   *  Is not a number
   * @see {@link https://formkit.com/essentials/validation#number}
   */
  number({ name }) {
    return `${sentence(name)} зөвхөн тоо байх ёстой.`;
  },
  /**
   * Required field.
   * @see {@link https://formkit.com/essentials/validation#required}
   */
  required({ name }) {
    return `${sentence(name)} байх ёстой.`;
  },
  /**
   * Does not start with specified value
   * @see {@link https://formkit.com/essentials/validation#starts-with}
   */
  starts_with({ name, args }) {
    return `${sentence(name)} нь ${list(args)}-ээр эхлээгүй байна.`;
  },
  /**
   * Is not a url
   * @see {@link https://formkit.com/essentials/validation#url}
   */
  url() {
    return `Хүчннтай URL оруулна уу.`;
  },
  /**
   * Shown when the date is invalid.
   */
  invalidDate: "Сонгосон огноо буруу байна."
};
var mn = { ui: ui27, validation: validation27 };
var ui28 = {
  /**
   * Shown on a button for adding additional items.
   */
  add: "Legg til",
  /**
   * Shown when a button to remove items is visible.
   */
  remove: "Fjern",
  /**
   * Shown when there are multiple items to remove at the same time.
   */
  removeAll: "Fjern alle",
  /**
   * Shown when all fields are not filled out correctly.
   */
  incomplete: "Beklager, noen felter er ikke fylt ut korrekt.",
  /**
   * Shown in a button inside a form to submit the form.
   */
  submit: "Send inn",
  /**
   * Shown when no files are selected.
   */
  noFiles: "Ingen fil valgt",
  /**
   * Shown on buttons that move fields up in a list.
   */
  moveUp: "Flytt opp",
  /**
   * Shown on buttons that move fields down in a list.
   */
  moveDown: "Flytt ned",
  /**
   * Shown when something is actively loading.
   */
  isLoading: "Laster...",
  /**
   * Shown when there is more to load.
   */
  loadMore: "Last mer",
  /**
   * Show on buttons that navigate state forward
   */
  next: "Neste",
  /**
   * Show on buttons that navigate state backward
   */
  prev: "Forrige",
  /**
   * Shown when adding all values.
   */
  addAllValues: "Legg til alle verdier",
  /**
   * Shown when adding selected values.
   */
  addSelectedValues: "Legg til valgte verdier",
  /**
   * Shown when removing all values.
   */
  removeAllValues: "Fjern alle verdier",
  /**
   * Shown when removing selected values.
   */
  removeSelectedValues: "Fjern valgte verdier",
  /**
   * Shown when there is a date to choose.
   */
  chooseDate: "Velg dato",
  /**
   * Shown when there is a date to change.
   */
  changeDate: "Endre dato"
};
var validation28 = {
  /**
   * The value is not an accepted value.
   * @see {@link https://formkit.com/essentials/validation#accepted}
   */
  accepted({ name }) {
    return `Vennligst aksepter ${name}.`;
  },
  /**
   * The date is not after
   * @see {@link https://formkit.com/essentials/validation#date-after}
   */
  date_after({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${sentence(name)} må være senere enn ${date(args[0])}.`;
    }
    return `${sentence(name)} må være i fremtiden.`;
  },
  /**
   * The value is not a letter.
   * @see {@link https://formkit.com/essentials/validation#alpha}
   */
  alpha({ name }) {
    return `${sentence(name)} kan bare inneholde alfabetiske tegn.`;
  },
  /**
   * The value is not alphanumeric
   * @see {@link https://formkit.com/essentials/validation#alphanumeric}
   */
  alphanumeric({ name }) {
    return `${sentence(name)} kan bare inneholde bokstaver og tall.`;
  },
  /**
   * The value is not letter and/or spaces
   * @see {@link https://formkit.com/essentials/validation#alpha-spaces}
   */
  alpha_spaces({ name }) {
    return `${sentence(name)} kan bare inneholde bokstaver og mellomrom.`;
  },
  /**
   * The value have no letter.
   * @see {@link https://formkit.com/essentials/validation#contains_alpha}
   */
  contains_alpha({ name }) {
    return `${sentence(name)} must contain alphabetical characters.`;
  },
  /**
   * The value have no alphanumeric
   * @see {@link https://formkit.com/essentials/validation#contains_alphanumeric}
   */
  contains_alphanumeric({ name }) {
    return `${sentence(name)} must contain letters and numbers.`;
  },
  /**
   * The value have no letter and/or spaces
   * @see {@link https://formkit.com/essentials/validation#contains_alpha-spaces}
   */
  contains_alpha_spaces({ name }) {
    return `${sentence(name)} must contain letters and spaces.`;
  },
  /**
   * The value have no symbol
   * @see {@link https://formkit.com/essentials/validation#contains_symbol}
   */
  contains_symbol({ name }) {
    return `${sentence(name)} must contain symbol.`;
  },
  /**
   * The value have no uppercase
   * @see {@link https://formkit.com/essentials/validation#contains_uppercase}
   */
  contains_uppercase({ name }) {
    return `${sentence(name)} must contain uppercase.`;
  },
  /**
   * The value have no lowercase
   * @see {@link https://formkit.com/essentials/validation#contains_lowercase}
   */
  contains_lowercase({ name }) {
    return `${sentence(name)} must contain lowercase.`;
  },
  /**
   *  The value have no numeric
   * @see {@link https://formkit.com/essentials/validation#contains_numeric}
   */
  contains_numeric({ name }) {
    return `${sentence(name)} must contain number.`;
  },
  /**
   * The value is not symbol
   * @see {@link https://formkit.com/essentials/validation#symbol}
   */
  symbol({ name }) {
    return `${sentence(name)} can only contain symbol.`;
  },
  /**
   * The value is not uppercase
   * @see {@link https://formkit.com/essentials/validation#uppercase}
   */
  uppercase({ name }) {
    return `${sentence(name)} can only contain uppercase.`;
  },
  /**
   * The value is not lowercase
   * @see {@link https://formkit.com/essentials/validation#lowercase}
   */
  lowercase({ name }) {
    return `${sentence(name)} can only contain lowercase.`;
  },
  /**
   * The date is not before
   * @see {@link https://formkit.com/essentials/validation#date-before}
   */
  date_before({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${sentence(name)} må være tidligere enn ${date(args[0])}.`;
    }
    return `${sentence(name)} må være i fortiden.`;
  },
  /**
   * The value is not between two numbers
   * @see {@link https://formkit.com/essentials/validation#between}
   */
  between({ name, args }) {
    if (isNaN(args[0]) || isNaN(args[1])) {
      return `Dette feltet er feilkonfigurert og kan ikke innsendes.`;
    }
    const [a, b] = order(args[0], args[1]);
    return `${sentence(name)} må være mellom ${a} og ${b}.`;
  },
  /**
   * The confirmation field does not match
   * @see {@link https://formkit.com/essentials/validation#confirm}
   */
  confirm({ name }) {
    return `${sentence(name)} stemmer ikke overens.`;
  },
  /**
   * The value is not a valid date
   * @see {@link https://formkit.com/essentials/validation#date-format}
   */
  date_format({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${sentence(name)} er ikke en gyldig dato, vennligst bruk formatet ${args[0]}`;
    }
    return "Dette feltet er feilkonfigurert og kan ikke innsendes.";
  },
  /**
   * Is not within expected date range
   * @see {@link https://formkit.com/essentials/validation#date-between}
   */
  date_between({ name, args }) {
    return `${sentence(name)} må være mellom ${date(args[0])} og ${date(args[1])}`;
  },
  /**
   * Shown when the user-provided value is not a valid email address.
   * @see {@link https://formkit.com/essentials/validation#email}
   */
  email: "Vennligst oppgi en gyldig epostadresse.",
  /**
   * Does not end with the specified value
   * @see {@link https://formkit.com/essentials/validation#ends-with}
   */
  ends_with({ name, args }) {
    return `${sentence(name)} slutter ikke med ${list(args)}.`;
  },
  /**
   * Is not an allowed value
   * @see {@link https://formkit.com/essentials/validation#is}
   */
  is({ name }) {
    return `${sentence(name)} er ikke en tillatt verdi.`;
  },
  /**
   * Does not match specified length
   * @see {@link https://formkit.com/essentials/validation#length}
   */
  length({ name, args: [first = 0, second = Infinity] }) {
    const min = Number(first) <= Number(second) ? first : second;
    const max = Number(second) >= Number(first) ? second : first;
    if (min == 1 && max === Infinity) {
      return `${sentence(name)} må ha minst ett tegn.`;
    }
    if (min == 0 && max) {
      return `${sentence(name)} må ha mindre enn eller nøyaktig ${max} tegn.`;
    }
    if (min === max) {
      return `${sentence(name)} skal være ${max} tegn langt.`;
    }
    if (min && max === Infinity) {
      return `${sentence(name)} må ha mer enn eller nøyaktig ${min} tegn.`;
    }
    return `${sentence(name)} må ha mellom ${min} og ${max} tegn.`;
  },
  /**
   * Value is not a match
   * @see {@link https://formkit.com/essentials/validation#matches}
   */
  matches({ name }) {
    return `${sentence(name)} er ikke en tillatt verdi.`;
  },
  /**
   * Exceeds maximum allowed value
   * @see {@link https://formkit.com/essentials/validation#max}
   */
  max({ name, node: { value }, args }) {
    if (Array.isArray(value)) {
      return `Kan ikke ha mer enn ${args[0]} ${name}.`;
    }
    return `${sentence(name)} må være mindre enn eller nøyaktig ${args[0]}.`;
  },
  /**
   * The (field-level) value does not match specified mime type
   * @see {@link https://formkit.com/essentials/validation#mime}
   */
  mime({ name, args }) {
    if (!args[0]) {
      return "Ingen tillatte filformater.";
    }
    return `${sentence(name)} må være av typen: ${args[0]}`;
  },
  /**
   * Does not fulfill minimum allowed value
   * @see {@link https://formkit.com/essentials/validation#min}
   */
  min({ name, node: { value }, args }) {
    if (Array.isArray(value)) {
      return `Kan ikke ha mindre enn ${args[0]} ${name}.`;
    }
    return `${sentence(name)} må være minst ${args[0]}.`;
  },
  /**
   * Is not an allowed value
   * @see {@link https://formkit.com/essentials/validation#not}
   */
  not({ name, node: { value } }) {
    return `“${value}” er ikke en tillatt ${name}.`;
  },
  /**
   *  Is not a number
   * @see {@link https://formkit.com/essentials/validation#number}
   */
  number({ name }) {
    return `${sentence(name)} må være et tall.`;
  },
  /**
   * Require one field.
   * @see {@link https://formkit.com/essentials/validation#require-one}
   */
  require_one: ({ name, node, args: inputNames }) => {
    const labels = inputNames.map((name2) => {
      const dependentNode = node.at(name2);
      if (dependentNode) {
        return createMessageName(dependentNode);
      }
      return false;
    }).filter((name2) => !!name2);
    labels.unshift(name);
    return `${labels.join(" eller ")} er nødvendig.`;
  },
  /**
   * Required field.
   * @see {@link https://formkit.com/essentials/validation#required}
   */
  required({ name }) {
    return `${sentence(name)} er påkrevd.`;
  },
  /**
   * Does not start with specified value
   * @see {@link https://formkit.com/essentials/validation#starts-with}
   */
  starts_with({ name, args }) {
    return `${sentence(name)} starter ikke med ${list(args)}.`;
  },
  /**
   * Is not a url
   * @see {@link https://formkit.com/essentials/validation#url}
   */
  url() {
    return `Vennligst inkluder en gyldig url.`;
  },
  /**
   * Shown when the date is invalid.
   */
  invalidDate: "Den valgte datoen er ugyldig."
};
var nb = { ui: ui28, validation: validation28 };
var ui29 = {
  /**
   * Shown on buttons for adding new items.
   */
  add: "Toevoegen",
  /**
   * Shown when a button to remove items is visible.
   */
  remove: "Verwijderen",
  /**
   * Shown when there are multiple items to remove at the same time.
   */
  removeAll: "Alles verwijderen",
  /**
   * Shown when all fields are not filled out correctly.
   */
  incomplete: "Sorry, niet alle velden zijn correct ingevuld.",
  /**
   * Shown in a button inside a form to submit the form.
   */
  submit: "Versturen",
  /**
   * Shown when no files are selected.
   */
  noFiles: "Geen bestand gekozen",
  /**
   * Shown on buttons that move fields up in a list.
   */
  moveUp: "Naar boven gaan",
  /**
   * Shown on buttons that move fields down in a list.
   */
  moveDown: "Naar beneden verplaatsen",
  /**
   * Shown when something is actively loading.
   */
  isLoading: "Aan het laden...",
  /**
   * Shown when there is more to load.
   */
  loadMore: "Meer laden",
  /**
   * Shown on buttons that navigate state forward
   */
  next: "Vervolgens",
  /**
   * Shown on buttons that navigate state backward
   */
  prev: "Voorgaand",
  /**
   * Shown when adding all values.
   */
  addAllValues: "Alle waarden toevoegen",
  /**
   * Shown when adding selected values.
   */
  addSelectedValues: "Geselecteerde waarden toevoegen",
  /**
   * Shown when removing all values.
   */
  removeAllValues: "Alle waarden verwijderen",
  /**
   * Shown when removing selected values.
   */
  removeSelectedValues: "Geselecteerde waarden verwijderen",
  /**
   * Shown when there is a date to choose.
   */
  chooseDate: "Kies een datum",
  /**
   * Shown when there is a date to change.
   */
  changeDate: "Datum wijzigen",
  /**
   * Shown when there is something to close
   */
  close: "Sluiten",
  /**
   * Shown when there is something to open.
   */
  open: "Open"
};
var validation29 = {
  /**
   * The value is not an accepted value.
   * @see {@link https://formkit.com/essentials/validation#accepted}
   */
  accepted({ name }) {
    return `Accepteer de ${name}.`;
  },
  /**
   * The date is not after
   * @see {@link https://formkit.com/essentials/validation#date-after}
   */
  date_after({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${sentence(name)} moet na ${date(args[0])} zijn.`;
    }
    return `${sentence(name)} moet in de toekomst liggen.`;
  },
  /**
   * The value is not a letter.
   * @see {@link https://formkit.com/essentials/validation#alpha}
   */
  alpha({ name }) {
    return `${sentence(name)} mag alleen alfabetische tekens bevatten.`;
  },
  /**
   * The value is not alphanumeric
   * @see {@link https://formkit.com/essentials/validation#alphanumeric}
   */
  alphanumeric({ name }) {
    return `${sentence(name)} mag alleen letters en cijfers bevatten.`;
  },
  /**
   * The value is not letter and/or spaces
   * @see {@link https://formkit.com/essentials/validation#alpha-spaces}
   */
  alpha_spaces({ name }) {
    return `${sentence(name)} mag alleen letters en spaties bevatten.`;
  },
  /**
   * The value have no letter.
   * @see {@link https://formkit.com/essentials/validation#contains_alpha}
   */
  contains_alpha({ name }) {
    return `${sentence(name)} moet alfabetische tekens bevatten.`;
  },
  /**
   * The value have no alphanumeric
   * @see {@link https://formkit.com/essentials/validation#contains_alphanumeric}
   */
  contains_alphanumeric({ name }) {
    return `${sentence(name)} moet letters of cijfers bevatten.`;
  },
  /**
   * The value have no letter and/or spaces
   * @see {@link https://formkit.com/essentials/validation#contains_alpha-spaces}
   */
  contains_alpha_spaces({ name }) {
    return `${sentence(name)} moet letters of spaties bevatten.`;
  },
  /**
   * The value have no symbol
   * @see {@link https://formkit.com/essentials/validation#contains_symbol}
   */
  contains_symbol({ name }) {
    return `${sentence(name)} moet een symbool bevatten.`;
  },
  /**
   * The value have no uppercase
   * @see {@link https://formkit.com/essentials/validation#contains_uppercase}
   */
  contains_uppercase({ name }) {
    return `${sentence(name)} moet hoofdletters bevatten.`;
  },
  /**
   * The value have no lowercase
   * @see {@link https://formkit.com/essentials/validation#contains_lowercase}
   */
  contains_lowercase({ name }) {
    return `${sentence(name)} moet kleine letters bevatten.`;
  },
  /**
   *  The value have no numeric
   * @see {@link https://formkit.com/essentials/validation#contains_numeric}
   */
  contains_numeric({ name }) {
    return `${sentence(name)} moet cijfers bevatten.`;
  },
  /**
   * The value is not symbol
   * @see {@link https://formkit.com/essentials/validation#symbol}
   */
  symbol({ name }) {
    return `${sentence(name)} moet een symbool zijn.`;
  },
  /**
   * The value is not uppercase
   * @see {@link https://formkit.com/essentials/validation#uppercase}
   */
  uppercase({ name }) {
    return `${sentence(name)} mag alleen hoofdletters bevatten.`;
  },
  /**
   * The value is not lowercase
   * @see {@link https://formkit.com/essentials/validation#lowercase}
   */
  lowercase({ name }) {
    return `${sentence(name)} mag alleen kleine letters bevatten.`;
  },
  /**
   * The date is not before
   * @see {@link https://formkit.com/essentials/validation#date-before}
   */
  date_before({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${sentence(name)} moet vóór ${date(args[0])} vallen.`;
    }
    return `${sentence(name)} moet in het verleden liggen.`;
  },
  /**
   * The value is not between two numbers
   * @see {@link https://formkit.com/essentials/validation#between}
   */
  between({ name, args }) {
    if (isNaN(args[0]) || isNaN(args[1])) {
      return `Dit veld is onjuist geconfigureerd en kan niet worden verzonden.`;
    }
    const [a, b] = order(args[0], args[1]);
    return `${sentence(name)} moet tussen ${a} en ${b} liggen.`;
  },
  /**
   * The confirmation field does not match
   * @see {@link https://formkit.com/essentials/validation#confirm}
   */
  confirm({ name }) {
    return `${sentence(name)} komt niet overeen.`;
  },
  /**
   * The value is not a valid date
   * @see {@link https://formkit.com/essentials/validation#date-format}
   */
  date_format({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${sentence(name)} is geen geldige datum, gebruik de notatie ${args[0]}`;
    }
    return "Dit veld is onjuist geconfigureerd en kan niet worden verzonden";
  },
  /**
   * Is not within expected date range
   * @see {@link https://formkit.com/essentials/validation#date-between}
   */
  date_between({ name, args }) {
    return `${sentence(name)} moet tussen ${date(args[0])} en ${date(args[1])} liggen`;
  },
  /**
   * Shown when the user-provided value is not a valid email address.
   * @see {@link https://formkit.com/essentials/validation#email}
   */
  email: "Vul een geldig e-mailadres in.",
  /**
   * Does not end with the specified value
   * @see {@link https://formkit.com/essentials/validation#ends-with}
   */
  ends_with({ name, args }) {
    return `${sentence(name)} eindigt niet met ${list(args)}.`;
  },
  /**
   * Is not an allowed value
   * @see {@link https://formkit.com/essentials/validation#is}
   */
  is({ name }) {
    return `${sentence(name)} is geen toegestane waarde.`;
  },
  /**
   * Does not match specified length
   * @see {@link https://formkit.com/essentials/validation#length}
   */
  length({ name, args: [first = 0, second = Infinity] }) {
    const min = Number(first) <= Number(second) ? first : second;
    const max = Number(second) >= Number(first) ? second : first;
    if (min == 1 && max === Infinity) {
      return `${sentence(name)} moet minimaal één teken zijn.`;
    }
    if (min == 0 && max) {
      return `${sentence(name)} mag maximaal ${max} tekens lang zijn.`;
    }
    if (min === max) {
      return `${sentence(name)} moet ${max} tekens lang zijn.`;
    }
    if (min && max === Infinity) {
      return `${sentence(name)} moet minimaal ${min} tekens lang zijn.`;
    }
    return `${sentence(name)} moet tussen de ${min} en ${max} tekens zijn.`;
  },
  /**
   * Value is not a match
   * @see {@link https://formkit.com/essentials/validation#matches}
   */
  matches({ name }) {
    return `${sentence(name)} is geen toegestane waarde.`;
  },
  /**
   * Exceeds maximum allowed value
   * @see {@link https://formkit.com/essentials/validation#max}
   */
  max({ name, node: { value }, args }) {
    if (Array.isArray(value)) {
      return `Mag niet meer dan ${args[0]} ${name} hebben.`;
    }
    return `${sentence(name)} moet kleiner zijn dan of gelijk zijn aan ${args[0]}.`;
  },
  /**
   * The (field-level) value does not match specified mime type
   * @see {@link https://formkit.com/essentials/validation#mime}
   */
  mime({ name, args }) {
    if (!args[0]) {
      return "Geen bestandsformaten toegestaan.";
    }
    return `${sentence(name)} moet van het type: ${args[0]} zijn`;
  },
  /**
   * Does not fulfill minimum allowed value
   * @see {@link https://formkit.com/essentials/validation#min}
   */
  min({ name, node: { value }, args }) {
    if (Array.isArray(value)) {
      return `Mag niet minder dan ${args[0]} ${name} hebben.`;
    }
    return `${sentence(name)} moet minimaal ${args[0]} zijn.`;
  },
  /**
   * Is not an allowed value
   * @see {@link https://formkit.com/essentials/validation#not}
   */
  not({ name, node: { value } }) {
    return `"${value}" is geen toegestane ${name}.`;
  },
  /**
   *  Is not a number
   * @see {@link https://formkit.com/essentials/validation#number}
   */
  number({ name }) {
    return `${sentence(name)} moet een getal zijn.`;
  },
  /**
   * Require one field.
   * @see {@link https://formkit.com/essentials/validation#require-one}
   */
  require_one: ({ name, node, args: inputNames }) => {
    const labels = inputNames.map((name2) => {
      const dependentNode = node.at(name2);
      if (dependentNode) {
        return createMessageName(dependentNode);
      }
      return false;
    }).filter((name2) => !!name2);
    labels.unshift(name);
    return `${labels.join(" of ")} is vereist.`;
  },
  /**
   * Required field.
   * @see {@link https://formkit.com/essentials/validation#required}
   */
  required({ name }) {
    return `${sentence(name)} is verplicht.`;
  },
  /**
   * Does not start with specified value
   * @see {@link https://formkit.com/essentials/validation#starts-with}
   */
  starts_with({ name, args }) {
    return `${sentence(name)} begint niet met ${list(args)}.`;
  },
  /**
   * Is not a url
   * @see {@link https://formkit.com/essentials/validation#url}
   */
  url() {
    return `Voer een geldige URL in.`;
  },
  /**
   * Shown when the date is invalid.
   */
  invalidDate: "De geselecteerde datum is ongeldig."
};
var nl = { ui: ui29, validation: validation29 };
var ui30 = {
  /**
   * Shown on buttons for adding new items.
   */
  add: "Dodaj",
  /**
   * Shown when a button to remove items is visible.
   */
  remove: "Usuń",
  /**
   * Shown when there are multiple items to remove at the same time.
   */
  removeAll: "Usuń wszystko",
  /**
   * Shown when all fields are not filled out correctly.
   */
  incomplete: "Nie wszystkie pola zostały wypełnione poprawnie.",
  /**
   * Shown in a button inside a form to submit the form.
   */
  submit: "Wyślij",
  /**
   * Shown when no files are selected.
   */
  noFiles: "Nie wybrano pliku",
  /**
   * Shown on buttons that move fields up in a list.
   */
  moveUp: "Przesuń w górę",
  /**
   * Shown on buttons that move fields down in a list.
   */
  moveDown: "Przesuń w dół",
  /**
   * Shown when something is actively loading.
   */
  isLoading: "Ładowanie...",
  /**
   * Shown when there is more to load.
   */
  loadMore: "Załaduj więcej",
  /**
   * Shown on buttons that navigate state forward
   */
  next: "Kolejny",
  /**
   * Shown on buttons that navigate state backward
   */
  prev: "Poprzednia",
  /**
   * Shown when adding all values.
   */
  addAllValues: "Dodaj wszystkie wartości",
  /**
   * Shown when adding selected values.
   */
  addSelectedValues: "Dodaj wybrane wartości",
  /**
   * Shown when removing all values.
   */
  removeAllValues: "Usuń wszystkie wartości",
  /**
   * Shown when removing selected values.
   */
  removeSelectedValues: "Usuń wybrane wartości",
  /**
   * Shown when there is a date to choose.
   */
  chooseDate: "Wybierz datę",
  /**
   * Shown when there is a date to change.
   */
  changeDate: "Zmień datę",
  /**
   * Shown when there is something to close
   */
  close: "Zamknij",
  /**
   * Shown when there is something to open.
   */
  open: "Otwórz"
};
var validation30 = {
  /**
   * The value is not an accepted value.
   * @see {@link https://formkit.com/essentials/validation#accepted}
   */
  accepted({ name }) {
    return `Proszę zaakceptować ${name}.`;
  },
  /**
   * The date is not after
   * @see {@link https://formkit.com/essentials/validation#date-after}
   */
  date_after({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${sentence(name)} musi być po ${date(args[0])}.`;
    }
    return `${sentence(name)} musi być w przyszłości.`;
  },
  /**
   * The value is not a letter.
   * @see {@link https://formkit.com/essentials/validation#alpha}
   */
  alpha({ name }) {
    return `Pole ${sentence(name)} może zawierać tylko znaki alfabetyczne.`;
  },
  /**
   * The value is not alphanumeric
   * @see {@link https://formkit.com/essentials/validation#alphanumeric}
   */
  alphanumeric({ name }) {
    return `Pole ${sentence(name)} może zawierać tylko znaki alfanumeryczne.`;
  },
  /**
   * The value is not letter and/or spaces
   * @see {@link https://formkit.com/essentials/validation#alpha-spaces}
   */
  alpha_spaces({ name }) {
    return `Pole ${sentence(name)} mogą zawierać tylko litery i spacje.`;
  },
  /**
   * The value have no letter.
   * @see {@link https://formkit.com/essentials/validation#contains_alpha}
   */
  contains_alpha({ name }) {
    return `${sentence(name)} musi zawierać znaki alfabetyczne.`;
  },
  /**
   * The value have no alphanumeric
   * @see {@link https://formkit.com/essentials/validation#contains_alphanumeric}
   */
  contains_alphanumeric({ name }) {
    return `${sentence(name)} musi zawierać litery lub cyfry.`;
  },
  /**
   * The value have no letter and/or spaces
   * @see {@link https://formkit.com/essentials/validation#contains_alpha-spaces}
   */
  contains_alpha_spaces({ name }) {
    return `${sentence(name)} musi zawierać litery lub spacje.`;
  },
  /**
   * The value have no symbol
   * @see {@link https://formkit.com/essentials/validation#contains_symbol}
   */
  contains_symbol({ name }) {
    return `${sentence(name)} musi zawierać symbol.`;
  },
  /**
   * The value have no uppercase
   * @see {@link https://formkit.com/essentials/validation#contains_uppercase}
   */
  contains_uppercase({ name }) {
    return `${sentence(name)} musi zawierać wielkie litery.`;
  },
  /**
   * The value have no lowercase
   * @see {@link https://formkit.com/essentials/validation#contains_lowercase}
   */
  contains_lowercase({ name }) {
    return `${sentence(name)} musi zawierać małe litery.`;
  },
  /**
   *  The value have no numeric
   * @see {@link https://formkit.com/essentials/validation#contains_numeric}
   */
  contains_numeric({ name }) {
    return `${sentence(name)} musi zawierać liczby.`;
  },
  /**
   * The value is not symbol
   * @see {@link https://formkit.com/essentials/validation#symbol}
   */
  symbol({ name }) {
    return `${sentence(name)} musi być symbolem.`;
  },
  /**
   * The value is not uppercase
   * @see {@link https://formkit.com/essentials/validation#uppercase}
   */
  uppercase({ name }) {
    return `${sentence(name)} może zawierać tylko wielkie litery.`;
  },
  /**
   * The value is not lowercase
   * @see {@link https://formkit.com/essentials/validation#lowercase}
   */
  lowercase({ name }) {
    return `${sentence(name)} może zawierać tylko małe litery.`;
  },
  /**
   * The date is not before
   * @see {@link https://formkit.com/essentials/validation#date-before}
   */
  date_before({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${sentence(name)} musi być przed ${date(args[0])}.`;
    }
    return `${sentence(name)} musi być w przeszłości.`;
  },
  /**
   * The value is not between two numbers
   * @see {@link https://formkit.com/essentials/validation#between}
   */
  between({ name, args }) {
    if (isNaN(args[0]) || isNaN(args[1])) {
      return `Pole zostało wypełnione niepoprawnie i nie może zostać wysłane.`;
    }
    const [a, b] = order(args[0], args[1]);
    return `Wartość pola ${sentence(name)} musi być pomiędzy ${a} i ${b}.`;
  },
  /**
   * The confirmation field does not match
   * @see {@link https://formkit.com/essentials/validation#confirm}
   */
  confirm({ name }) {
    return `${sentence(name)} nie pokrywa się.`;
  },
  /**
   * The value is not a valid date
   * @see {@link https://formkit.com/essentials/validation#date-format}
   */
  date_format({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `Wartość pola ${sentence(
        name
      )} nie jest poprawną datą, proszę użyć formatu ${args[0]}`;
    }
    return "To pole zostało wypełnione niepoprawnie i nie może zostać wysłane";
  },
  /**
   * Is not within expected date range
   * @see {@link https://formkit.com/essentials/validation#date-between}
   */
  date_between({ name, args }) {
    return `Data w polu ${sentence(name)} musi być pomiędzy ${date(args[0])} i ${date(
      args[1]
    )}`;
  },
  /**
   * Shown when the user-provided value is not a valid email address.
   * @see {@link https://formkit.com/essentials/validation#email}
   */
  email: "Proszę wpisać poprawny adres email.",
  /**
   * Does not end with the specified value
   * @see {@link https://formkit.com/essentials/validation#ends-with}
   */
  ends_with({ name, args }) {
    return `Pole ${sentence(name)} nie kończy się na ${list(args)}.`;
  },
  /**
   * Is not an allowed value
   * @see {@link https://formkit.com/essentials/validation#is}
   */
  is({ name }) {
    return `Pole ${sentence(name)} nie jest dozwoloną wartością.`;
  },
  /**
   * Does not match specified length
   * @see {@link https://formkit.com/essentials/validation#length}
   */
  length({ name, args: [first = 0, second = Infinity] }) {
    const min = Number(first) <= Number(second) ? first : second;
    const max = Number(second) >= Number(first) ? second : first;
    if (min == 1 && max === Infinity) {
      return `Pole ${sentence(name)} musi posiadać minimum jeden znak.`;
    }
    if (min == 0 && max) {
      return `Pole ${sentence(name)} musi zawierać ${max} lub mniej znaków.`;
    }
    if (min && max === Infinity) {
      return `Pole ${sentence(name)} musi zawierać ${min} lub więcej znaków.`;
    }
    if (min === max) {
      return `Pole ${sentence(name)} musi mieć ${min} znaków.`;
    }
    return `Pole ${sentence(name)} musi mieć ${min}-${max} znaków.`;
  },
  /**
   * Value is not a match
   * @see {@link https://formkit.com/essentials/validation#matches}
   */
  matches({ name }) {
    return `Pole ${sentence(name)} zawiera niedozwolone znaki.`;
  },
  /**
   * Exceeds maximum allowed value
   * @see {@link https://formkit.com/essentials/validation#max}
   */
  max({ name, node: { value }, args }) {
    if (Array.isArray(value)) {
      return `Nie można mieć więcej niż ${args[0]} ${name}.`;
    }
    return `Wartość pola ${sentence(name)} musi być mniejsza lub równa ${args[0]}.`;
  },
  /**
   * The (field-level) value does not match specified mime type
   * @see {@link https://formkit.com/essentials/validation#mime}
   */
  mime({ name, args }) {
    if (!args[0]) {
      return "Nie podano dozwolonych typów plików.";
    }
    return `${sentence(name)} musi być typem: ${args[0]}`;
  },
  /**
   * Does not fulfill minimum allowed value
   * @see {@link https://formkit.com/essentials/validation#min}
   */
  min({ name, node: { value }, args }) {
    if (Array.isArray(value)) {
      return `Musisz podać więcej niż ${args[0]} ${name}.`;
    }
    return ` Musisz podać conajmniej ${args[0]} ${sentence(name)}.`;
  },
  /**
   * Is not an allowed value
   * @see {@link https://formkit.com/essentials/validation#not}
   */
  not({ name }) {
    return `Wartość pola ${name} jest niedozwolona.`;
  },
  /**
   *  Is not a number
   * @see {@link https://formkit.com/essentials/validation#number}
   */
  number({ name }) {
    return `${sentence(name)} musi być numerem.`;
  },
  /**
   * Require one field.
   * @see {@link https://formkit.com/essentials/validation#require-one}
   */
  require_one: ({ name, node, args: inputNames }) => {
    const labels = inputNames.map((name2) => {
      const dependentNode = node.at(name2);
      if (dependentNode) {
        return createMessageName(dependentNode);
      }
      return false;
    }).filter((name2) => !!name2);
    labels.unshift(name);
    return `${labels.join(" lub ")} wymagany jest.`;
  },
  /**
   * Required field.
   * @see {@link https://formkit.com/essentials/validation#required}
   */
  required({ name }) {
    return `Pole ${sentence(name)} jest wymagane.`;
  },
  /**
   * Does not start with specified value
   * @see {@link https://formkit.com/essentials/validation#starts-with}
   */
  starts_with({ name, args }) {
    return `Wartośc pola ${sentence(name)} nie zaczyna się od ${list(args)}.`;
  },
  /**
   * Is not a url
   * @see {@link https://formkit.com/essentials/validation#url}
   */
  url() {
    return `Wprowadź prawidłowy adres URL.`;
  },
  /**
   * Shown when the date is invalid.
   */
  invalidDate: "Wybrana data jest nieprawidłowa."
};
var pl = { ui: ui30, validation: validation30 };
var ui31 = {
  /**
   * Shown on buttons for adding new items.
   */
  add: "Incluir",
  /**
   * Shown when a button to remove items is visible.
   */
  remove: "Remover",
  /**
   * Shown when there are multiple items to remove at the same time.
   */
  removeAll: "Remover todos",
  /**
   * Shown when all fields are not filled out correctly.
   */
  incomplete: "Desculpe, alguns campos não foram preenchidos corretamente.",
  /**
   * Shown in a button inside a form to submit the form.
   */
  submit: "Enviar",
  /**
   * Shown when no files are selected.
   */
  noFiles: "Nenhum arquivo selecionado.",
  /**
   * Shown on buttons that move fields up in a list.
   */
  moveUp: "Mover para cima",
  /**
   * Shown on buttons that move fields down in a list.
   */
  moveDown: "Mover para baixo",
  /**
   * Shown when something is actively loading.
   */
  isLoading: "Carregando...",
  /**
   * Shown when there is more to load.
   */
  loadMore: "Carregar mais",
  /**
   * Shown on buttons that navigate state forward
   */
  next: "Próximo",
  /**
   * Shown on buttons that navigate state backward
   */
  prev: "Anterior",
  /**
   * Shown when adding all values.
   */
  addAllValues: "Adicione todos os valores",
  /**
   * Shown when adding selected values.
   */
  addSelectedValues: "Adicionar valores selecionados",
  /**
   * Shown when removing all values.
   */
  removeAllValues: "Remover todos os valores",
  /**
   * Shown when removing selected values.
   */
  removeSelectedValues: "Remover valores selecionados",
  /**
   * Shown when there is a date to choose.
   */
  chooseDate: "Escolha a data",
  /**
   * Shown when there is a date to change.
   */
  changeDate: "Data da alteração",
  /**
   * Shown when there is something to close
   */
  close: "Fechar",
  /**
   * Shown when there is something to open.
   */
  open: "Aberto"
};
var validation31 = {
  /**
   * The value is not an accepted value.
   * @see {@link https://formkit.com/essentials/validation#accepted}
   */
  accepted({ name }) {
    return `Por favor aceite o ${name}.`;
  },
  /**
   * The date is not after
   * @see {@link https://formkit.com/essentials/validation#date-after}
   */
  date_after({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${sentence(name)} precisa ser depois de ${date(args[0])}.`;
    }
    return `${sentence(name)} precisa ser no futuro.`;
  },
  /**
   * The value is not a letter.
   * @see {@link https://formkit.com/essentials/validation#alpha}
   */
  alpha({ name }) {
    return `${sentence(name)} precisa conter apenas letras.`;
  },
  /**
   * The value is not alphanumeric
   * @see {@link https://formkit.com/essentials/validation#alphanumeric}
   */
  alphanumeric({ name }) {
    return `${sentence(name)} pode conter apenas letras e números.`;
  },
  /**
   * The value is not letter and/or spaces
   * @see {@link https://formkit.com/essentials/validation#alpha-spaces}
   */
  alpha_spaces({ name }) {
    return `${sentence(name)} pode conter apenas números e espaços.`;
  },
  /**
   * The value have no letter.
   * @see {@link https://formkit.com/essentials/validation#contains_alpha}
   */
  contains_alpha({ name }) {
    return `${sentence(name)} deve conter caracteres alfabéticos.`;
  },
  /**
   * The value have no alphanumeric
   * @see {@link https://formkit.com/essentials/validation#contains_alphanumeric}
   */
  contains_alphanumeric({ name }) {
    return `${sentence(name)} deve conter letras ou números.`;
  },
  /**
   * The value have no letter and/or spaces
   * @see {@link https://formkit.com/essentials/validation#contains_alpha-spaces}
   */
  contains_alpha_spaces({ name }) {
    return `${sentence(name)} deve conter letras ou espaços.`;
  },
  /**
   * The value have no symbol
   * @see {@link https://formkit.com/essentials/validation#contains_symbol}
   */
  contains_symbol({ name }) {
    return `${sentence(name)} deve conter um símbolo.`;
  },
  /**
   * The value have no uppercase
   * @see {@link https://formkit.com/essentials/validation#contains_uppercase}
   */
  contains_uppercase({ name }) {
    return `${sentence(name)} deve conter letras maiúsculas.`;
  },
  /**
   * The value have no lowercase
   * @see {@link https://formkit.com/essentials/validation#contains_lowercase}
   */
  contains_lowercase({ name }) {
    return `${sentence(name)} deve conter letras minúsculas.`;
  },
  /**
   *  The value have no numeric
   * @see {@link https://formkit.com/essentials/validation#contains_numeric}
   */
  contains_numeric({ name }) {
    return `${sentence(name)} deve conter números.`;
  },
  /**
   * The value is not symbol
   * @see {@link https://formkit.com/essentials/validation#symbol}
   */
  symbol({ name }) {
    return `${sentence(name)} deve ser um símbolo.`;
  },
  /**
   * The value is not uppercase
   * @see {@link https://formkit.com/essentials/validation#uppercase}
   */
  uppercase({ name }) {
    return `${sentence(name)} só pode conter letras maiúsculas.`;
  },
  /**
   * The value is not lowercase
   * @see {@link https://formkit.com/essentials/validation#lowercase}
   */
  lowercase({ name }) {
    return `${sentence(name)} só pode conter letras minúsculas.`;
  },
  /**
   * The date is not before
   * @see {@link https://formkit.com/essentials/validation#date-before}
   */
  date_before({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${sentence(name)} precisa ser antes de ${date(args[0])}.`;
    }
    return `${sentence(name)} precisa ser no passado.`;
  },
  /**
   * The value is not between two numbers
   * @see {@link https://formkit.com/essentials/validation#between}
   */
  between({ name, args }) {
    if (isNaN(args[0]) || isNaN(args[1])) {
      return `Este campo não foi configurado corretamente e não pode ser submetido.`;
    }
    const [a, b] = order(args[0], args[1]);
    return `${sentence(name)} precisa ser entre ${a} e ${b}.`;
  },
  /**
   * The confirmation field does not match
   * @see {@link https://formkit.com/essentials/validation#confirm}
   */
  confirm({ name }) {
    return `${sentence(name)} não é igual.`;
  },
  /**
   * The value is not a valid date
   * @see {@link https://formkit.com/essentials/validation#date-format}
   */
  date_format({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${sentence(name)} não é uma data válida, por favor use este formato ${args[0]}`;
    }
    return "Este campo não foi configurado corretamente e não pode ser submetido.";
  },
  /**
   * Is not within expected date range
   * @see {@link https://formkit.com/essentials/validation#date-between}
   */
  date_between({ name, args }) {
    return `${sentence(name)} precisa ser entre ${date(args[0])} e ${date(args[1])}`;
  },
  /**
   * Shown when the user-provided value is not a valid email address.
   * @see {@link https://formkit.com/essentials/validation#email}
   */
  email: "Por favor, insira um endereço de email válido.",
  /**
   * Does not end with the specified value
   * @see {@link https://formkit.com/essentials/validation#ends-with}
   */
  ends_with({ name, args }) {
    return `${sentence(name)} não termina com ${list(args)}.`;
  },
  /**
   * Is not an allowed value
   * @see {@link https://formkit.com/essentials/validation#is}
   */
  is({ name }) {
    return `${sentence(name)} não é um valor permitido.`;
  },
  /**
   * Does not match specified length
   * @see {@link https://formkit.com/essentials/validation#length}
   */
  length({ name, args: [first = 0, second = Infinity] }) {
    const min = first <= second ? first : second;
    const max = second >= first ? second : first;
    if (min == 1 && max === Infinity) {
      return `${sentence(name)} precisa conter ao menos um caractere.`;
    }
    if (min == 0 && max) {
      return `${sentence(name)} precisa ser menor ou igual a ${max} caracteres.`;
    }
    if (min === max) {
      return `${sentence(name)} precisa conter ${max} caracteres.`;
    }
    if (min && max === Infinity) {
      return `${sentence(name)} precisa ser maior ou igual a ${min} caracteres.`;
    }
    return `${sentence(name)} precisa ter entre ${min} e ${max} caracteres.`;
  },
  /**
   * Value is not a match
   * @see {@link https://formkit.com/essentials/validation#matches}
   */
  matches({ name }) {
    return `${sentence(name)} não é um valor permitido.`;
  },
  /**
   * Exceeds maximum allowed value
   * @see {@link https://formkit.com/essentials/validation#max}
   */
  max({ name, node: { value }, args }) {
    if (Array.isArray(value)) {
      return `Não pode ter mais de ${args[0]} ${name}.`;
    }
    return `${sentence(name)} precisa ser menor ou igual a ${args[0]}.`;
  },
  /**
   * The (field-level) value does not match specified mime type
   * @see {@link https://formkit.com/essentials/validation#mime}
   */
  mime({ name, args }) {
    if (!args[0]) {
      return "Não há formatos de arquivos permitidos.";
    }
    return `${sentence(name)} precisa ser do tipo: ${args[0]}`;
  },
  /**
   * Does not fulfill minimum allowed value
   * @see {@link https://formkit.com/essentials/validation#min}
   */
  min({ name, node: { value }, args }) {
    if (Array.isArray(value)) {
      return `Não pode ter menos de ${args[0]} ${name}.`;
    }
    return `${sentence(name)} precisa ser pelo menos ${args[0]}.`;
  },
  /**
   * Is not an allowed value
   * @see {@link https://formkit.com/essentials/validation#not}
   */
  not({ name, node: { value } }) {
    return `“${value}” não é um(a) ${name} permitido(a).`;
  },
  /**
   *  Is not a number
   * @see {@link https://formkit.com/essentials/validation#number}
   */
  number({ name }) {
    return `${sentence(name)} precisa ser um número.`;
  },
  /**
   * Require one field.
   * @see {@link https://formkit.com/essentials/validation#require-one}
   */
  require_one: ({ name, node, args: inputNames }) => {
    const labels = inputNames.map((name2) => {
      const dependentNode = node.at(name2);
      if (dependentNode) {
        return createMessageName(dependentNode);
      }
      return false;
    }).filter((name2) => !!name2);
    labels.unshift(name);
    return `${labels.join(" ou ")} é necessário.`;
  },
  /**
   * Required field.
   * @see {@link https://formkit.com/essentials/validation#required}
   */
  required({ name }) {
    return `${sentence(name)} é obrigatório.`;
  },
  /**
   * Does not start with specified value
   * @see {@link https://formkit.com/essentials/validation#starts-with}
   */
  starts_with({ name, args }) {
    return `${sentence(name)} não começa com ${list(args)}.`;
  },
  /**
   * Is not a url
   * @see {@link https://formkit.com/essentials/validation#url}
   */
  url() {
    return `Por favor, insira uma url válida.`;
  },
  /**
   * Shown when the date is invalid.
   */
  invalidDate: "A data selecionada é inválida."
};
var pt = { ui: ui31, validation: validation31 };
var ui32 = {
  /**
   * Shown on buttons for adding new items.
   */
  add: "Adăugare",
  /**
   * Shown when a button to remove items is visible.
   */
  remove: "Elimină",
  /**
   * Shown when there are multiple items to remove at the same time.
   */
  removeAll: "Elimină tot",
  /**
   * Shown when all fields are not filled out correctly.
   */
  incomplete: "Pare rău, unele câmpuri nu sunt corect completate.",
  /**
   * Shown in a button inside a form to submit the form.
   */
  submit: "Trimite",
  /**
   * Shown when no files are selected.
   */
  noFiles: "Nu este selectat nici un fișier",
  /**
   * Shown on buttons that move fields up in a list.
   */
  moveUp: "Mutare în sus",
  /**
   * Shown on buttons that move fields down in a list.
   */
  moveDown: "Mutare în jos",
  /**
   * Shown when something is actively loading.
   */
  isLoading: "Se încarcă...",
  /**
   * Shown when there is more to load.
   */
  loadMore: "Încărcați mai mult",
  /**
   * Shown on buttons that navigate state forward
   */
  next: "Urmatorul",
  /**
   * Shown on buttons that navigate state backward
   */
  prev: "Precedent",
  /**
   * Shown when adding all values.
   */
  addAllValues: "Adăugați toate valorile",
  /**
   * Shown when adding selected values.
   */
  addSelectedValues: "Adăugarea valorilor selectate",
  /**
   * Shown when removing all values.
   */
  removeAllValues: "Eliminați toate valorile",
  /**
   * Shown when removing selected values.
   */
  removeSelectedValues: "Eliminați valorile selectate",
  /**
   * Shown when there is a date to choose.
   */
  chooseDate: "Alege data",
  /**
   * Shown when there is a date to change.
   */
  changeDate: "Modificați data",
  /**
   * Shown when there is something to close
   */
  close: "Închide",
  /**
   * Shown when there is something to open.
   */
  open: "Deschis"
};
var validation32 = {
  /**
   * The value is not an accepted value.
   * @see {@link https://formkit.com/essentials/validation#accepted}
   */
  accepted({ name }) {
    return `Te rog acceptă ${name}.`;
  },
  /**
   * The date is not after
   * @see {@link https://formkit.com/essentials/validation#date-after}
   */
  date_after({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${sentence(name)} trebuie să fie după ${date(args[0])}.`;
    }
    return `${sentence(name)} trebuie sa fie în viitor.`;
  },
  /**
   * The value is not a letter.
   * @see {@link https://formkit.com/essentials/validation#alpha}
   */
  alpha({ name }) {
    return `${sentence(name)} poate conține doar caractere alafetice.`;
  },
  /**
   * The value is not alphanumeric
   * @see {@link https://formkit.com/essentials/validation#alphanumeric}
   */
  alphanumeric({ name }) {
    return `${sentence(name)} poate conține doar litere și numere.`;
  },
  /**
   * The value is not letter and/or spaces
   * @see {@link https://formkit.com/essentials/validation#alpha-spaces}
   */
  alpha_spaces({ name }) {
    return `${sentence(name)} poate conține doar litere și spații.`;
  },
  /**
   * The value have no letter.
   * @see {@link https://formkit.com/essentials/validation#contains_alpha}
   */
  contains_alpha({ name }) {
    return `${sentence(name)} trebuie să conțină caractere alfabetice.`;
  },
  /**
   * The value have no alphanumeric
   * @see {@link https://formkit.com/essentials/validation#contains_alphanumeric}
   */
  contains_alphanumeric({ name }) {
    return `${sentence(name)} trebuie să conțină litere sau numere.`;
  },
  /**
   * The value have no letter and/or spaces
   * @see {@link https://formkit.com/essentials/validation#contains_alpha-spaces}
   */
  contains_alpha_spaces({ name }) {
    return `${sentence(name)} trebuie să conțină litere sau spații.`;
  },
  /**
   * The value have no symbol
   * @see {@link https://formkit.com/essentials/validation#contains_symbol}
   */
  contains_symbol({ name }) {
    return `${sentence(name)} trebuie să conțină simbol.`;
  },
  /**
   * The value have no uppercase
   * @see {@link https://formkit.com/essentials/validation#contains_uppercase}
   */
  contains_uppercase({ name }) {
    return `${sentence(name)} trebuie să conțină majuscule.`;
  },
  /**
   * The value have no lowercase
   * @see {@link https://formkit.com/essentials/validation#contains_lowercase}
   */
  contains_lowercase({ name }) {
    return `${sentence(name)} trebuie să conțină litere mici.`;
  },
  /**
   *  The value have no numeric
   * @see {@link https://formkit.com/essentials/validation#contains_numeric}
   */
  contains_numeric({ name }) {
    return `${sentence(name)} trebuie să conțină numere.`;
  },
  /**
   * The value is not symbol
   * @see {@link https://formkit.com/essentials/validation#symbol}
   */
  symbol({ name }) {
    return `${sentence(name)} trebuie să fie un simbol.`;
  },
  /**
   * The value is not uppercase
   * @see {@link https://formkit.com/essentials/validation#uppercase}
   */
  uppercase({ name }) {
    return `${sentence(name)} poate conține doar litere mari.`;
  },
  /**
   * The value is not lowercase
   * @see {@link https://formkit.com/essentials/validation#lowercase}
   */
  lowercase({ name }) {
    return `${sentence(name)} poate conține doar litere mici.`;
  },
  /**
   * The date is not before
   * @see {@link https://formkit.com/essentials/validation#date-before}
   */
  date_before({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${sentence(name)} trebuie să preceadă ${date(args[0])}.`;
    }
    return `${sentence(name)} trebuie să fie în trecut.`;
  },
  /**
   * The value is not between two numbers
   * @see {@link https://formkit.com/essentials/validation#between}
   */
  between({ name, args }) {
    if (isNaN(args[0]) || isNaN(args[1])) {
      return `Câmpul a fost configurat incorect și nu poate fi trimis.`;
    }
    const [a, b] = order(args[0], args[1]);
    return `${sentence(name)} trebuie să fie între ${a} și ${b}.`;
  },
  /**
   * The confirmation field does not match
   * @see {@link https://formkit.com/essentials/validation#confirm}
   */
  confirm({ name }) {
    return `${sentence(name)} nu se potrivește.`;
  },
  /**
   * The value is not a valid date
   * @see {@link https://formkit.com/essentials/validation#date-format}
   */
  date_format({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${sentence(name)} nu este validă, te rog foloște formatul ${args[0]}`;
    }
    return "Câmpul a fost incorect configurat și nu poate fi trimis.";
  },
  /**
   * Is not within expected date range
   * @see {@link https://formkit.com/essentials/validation#date-between}
   */
  date_between({ name, args }) {
    return `${sentence(name)} trebuie să fie între ${date(args[0])} și ${date(
      args[1]
    )}`;
  },
  /**
   * Shown when the user-provided value is not a valid email address.
   * @see {@link https://formkit.com/essentials/validation#email}
   */
  email: "Te rog folosește o adresă de email validă.",
  /**
   * Does not end with the specified value
   * @see {@link https://formkit.com/essentials/validation#ends-with}
   */
  ends_with({ name, args }) {
    return `${sentence(name)} nu se termină cu ${list(args)}.`;
  },
  /**
   * Is not an allowed value
   * @see {@link https://formkit.com/essentials/validation#is}
   */
  is({ name }) {
    return `${sentence(name)} nu este o valoare acceptată.`;
  },
  /**
   * Does not match specified length
   * @see {@link https://formkit.com/essentials/validation#length}
   */
  length({ name, args: [first = 0, second = Infinity] }) {
    const min = Number(first) <= Number(second) ? first : second;
    const max = Number(second) >= Number(first) ? second : first;
    if (min == 1 && max === Infinity) {
      return `${sentence(name)} trebuie sa conțină cel puțin un caracter.`;
    }
    if (min == 0 && max) {
      return `${sentence(name)} trebuie sa aibă cel mult ${max} caractere.`;
    }
    if (min === max) {
      return `${sentence(name)} ar trebui să aibă ${max} caractere lungi.`;
    }
    if (min && max === Infinity) {
      return `${sentence(name)} trebuie să aibă cel puțin ${min} caractere.`;
    }
    return `${sentence(name)} trebuie să aibă între ${min} și ${max} caractere.`;
  },
  /**
   * Value is not a match
   * @see {@link https://formkit.com/essentials/validation#matches}
   */
  matches({ name }) {
    return `${sentence(name)} nu este o valoare acceptată.`;
  },
  /**
   * Exceeds maximum allowed value
   * @see {@link https://formkit.com/essentials/validation#max}
   */
  max({ name, node: { value }, args }) {
    if (Array.isArray(value)) {
      return `Nu poate avea mai mult decat ${args[0]} ${name}.`;
    }
    return `${sentence(name)} trebuie să fie cel mult egal cu ${args[0]}.`;
  },
  /**
   * The (field-level) value does not match specified mime type
   * @see {@link https://formkit.com/essentials/validation#mime}
   */
  mime({ name, args }) {
    if (!args[0]) {
      return "Tipul de fișier neacceptat.";
    }
    return `${sentence(name)} trebuie să fie de tipul: ${args[0]}`;
  },
  /**
   * Does not fulfill minimum allowed value
   * @see {@link https://formkit.com/essentials/validation#min}
   */
  min({ name, node: { value }, args }) {
    if (Array.isArray(value)) {
      return `Nu poate avea mai puțin decât ${args[0]} ${name}.`;
    }
    return `${sentence(name)} trebuie să fie cel puțin ${args[0]}.`;
  },
  /**
   * Is not an allowed value
   * @see {@link https://formkit.com/essentials/validation#not}
   */
  not({ name, node: { value } }) {
    return `“${value}” nu este o valoare acceptă pentru ${name}.`;
  },
  /**
   *  Is not a number
   * @see {@link https://formkit.com/essentials/validation#number}
   */
  number({ name }) {
    return `${sentence(name)} trebuie să fie un număr.`;
  },
  /**
   * Require one field.
   * @see {@link https://formkit.com/essentials/validation#require-one}
   */
  require_one: ({ name, node, args: inputNames }) => {
    const labels = inputNames.map((name2) => {
      const dependentNode = node.at(name2);
      if (dependentNode) {
        return createMessageName(dependentNode);
      }
      return false;
    }).filter((name2) => !!name2);
    labels.unshift(name);
    return `${labels.join(" sau ")} este necesar.`;
  },
  /**
   * Required field.
   * @see {@link https://formkit.com/essentials/validation#required}
   */
  required({ name }) {
    return `${sentence(name)} este necesar.`;
  },
  /**
   * Does not start with specified value
   * @see {@link https://formkit.com/essentials/validation#starts-with}
   */
  starts_with({ name, args }) {
    return `${sentence(name)} nu începe cu ${list(args)}.`;
  },
  /**
   * Is not a url
   * @see {@link https://formkit.com/essentials/validation#url}
   */
  url() {
    return `Introduceți o adresă URL validă.`;
  },
  /**
   * Shown when the date is invalid.
   */
  invalidDate: "Data selectată este nevalidă."
};
var ro = { ui: ui32, validation: validation32 };
var ui33 = {
  /**
   * Shown on buttons for adding new items.
   */
  add: "Добавить",
  /**
   * Shown when a button to remove items is visible.
   */
  remove: "Удалить",
  /**
   * Shown when there are multiple items to remove at the same time.
   */
  removeAll: "Убрать все",
  /**
   * Shown when all fields are not filled out correctly.
   */
  incomplete: "Извините, не все поля заполнены верно.",
  /**
   * Shown in a button inside a form to submit the form.
   */
  submit: "Отправить",
  /**
   * Shown when no files are selected.
   */
  noFiles: "Файл не выбран",
  /**
   * Shown on buttons that move fields up in a list.
   */
  moveUp: "Переместить вверх",
  /**
   * Shown on buttons that move fields down in a list.
   */
  moveDown: "Переместить вниз",
  /**
   * Shown when something is actively loading.
   */
  isLoading: "Загрузка...",
  /**
   * Shown when there is more to load.
   */
  loadMore: "Загрузить больше",
  /**
   * Shown on buttons that navigate state forward
   */
  next: "Следующий",
  /**
   * Shown on buttons that navigate state backward
   */
  prev: "Предыдущий",
  /**
   * Shown when adding all values.
   */
  addAllValues: "Добавить все значения",
  /**
   * Shown when adding selected values.
   */
  addSelectedValues: "Добавить выбранные значения",
  /**
   * Shown when removing all values.
   */
  removeAllValues: "Удалить все значения",
  /**
   * Shown when removing selected values.
   */
  removeSelectedValues: "Удалить выбранные значения",
  /**
   * Shown when there is a date to choose.
   */
  chooseDate: "Выберите дату",
  /**
   * Shown when there is a date to change.
   */
  changeDate: "Изменить дату",
  /**
   * Shown when there is something to close
   */
  close: "Закрыть",
  /**
   * Shown when there is something to open.
   */
  open: "Открыть"
};
var validation33 = {
  /**
   * The value is not an accepted value.
   * @see {@link https://formkit.com/essentials/validation#accepted}
   */
  accepted({ name }) {
    return `Пожалуйста, примите ${name}.`;
  },
  /**
   * The date is not after
   * @see {@link https://formkit.com/essentials/validation#date-after}
   */
  date_after({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `Дата ${sentence(name)} должна быть позже ${date(args[0])}.`;
    }
    return `Дата ${sentence(name)} должна быть в будущем.`;
  },
  /**
   * The value is not a letter.
   * @see {@link https://formkit.com/essentials/validation#alpha}
   */
  alpha({ name }) {
    return `Поле ${sentence(name)} может содержать только буквы.`;
  },
  /**
   * The value is not alphanumeric
   * @see {@link https://formkit.com/essentials/validation#alphanumeric}
   */
  alphanumeric({ name }) {
    return `Поле ${sentence(name)} может содержать только буквы и цифры.`;
  },
  /**
   * The value is not letter and/or spaces
   * @see {@link https://formkit.com/essentials/validation#alpha-spaces}
   */
  alpha_spaces({ name }) {
    return `${sentence(name)} могут содержать только буквы и пробелы.`;
  },
  /**
   * The value have no letter.
   * @see {@link https://formkit.com/essentials/validation#contains_alpha}
   */
  contains_alpha({ name }) {
    return `${sentence(name)} должен содержать алфавитные символы.`;
  },
  /**
   * The value have no alphanumeric
   * @see {@link https://formkit.com/essentials/validation#contains_alphanumeric}
   */
  contains_alphanumeric({ name }) {
    return `${sentence(name)} должен содержать буквы или цифры.`;
  },
  /**
   * The value have no letter and/or spaces
   * @see {@link https://formkit.com/essentials/validation#contains_alpha-spaces}
   */
  contains_alpha_spaces({ name }) {
    return `${sentence(name)} должно содержать буквы или пробелы.`;
  },
  /**
   * The value have no symbol
   * @see {@link https://formkit.com/essentials/validation#contains_symbol}
   */
  contains_symbol({ name }) {
    return `${sentence(name)} должен содержать символ.`;
  },
  /**
   * The value have no uppercase
   * @see {@link https://formkit.com/essentials/validation#contains_uppercase}
   */
  contains_uppercase({ name }) {
    return `${sentence(name)} должно содержать прописные буквы.`;
  },
  /**
   * The value have no lowercase
   * @see {@link https://formkit.com/essentials/validation#contains_lowercase}
   */
  contains_lowercase({ name }) {
    return `${sentence(name)} должно содержать строчные буквы.`;
  },
  /**
   *  The value have no numeric
   * @see {@link https://formkit.com/essentials/validation#contains_numeric}
   */
  contains_numeric({ name }) {
    return `${sentence(name)} должен содержать числа.`;
  },
  /**
   * The value is not symbol
   * @see {@link https://formkit.com/essentials/validation#symbol}
   */
  symbol({ name }) {
    return `${sentence(name)} должен быть символом.`;
  },
  /**
   * The value is not uppercase
   * @see {@link https://formkit.com/essentials/validation#uppercase}
   */
  uppercase({ name }) {
    return `${sentence(name)} может содержать только прописные буквы.`;
  },
  /**
   * The value is not lowercase
   * @see {@link https://formkit.com/essentials/validation#lowercase}
   */
  lowercase({ name }) {
    return `${sentence(name)} может содержать только буквы нижнего регистра.`;
  },
  /**
   * The date is not before
   * @see {@link https://formkit.com/essentials/validation#date-before}
   */
  date_before({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `Дата ${sentence(name)} должна быть раньше ${date(args[0])}.`;
    }
    return `Дата ${sentence(name)} должна быть в прошлом.`;
  },
  /**
   * The value is not between two numbers
   * @see {@link https://formkit.com/essentials/validation#between}
   */
  between({ name, args }) {
    if (isNaN(args[0]) || isNaN(args[1])) {
      return `Это поле заполнено неверно и не может быть отправлено.`;
    }
    const [a, b] = order(args[0], args[1]);
    return `Поле ${sentence(name)} должно быть между ${a} и ${b}.`;
  },
  /**
   * The confirmation field does not match
   * @see {@link https://formkit.com/essentials/validation#confirm}
   */
  confirm({ name }) {
    return `Поле ${sentence(name)} не совпадает.`;
  },
  /**
   * The value is not a valid date
   * @see {@link https://formkit.com/essentials/validation#date-format}
   */
  date_format({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `Поле ${sentence(
        name
      )} имеет неверную дату. Пожалуйста, используйте формат ${args[0]}`;
    }
    return "Это поле заполнено неверно и не может быть отправлено.";
  },
  /**
   * Is not within expected date range
   * @see {@link https://formkit.com/essentials/validation#date-between}
   */
  date_between({ name, args }) {
    return `Дата ${sentence(name)} должна быть между ${date(args[0])} и ${date(
      args[1]
    )}`;
  },
  /**
   * Shown when the user-provided value is not a valid email address.
   * @see {@link https://formkit.com/essentials/validation#email}
   */
  email: "Пожалуйста, введите действительный электронный адрес.",
  /**
   * Does not end with the specified value
   * @see {@link https://formkit.com/essentials/validation#ends-with}
   */
  ends_with({ name, args }) {
    return `Поле ${sentence(name)} не должно заканчиваться на ${list(args)}.`;
  },
  /**
   * Is not an allowed value
   * @see {@link https://formkit.com/essentials/validation#is}
   */
  is({ name }) {
    return `Поле ${sentence(name)} имеет неподустимое значение.`;
  },
  /**
   * Does not match specified length
   * @see {@link https://formkit.com/essentials/validation#length}
   */
  length({ name, args: [first = 0, second = Infinity] }) {
    const min = Number(first) <= Number(second) ? first : second;
    const max = Number(second) >= Number(first) ? second : first;
    if (min == 1 && max === Infinity) {
      return `Поле ${sentence(name)} должно содержать минимум один символ.`;
    }
    if (min == 0 && max) {
      return `Длина поля ${sentence(
        name
      )} должна быть меньше или равна ${max} символам.`;
    }
    if (min === max) {
      return `Длина ${sentence(name)} должна составлять ${max} символов.`;
    }
    if (min && max === Infinity) {
      return `Длина поля ${sentence(
        name
      )} должна быть больше или равна ${min} символам.`;
    }
    return `Длина поля ${sentence(name)} должна быть между ${min} и ${max} символами.`;
  },
  /**
   * Value is not a match
   * @see {@link https://formkit.com/essentials/validation#matches}
   */
  matches({ name }) {
    return `Поле ${sentence(name)} имеет недопустимое значение.`;
  },
  /**
   * Exceeds maximum allowed value
   * @see {@link https://formkit.com/essentials/validation#max}
   */
  max({ name, node: { value }, args }) {
    if (Array.isArray(value)) {
      return `Не может быть выбрано больше, чем ${args[0]} ${name}.`;
    }
    return `Поле ${sentence(name)} должно быть меньше или равно ${args[0]}.`;
  },
  /**
   * The (field-level) value does not match specified mime type
   * @see {@link https://formkit.com/essentials/validation#mime}
   */
  mime({ name, args }) {
    if (!args[0]) {
      return "Не указаны поддержиавемые форматы файла.";
    }
    return `Формат файла в поле ${sentence(name)} должен быть: ${args[0]}.`;
  },
  /**
   * Does not fulfill minimum allowed value
   * @see {@link https://formkit.com/essentials/validation#min}
   */
  min({ name, node: { value }, args }) {
    if (Array.isArray(value)) {
      return `Не может быть выбрано меньше, чем ${args[0]} ${name}.`;
    }
    return `Поле ${sentence(name)} должно быть не менее, чем ${args[0]}.`;
  },
  /**
   * Is not an allowed value
   * @see {@link https://formkit.com/essentials/validation#not}
   */
  not({ name, node: { value } }) {
    return `“${value}” не поддерживается в поле ${name}.`;
  },
  /**
   *  Is not a number
   * @see {@link https://formkit.com/essentials/validation#number}
   */
  number({ name }) {
    return `Поле ${sentence(name)} должно быть числом.`;
  },
  /**
   * Require one field.
   * @see {@link https://formkit.com/essentials/validation#require-one}
   */
  require_one: ({ name, node, args: inputNames }) => {
    const labels = inputNames.map((name2) => {
      const dependentNode = node.at(name2);
      if (dependentNode) {
        return createMessageName(dependentNode);
      }
      return false;
    }).filter((name2) => !!name2);
    labels.unshift(name);
    return `${labels.join(" или ")} требуется.`;
  },
  /**
   * Required field.
   * @see {@link https://formkit.com/essentials/validation#required}
   */
  required({ name }) {
    return `Поле ${sentence(name)} обязательно для заполнения.`;
  },
  /**
   * Does not start with specified value
   * @see {@link https://formkit.com/essentials/validation#starts-with}
   */
  starts_with({ name, args }) {
    return `Поле ${sentence(name)} должно начинаться с ${list(args)}.`;
  },
  /**
   * Is not a url
   * @see {@link https://formkit.com/essentials/validation#url}
   */
  url() {
    return `Пожалуйста, введите действительный URL-адрес.`;
  },
  /**
   * Shown when the date is invalid.
   */
  invalidDate: "Выбранная дата недействительна."
};
var ru = { ui: ui33, validation: validation33 };
var ui34 = {
  /**
   * Shown on a button for adding additional items.
   */
  add: "Pridať",
  /**
   * Shown when a button to remove items is visible.
   */
  remove: "Odstrániť",
  /**
   * Shown when there are multiple items to remove at the same time.
   */
  removeAll: "Odstrániť všetko",
  /**
   * Shown when all fields are not filled out correctly.
   */
  incomplete: "Prepáčte, ale nie všetky polia sú vyplnené správne.",
  /**
   * Shown in a button inside a form to submit the form.
   */
  submit: "Odoslať",
  /**
   * Shown when no files are selected.
   */
  noFiles: "Nebol vybraný žiadny súbor",
  /**
   * Shown on buttons that move fields up in a list.
   */
  moveUp: "Posunúť hore",
  /**
   * Shown on buttons that move fields down in a list.
   */
  moveDown: "Posunúť dole",
  /**
   * Shown when something is actively loading.
   */
  isLoading: "Načítavanie...",
  /**
   * Shown when there is more to load.
   */
  loadMore: "Načítať viac",
  /**
   * Shown on buttons that navigate state forward
   */
  next: "Ďalšie",
  /**
   * Shown on buttons that navigate state backward
   */
  prev: "Predošlý",
  /**
   * Shown when adding all values.
   */
  addAllValues: "Pridajte všetky hodnoty",
  /**
   * Shown when adding selected values.
   */
  addSelectedValues: "Pridajte vybrané hodnoty",
  /**
   * Shown when removing all values.
   */
  removeAllValues: "Odstrániť všetky hodnoty",
  /**
   * Shown when removing selected values.
   */
  removeSelectedValues: "Odstrániť vybrané hodnoty",
  /**
   * Shown when there is a date to choose.
   */
  chooseDate: "Vyberte dátum",
  /**
   * Shown when there is a date to change.
   */
  changeDate: "Zmena dátumu",
  /**
   * Shown when there is something to close
   */
  close: "Zavrieť",
  /**
   * Shown when there is something to open.
   */
  open: "Otvorené"
};
var validation34 = {
  /**
   * The value is not an accepted value.
   * @see {@link https://formkit.com/essentials/validation#accepted}
   */
  accepted({ name }) {
    return `Prosím zaškrtnite ${name}.`;
  },
  /**
   * The date is not after
   * @see {@link https://formkit.com/essentials/validation#date-after}
   */
  date_after({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${sentence(name)} musí byť za ${date(args[0])}.`;
    }
    return `${sentence(name)} musí byť v budúcnosti.`;
  },
  /**
   * The value is not a letter.
   * @see {@link https://formkit.com/essentials/validation#alpha}
   */
  alpha({ name }) {
    return `${sentence(name)} môže obsahovať iba písmená.`;
  },
  /**
   * The value is not alphanumeric
   * @see {@link https://formkit.com/essentials/validation#alphanumeric}
   */
  alphanumeric({ name }) {
    return `${sentence(name)} môže obsahovať iba písmená a čísla.`;
  },
  /**
   * The value is not letter and/or spaces
   * @see {@link https://formkit.com/essentials/validation#alpha-spaces}
   */
  alpha_spaces({ name }) {
    return `${sentence(name)} môže obsahovať iba písmená a medzery.`;
  },
  /**
   * The value have no letter.
   * @see {@link https://formkit.com/essentials/validation#contains_alpha}
   */
  contains_alpha({ name }) {
    return `${sentence(name)} musí obsahovať abecedné znaky.`;
  },
  /**
   * The value have no alphanumeric
   * @see {@link https://formkit.com/essentials/validation#contains_alphanumeric}
   */
  contains_alphanumeric({ name }) {
    return `${sentence(name)} musí obsahovať písmená alebo číslice.`;
  },
  /**
   * The value have no letter and/or spaces
   * @see {@link https://formkit.com/essentials/validation#contains_alpha-spaces}
   */
  contains_alpha_spaces({ name }) {
    return `${sentence(name)} musí obsahovať písmená alebo medzery.`;
  },
  /**
   * The value have no symbol
   * @see {@link https://formkit.com/essentials/validation#contains_symbol}
   */
  contains_symbol({ name }) {
    return `${sentence(name)} musí obsahovať symbol.`;
  },
  /**
   * The value have no uppercase
   * @see {@link https://formkit.com/essentials/validation#contains_uppercase}
   */
  contains_uppercase({ name }) {
    return `${sentence(name)} musí obsahovať veľké písmená.`;
  },
  /**
   * The value have no lowercase
   * @see {@link https://formkit.com/essentials/validation#contains_lowercase}
   */
  contains_lowercase({ name }) {
    return `${sentence(name)} musí obsahovať malé písmená.`;
  },
  /**
   *  The value have no numeric
   * @see {@link https://formkit.com/essentials/validation#contains_numeric}
   */
  contains_numeric({ name }) {
    return `${sentence(name)} musí obsahovať čísla.`;
  },
  /**
   * The value is not symbol
   * @see {@link https://formkit.com/essentials/validation#symbol}
   */
  symbol({ name }) {
    return `${sentence(name)} musí byť symbol.`;
  },
  /**
   * The value is not uppercase
   * @see {@link https://formkit.com/essentials/validation#uppercase}
   */
  uppercase({ name }) {
    return `${sentence(name)} môže obsahovať iba veľké písmená.`;
  },
  /**
   * The value is not lowercase
   * @see {@link https://formkit.com/essentials/validation#lowercase}
   */
  lowercase({ name }) {
    return `${sentence(name)} môže obsahovať len malé písmená.`;
  },
  /**
   * The date is not before
   * @see {@link https://formkit.com/essentials/validation#date-before}
   */
  date_before({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${sentence(name)} musí byť pred ${date(args[0])}.`;
    }
    return `${sentence(name)} musí byť v minulosti.`;
  },
  /**
   * The value is not between two numbers
   * @see {@link https://formkit.com/essentials/validation#between}
   */
  between({ name, args }) {
    if (isNaN(args[0]) || isNaN(args[1])) {
      return `Toto pole bolo nesprávne nakonfigurované a nemôže byť odoslané.`;
    }
    const [a, b] = order(args[0], args[1]);
    return `${sentence(name)} musí byť medzi ${a} and ${b}.`;
  },
  /**
   * The confirmation field does not match
   * @see {@link https://formkit.com/essentials/validation#confirm}
   */
  confirm({ name }) {
    return `${sentence(name)} does not match.`;
  },
  /**
   * The value is not a valid date
   * @see {@link https://formkit.com/essentials/validation#date-format}
   */
  date_format({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${sentence(name)} nie je platným dátumom, prosím, použite formát ${args[0]}`;
    }
    return "Toto pole bolo nesprávne nakonfigurované a nemôže byť odoslané.";
  },
  /**
   * Is not within expected date range
   * @see {@link https://formkit.com/essentials/validation#date-between}
   */
  date_between({ name, args }) {
    return `${sentence(name)} musí byť medzi ${date(args[0])} a ${date(args[1])}`;
  },
  /**
   * Shown when the user-provided value is not a valid email address.
   * @see {@link https://formkit.com/essentials/validation#email}
   */
  email: "Prosím, zadajte platnú emailovú adresu.",
  /**
   * Does not end with the specified value
   * @see {@link https://formkit.com/essentials/validation#ends-with}
   */
  ends_with({ name, args }) {
    return `${sentence(name)} nekončí na ${list(args)}.`;
  },
  /**
   * Is not an allowed value
   * @see {@link https://formkit.com/essentials/validation#is}
   */
  is({ name }) {
    return `${sentence(name)} nie je povolená hodnota.`;
  },
  /**
   * Does not match specified length
   * @see {@link https://formkit.com/essentials/validation#length}
   */
  length({ name, args: [first = 0, second = Infinity] }) {
    const min = Number(first) <= Number(second) ? first : second;
    const max = Number(second) >= Number(first) ? second : first;
    if (min == 1 && max === Infinity) {
      return `${sentence(name)} musí mať najmenej jeden znak.`;
    }
    if (min == 0 && max) {
      return `${sentence(name)} musí byť menšie alebo rovné ako ${max} znakov.`;
    }
    if (min === max) {
      return `${sentence(name)} by mala mať dĺžku ${max} znakov.`;
    }
    if (min && max === Infinity) {
      return `${sentence(name)} musí byť väčšie alebo rovné ako ${min} znakov.`;
    }
    return `${sentence(name)} musí byť medzi ${min} až ${max} znakov.`;
  },
  /**
   * Value is not a match
   * @see {@link https://formkit.com/essentials/validation#matches}
   */
  matches({ name }) {
    return `${sentence(name)} nie je povolená hodnota.`;
  },
  /**
   * Exceeds maximum allowed value
   * @see {@link https://formkit.com/essentials/validation#max}
   */
  max({ name, node: { value }, args }) {
    if (Array.isArray(value)) {
      return `Nie je možné použiť viac než ${args[0]} ${name}.`;
    }
    return `${sentence(name)} musí byť menšie alebo rovné ako ${args[0]}.`;
  },
  /**
   * The (field-level) value does not match specified mime type
   * @see {@link https://formkit.com/essentials/validation#mime}
   */
  mime({ name, args }) {
    if (!args[0]) {
      return "Nie sú povolené formáty súborov.";
    }
    return `${sentence(name)} musí byť typu: ${args[0]}`;
  },
  /**
   * Does not fulfill minimum allowed value
   * @see {@link https://formkit.com/essentials/validation#min}
   */
  min({ name, node: { value }, args }) {
    if (Array.isArray(value)) {
      return `Nemôže byť menej než ${args[0]} ${name}.`;
    }
    return `${sentence(name)} musí byť minimálne ${args[0]}.`;
  },
  /**
   * Is not an allowed value
   * @see {@link https://formkit.com/essentials/validation#not}
   */
  not({ name, node: { value } }) {
    return `“${value}” nie je povolené hodnota pre ${name}.`;
  },
  /**
   *  Is not a number
   * @see {@link https://formkit.com/essentials/validation#number}
   */
  number({ name }) {
    return `${sentence(name)} musí byť číslo.`;
  },
  /**
   * Require one field.
   * @see {@link https://formkit.com/essentials/validation#require-one}
   */
  require_one: ({ name, node, args: inputNames }) => {
    const labels = inputNames.map((name2) => {
      const dependentNode = node.at(name2);
      if (dependentNode) {
        return createMessageName(dependentNode);
      }
      return false;
    }).filter((name2) => !!name2);
    labels.unshift(name);
    return `${labels.join(" alebo ")} je potrebný.`;
  },
  /**
   * Required field.
   * @see {@link https://formkit.com/essentials/validation#required}
   */
  required({ name }) {
    return `${sentence(name)} je povinné.`;
  },
  /**
   * Does not start with specified value
   * @see {@link https://formkit.com/essentials/validation#starts-with}
   */
  starts_with({ name, args }) {
    return `${sentence(name)} nezačíná s ${list(args)}.`;
  },
  /**
   * Is not a url
   * @see {@link https://formkit.com/essentials/validation#url}
   */
  url() {
    return `Zadajte platnú adresu URL.`;
  },
  /**
   * Shown when the date is invalid.
   */
  invalidDate: "Vybraný dátum je neplatný."
};
var sk = { ui: ui34, validation: validation34 };
var ui35 = {
  /**
   * Shown on buttons for adding new items.
   */
  add: "Dodaj",
  /**
   * Shown when a button to remove items is visible.
   */
  remove: "Odstrani",
  /**
   * Shown when there are multiple items to remove at the same time.
   */
  removeAll: "Odstrani vse",
  /**
   * Shown when all fields are not filled out correctly.
   */
  incomplete: "Nekatera polja niso pravilno izpolnjena.",
  /**
   * Shown in a button inside a form to submit the form.
   */
  submit: "Pošlji",
  /**
   * Shown when no files are selected.
   */
  noFiles: "Nobena datoteka ni izbrana",
  /**
   * Shown on buttons that move fields up in a list.
   */
  moveUp: "Premakni se navzgor",
  /**
   * Shown on buttons that move fields down in a list.
   */
  moveDown: "Premakni se navzdol",
  /**
   * Shown when something is actively loading.
   */
  isLoading: "Nalaganje...",
  /**
   * Shown when there is more to load.
   */
  loadMore: "Naloži več",
  /**
   * Shown on buttons that navigate state forward
   */
  next: "Naslednji",
  /**
   * Shown on buttons that navigate state backward
   */
  prev: "Prejšnji",
  /**
   * Shown when adding all values.
   */
  addAllValues: "Dodajte vse vrednosti",
  /**
   * Shown when adding selected values.
   */
  addSelectedValues: "Dodajanje izbranih vrednosti",
  /**
   * Shown when removing all values.
   */
  removeAllValues: "Odstranite vse vrednosti",
  /**
   * Shown when removing selected values.
   */
  removeSelectedValues: "Odstrani izbrane vrednosti",
  /**
   * Shown when there is a date to choose.
   */
  chooseDate: "Izberite datum",
  /**
   * Shown when there is a date to change.
   */
  changeDate: "Spremeni datum",
  /**
   * Shown when there is something to close
   */
  close: "Zapri",
  /**
   * Shown when there is something to open.
   */
  open: "Odpri"
};
var validation35 = {
  /**
   * The value is not an accepted value.
   * @see {@link https://formkit.com/essentials/validation#accepted}
   */
  accepted({ name }) {
    return `Prosimo popravite ${name}.`;
  },
  /**
   * The date is not after
   * @see {@link https://formkit.com/essentials/validation#date-after}
   */
  date_after({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${sentence(name)} mora biti po ${date(args[0])}.`;
    }
    return `${sentence(name)} mora biti v prihodnosti.`;
  },
  /**
   * The value is not a letter.
   * @see {@link https://formkit.com/essentials/validation#alpha}
   */
  alpha({ name }) {
    return `${sentence(name)} lahko vsebuje samo znake abecede.`;
  },
  /**
   * The value is not alphanumeric
   * @see {@link https://formkit.com/essentials/validation#alphanumeric}
   */
  alphanumeric({ name }) {
    return `${sentence(name)} lahko vsebuje samo črke in številke.`;
  },
  /**
   * The value is not letter and/or spaces
   * @see {@link https://formkit.com/essentials/validation#alpha-spaces}
   */
  alpha_spaces({ name }) {
    return `${sentence(name)} lahko vsebuje samo črke in presledke.`;
  },
  /**
   * The value have no letter.
   * @see {@link https://formkit.com/essentials/validation#contains_alpha}
   */
  contains_alpha({ name }) {
    return `${sentence(name)} mora vsebovati abecedne znake.`;
  },
  /**
   * The value have no alphanumeric
   * @see {@link https://formkit.com/essentials/validation#contains_alphanumeric}
   */
  contains_alphanumeric({ name }) {
    return `${sentence(name)} mora vsebovati črke ali številke.`;
  },
  /**
   * The value have no letter and/or spaces
   * @see {@link https://formkit.com/essentials/validation#contains_alpha-spaces}
   */
  contains_alpha_spaces({ name }) {
    return `${sentence(name)} mora vsebovati črke ali presledke.`;
  },
  /**
   * The value have no symbol
   * @see {@link https://formkit.com/essentials/validation#contains_symbol}
   */
  contains_symbol({ name }) {
    return `${sentence(name)} mora vsebovati simbol.`;
  },
  /**
   * The value have no uppercase
   * @see {@link https://formkit.com/essentials/validation#contains_uppercase}
   */
  contains_uppercase({ name }) {
    return `${sentence(name)} mora vsebovati velike črke.`;
  },
  /**
   * The value have no lowercase
   * @see {@link https://formkit.com/essentials/validation#contains_lowercase}
   */
  contains_lowercase({ name }) {
    return `${sentence(name)} mora vsebovati male črke.`;
  },
  /**
   *  The value have no numeric
   * @see {@link https://formkit.com/essentials/validation#contains_numeric}
   */
  contains_numeric({ name }) {
    return `${sentence(name)} mora vsebovati številke.`;
  },
  /**
   * The value is not symbol
   * @see {@link https://formkit.com/essentials/validation#symbol}
   */
  symbol({ name }) {
    return `${sentence(name)} mora biti simbol.`;
  },
  /**
   * The value is not uppercase
   * @see {@link https://formkit.com/essentials/validation#uppercase}
   */
  uppercase({ name }) {
    return `${sentence(name)} lahko vsebuje le velike črke.`;
  },
  /**
   * The value is not lowercase
   * @see {@link https://formkit.com/essentials/validation#lowercase}
   */
  lowercase({ name }) {
    return `${sentence(name)} lahko vsebuje le male črke.`;
  },
  /**
   * The date is not before
   * @see {@link https://formkit.com/essentials/validation#date-before}
   */
  date_before({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${sentence(name)} mora biti pred ${date(args[0])}.`;
    }
    return `${sentence(name)} mora biti v preteklosti.`;
  },
  /**
   * The value is not between two numbers
   * @see {@link https://formkit.com/essentials/validation#between}
   */
  between({ name, args }) {
    if (isNaN(args[0]) || isNaN(args[1])) {
      return `To polje je narobe nastavljeno in ne mora biti izpolnjeno.`;
    }
    const [a, b] = order(args[0], args[1]);
    return `${sentence(name)} mora biti med ${a} in ${b}.`;
  },
  /**
   * The confirmation field does not match
   * @see {@link https://formkit.com/essentials/validation#confirm}
   */
  confirm({ name }) {
    return `${sentence(name)} se ne ujema.`;
  },
  /**
   * The value is not a valid date
   * @see {@link https://formkit.com/essentials/validation#date-format}
   */
  date_format({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${sentence(name)} ni pravilen datum, prosimo uporabite format ${args[0]}`;
    }
    return "To polje je narobe nastavljeno in ne mora biti izpolnjeno.";
  },
  /**
   * Is not within expected date range
   * @see {@link https://formkit.com/essentials/validation#date-between}
   */
  date_between({ name, args }) {
    return `${sentence(name)} mora biti med ${date(args[0])} in ${date(args[1])}`;
  },
  /**
   * Shown when the user-provided value is not a valid email address.
   * @see {@link https://formkit.com/essentials/validation#email}
   */
  email: "Vnesite veljaven e-poštni naslov.",
  /**
   * Does not end with the specified value
   * @see {@link https://formkit.com/essentials/validation#ends-with}
   */
  ends_with({ name, args }) {
    return `${sentence(name)} se mora kočati z ${list(args)}.`;
  },
  /**
   * Is not an allowed value
   * @see {@link https://formkit.com/essentials/validation#is}
   */
  is({ name }) {
    return `${sentence(name)} ni dovoljena vrednost.`;
  },
  /**
   * Does not match specified length
   * @see {@link https://formkit.com/essentials/validation#length}
   */
  length({ name, args: [first = 0, second = Infinity] }) {
    const min = Number(first) <= Number(second) ? first : second;
    const max = Number(second) >= Number(first) ? second : first;
    if (min == 1 && max === Infinity) {
      return `${sentence(name)} mora vsebovati vsaj en znak.`;
    }
    if (min == 0 && max) {
      return `${sentence(name)} mora vsebovati največ ${max} znakov.`;
    }
    if (min === max) {
      return `${sentence(name)} mora biti dolg ${max} znakov.`;
    }
    if (min && max === Infinity) {
      return `${sentence(name)} mora vsebovati vsaj ${min} znakov.`;
    }
    return `${sentence(name)} mora vsebovati med ${min} in ${max} znakov.`;
  },
  /**
   * Value is not a match
   * @see {@link https://formkit.com/essentials/validation#matches}
   */
  matches({ name }) {
    return `${sentence(name)} ni dovoljena vrednost.`;
  },
  /**
   * Exceeds maximum allowed value
   * @see {@link https://formkit.com/essentials/validation#max}
   */
  max({ name, node: { value }, args }) {
    if (Array.isArray(value)) {
      return `Največ je ${args[0]} ${name}.`;
    }
    return `${sentence(name)} je lahko največ ${args[0]}.`;
  },
  /**
   * The (field-level) value does not match specified mime type
   * @see {@link https://formkit.com/essentials/validation#mime}
   */
  mime({ name, args }) {
    if (!args[0]) {
      return "Nobena vrsta datoteke ni dovoljena.";
    }
    return `${sentence(name)} mora biti tipa: ${args[0]}`;
  },
  /**
   * Does not fulfill minimum allowed value
   * @see {@link https://formkit.com/essentials/validation#min}
   */
  min({ name, node: { value }, args }) {
    if (Array.isArray(value)) {
      return `Najmanj ${args[0]} ${name} je dovoljenih.`;
    }
    return `${sentence(name)} mora biti vsaj ${args[0]}.`;
  },
  /**
   * Is not an allowed value
   * @see {@link https://formkit.com/essentials/validation#not}
   */
  not({ name, node: { value } }) {
    return `“${value}” ni dovoljen(a/o) ${name}.`;
  },
  /**
   *  Is not a number
   * @see {@link https://formkit.com/essentials/validation#number}
   */
  number({ name }) {
    return `${sentence(name)} mora biti številka.`;
  },
  /**
   * Require one field.
   * @see {@link https://formkit.com/essentials/validation#require-one}
   */
  require_one: ({ name, node, args: inputNames }) => {
    const labels = inputNames.map((name2) => {
      const dependentNode = node.at(name2);
      if (dependentNode) {
        return createMessageName(dependentNode);
      }
      return false;
    }).filter((name2) => !!name2);
    labels.unshift(name);
    return `${labels.join(" ali ")} zahtevan je.`;
  },
  /**
   * Required field.
   * @see {@link https://formkit.com/essentials/validation#required}
   */
  required({ name }) {
    return `${sentence(name)} je zahtevan(o/a).`;
  },
  /**
   * Does not start with specified value
   * @see {@link https://formkit.com/essentials/validation#starts-with}
   */
  starts_with({ name, args }) {
    return `${sentence(name)} se mora začeti z ${list(args)}.`;
  },
  /**
   * Is not a url
   * @see {@link https://formkit.com/essentials/validation#url}
   */
  url() {
    return `Vnesite veljaven URL.`;
  },
  /**
   * Shown when the date is invalid.
   */
  invalidDate: "Izbrani datum je neveljaven."
};
var sl = { ui: ui35, validation: validation35 };
var ui36 = {
  /**
   * Shown on a button for adding additional items.
   */
  add: "Dodaj",
  /**
   * Shown when a button to remove items is visible.
   */
  remove: "Ukloni",
  /**
   * Shown when there are multiple items to remove at the same time.
   */
  removeAll: "Ukloni sve",
  /**
   * Shown when all fields are not filled out correctly.
   */
  incomplete: "Pojedina polja nisu ispravno ispunjena.",
  /**
   * Shown in a button inside a form to submit the form.
   */
  submit: "Pošalji",
  /**
   * Shown when no files are selected.
   */
  noFiles: "Fajl nije odabran",
  /**
   * Shown on buttons that move fields up in a list.
   */
  moveUp: "Pomerite se gore",
  /**
   * Shown on buttons that move fields down in a list.
   */
  moveDown: "Pomeri se dole",
  /**
   * Shown when something is actively loading.
   */
  isLoading: "Učitavanje...",
  /**
   * Shown when there is more to load.
   */
  loadMore: "Učitaj više",
  /**
   * Shown on buttons that navigate state forward
   */
  next: "Sledeća",
  /**
   * Shown on buttons that navigate state backward
   */
  prev: "Prethodna",
  /**
   * Shown when adding all values.
   */
  addAllValues: "Dodajte sve vrednosti",
  /**
   * Shown when adding selected values.
   */
  addSelectedValues: "Dodajte izabrane vrednosti",
  /**
   * Shown when removing all values.
   */
  removeAllValues: "Uklonite sve vrednosti",
  /**
   * Shown when removing selected values.
   */
  removeSelectedValues: "Uklonite izabrane vrednosti",
  /**
   * Shown when there is a date to choose.
   */
  chooseDate: "Izaberite datum",
  /**
   * Shown when there is a date to change.
   */
  changeDate: "Promenite datum",
  /**
   * Shown when there is something to close
   */
  close: "Zatvori",
  /**
   * Shown when there is something to open.
   */
  open: "Otvori"
};
var validation36 = {
  /**
   * The value is not an accepted value.
   * @see {@link https://formkit.com/essentials/validation#accepted}
   */
  accepted({ name }) {
    return `Molimo prihvatite ${name}`;
  },
  /**
   * The date is not after
   * @see {@link https://formkit.com/essentials/validation#date-after}
   */
  date_after({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${sentence(name)} mora biti posle ${date(args[0])}.`;
    }
    return `${sentence(name)} mora biti u budućnosti.`;
  },
  /**
   * The value is not a letter.
   * @see {@link https://formkit.com/essentials/validation#alpha}
   */
  alpha({ name }) {
    return `${sentence(name)} može da sadrži samo abecedne znakove.`;
  },
  /**
   * The value is not alphanumeric
   * @see {@link https://formkit.com/essentials/validation#alphanumeric}
   */
  alphanumeric({ name }) {
    return `${sentence(name)} može da sadrži samo slova i brojeve.`;
  },
  /**
   * The value is not letter and/or spaces
   * @see {@link https://formkit.com/essentials/validation#alpha-spaces}
   */
  alpha_spaces({ name }) {
    return `${sentence(name)} može da sadrži samo slova i razmake.`;
  },
  /**
   * The value have no letter.
   * @see {@link https://formkit.com/essentials/validation#contains_alpha}
   */
  contains_alpha({ name }) {
    return `${sentence(name)} mora da sadrži abecedne znakove.`;
  },
  /**
   * The value have no alphanumeric
   * @see {@link https://formkit.com/essentials/validation#contains_alphanumeric}
   */
  contains_alphanumeric({ name }) {
    return `${sentence(name)} mora da sadrži slova ili brojeve.`;
  },
  /**
   * The value have no letter and/or spaces
   * @see {@link https://formkit.com/essentials/validation#contains_alpha-spaces}
   */
  contains_alpha_spaces({ name }) {
    return `${sentence(name)} mora da sadrži slova ili razmake.`;
  },
  /**
   * The value have no symbol
   * @see {@link https://formkit.com/essentials/validation#contains_symbol}
   */
  contains_symbol({ name }) {
    return `${sentence(name)} mora da sadrži simbol.`;
  },
  /**
   * The value have no uppercase
   * @see {@link https://formkit.com/essentials/validation#contains_uppercase}
   */
  contains_uppercase({ name }) {
    return `${sentence(name)} mora da sadrži velika slova.`;
  },
  /**
   * The value have no lowercase
   * @see {@link https://formkit.com/essentials/validation#contains_lowercase}
   */
  contains_lowercase({ name }) {
    return `${sentence(name)} mora da sadrži mala slova.`;
  },
  /**
   *  The value have no numeric
   * @see {@link https://formkit.com/essentials/validation#contains_numeric}
   */
  contains_numeric({ name }) {
    return `${sentence(name)} mora da sadrži brojeve.`;
  },
  /**
   * The value is not symbol
   * @see {@link https://formkit.com/essentials/validation#symbol}
   */
  symbol({ name }) {
    return `${sentence(name)} mora biti simbol.`;
  },
  /**
   * The value is not uppercase
   * @see {@link https://formkit.com/essentials/validation#uppercase}
   */
  uppercase({ name }) {
    return `${sentence(name)} može da sadrži samo velika slova.`;
  },
  /**
   * The value is not lowercase
   * @see {@link https://formkit.com/essentials/validation#lowercase}
   */
  lowercase({ name }) {
    return `${sentence(name)} može da sadrži samo mala slova.`;
  },
  /**
   * The date is not before
   * @see {@link https://formkit.com/essentials/validation#date-before}
   */
  date_before({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${sentence(name)} mora biti pre ${date(args[0])}.`;
    }
    return `${sentence(name)} mora biti u prošlosti.`;
  },
  /**
   * The value is not between two numbers
   * @see {@link https://formkit.com/essentials/validation#between}
   */
  between({ name, args }) {
    if (isNaN(args[0]) || isNaN(args[1])) {
      return `Ovo polje je pogrešno konfigurisano i ne može se poslati.`;
    }
    const [a, b] = order(args[0], args[1]);
    return `${sentence(name)} mora biti između ${a} i ${b}.`;
  },
  /**
   * The confirmation field does not match
   * @see {@link https://formkit.com/essentials/validation#confirm}
   */
  confirm({ name }) {
    return `${sentence(name)} se ne podudara.`;
  },
  /**
   * The value is not a valid date
   * @see {@link https://formkit.com/essentials/validation#date-format}
   */
  date_format({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${sentence(name)} nije važeći datum, molimo Vas koristite format ${args[0]}`;
    }
    return "Ovo polje je pogrešno konfigurisano i ne može se poslati";
  },
  /**
   * Is not within expected date range
   * @see {@link https://formkit.com/essentials/validation#date-between}
   */
  date_between({ name, args }) {
    return `${sentence(name)} mora biti između ${date(args[0])} i ${date(args[1])}`;
  },
  /**
   * Shown when the user-provided value is not a valid email address.
   * @see {@link https://formkit.com/essentials/validation#email}
   */
  email: "Unesite ispravnu e-mail adresu.",
  /**
   * Does not end with the specified value
   * @see {@link https://formkit.com/essentials/validation#ends-with}
   */
  ends_with({ name, args }) {
    return `${sentence(name)} se ne završava sa ${list(args)}.`;
  },
  /**
   * Is not an allowed value
   * @see {@link https://formkit.com/essentials/validation#is}
   */
  is({ name }) {
    return `${sentence(name)} nije dozvoljena vrednost`;
  },
  /**
   * Does not match specified length
   * @see {@link https://formkit.com/essentials/validation#length}
   */
  length({ name, args: [first = 0, second = Infinity] }) {
    const min = Number(first) <= Number(second) ? first : second;
    const max = Number(second) >= Number(first) ? second : first;
    if (min == 1 && max === Infinity) {
      return `${sentence(name)} mora biti najmanje jedan karakter.`;
    }
    if (min == 0 && max) {
      return `${sentence(name)} mora biti manji ili jednaki od ${max} karaktera.`;
    }
    if (min === max) {
      return `${sentence(name)} treba da bude ${max} znakova dugačak.`;
    }
    if (min && max === Infinity) {
      return `${sentence(name)} mora biti veći ili jednaki od ${min} karaktera.`;
    }
    return `${sentence(name)} mora biti između ${min} i ${max} karaktera.`;
  },
  /**
   * Value is not a match
   * @see {@link https://formkit.com/essentials/validation#matches}
   */
  matches({ name }) {
    return `${sentence(name)} nije dozvoljena vrednost.`;
  },
  /**
   * Exceeds maximum allowed value
   * @see {@link https://formkit.com/essentials/validation#max}
   */
  max({ name, node: { value }, args }) {
    if (Array.isArray(value)) {
      return `Ne može imati više od ${args[0]} ${name}.`;
    }
    return `${sentence(name)} mora biti manji ili jednaki od ${args[0]}.`;
  },
  /**
   * The (field-level) value does not match specified mime type
   * @see {@link https://formkit.com/essentials/validation#mime}
   */
  mime({ name, args }) {
    if (!args[0]) {
      return "Nisu dozvoljeni formati datoteka.";
    }
    return `${sentence(name)} mora biti tipa: ${args[0]}`;
  },
  /**
   * Does not fulfill minimum allowed value
   * @see {@link https://formkit.com/essentials/validation#min}
   */
  min({ name, node: { value }, args }) {
    if (Array.isArray(value)) {
      return `Ne može imati manje od ${args[0]} ${name}.`;
    }
    return `${sentence(name)} mora da ima najmanje ${args[0]}.`;
  },
  /**
   * Is not an allowed value
   * @see {@link https://formkit.com/essentials/validation#not}
   */
  not({ name, node: { value } }) {
    return `“${value}” nije dozvoljeno ${name}.`;
  },
  /**
   *  Is not a number
   * @see {@link https://formkit.com/essentials/validation#number}
   */
  number({ name }) {
    return `${sentence(name)} mora biti broj.`;
  },
  /**
   * Require one field.
   * @see {@link https://formkit.com/essentials/validation#require-one}
   */
  require_one: ({ name, node, args: inputNames }) => {
    const labels = inputNames.map((name2) => {
      const dependentNode = node.at(name2);
      if (dependentNode) {
        return createMessageName(dependentNode);
      }
      return false;
    }).filter((name2) => !!name2);
    labels.unshift(name);
    return `${labels.join(" или ")} потребан је.`;
  },
  /**
   * Required field.
   * @see {@link https://formkit.com/essentials/validation#required}
   */
  required({ name }) {
    return `${sentence(name)} je obavezno polje.`;
  },
  /**
   * Does not start with specified value
   * @see {@link https://formkit.com/essentials/validation#starts-with}
   */
  starts_with({ name, args }) {
    return `${sentence(name)} ne počinje sa ${list(args)}.`;
  },
  /**
   * Is not a url
   * @see {@link https://formkit.com/essentials/validation#url}
   */
  url() {
    return `Unesite važeću URL adresu.`;
  },
  /**
   * Shown when the date is invalid.
   */
  invalidDate: "Izabrani datum je nevažeći."
};
var sr = { ui: ui36, validation: validation36 };
var ui37 = {
  /**
   * Shown when a button to remove items is visible.
   */
  remove: "Ta bort",
  /**
   * Shown when there are multiple items to remove at the same time.
   */
  removeAll: "Ta bort alla",
  /**
   * Shown when all fields are not filled out correctly.
   */
  incomplete: "Tyvärr är inte alla fält korrekt ifyllda",
  /**
   * Shown in a button inside a form to submit the form.
   */
  submit: "Skicka",
  /**
   * Shown when no files are selected.
   */
  noFiles: "Ingen fil vald",
  /**
   * Shown on buttons that move fields up in a list.
   */
  moveUp: "Flytta upp",
  /**
   * Shown on buttons that move fields down in a list.
   */
  moveDown: "Flytta ner",
  /**
   * Shown when something is actively loading.
   */
  isLoading: "Laddar...",
  /**
   * Shown when there is more to load.
   */
  loadMore: "Ladda mer",
  /**
   * Shown on buttons that navigate state forward
   */
  next: "Nästa",
  /**
   * Shown on buttons that navigate state backward
   */
  prev: "Föregående",
  /**
   * Shown when adding all values.
   */
  addAllValues: "Lägg till alla värden",
  /**
   * Shown when adding selected values.
   */
  addSelectedValues: "Lägg till valda värden",
  /**
   * Shown when removing all values.
   */
  removeAllValues: "Ta bort alla värden",
  /**
   * Shown when removing selected values.
   */
  removeSelectedValues: "Ta bort valda värden",
  /**
   * Shown when there is a date to choose.
   */
  chooseDate: "Välj datum",
  /**
   * Shown when there is a date to change.
   */
  changeDate: "Ändra datum",
  /**
   * Shown when there is something to close
   */
  close: "Stäng",
  /**
   * Shown when there is something to open.
   */
  open: "Öppna"
};
var validation37 = {
  /**
   * The value is not an accepted value.
   * @see {@link https://formkit.com/essentials/validation#accepted}
   */
  accepted({ name }) {
    return `Var god acceptera ${name}.`;
  },
  /**
   * The date is not after
   * @see {@link https://formkit.com/essentials/validation#date-after}
   */
  date_after({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${sentence(name)} måste vara efter ${date(args[0])}.`;
    }
    return `${sentence(name)} måste vara framåt i tiden.`;
  },
  /**
   * The value is not a letter.
   * @see {@link https://formkit.com/essentials/validation#alpha}
   */
  alpha({ name }) {
    return `${sentence(name)} kan enbart innehålla bokstäver i alfabetet.`;
  },
  /**
   * The value is not alphanumeric
   * @see {@link https://formkit.com/essentials/validation#alphanumeric}
   */
  alphanumeric({ name }) {
    return `${sentence(name)} kan bara innehålla bokstäver och siffror.`;
  },
  /**
   * The value is not letter and/or spaces
   * @see {@link https://formkit.com/essentials/validation#alpha-spaces}
   */
  alpha_spaces({ name }) {
    return `${sentence(name)} kan bara innehålla bokstäver och blanksteg.`;
  },
  /**
   * The value have no letter.
   * @see {@link https://formkit.com/essentials/validation#contains_alpha}
   */
  contains_alpha({ name }) {
    return `${sentence(name)} måste innehålla alfabetiska tecken.`;
  },
  /**
   * The value have no alphanumeric
   * @see {@link https://formkit.com/essentials/validation#contains_alphanumeric}
   */
  contains_alphanumeric({ name }) {
    return `${sentence(name)} måste innehålla bokstäver eller siffror.`;
  },
  /**
   * The value have no letter and/or spaces
   * @see {@link https://formkit.com/essentials/validation#contains_alpha-spaces}
   */
  contains_alpha_spaces({ name }) {
    return `${sentence(name)} måste innehålla bokstäver eller mellanslag.`;
  },
  /**
   * The value have no symbol
   * @see {@link https://formkit.com/essentials/validation#contains_symbol}
   */
  contains_symbol({ name }) {
    return `${sentence(name)} måste innehålla symbol.`;
  },
  /**
   * The value have no uppercase
   * @see {@link https://formkit.com/essentials/validation#contains_uppercase}
   */
  contains_uppercase({ name }) {
    return `${sentence(name)} måste innehålla versaler.`;
  },
  /**
   * The value have no lowercase
   * @see {@link https://formkit.com/essentials/validation#contains_lowercase}
   */
  contains_lowercase({ name }) {
    return `${sentence(name)} måste innehålla gemener.`;
  },
  /**
   *  The value have no numeric
   * @see {@link https://formkit.com/essentials/validation#contains_numeric}
   */
  contains_numeric({ name }) {
    return `${sentence(name)} måste innehålla siffror.`;
  },
  /**
   * The value is not symbol
   * @see {@link https://formkit.com/essentials/validation#symbol}
   */
  symbol({ name }) {
    return `${sentence(name)} måste vara en symbol.`;
  },
  /**
   * The value is not uppercase
   * @see {@link https://formkit.com/essentials/validation#uppercase}
   */
  uppercase({ name }) {
    return `${sentence(name)} kan bara innehålla versaler.`;
  },
  /**
   * The value is not lowercase
   * @see {@link https://formkit.com/essentials/validation#lowercase}
   */
  lowercase({ name }) {
    return `${sentence(name)} kan bara innehålla små bokstäver.`;
  },
  /**
   * The date is not before
   * @see {@link https://formkit.com/essentials/validation#date-before}
   */
  date_before({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${sentence(name)} måste vara före ${date(args[0])}.`;
    }
    return `${sentence(name)} måste vara bakåt i tiden.`;
  },
  /**
   * The value is not between two numbers
   * @see {@link https://formkit.com/essentials/validation#between}
   */
  between({ name, args }) {
    if (isNaN(args[0]) || isNaN(args[1])) {
      return `Det här fältet ställdes inte in korrekt och kan inte användas.`;
    }
    const [a, b] = order(args[0], args[1]);
    return `${sentence(name)} måste vara mellan ${a} och ${b}.`;
  },
  /**
   * The confirmation field does not match
   * @see {@link https://formkit.com/essentials/validation#confirm}
   */
  confirm({ name }) {
    return `${sentence(name)} matchar inte.`;
  },
  /**
   * The value is not a valid date
   * @see {@link https://formkit.com/essentials/validation#date-format}
   */
  date_format({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${sentence(name)} är inte ett giltigt datum, var god använd formatet ${args[0]}`;
    }
    return "Det här fältet ställdes inte in korrekt och kan inte användas";
  },
  /**
   * Is not within expected date range
   * @see {@link https://formkit.com/essentials/validation#date-between}
   */
  date_between({ name, args }) {
    return `${sentence(name)} måste vara mellan ${date(args[0])} och ${date(args[1])}`;
  },
  /**
   * Shown when the user-provided value is not a valid email address.
   * @see {@link https://formkit.com/essentials/validation#email}
   */
  email: "Var god fyll i en giltig e-postadress.",
  /**
   * Does not end with the specified value
   * @see {@link https://formkit.com/essentials/validation#ends-with}
   */
  ends_with({ name, args }) {
    return `${sentence(name)} slutar inte med ${list(args)}.`;
  },
  /**
   * Is not an allowed value
   * @see {@link https://formkit.com/essentials/validation#is}
   */
  is({ name }) {
    return `${sentence(name)} är inte ett godkänt värde.`;
  },
  /**
   * Does not match specified length
   * @see {@link https://formkit.com/essentials/validation#length}
   */
  length({ name, args: [first = 0, second = Infinity] }) {
    const min = Number(first) <= Number(second) ? first : second;
    const max = Number(second) >= Number(first) ? second : first;
    if (min == 1 && max === Infinity) {
      return `${sentence(name)} måste ha minst ett tecken.`;
    }
    if (min == 0 && max) {
      return `${sentence(name)} måste vara ${max} tecken eller färre.`;
    }
    if (min === max) {
      return `${sentence(name)} bör vara ${max} tecken långa.`;
    }
    if (min && max === Infinity) {
      return `${sentence(name)} måste vara ${min} tecken eller fler.`;
    }
    return `${sentence(name)} måste vara mellan ${min} och ${max} tecken.`;
  },
  /**
   * Value is not a match
   * @see {@link https://formkit.com/essentials/validation#matches}
   */
  matches({ name }) {
    return `${sentence(name)} är inte ett godkänt värde.`;
  },
  /**
   * Exceeds maximum allowed value
   * @see {@link https://formkit.com/essentials/validation#max}
   */
  max({ name, node: { value }, args }) {
    if (Array.isArray(value)) {
      return `Kan inte ha mer än ${args[0]} ${name}.`;
    }
    return `${sentence(name)} måste vara ${args[0]} eller mindre.`;
  },
  /**
   * The (field-level) value does not match specified mime type
   * @see {@link https://formkit.com/essentials/validation#mime}
   */
  mime({ name, args }) {
    if (!args[0]) {
      return "Inga filtyper tillåtna.";
    }
    return `${sentence(name)} måste vara av filtypen: ${args[0]}`;
  },
  /**
   * Does not fulfill minimum allowed value
   * @see {@link https://formkit.com/essentials/validation#min}
   */
  min({ name, node: { value }, args }) {
    if (Array.isArray(value)) {
      return `Kan inte ha mindre än ${args[0]} ${name}.`;
    }
    return `${sentence(name)} måste vara minst ${args[0]}.`;
  },
  /**
   * Is not an allowed value
   * @see {@link https://formkit.com/essentials/validation#not}
   */
  not({ name, node: { value } }) {
    return `“${value}” är inte ett godkänt ${name}.`;
  },
  /**
   *  Is not a number
   * @see {@link https://formkit.com/essentials/validation#number}
   */
  number({ name }) {
    return `${sentence(name)} måste vara en siffra.`;
  },
  /**
   * Require one field.
   * @see {@link https://formkit.com/essentials/validation#require-one}
   */
  require_one: ({ name, node, args: inputNames }) => {
    const labels = inputNames.map((name2) => {
      const dependentNode = node.at(name2);
      if (dependentNode) {
        return createMessageName(dependentNode);
      }
      return false;
    }).filter((name2) => !!name2);
    labels.unshift(name);
    return `${labels.join(" eller ")} krävs.`;
  },
  /**
   * Required field.
   * @see {@link https://formkit.com/essentials/validation#required}
   */
  required({ name }) {
    return `${sentence(name)} är obligatoriskt.`;
  },
  /**
   * Does not start with specified value
   * @see {@link https://formkit.com/essentials/validation#starts-with}
   */
  starts_with({ name, args }) {
    return `${sentence(name)} börjar inte med ${list(args)}.`;
  },
  /**
   * Is not a url
   * @see {@link https://formkit.com/essentials/validation#url}
   */
  url() {
    return `Ange en giltig URL.`;
  },
  /**
   * Shown when the date is invalid.
   */
  invalidDate: "Det valda datumet är ogiltigt."
};
var sv = { ui: ui37, validation: validation37 };

// packages/i18n/src/locales/tet.ts
var ui38 = {
  /**
   * Shown on a button for adding additional items.
   */
  add: "Aumenta",
  /**
   * Shown when a button to remove items is visible.
   */
  remove: "Hasai",
  /**
   * Shown when there are multiple items to remove at the same time.
   */
  removeAll: "Hasai Hotu",
  /**
   * Shown when all fields are not filled out correctly.
   */
  incomplete: "Deskulpa, iha informasaun neebe sala iha formuláriu",
  /**
   * Shown in a button inside a form to submit the form.
   */
  submit: "Submete",
  /**
   * Shown when no files are selected.
   */
  noFiles: "Seidauk hili file",
  /**
   * Shown on buttons that move fields up in a list.
   */
  moveUp: "Muda ba leten",
  /**
   * Shown on buttons that move fields down in a list.
   */
  moveDown: "Muda ba kotuk",
  /**
   * Shown when something is actively loading.
   */
  isLoading: "Hein lai...",
  /**
   * Shown when there is more to load.
   */
  loadMore: "Foti tan",
  /**
   * Show on buttons that navigate state forward
   */
  next: "Ba oin",
  /**
   * Show on buttons that navigate state backward
   */
  prev: "Ba kotuk",
  /**
   * Shown when adding all values.
   */
  addAllValues: "Aumenta hotu",
  /**
   * Shown when adding selected values.
   */
  addSelectedValues: "Aumenta buat neebe hili ona",
  /**
   * Shown when removing all values.
   */
  removeAllValues: "Hasai hotu",
  /**
   * Shown when removing selected values.
   */
  removeSelectedValues: "Hasai buat neebe hili ona",
  /**
   * Shown when there is a date to choose.
   */
  chooseDate: "Hili data",
  /**
   * Shown when there is a date to change.
   */
  changeDate: "Troka data"
};
var validation38 = {
  /**
   * The value is not an accepted value.
   * @see {@link https://formkit.com/essentials/validation#accepted}
   */
  accepted({ name }) {
    return `Favor ida simu ${name}.`;
  },
  /**
   * The date is not after
   * @see {@link https://formkit.com/essentials/validation#date-after}
   */
  date_after({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${sentence(name)} tenki depoid ${date(args[0])}.`;
    }
    return `${sentence(name)} tenki iha futuru.`;
  },
  /**
   * The value is not a letter.
   * @see {@link https://formkit.com/essentials/validation#alpha}
   */
  alpha({ name }) {
    return `${sentence(name)} bele uza letra deit.`;
  },
  /**
   * The value is not alphanumeric
   * @see {@link https://formkit.com/essentials/validation#alphanumeric}
   */
  alphanumeric({ name }) {
    return `${sentence(name)} bele uza letra ka numeru deit.`;
  },
  /**
   * The value is not letter and/or spaces
   * @see {@link https://formkit.com/essentials/validation#alpha-spaces}
   */
  alpha_spaces({ name }) {
    return `${sentence(name)} bele uza letra ka numeru deit.`;
  },
  /**
   * The date is not before
   * @see {@link https://formkit.com/essentials/validation#date-before}
   */
  date_before({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${sentence(name)} tenki antes ${date(args[0])}.`;
    }
    return `${sentence(name)} tenki antes ohin loron.`;
  },
  /**
   * The value is not between two numbers
   * @see {@link https://formkit.com/essentials/validation#between}
   */
  between({ name, args }) {
    if (isNaN(args[0]) || isNaN(args[1])) {
      return `Informasaun nee la loos no la bele submete.`;
    }
    const [a, b] = order(args[0], args[1]);
    return `${sentence(name)} tenki iha klaran entre ${a} no ${b}.`;
  },
  /**
   * The confirmation field does not match
   * @see {@link https://formkit.com/essentials/validation#confirm}
   */
  confirm({ name }) {
    return `${sentence(name)} la hanesan.`;
  },
  /**
   * The value is not a valid date
   * @see {@link https://formkit.com/essentials/validation#date-format}
   */
  date_format({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${sentence(name)} la loos, favor ida hakerek tuir ${args[0]}`;
    }
    return "Informasaun nee la loos no la bele submete.";
  },
  /**
   * Is not within expected date range
   * @see {@link https://formkit.com/essentials/validation#date-between}
   */
  date_between({ name, args }) {
    return `${sentence(name)} tenki iha ${date(args[0])} no ${date(
      args[1]
    )} nia klaran`;
  },
  /**
   * Shown when the user-provided value is not a valid email address.
   * @see {@link https://formkit.com/essentials/validation#email}
   */
  email: "Favor hakerek endresu email neebe loos.",
  /**
   * Does not end with the specified value
   * @see {@link https://formkit.com/essentials/validation#ends-with}
   */
  ends_with({ name, args }) {
    return `${sentence(name)} la remata ho ${list(args)}.`;
  },
  /**
   * Is not an allowed value
   * @see {@link https://formkit.com/essentials/validation#is}
   */
  is({ name }) {
    return `la bele uza ${sentence(name)}.`;
  },
  /**
   * Does not match specified length
   * @see {@link https://formkit.com/essentials/validation#length}
   */
  length({ name, args: [first = 0, second = Infinity] }) {
    const min = Number(first) <= Number(second) ? first : second;
    const max = Number(second) >= Number(first) ? second : first;
    if (min == 1 && max === Infinity) {
      return `${sentence(name)} tenki iha letra ida ka liu.`;
    }
    if (min == 0 && max) {
      return `${sentence(name)} tenki badak liu ${max} letra.`;
    }
    if (min === max) {
      return `${sentence(name)} tenki iha letra ${max}.`;
    }
    if (min && max === Infinity) {
      return `${sentence(name)} tenki iha letra ${min} ka liu.`;
    }
    return `${sentence(name)} tenki iha letra ${min} too ${max}.`;
  },
  /**
   * Value is not a match
   * @see {@link https://formkit.com/essentials/validation#matches}
   */
  matches({ name }) {
    return `la bele uza ${sentence(name)}.`;
  },
  /**
   * Exceeds maximum allowed value
   * @see {@link https://formkit.com/essentials/validation#max}
   */
  max({ name, node: { value }, args }) {
    if (Array.isArray(value)) {
      return `La bele iha ${args[0]} ka liu ${name}.`;
    }
    return `${sentence(name)} tenki kiik liu ka hanesan ${args[0]}.`;
  },
  /**
   * The (field-level) value does not match specified mime type
   * @see {@link https://formkit.com/essentials/validation#mime}
   */
  mime({ name, args }) {
    if (!args[0]) {
      return `La bele simu 'format' ida.`;
    }
    return `${sentence(name)} tenki iha tipo: ${args[0]}`;
  },
  /**
   * Does not fulfill minimum allowed value
   * @see {@link https://formkit.com/essentials/validation#min}
   */
  min({ name, node: { value }, args }) {
    if (Array.isArray(value)) {
      return `Presiza ${args[0]} ${name} ka liu.`;
    }
    return `${name} tenki ${args[0]} ka liu.`;
  },
  /**
   * Is not an allowed value
   * @see {@link https://formkit.com/essentials/validation#not}
   */
  not({ name, node: { value } }) {
    return `La bele uza “${value}” ba ${name}.`;
  },
  /**
   *  Is not a number
   * @see {@link https://formkit.com/essentials/validation#number}
   */
  number({ name }) {
    return `${sentence(name)} tenki numeru.`;
  },
  /**
   * Required field.
   * @see {@link https://formkit.com/essentials/validation#required}
   */
  required({ name }) {
    return `Presiza ${sentence(name)}.`;
  },
  /**
   * Does not start with specified value
   * @see {@link https://formkit.com/essentials/validation#starts-with}
   */
  starts_with({ name, args }) {
    return `${sentence(name)} la komesa ho ${list(args)}.`;
  },
  /**
   * Is not a url
   * @see {@link https://formkit.com/essentials/validation#url}
   */
  url() {
    return `Favor hakerek URL neebe loos.`;
  },
  /**
   * Shown when the date is invalid.
   */
  invalidDate: "Data la loos."
};
var tet = { ui: ui38, validation: validation38 };
var ui39 = {
  /**
   * Shown on a button for adding additional items.
   */
  add: "Илова кардан",
  /**
   * Shown when a button to remove items is visible.
   */
  remove: "Хориҷ кардан",
  /**
   * Shown when there are multiple items to remove at the same time.
   */
  removeAll: "Ҳамаро хориҷ кунед",
  /**
   * Shown when all fields are not filled out correctly.
   */
  incomplete: "Бубахшед, на ҳама майдонҳо дуруст пур карда шудаанд.",
  /**
   * Shown in a button inside a form to submit the form.
   */
  submit: "Пешниҳод кунед",
  /**
   * Shown when no files are selected.
   */
  noFiles: "Ягон файл интихоб нашудааст",
  /**
   * Shown on buttons that move fields up in a list.
   */
  moveUp: "Ба боло ҳаракат кунед",
  /**
   * Shown on buttons that move fields down in a list.
   */
  moveDown: "Ба поён ҳаракат кунед",
  /**
   * Shown when something is actively loading.
   */
  isLoading: "Дар ҳоли боргузорӣ",
  /**
   * Shown when there is more to load.
   */
  loadMore: "Бештар бор кунед",
  /**
   * Show on buttons that navigate state forward
   */
  next: "Баъдӣ",
  /**
   * Show on buttons that navigate state backward
   */
  prev: "Гузашта",
  /**
   * Shown when adding all values.
   */
  addAllValues: "Ҳама арзишҳоро илова кунед",
  /**
   * Shown when adding selected values.
   */
  addSelectedValues: "Илова кардани арзишҳои интихобшуда",
  /**
   * Shown when removing all values.
   */
  removeAllValues: "Ҳама арзишҳоро хориҷ кунед",
  /**
   * Shown when removing selected values.
   */
  removeSelectedValues: "Арзишҳои интихобшударо хориҷ кунед",
  /**
   * Shown when there is a date to choose.
   */
  chooseDate: "Сана интихоб кунед",
  /**
   * Shown when there is a date to change.
   */
  changeDate: "Тағйир додани сана"
};
var validation39 = {
  /**
   * The value is not an accepted value.
   * @see {@link https://formkit.com/essentials/validation#accepted}
   */
  accepted({ name }) {
    return `Лутфан ${name}-ро қабул кунед`;
  },
  /**
   * The date is not after
   * @see {@link https://formkit.com/essentials/validation#date-after}
   */
  date_after({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${sentence(name)} бояд пас аз ${date(args[0])} бошад.`;
    }
    return `${sentence(name)} бояд дар оянда бошад.`;
  },
  /**
   * The value is not a letter.
   * @see {@link https://formkit.com/essentials/validation#alpha}
   */
  alpha({ name }) {
    return `${sentence(name)} метавонад танҳо аломатҳои алифборо дар бар гирад.`;
  },
  /**
   * The value is not alphanumeric
   * @see {@link https://formkit.com/essentials/validation#alphanumeric}
   */
  alphanumeric({ name }) {
    return `${sentence(name)} метавонад танҳо ҳарфҳо ва рақамҳоро дар бар гирад.`;
  },
  /**
   * The value is not letter and/or spaces
   * @see {@link https://formkit.com/essentials/validation#alpha-spaces}
   */
  alpha_spaces({ name }) {
    return `${sentence(name)} метавонад танҳо ҳарфҳо ва фосилаҳоро дар бар гирад.`;
  },
  /**
   * The value have no letter.
   * @see {@link https://formkit.com/essentials/validation#contains_alpha}
   */
  contains_alpha({ name }) {
    return `${sentence(name)} must contain alphabetical characters.`;
  },
  /**
   * The value have no alphanumeric
   * @see {@link https://formkit.com/essentials/validation#contains_alphanumeric}
   */
  contains_alphanumeric({ name }) {
    return `${sentence(name)} must contain letters and numbers.`;
  },
  /**
   * The value have no letter and/or spaces
   * @see {@link https://formkit.com/essentials/validation#contains_alpha-spaces}
   */
  contains_alpha_spaces({ name }) {
    return `${sentence(name)} must contain letters and spaces.`;
  },
  /**
   * The value have no symbol
   * @see {@link https://formkit.com/essentials/validation#contains_symbol}
   */
  contains_symbol({ name }) {
    return `${sentence(name)} must contain symbol.`;
  },
  /**
   * The value have no uppercase
   * @see {@link https://formkit.com/essentials/validation#contains_uppercase}
   */
  contains_uppercase({ name }) {
    return `${sentence(name)} must contain uppercase.`;
  },
  /**
   * The value have no lowercase
   * @see {@link https://formkit.com/essentials/validation#contains_lowercase}
   */
  contains_lowercase({ name }) {
    return `${sentence(name)} must contain lowercase.`;
  },
  /**
   *  The value have no numeric
   * @see {@link https://formkit.com/essentials/validation#contains_numeric}
   */
  contains_numeric({ name }) {
    return `${sentence(name)} must contain number.`;
  },
  /**
   * The value is not symbol
   * @see {@link https://formkit.com/essentials/validation#symbol}
   */
  symbol({ name }) {
    return `${sentence(name)} can only contain symbol.`;
  },
  /**
   * The value is not uppercase
   * @see {@link https://formkit.com/essentials/validation#uppercase}
   */
  uppercase({ name }) {
    return `${sentence(name)} can only contain uppercase.`;
  },
  /**
   * The value is not lowercase
   * @see {@link https://formkit.com/essentials/validation#lowercase}
   */
  lowercase({ name }) {
    return `${sentence(name)} can only contain lowercase.`;
  },
  /**
   * The date is not before
   * @see {@link https://formkit.com/essentials/validation#date-before}
   */
  date_before({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${sentence(name)} бояд пеш аз ${date(args[0])} бошад.`;
    }
    return `${sentence(name)} бояд дар гузашта бошад.`;
  },
  /**
   * The value is not between two numbers
   * @see {@link https://formkit.com/essentials/validation#between}
   */
  between({ name, args }) {
    if (isNaN(args[0]) || isNaN(args[1])) {
      return `Ин майдон нодуруст танзим шудааст ва онро пешниҳод кардан ғайриимкон аст.`;
    }
    const [a, b] = order(args[0], args[1]);
    return `${sentence(name)} бояд дар байни ${a} ва ${b} бошад.`;
  },
  /**
   * The confirmation field does not match
   * @see {@link https://formkit.com/essentials/validation#confirm}
   */
  confirm({ name }) {
    return `${sentence(name)} мувофиқат намекунад.`;
  },
  /**
   * The value is not a valid date
   * @see {@link https://formkit.com/essentials/validation#date-format}
   */
  date_format({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${sentence(name)} санаи дуруст нест, лутфан формати ${args[0]}-ро истифода баред`;
    }
    return "Ин майдон нодуруст танзим шудааст ва онро пешниҳод кардан ғайриимкон аст";
  },
  /**
   * Is not within expected date range
   * @see {@link https://formkit.com/essentials/validation#date-between}
   */
  date_between({ name, args }) {
    return `${sentence(name)} бояд дар байни ${date(args[0])} ва ${date(
      args[1]
    )} бошад`;
  },
  /**
   * Shown when the user-provided value is not a valid email address.
   * @see {@link https://formkit.com/essentials/validation#email}
   */
  email: "Лутфан нишонаи имейли амалкунандаро ворид намоед.",
  /**
   * Does not end with the specified value
   * @see {@link https://formkit.com/essentials/validation#ends-with}
   */
  ends_with({ name, args }) {
    return `${sentence(name)} бо ${list(args)} ба охир намерасад.`;
  },
  /**
   * Is not an allowed value
   * @see {@link https://formkit.com/essentials/validation#is}
   */
  is({ name }) {
    return `${sentence(name)} арзиши иҷозатдодашуда нест.`;
  },
  /**
   * Does not match specified length
   * @see {@link https://formkit.com/essentials/validation#length}
   */
  length({ name, args: [first = 0, second = Infinity] }) {
    const min = Number(first) <= Number(second) ? first : second;
    const max = Number(second) >= Number(first) ? second : first;
    if (min == 1 && max === Infinity) {
      return `${sentence(name)} бояд ҳадди аққал як аломат бошад.`;
    }
    if (min == 0 && max) {
      return `${sentence(name)} бояд аз ${max} аломат камтар ё баробар бошад.`;
    }
    if (min === max) {
      return `${sentence(name)} бояд ${max} аломат бошад.`;
    }
    if (min && max === Infinity) {
      return `${sentence(name)} бояд аз ${min} аломат зиёд ё баробар бошад.`;
    }
    return `${sentence(name)} бояд дар байни ${min} ва ${max} аломат бошад.`;
  },
  /**
   * Value is not a match
   * @see {@link https://formkit.com/essentials/validation#matches}
   */
  matches({ name }) {
    return `${sentence(name)} арзиши иҷозатдодашуда нест.`;
  },
  /**
   * Exceeds maximum allowed value
   * @see {@link https://formkit.com/essentials/validation#max}
   */
  max({ name, node: { value }, args }) {
    if (Array.isArray(value)) {
      return `Зиёда аз ${args[0]} ${name} дошта наметавонад.`;
    }
    return `${sentence(name)} бояд аз ${args[0]} камтар ё баробар бошад.`;
  },
  /**
   * The (field-level) value does not match specified mime type
   * @see {@link https://formkit.com/essentials/validation#mime}
   */
  mime({ name, args }) {
    if (!args[0]) {
      return "Ягон формати файл иҷозат дода намешавад.";
    }
    return `${sentence(name)} бояд чунин намуд бошад: ${args[0]}`;
  },
  /**
   * Does not fulfill minimum allowed value
   * @see {@link https://formkit.com/essentials/validation#min}
   */
  min({ name, node: { value }, args }) {
    if (Array.isArray(value)) {
      return `Камтар аз ${args[0]} ${name} дошта наметавонад.`;
    }
    return `${sentence(name)} бояд ҳадди аққал ${args[0]} бошад.`;
  },
  /**
   * Is not an allowed value
   * @see {@link https://formkit.com/essentials/validation#not}
   */
  not({ name, node: { value } }) {
    return `"${value}" ${name} иҷозат дода намешавад.`;
  },
  /**
   *  Is not a number
   * @see {@link https://formkit.com/essentials/validation#number}
   */
  number({ name }) {
    return `${sentence(name)} бояд рақам бошад.`;
  },
  /**
   * Require one field.
   * @see {@link https://formkit.com/essentials/validation#require-one}
   */
  require_one: ({ name, node, args: inputNames }) => {
    const labels = inputNames.map((name2) => {
      const dependentNode = node.at(name2);
      if (dependentNode) {
        return createMessageName(dependentNode);
      }
      return false;
    }).filter((name2) => !!name2);
    labels.unshift(name);
    return `${labels.join(" ё ")} зарур а`;
  },
  /**
   * Required field.
   * @see {@link https://formkit.com/essentials/validation#required}
   */
  required({ name }) {
    return `${sentence(name)} лозим аст.`;
  },
  /**
   * Does not start with specified value
   * @see {@link https://formkit.com/essentials/validation#starts-with}
   */
  starts_with({ name, args }) {
    return `${sentence(name)} бо ${list(args)} оғоз намешавад.`;
  },
  /**
   * Is not a url
   * @see {@link https://formkit.com/essentials/validation#url}
   */
  url() {
    return `Лутфан URL-и дурустро дохил кунед.`;
  },
  /**
   * Shown when the date is invalid.
   */
  invalidDate: "Санаи интихобшуда нодуруст аст."
};
var tg = { ui: ui39, validation: validation39 };
var ui40 = {
  /**
   * Shown on buttons for adding new items.
   */
  add: "เพิ่ม",
  /**
   * Shown when a button to remove items is visible.
   */
  remove: "เอาออก",
  /**
   * Shown when there are multiple items to remove at the same time.
   */
  removeAll: "เอาออกทั้งหมด",
  /**
   * Shown when all fields are not filled out correctly.
   */
  incomplete: "ขออภัย ข้อมูลบางช่องที่กรอกไม่ถูกต้อง",
  /**
   * Shown in a button inside a form to submit the form.
   */
  submit: "ส่ง",
  /**
   * Shown when no files are selected.
   */
  noFiles: "ยังไม่ได้เลือกไฟล์",
  /**
   * Shown on buttons that move fields up in a list.
   */
  moveUp: "เลื่อนขึ้น",
  /**
   * Shown on buttons that move fields down in a list.
   */
  moveDown: "เลื่อนลง",
  /**
   * Shown when something is actively loading.
   */
  isLoading: "กำลังโหลด...",
  /**
   * Shown when there is more to load.
   */
  loadMore: "โหลดเพิ่มเติม",
  /**
   * Shown on buttons that navigate state forward
   */
  next: "ถัดไป",
  /**
   * Shown on buttons that navigate state backward
   */
  prev: "ก่อนหน้า",
  /**
   * Shown when adding all values.
   */
  addAllValues: "เพิ่มค่าทั้งหมด",
  /**
   * Shown when adding selected values.
   */
  addSelectedValues: "เพิ่มค่าที่เลือก",
  /**
   * Shown when removing all values.
   */
  removeAllValues: "ลบค่าทั้งหมด",
  /**
   * Shown when removing selected values.
   */
  removeSelectedValues: "ลบค่าที่เลือก",
  /**
   * Shown when there is a date to choose.
   */
  chooseDate: "เลือกวันที่",
  /**
   * Shown when there is a date to change.
   */
  changeDate: "เปลี่ยนวันที่",
  /**
   * Shown when there is something to close
   */
  close: "ปิด",
  /**
   * Shown when there is something to open.
   */
  open: "เปิด"
};
var validation40 = {
  /**
   * The value is not an accepted value.
   * @see {@link https://formkit.com/essentials/validation#accepted}
   */
  accepted({ name }) {
    return `กรุณายอมรับ ${name}`;
  },
  /**
   * The date is not after
   * @see {@link https://formkit.com/essentials/validation#date-after}
   */
  date_after({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${sentence(name)} จะต้องเป็นวันที่หลังจาก ${date(args[0])}`;
    }
    return `${sentence(name)} จะต้องเป็นวันที่ที่ยังไม่มาถึง`;
  },
  /**
   * The value is not a letter.
   * @see {@link https://formkit.com/essentials/validation#alpha}
   */
  alpha({ name }) {
    return `${sentence(name)} สามารถเป็นได้แค่ตัวอักษรเท่านั้น`;
  },
  /**
   * The value is not alphanumeric
   * @see {@link https://formkit.com/essentials/validation#alphanumeric}
   */
  alphanumeric({ name }) {
    return `${sentence(name)} สามารถเป็นได้แค่ตัวอักษรและตัวเลขเท่านั้น`;
  },
  /**
   * The value is not letter and/or spaces
   * @see {@link https://formkit.com/essentials/validation#alpha-spaces}
   */
  alpha_spaces({ name }) {
    return `${sentence(name)} สามารถเป็นได้แค่ตัวอักษรและเว้นวรรคเท่านั้น`;
  },
  /**
   * The value have no letter.
   * @see {@link https://formkit.com/essentials/validation#contains_alpha}
   */
  contains_alpha({ name }) {
    return `${sentence(name)} ต้องมีตัวอักษรตัวอักษร`;
  },
  /**
   * The value have no alphanumeric
   * @see {@link https://formkit.com/essentials/validation#contains_alphanumeric}
   */
  contains_alphanumeric({ name }) {
    return `${sentence(name)} ต้องมีตัวอักษรหรือตัวเลข`;
  },
  /**
   * The value have no letter and/or spaces
   * @see {@link https://formkit.com/essentials/validation#contains_alpha-spaces}
   */
  contains_alpha_spaces({ name }) {
    return `${sentence(name)} ต้องมีตัวอักษรหรือช่องว่าง`;
  },
  /**
   * The value have no symbol
   * @see {@link https://formkit.com/essentials/validation#contains_symbol}
   */
  contains_symbol({ name }) {
    return `${sentence(name)} ต้องมีสัญลักษณ์`;
  },
  /**
   * The value have no uppercase
   * @see {@link https://formkit.com/essentials/validation#contains_uppercase}
   */
  contains_uppercase({ name }) {
    return `${sentence(name)} ต้องมีตัวพิมพ์ใหญ่`;
  },
  /**
   * The value have no lowercase
   * @see {@link https://formkit.com/essentials/validation#contains_lowercase}
   */
  contains_lowercase({ name }) {
    return `${sentence(name)} ต้องมีตัวพิมพ์เล็ก`;
  },
  /**
   *  The value have no numeric
   * @see {@link https://formkit.com/essentials/validation#contains_numeric}
   */
  contains_numeric({ name }) {
    return `${sentence(name)} ต้องมีตัวเลข`;
  },
  /**
   * The value is not symbol
   * @see {@link https://formkit.com/essentials/validation#symbol}
   */
  symbol({ name }) {
    return `${sentence(name)} จะต้องเป็นสัญลักษณ์`;
  },
  /**
   * The value is not uppercase
   * @see {@link https://formkit.com/essentials/validation#uppercase}
   */
  uppercase({ name }) {
    return `${sentence(name)} เท่านั้นที่สามารถมีตัวอักษรตัวพิมพ์ใหญ่`;
  },
  /**
   * The value is not lowercase
   * @see {@link https://formkit.com/essentials/validation#lowercase}
   */
  lowercase({ name }) {
    return `${sentence(name)} เท่านั้นที่สามารถมีตัวอักษรตัวพิมพ์เล็ก`;
  },
  /**
   * The date is not before
   * @see {@link https://formkit.com/essentials/validation#date-before}
   */
  date_before({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${sentence(name)} จะต้องเป็นวันที่ที่มาก่อน ${date(args[0])}`;
    }
    return `${sentence(name)} จะต้องเป็นวันที่ที่ผ่านมาแล้ว`;
  },
  /**
   * The value is not between two numbers
   * @see {@link https://formkit.com/essentials/validation#between}
   */
  between({ name, args }) {
    if (isNaN(args[0]) || isNaN(args[1])) {
      return `ช่องนี้ถูกตั้งค่าอย่างไม่ถูกต้อง และจะไม่สามารถส่งข้อมูลได้`;
    }
    const [a, b] = order(args[0], args[1]);
    return `${sentence(name)} จะต้องเป็นค่าระหว่าง ${a} และ ${b}`;
  },
  /**
   * The confirmation field does not match
   * @see {@link https://formkit.com/essentials/validation#confirm}
   */
  confirm({ name }) {
    return `${sentence(name)} ไม่ตรงกัน`;
  },
  /**
   * The value is not a valid date
   * @see {@link https://formkit.com/essentials/validation#date-format}
   */
  date_format({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${sentence(name)} ไม่อยู่ในรูปแบบวันที่ที่ถูกต้อง กรุณากรอกตามรูปแบบ ${args[0]}`;
    }
    return "ช่องนี้ถูกตั้งค่าอย่างไม่ถูกต้อง และจะไม่สามารถส่งข้อมูลได้";
  },
  /**
   * Is not within expected date range
   * @see {@link https://formkit.com/essentials/validation#date-between}
   */
  date_between({ name, args }) {
    return `${sentence(name)} จะต้องเป็นวันที่ระหว่าง ${date(args[0])} และ ${date(
      args[1]
    )}`;
  },
  /**
   * Shown when the user-provided value is not a valid email address.
   * @see {@link https://formkit.com/essentials/validation#email}
   */
  email: "กรุณากรอกที่อยู่อีเมลทีถูกต้อง",
  /**
   * Does not end with the specified value
   * @see {@link https://formkit.com/essentials/validation#ends-with}
   */
  ends_with({ name, args }) {
    return `${sentence(name)} จะต้องลงท้ายด้วย ${list(args)}`;
  },
  /**
   * Is not an allowed value
   * @see {@link https://formkit.com/essentials/validation#is}
   */
  is({ name }) {
    return `${sentence(name)} ไม่ใช่ค่าที่อนุญาตให้กรอก`;
  },
  /**
   * Does not match specified length
   * @see {@link https://formkit.com/essentials/validation#length}
   */
  length({ name, args: [first = 0, second = Infinity] }) {
    const min = Number(first) <= Number(second) ? first : second;
    const max = Number(second) >= Number(first) ? second : first;
    if (min == 1 && max === Infinity) {
      return `${sentence(name)} จะต้องมีความยาวอย่างน้อยหนึ่งตัวอักษร`;
    }
    if (min == 0 && max) {
      return `${sentence(name)} จะต้องมีความยาวไม่เกิน ${max} ตัวอักษร`;
    }
    if (min === max) {
      return `${sentence(name)} ควรจะเป็น ${max} ตัวอักษรยาว`;
    }
    if (min && max === Infinity) {
      return `${sentence(name)} จะต้องมีความยาว ${min} ตัวอักษรขึ้นไป`;
    }
    return `${sentence(name)} จะต้องมีความยาวระหว่าง ${min} และ ${max} ตัวอักษร`;
  },
  /**
   * Value is not a match
   * @see {@link https://formkit.com/essentials/validation#matches}
   */
  matches({ name }) {
    return `${sentence(name)} ไม่ใช่ค่าที่อนุญาตให้กรอก`;
  },
  /**
   * Exceeds maximum allowed value
   * @see {@link https://formkit.com/essentials/validation#max}
   */
  max({ name, node: { value }, args }) {
    if (Array.isArray(value)) {
      return `ไม่สามารถเลือกมากกว่า ${args[0]} ${name} ได้`;
    }
    return `${sentence(name)} จะต้องมีค่าไม่เกิน ${args[0]}`;
  },
  /**
   * The (field-level) value does not match specified mime type
   * @see {@link https://formkit.com/essentials/validation#mime}
   */
  mime({ name, args }) {
    if (!args[0]) {
      return "ไม่มีประเภทของไฟล์ที่อนุญาต";
    }
    return `${sentence(name)} จะต้องเป็นไฟล์ประเภท ${args[0]} เท่านั้น`;
  },
  /**
   * Does not fulfill minimum allowed value
   * @see {@link https://formkit.com/essentials/validation#min}
   */
  min({ name, node: { value }, args }) {
    if (Array.isArray(value)) {
      return `ไม่สามารถเลือกน้อยกว่า ${args[0]} ${name} ได้`;
    }
    return `${sentence(name)} จะต้องมีค่าอย่างน้อย ${args[0]}`;
  },
  /**
   * Is not an allowed value
   * @see {@link https://formkit.com/essentials/validation#not}
   */
  not({ name, node: { value } }) {
    return `“${value}” ไม่ใช่ค่า ${name} ที่อนุญาตให้กรอก`;
  },
  /**
   *  Is not a number
   * @see {@link https://formkit.com/essentials/validation#number}
   */
  number({ name }) {
    return `${sentence(name)} จะต้องเป็นตัวเลขเท่านั้น`;
  },
  /**
   * Require one field.
   * @see {@link https://formkit.com/essentials/validation#require-one}
   */
  require_one: ({ name, node, args: inputNames }) => {
    const labels = inputNames.map((name2) => {
      const dependentNode = node.at(name2);
      if (dependentNode) {
        return createMessageName(dependentNode);
      }
      return false;
    }).filter((name2) => !!name2);
    labels.unshift(name);
    return `${labels.join(" หรือ ")} ต้องการ.`;
  },
  /**
   * Required field.
   * @see {@link https://formkit.com/essentials/validation#required}
   */
  required({ name }) {
    return `กรุณากรอก ${sentence(name)}`;
  },
  /**
   * Does not start with specified value
   * @see {@link https://formkit.com/essentials/validation#starts-with}
   */
  starts_with({ name, args }) {
    return `${sentence(name)} จะต้องเริ่มต้นด้วย ${list(args)}`;
  },
  /**
   * Is not a url
   * @see {@link https://formkit.com/essentials/validation#url}
   */
  url() {
    return `กรุณาระบุที่อยู่ลิงก์ให้ถูกต้อง`;
  },
  /**
   * Shown when the date is invalid.
   */
  invalidDate: "วันที่ที่เลือกไม่ถูกต้อง"
};
var th = { ui: ui40, validation: validation40 };
var ui41 = {
  /**
   * Shown on buttons for adding new items.
   */
  add: "Ekle",
  /**
   * Shown when a button to remove items is visible.
   */
  remove: "Kaldır",
  /**
   * Shown when there are multiple items to remove at the same time.
   */
  removeAll: "Hepsini kaldır",
  /**
   * Shown when all fields are not filled out correctly.
   */
  incomplete: "Maalesef, tüm alanlar doğru doldurulmadı.",
  /**
   * Shown in a button inside a form to submit the form.
   */
  submit: "Gönder",
  /**
   * Shown when no files are selected.
   */
  noFiles: "Dosya yok",
  /**
   * Shown on buttons that move fields up in a list.
   */
  moveUp: "Yukarı Taşı",
  /**
   * Shown on buttons that move fields down in a list.
   */
  moveDown: "Aşağı taşı",
  /**
   * Shown when something is actively loading.
   */
  isLoading: "Yükleniyor...",
  /**
   * Shown when there is more to load.
   */
  loadMore: "Daha fazla yükle",
  /**
   * Shown on buttons that navigate state forward
   */
  next: "Sonraki",
  /**
   * Shown on buttons that navigate state backward
   */
  prev: "Önceki",
  /**
   * Shown when adding all values.
   */
  addAllValues: "Tüm değerleri ekle",
  /**
   * Shown when adding selected values.
   */
  addSelectedValues: "Seçili değerleri ekle",
  /**
   * Shown when removing all values.
   */
  removeAllValues: "Tüm değerleri kaldır",
  /**
   * Shown when removing selected values.
   */
  removeSelectedValues: "Seçili değerleri kaldır",
  /**
   * Shown when there is a date to choose.
   */
  chooseDate: "Tarih seçin",
  /**
   * Shown when there is a date to change.
   */
  changeDate: "Tarihi değiştir",
  /**
   * Shown when there is something to close
   */
  close: "Kapat",
  /**
   * Shown when there is something to open.
   */
  open: "Açık"
};
var validation41 = {
  /**
   * The value is not an accepted value.
   * @see {@link https://formkit.com/essentials/validation#accepted}
   */
  accepted({ name }) {
    return `Lütfen ${name}'yi kabul edin.`;
  },
  /**
   * The date is not after
   * @see {@link https://formkit.com/essentials/validation#date-after}
   */
  date_after({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${sentence(name)} ${date(args[0])}'den sonra olmalıdır.`;
    }
    return `${sentence(name)} gelecekte bir zaman olmalıdır.`;
  },
  /**
   * The value is not a letter.
   * @see {@link https://formkit.com/essentials/validation#alpha}
   */
  alpha({ name }) {
    return `${sentence(name)} sadece alfabetik karakterler içerebilir.`;
  },
  /**
   * The value is not alphanumeric
   * @see {@link https://formkit.com/essentials/validation#alphanumeric}
   */
  alphanumeric({ name }) {
    return `${sentence(name)} sadece alfabetik karakterler ve sayı içerebilir.`;
  },
  /**
   * The value is not letter and/or spaces
   * @see {@link https://formkit.com/essentials/validation#alpha-spaces}
   */
  alpha_spaces({ name }) {
    return `${sentence(name)} yalnızca harf ve boşluk içerebilir.`;
  },
  /**
   * The value have no letter.
   * @see {@link https://formkit.com/essentials/validation#contains_alpha}
   */
  contains_alpha({ name }) {
    return `${sentence(name)} alfabetik karakterler içermelidir.`;
  },
  /**
   * The value have no alphanumeric
   * @see {@link https://formkit.com/essentials/validation#contains_alphanumeric}
   */
  contains_alphanumeric({ name }) {
    return `${sentence(name)} harf veya rakamı içermelidir.`;
  },
  /**
   * The value have no letter and/or spaces
   * @see {@link https://formkit.com/essentials/validation#contains_alpha-spaces}
   */
  contains_alpha_spaces({ name }) {
    return `${sentence(name)} harf veya boşluk içermelidir.`;
  },
  /**
   * The value have no symbol
   * @see {@link https://formkit.com/essentials/validation#contains_symbol}
   */
  contains_symbol({ name }) {
    return `${sentence(name)} sembol içermelidir.`;
  },
  /**
   * The value have no uppercase
   * @see {@link https://formkit.com/essentials/validation#contains_uppercase}
   */
  contains_uppercase({ name }) {
    return `${sentence(name)} büyük harf içermelidir.`;
  },
  /**
   * The value have no lowercase
   * @see {@link https://formkit.com/essentials/validation#contains_lowercase}
   */
  contains_lowercase({ name }) {
    return `${sentence(name)} küçük harf içermelidir.`;
  },
  /**
   *  The value have no numeric
   * @see {@link https://formkit.com/essentials/validation#contains_numeric}
   */
  contains_numeric({ name }) {
    return `${sentence(name)} sayı içermelidir.`;
  },
  /**
   * The value is not symbol
   * @see {@link https://formkit.com/essentials/validation#symbol}
   */
  symbol({ name }) {
    return `${sentence(name)} bir sembol olmalıdır.`;
  },
  /**
   * The value is not uppercase
   * @see {@link https://formkit.com/essentials/validation#uppercase}
   */
  uppercase({ name }) {
    return `${sentence(name)} yalnızca büyük harfler içerebilir.`;
  },
  /**
   * The value is not lowercase
   * @see {@link https://formkit.com/essentials/validation#lowercase}
   */
  lowercase({ name }) {
    return `${sentence(name)} yalnızca küçük harfler içerebilir.`;
  },
  /**
   * The date is not before
   * @see {@link https://formkit.com/essentials/validation#date-before}
   */
  date_before({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${sentence(name)} ${date(args[0])} tarihinden önce olmalı.`;
    }
    return `${sentence(name)} geçmişte olmalı.`;
  },
  /**
   * The value is not between two numbers
   * @see {@link https://formkit.com/essentials/validation#between}
   */
  between({ name, args }) {
    if (isNaN(args[0]) || isNaN(args[1])) {
      return `Alan yanlış yapılandırılmış ve gönderilemez.`;
    }
    const [a, b] = order(args[0], args[1]);
    return `${sentence(name)} ${a} ve ${b} aralığında olmalı.`;
  },
  /**
   * The confirmation field does not match
   * @see {@link https://formkit.com/essentials/validation#confirm}
   */
  confirm({ name }) {
    return `${sentence(name)} eşleşmiyor.`;
  },
  /**
   * The value is not a valid date
   * @see {@link https://formkit.com/essentials/validation#date-format}
   */
  date_format({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${sentence(name)} geçerli bir tarih değil, lütfen ${args[0]} biçimini kullanın.`;
    }
    return "Alan yanlış yapılandırılmış ve gönderilemez.";
  },
  /**
   * Is not within expected date range
   * @see {@link https://formkit.com/essentials/validation#date-between}
   */
  date_between({ name, args }) {
    return `${sentence(name)}, ${date(args[0])} ve ${date(args[1])} aralığında olmalı.`;
  },
  /**
   * Shown when the user-provided value is not a valid email address.
   * @see {@link https://formkit.com/essentials/validation#email}
   */
  email: "Lütfen geçerli bir e-mail adresi girin.",
  /**
   * Does not end with the specified value
   * @see {@link https://formkit.com/essentials/validation#ends-with}
   */
  ends_with({ name, args }) {
    return `${sentence(name)} ${list(args)} ile bitmiyor.`;
  },
  /**
   * Is not an allowed value
   * @see {@link https://formkit.com/essentials/validation#is}
   */
  is({ name }) {
    return `${sentence(name)} izin verilen bir değer değil.`;
  },
  /**
   * Does not match specified length
   * @see {@link https://formkit.com/essentials/validation#length}
   */
  length({ name, args: [first = 0, second = Infinity] }) {
    const min = Number(first) <= Number(second) ? first : second;
    const max = Number(second) >= Number(first) ? second : first;
    if (min == 1 && max === Infinity) {
      return `${sentence(name)} en azından bir karakter uzunluğunda olmalı.`;
    }
    if (min == 0 && max) {
      return `${sentence(name)} ${max}'e eşit veya daha küçük olmalı.`;
    }
    if (min === max) {
      return `${sentence(name)} ${max} karakter uzunluğunda olmalıdır.`;
    }
    if (min && max === Infinity) {
      return `${sentence(name)} ${min}'e eşit veya daha büyük olmalı.`;
    }
    return `${sentence(name)}, ${min} ve ${max} karakter uzunluğu aralığında olmalı.`;
  },
  /**
   * Value is not a match
   * @see {@link https://formkit.com/essentials/validation#matches}
   */
  matches({ name }) {
    return `${sentence(name)} izin verilen bir değer değil.`;
  },
  /**
   * Exceeds maximum allowed value
   * @see {@link https://formkit.com/essentials/validation#max}
   */
  max({ name, node: { value }, args }) {
    if (Array.isArray(value)) {
      return `${name}'in uzunluğu ${args[0]}'dan daha uzun olamaz.`;
    }
    return `${sentence(name)} en azından ${args[0]} uzunluğunda veya ona eşit olmalı.`;
  },
  /**
   * The (field-level) value does not match specified mime type
   * @see {@link https://formkit.com/essentials/validation#mime}
   */
  mime({ name, args }) {
    if (!args[0]) {
      return "Hiçbir dosya türüne izin verilmez.";
    }
    return `${sentence(name)} şu tiplerden biri olmalı: ${args[0]}`;
  },
  /**
   * Does not fulfill minimum allowed value
   * @see {@link https://formkit.com/essentials/validation#min}
   */
  min({ name, node: { value }, args }) {
    if (Array.isArray(value)) {
      return `${name}'in uzunluğu ${args[0]}'dan daha kısa olamaz.`;
    }
    return `${sentence(name)} en azından ${args[0]} uzunluğunda olmalı.`;
  },
  /**
   * Is not an allowed value
   * @see {@link https://formkit.com/essentials/validation#not}
   */
  not({ name, node: { value } }) {
    return `“${value}” ${name} olamaz.`;
  },
  /**
   *  Is not a number
   * @see {@link https://formkit.com/essentials/validation#number}
   */
  number({ name }) {
    return `${sentence(name)} sayı olmalı.`;
  },
  /**
   * Require one field.
   * @see {@link https://formkit.com/essentials/validation#require-one}
   */
  require_one: ({ name, node, args: inputNames }) => {
    const labels = inputNames.map((name2) => {
      const dependentNode = node.at(name2);
      if (dependentNode) {
        return createMessageName(dependentNode);
      }
      return false;
    }).filter((name2) => !!name2);
    labels.unshift(name);
    return `${labels.join(" veya ")} gereklidir.`;
  },
  /**
   * Required field.
   * @see {@link https://formkit.com/essentials/validation#required}
   */
  required({ name }) {
    return `${sentence(name)} gerekli.`;
  },
  /**
   * Does not start with specified value
   * @see {@link https://formkit.com/essentials/validation#starts-with}
   */
  starts_with({ name, args }) {
    return `${sentence(name)} ${list(args)} ile başlamıyor.`;
  },
  /**
   * Is not a url
   * @see {@link https://formkit.com/essentials/validation#url}
   */
  url() {
    return `Lütfen geçerli bir URL girin.`;
  },
  /**
   * Shown when the date is invalid.
   */
  invalidDate: "Seçilen tarih geçersiz."
};
var tr = { ui: ui41, validation: validation41 };
var ui42 = {
  /**
   * Shown on a button for adding additional items.
   */
  add: "Додати",
  /**
   * Shown when a button to remove items is visible.
   */
  remove: "Видалити",
  /**
   * Shown when there are multiple items to remove at the same time.
   */
  removeAll: "Видалити все",
  /**
   * Shown when all fields are not filled out correctly.
   */
  incomplete: "Вибачте, не всі поля заповнені правильно.",
  /**
   * Shown in a button inside a form to submit the form.
   */
  submit: "Відправити",
  /**
   * Shown when no files are selected.
   */
  noFiles: "Файл не вибрано",
  /**
   * Shown on buttons that move fields up in a list.
   */
  moveUp: "Рухатися вгору",
  /**
   * Shown on buttons that move fields down in a list.
   */
  moveDown: "Пересунути вниз",
  /**
   * Shown when something is actively loading.
   */
  isLoading: "Завантаження...",
  /**
   * Shown when there is more to load.
   */
  loadMore: "Завантажте більше",
  /**
   * Shown on buttons that navigate state forward
   */
  next: "Наступний",
  /**
   * Shown on buttons that navigate state backward
   */
  prev: "Попередній",
  /**
   * Shown when adding all values.
   */
  addAllValues: "Додати всі значення",
  /**
   * Shown when adding selected values.
   */
  addSelectedValues: "Додати вибрані значення",
  /**
   * Shown when removing all values.
   */
  removeAllValues: "Вилучити всі значення",
  /**
   * Shown when removing selected values.
   */
  removeSelectedValues: "Вилучити вибрані значення",
  /**
   * Shown when there is a date to choose.
   */
  chooseDate: "Виберіть дату",
  /**
   * Shown when there is a date to change.
   */
  changeDate: "Змінити дату",
  /**
   * Shown when there is something to close
   */
  close: "Закрити",
  /**
   * Shown when there is something to open.
   */
  open: "Відкрити"
};
var validation42 = {
  /**
   * The value is not an accepted value.
   * @see {@link https://formkit.com/essentials/validation#accepted}
   */
  accepted({ name }) {
    return `Будь ласка, прийміть ${name}.`;
  },
  /**
   * The date is not after
   * @see {@link https://formkit.com/essentials/validation#date-after}
   */
  date_after({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `Дата ${sentence(name)} повинна бути пізніше за ${date(args[0])}.`;
    }
    return `Дата ${sentence(name)} має бути в майбутньому.`;
  },
  /**
   * The value is not a letter.
   * @see {@link https://formkit.com/essentials/validation#alpha}
   */
  alpha({ name }) {
    return `Поле ${sentence(name)} може містити лише літери.`;
  },
  /**
   * The value is not alphanumeric
   * @see {@link https://formkit.com/essentials/validation#alphanumeric}
   */
  alphanumeric({ name }) {
    return `Поле ${sentence(name)} може містити лише літери та цифри.`;
  },
  /**
   * The value is not letter and/or spaces
   * @see {@link https://formkit.com/essentials/validation#alpha-spaces}
   */
  alpha_spaces({ name }) {
    return `Поле ${sentence(name)} може містити лише літери та пробіли.`;
  },
  /**
   * The value have no letter.
   * @see {@link https://formkit.com/essentials/validation#contains_alpha}
   */
  contains_alpha({ name }) {
    return `${sentence(name)} повинен містити алфавітні символи.`;
  },
  /**
   * The value have no alphanumeric
   * @see {@link https://formkit.com/essentials/validation#contains_alphanumeric}
   */
  contains_alphanumeric({ name }) {
    return `${sentence(name)} повинен містити букви або цифри.`;
  },
  /**
   * The value have no letter and/or spaces
   * @see {@link https://formkit.com/essentials/validation#contains_alpha-spaces}
   */
  contains_alpha_spaces({ name }) {
    return `${sentence(name)} повинен містити літери або пробіли.`;
  },
  /**
   * The value have no symbol
   * @see {@link https://formkit.com/essentials/validation#contains_symbol}
   */
  contains_symbol({ name }) {
    return `${sentence(name)} повинен містити символ.`;
  },
  /**
   * The value have no uppercase
   * @see {@link https://formkit.com/essentials/validation#contains_uppercase}
   */
  contains_uppercase({ name }) {
    return `${sentence(name)} повинен містити великі регістри.`;
  },
  /**
   * The value have no lowercase
   * @see {@link https://formkit.com/essentials/validation#contains_lowercase}
   */
  contains_lowercase({ name }) {
    return `${sentence(name)} повинен містити малі регістри.`;
  },
  /**
   *  The value have no numeric
   * @see {@link https://formkit.com/essentials/validation#contains_numeric}
   */
  contains_numeric({ name }) {
    return `${sentence(name)} повинен містити цифри.`;
  },
  /**
   * The value is not symbol
   * @see {@link https://formkit.com/essentials/validation#symbol}
   */
  symbol({ name }) {
    return `${sentence(name)} має бути символом.`;
  },
  /**
   * The value is not uppercase
   * @see {@link https://formkit.com/essentials/validation#uppercase}
   */
  uppercase({ name }) {
    return `${sentence(name)} може містити лише великі літери.`;
  },
  /**
   * The value is not lowercase
   * @see {@link https://formkit.com/essentials/validation#lowercase}
   */
  lowercase({ name }) {
    return `${sentence(name)} може містити лише малі літери.`;
  },
  /**
   * The date is not before
   * @see {@link https://formkit.com/essentials/validation#date-before}
   */
  date_before({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `Дата ${sentence(name)} повинна бути раніше за ${date(args[0])}.`;
    }
    return `Дата ${sentence(name)} повинна бути в минулому.`;
  },
  /**
   * The value is not between two numbers
   * @see {@link https://formkit.com/essentials/validation#between}
   */
  between({ name, args }) {
    if (isNaN(args[0]) || isNaN(args[1])) {
      return `Це поле заповнено неправильно і не може бути надіслано.`;
    }
    const [a, b] = order(args[0], args[1]);
    return `Поле ${sentence(name)} повинно бути між ${a} та ${b}.`;
  },
  /**
   * The confirmation field does not match
   * @see {@link https://formkit.com/essentials/validation#confirm}
   */
  confirm({ name }) {
    return `Поле ${sentence(name)} не збігається.`;
  },
  /**
   * The value is not a valid date
   * @see {@link https://formkit.com/essentials/validation#date-format}
   */
  date_format({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `Поле ${sentence(
        name
      )} має неправильну дату. Будь ласка, використовуйте формат ${args[0]}.`;
    }
    return "Це поле заповнено неправильно і не може бути надіслано.";
  },
  /**
   * Is not within expected date range
   * @see {@link https://formkit.com/essentials/validation#date-between}
   */
  date_between({ name, args }) {
    return `Дата ${sentence(name)} повинна бути між ${date(args[0])} та ${date(
      args[1]
    )}.`;
  },
  /**
   * Shown when the user-provided value is not a valid email address.
   * @see {@link https://formkit.com/essentials/validation#email}
   */
  email: "Будь ласка, введіть дійсну електронну адресу.",
  /**
   * Does not end with the specified value
   * @see {@link https://formkit.com/essentials/validation#ends-with}
   */
  ends_with({ name, args }) {
    return `Поле ${sentence(name)} не повинно закінчуватися на ${list(args)}.`;
  },
  /**
   * Is not an allowed value
   * @see {@link https://formkit.com/essentials/validation#is}
   */
  is({ name }) {
    return `Поле ${sentence(name)} має неприпустиме значення.`;
  },
  /**
   * Does not match specified length
   * @see {@link https://formkit.com/essentials/validation#length}
   */
  length({ name, args: [first = 0, second = Infinity] }) {
    const min = Number(first) <= Number(second) ? first : second;
    const max = Number(second) >= Number(first) ? second : first;
    if (min == 1 && max === Infinity) {
      return `Поле ${sentence(name)} має містити щонайменше один символ.`;
    }
    if (min == 0 && max) {
      return `Довжина поля ${sentence(
        name
      )} повинна бути меншою або дорівнювати ${max} символам.`;
    }
    if (min === max) {
      return `${sentence(name)} має бути довжиною ${max} символів.`;
    }
    if (min && max === Infinity) {
      return `Довжина поля ${sentence(
        name
      )} повинна бути більшою або дорівнювати ${min} символам.`;
    }
    return `Довжина поля ${sentence(
      name
    )} повинна бути між ${min} та ${max} символами.`;
  },
  /**
   * Value is not a match
   * @see {@link https://formkit.com/essentials/validation#matches}
   */
  matches({ name }) {
    return `Поле ${sentence(name)} має неприпустиме значення.`;
  },
  /**
   * Exceeds maximum allowed value
   * @see {@link https://formkit.com/essentials/validation#max}
   */
  max({ name, node: { value }, args }) {
    if (Array.isArray(value)) {
      return `Не може бути вибрано більше ніж ${args[0]} ${name}.`;
    }
    return `Поле ${sentence(name)} має бути менше або дорівнювати ${args[0]}.`;
  },
  /**
   * The (field-level) value does not match specified mime type
   * @see {@link https://formkit.com/essentials/validation#mime}
   */
  mime({ name, args }) {
    if (!args[0]) {
      return "Не вказано дозволені типи файлів.";
    }
    return `Тип файлу в полі ${sentence(name)} має бути: ${args[0]}.`;
  },
  /**
   * Does not fulfill minimum allowed value
   * @see {@link https://formkit.com/essentials/validation#min}
   */
  min({ name, node: { value }, args }) {
    if (Array.isArray(value)) {
      return `Не може бути вибрано менше ніж ${args[0]} ${name}.`;
    }
    return `Поле ${sentence(name)} має бути не менше ніж ${args[0]}.`;
  },
  /**
   * Is not an allowed value
   * @see {@link https://formkit.com/essentials/validation#not}
   */
  not({ name, node: { value } }) {
    return `“${value}” не дозволено в полі ${name}.`;
  },
  /**
   *  Is not a number
   * @see {@link https://formkit.com/essentials/validation#number}
   */
  number({ name }) {
    return `Поле ${sentence(name)} має бути числом.`;
  },
  /**
   * Require one field.
   * @see {@link https://formkit.com/essentials/validation#require-one}
   */
  require_one: ({ name, node, args: inputNames }) => {
    const labels = inputNames.map((name2) => {
      const dependentNode = node.at(name2);
      if (dependentNode) {
        return createMessageName(dependentNode);
      }
      return false;
    }).filter((name2) => !!name2);
    labels.unshift(name);
    return `${labels.join(" або ")} потрібно.`;
  },
  /**
   * Required field.
   * @see {@link https://formkit.com/essentials/validation#required}
   */
  required({ name }) {
    return `Поле ${sentence(name)} є обов'язковим.`;
  },
  /**
   * Does not start with specified value
   * @see {@link https://formkit.com/essentials/validation#starts-with}
   */
  starts_with({ name, args }) {
    return `Поле ${sentence(name)} має починатися з ${list(args)}.`;
  },
  /**
   * Is not a url
   * @see {@link https://formkit.com/essentials/validation#url}
   */
  url() {
    return `Будь ласка, введіть коректну URL-адресу.`;
  },
  /**
   * Shown when the date is invalid.
   */
  invalidDate: "Вибрана дата недійсна."
};
var uk = { ui: ui42, validation: validation42 };
var ui43 = {
  /**
   * Shown on a button for adding additional items.
   */
  add: "Qo'shish",
  /**
   * Shown when a button to remove items is visible.
   */
  remove: "O'chirish",
  /**
   * Shown when there are multiple items to remove at the same time.
   */
  removeAll: "Hammasini o'chirish",
  /**
   * Shown when all fields are not filled out correctly.
   */
  incomplete: "Kechirasiz, barcha maydonlar to'g'ri to'ldirilmagan.",
  /**
   * Shown in a button inside a form to submit the form.
   */
  submit: "Yuborish",
  /**
   * Shown when no files are selected.
   */
  noFiles: "Hech qanday fayl tanlanmagan",
  /**
   * Shown on buttons that move fields up in a list.
   */
  moveUp: "Yuqoriga ko’taring",
  /**
   * Shown on buttons that move fields down in a list.
   */
  moveDown: "Pastga siljish",
  /**
   * Shown when something is actively loading.
   */
  isLoading: "Yuklanmoqda...",
  /**
   * Shown when there is more to load.
   */
  loadMore: "Ko’proq yuklang",
  /**
   * Shown on buttons that navigate state forward
   */
  next: "Keyingi",
  /**
   * Shown on buttons that navigate state backward
   */
  prev: "Oldingi",
  /**
   * Shown when adding all values.
   */
  addAllValues: `Barcha qiymatlarni qo'shish`,
  /**
   * Shown when adding selected values.
   */
  addSelectedValues: `Tanlangan qiymatlarni qoʻshish`,
  /**
   * Shown when removing all values.
   */
  removeAllValues: "Barcha qiymatlarni olib tashlang",
  /**
   * Shown when removing selected values.
   */
  removeSelectedValues: "Tanlangan qiymatlarni olib tashlash",
  /**
   * Shown when there is a date to choose.
   */
  chooseDate: "Sanani tanlang",
  /**
   * Shown when there is a date to change.
   */
  changeDate: `O'zgartirish sanasi`,
  /**
   * Shown when there is something to close
   */
  close: "Yopish",
  /**
   * Shown when there is something to open.
   */
  open: "Ochiq"
};
var validation43 = {
  /**
   * The value is not an accepted value.
   * @see {@link https://formkit.com/essentials/validation#accepted}
   */
  accepted({ name }) {
    return `${name} ni qabul qiling.`;
  },
  /**
   * The date is not after
   * @see {@link https://formkit.com/essentials/validation#date-after}
   */
  date_after({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${sentence(name)} ${date(args[0])} dan keyin bo'lishi kerak.`;
    }
    return `${sentence(name)} kelajakda bo'lishi kerak.`;
  },
  /**
   * The value is not a letter.
   * @see {@link https://formkit.com/essentials/validation#alpha}
   */
  alpha({ name }) {
    return `${sentence(
      name
    )} faqat alifbo tartibidagi belgilardan iborat bo'lishi mumkin.`;
  },
  /**
   * The value is not alphanumeric
   * @see {@link https://formkit.com/essentials/validation#alphanumeric}
   */
  alphanumeric({ name }) {
    return `${sentence(name)} faqat harflar va raqamlardan iborat bo'lishi mumkin.`;
  },
  /**
   * The value is not letter and/or spaces
   * @see {@link https://formkit.com/essentials/validation#alpha-spaces}
   */
  alpha_spaces({ name }) {
    return `${sentence(name)} faqat harf va bo'shliqlardan iborat bo'lishi mumkin.`;
  },
  /**
   * The value have no letter.
   * @see {@link https://formkit.com/essentials/validation#contains_alpha}
   */
  contains_alpha({ name }) {
    return `${sentence(name)} alfavit belgilarini o'z ichiga olishi kerak.`;
  },
  /**
   * The value have no alphanumeric
   * @see {@link https://formkit.com/essentials/validation#contains_alphanumeric}
   */
  contains_alphanumeric({ name }) {
    return `${sentence(name)} harflar yoki raqamlarni o'z ichiga olishi kerak.`;
  },
  /**
   * The value have no letter and/or spaces
   * @see {@link https://formkit.com/essentials/validation#contains_alpha-spaces}
   */
  contains_alpha_spaces({ name }) {
    return `${sentence(name)} harflar yoki bo'shliqlar bo'lishi kerak.`;
  },
  /**
   * The value have no symbol
   * @see {@link https://formkit.com/essentials/validation#contains_symbol}
   */
  contains_symbol({ name }) {
    return `${sentence(name)} belgisi bo'lishi kerak.`;
  },
  /**
   * The value have no uppercase
   * @see {@link https://formkit.com/essentials/validation#contains_uppercase}
   */
  contains_uppercase({ name }) {
    return `${sentence(name)} katta harfni o'z ichiga olishi kerak.`;
  },
  /**
   * The value have no lowercase
   * @see {@link https://formkit.com/essentials/validation#contains_lowercase}
   */
  contains_lowercase({ name }) {
    return `${sentence(name)} kichik harflarni o'z ichiga olishi kerak.`;
  },
  /**
   *  The value have no numeric
   * @see {@link https://formkit.com/essentials/validation#contains_numeric}
   */
  contains_numeric({ name }) {
    return `${sentence(name)} raqamlarini o'z ichiga olishi kerak.`;
  },
  /**
   * The value is not symbol
   * @see {@link https://formkit.com/essentials/validation#symbol}
   */
  symbol({ name }) {
    return `${sentence(name)} belgisi bo'lishi kerak.`;
  },
  /**
   * The value is not uppercase
   * @see {@link https://formkit.com/essentials/validation#uppercase}
   */
  uppercase({ name }) {
    return `${sentence(name)} faqat katta harflarni o'z ichiga olishi mumkin.`;
  },
  /**
   * The value is not lowercase
   * @see {@link https://formkit.com/essentials/validation#lowercase}
   */
  lowercase({ name }) {
    return `${sentence(name)} faqat kichik harflarni o'z ichiga olishi mumkin.`;
  },
  /**
   * The date is not before
   * @see {@link https://formkit.com/essentials/validation#date-before}
   */
  date_before({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${sentence(name)} ${date(args[0])} dan oldin bo'lishi kerak`;
    }
    return `${sentence(name)} o'tmishda bo'lishi kerak.`;
  },
  /**
   * The value is not between two numbers
   * @see {@link https://formkit.com/essentials/validation#between}
   */
  between({ name, args }) {
    if (isNaN(args[0]) || isNaN(args[1])) {
      return `Bu maydon noto'g'ri sozlangan va uni yuborib bo'lmaydi.`;
    }
    const [a, b] = order(args[0], args[1]);
    return `${sentence(name)} ${a} va ${b} orasida bo'lishi kerak.`;
  },
  /**
   * The confirmation field does not match
   * @see {@link https://formkit.com/essentials/validation#confirm}
   */
  confirm({ name }) {
    return `${sentence(name)} mos emas.`;
  },
  /**
   * The value is not a valid date
   * @see {@link https://formkit.com/essentials/validation#date-format}
   */
  date_format({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${sentence(name)} haqiqiy sana emas, iltimos ${args[0]} formatidan foydalaning`;
    }
    return "Bu maydon noto'g'ri sozlangan va uni yuborib bo'lmaydi";
  },
  /**
   * Is not within expected date range
   * @see {@link https://formkit.com/essentials/validation#date-between}
   */
  date_between({ name, args }) {
    return `${sentence(name)} ${date(args[0])} va ${date(
      args[1]
    )} oralig'ida bo'lishi kerak`;
  },
  /**
   * Shown when the user-provided value is not a valid email address.
   * @see {@link https://formkit.com/essentials/validation#email}
   */
  email: "Iltimos amaldagi e-mail manzilingizni kiriting.",
  /**
   * Does not end with the specified value
   * @see {@link https://formkit.com/essentials/validation#ends-with}
   */
  ends_with({ name, args }) {
    return `${sentence(name)} ${list(args)} bilan tugamaydi.`;
  },
  /**
   * Is not an allowed value
   * @see {@link https://formkit.com/essentials/validation#is}
   */
  is({ name }) {
    return `${sentence(name)} ruxsat etilgan qiymat emas.`;
  },
  /**
   * Does not match specified length
   * @see {@link https://formkit.com/essentials/validation#length}
   */
  length({ name, args: [first = 0, second = Infinity] }) {
    const min = Number(first) <= Number(second) ? first : second;
    const max = Number(second) >= Number(first) ? second : first;
    if (min == 1 && max === Infinity) {
      return `${sentence(name)} kamida bitta belgidan iborat bo'lishi kerak.`;
    }
    if (min == 0 && max) {
      return `${sentence(name)} ${max} ta belgidan kam yoki teng bo'lishi kerak.`;
    }
    if (min === max) {
      return `${sentence(name)} bo'lishi kerak ${max} belgilar uzun.`;
    }
    if (min && max === Infinity) {
      return `${sentence(name)} ${min} ta belgidan ko'p yoki teng bo'lishi kerak.`;
    }
    return `${sentence(
      name
    )} ${min} va ${max} gacha belgilardan iborat bo'lishi kerak.`;
  },
  /**
   * Value is not a match
   * @see {@link https://formkit.com/essentials/validation#matches}
   */
  matches({ name }) {
    return `${sentence(name)} ruxsat etilgan qiymat emas.`;
  },
  /**
   * Exceeds maximum allowed value
   * @see {@link https://formkit.com/essentials/validation#max}
   */
  max({ name, node: { value }, args }) {
    if (Array.isArray(value)) {
      return `${args[0]} ${name} dan ortiq bo'lishi mumkin emas.`;
    }
    return `${sentence(name)} ${args[0]} dan kichik yoki teng bo'lishi kerak.`;
  },
  /**
   * The (field-level) value does not match specified mime type
   * @see {@link https://formkit.com/essentials/validation#mime}
   */
  mime({ name, args }) {
    if (!args[0]) {
      return "Fayl formatlariga ruxsat berilmagan.";
    }
    return `${sentence(name)} quyidagi turdagi bo'lishi kerak: ${args[0]}`;
  },
  /**
   * Does not fulfill minimum allowed value
   * @see {@link https://formkit.com/essentials/validation#min}
   */
  min({ name, node: { value }, args }) {
    if (Array.isArray(value)) {
      return `${args[0]} ${name} dan kam bo'lmasligi kerak.`;
    }
    return `${sentence(name)} kamida ${args[0]} bo'lishi kerak.`;
  },
  /**
   * Is not an allowed value
   * @see {@link https://formkit.com/essentials/validation#not}
   */
  not({ name, node: { value } }) {
    return `"${value}" ruxsat berilmagan ${name}.`;
  },
  /**
   *  Is not a number
   * @see {@link https://formkit.com/essentials/validation#number}
   */
  number({ name }) {
    return `${sentence(name)} raqam bo'lishi kerak.`;
  },
  /**
   * Require one field.
   * @see {@link https://formkit.com/essentials/validation#require-one}
   */
  require_one: ({ name, node, args: inputNames }) => {
    const labels = inputNames.map((name2) => {
      const dependentNode = node.at(name2);
      if (dependentNode) {
        return createMessageName(dependentNode);
      }
      return false;
    }).filter((name2) => !!name2);
    labels.unshift(name);
    return `${labels.join(" yoki ")} kerak.`;
  },
  /**
   * Required field.
   * @see {@link https://formkit.com/essentials/validation#required}
   */
  required({ name }) {
    return `${sentence(name)} talab qilinadi.`;
  },
  /**
   * Does not start with specified value
   * @see {@link https://formkit.com/essentials/validation#starts-with}
   */
  starts_with({ name, args }) {
    return `${sentence(name)} ${list(args)} bilan boshlanmaydi.`;
  },
  /**
   * Is not a url
   * @see {@link https://formkit.com/essentials/validation#url}
   */
  url() {
    return `Iltimos, tegishli URL manzilini kiriting.`;
  },
  /**
   * Shown when the date is invalid.
   */
  invalidDate: "Tanlangan sana yaroqsiz."
};
var uz = { ui: ui43, validation: validation43 };
var ui44 = {
  /**
   * Shown on buttons for adding new items.
   */
  add: "Thêm",
  /**
   * Shown when a button to remove items is visible.
   */
  remove: "Xoá",
  /**
   * Shown when there are multiple items to remove at the same time.
   */
  removeAll: "Xoá tất cả",
  /**
   * Shown when all fields are not filled out correctly.
   */
  incomplete: "Xin lỗi, không phải tất cả các trường đều được nhập đúng.",
  /**
   * Shown in a button inside a form to submit the form.
   */
  submit: "Gửi",
  /**
   * Shown when no files are selected.
   */
  noFiles: "Chưa chọn file",
  /**
   * Shown on buttons that move fields up in a list.
   */
  moveUp: "Di chuyển lên",
  /**
   * Shown on buttons that move fields down in a list.
   */
  moveDown: "Di chuyển xuống",
  /**
   * Shown when something is actively loading.
   */
  isLoading: "Đang tải...",
  /**
   * Shown when there is more to load.
   */
  loadMore: "Tải thêm",
  /**
   * Shown on buttons that navigate state forward
   */
  next: "Tiếp",
  /**
   * Shown on buttons that navigate state backward
   */
  prev: "Trước",
  /**
   * Shown when adding all values.
   */
  addAllValues: "Thêm tất cả các giá trị",
  /**
   * Shown when adding selected values.
   */
  addSelectedValues: "Thêm các giá trị đã chọn",
  /**
   * Shown when removing all values.
   */
  removeAllValues: "Loại bỏ tất cả các giá trị",
  /**
   * Shown when removing selected values.
   */
  removeSelectedValues: "Loại bỏ các giá trị đã chọn",
  /**
   * Shown when there is a date to choose.
   */
  chooseDate: "Chọn ngày",
  /**
   * Shown when there is a date to change.
   */
  changeDate: "Thay đổi ngày",
  /**
   * Shown when there is something to close
   */
  close: "Đóng",
  /**
   * Shown when there is something to open.
   */
  open: "Mở"
};
var validation44 = {
  /**
   * The value is not an accepted value.
   * @see {@link https://formkit.com/essentials/validation#accepted}
   */
  accepted({ name }) {
    return `Hãy đồng ý với ${name}.`;
  },
  /**
   * The date is not after
   * @see {@link https://formkit.com/essentials/validation#date-after}
   */
  date_after({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${sentence(name)} phải sau ${date(args[0])}.`;
    }
    return `${sentence(name)} phải trong tương lai.`;
  },
  /**
   * The value is not a letter.
   * @see {@link https://formkit.com/essentials/validation#alpha}
   */
  alpha({ name }) {
    return `${sentence(name)} có thể chỉ bao gồm các chữ cái alphabet.`;
  },
  /**
   * The value is not alphanumeric
   * @see {@link https://formkit.com/essentials/validation#alphanumeric}
   */
  alphanumeric({ name }) {
    return `${sentence(name)} có thể chỉ bao gồm các chữ cái và chữ số.`;
  },
  /**
   * The value is not letter and/or spaces
   * @see {@link https://formkit.com/essentials/validation#alpha-spaces}
   */
  alpha_spaces({ name }) {
    return `${sentence(name)} chỉ có thể chứa các chữ cái và khoảng trắng.`;
  },
  /**
   * The value have no letter.
   * @see {@link https://formkit.com/essentials/validation#contains_alpha}
   */
  contains_alpha({ name }) {
    return `${sentence(name)} phải chứa các ký tự chữ cái.`;
  },
  /**
   * The value have no alphanumeric
   * @see {@link https://formkit.com/essentials/validation#contains_alphanumeric}
   */
  contains_alphanumeric({ name }) {
    return `${sentence(name)} phải chứa chữ cái hoặc số.`;
  },
  /**
   * The value have no letter and/or spaces
   * @see {@link https://formkit.com/essentials/validation#contains_alpha-spaces}
   */
  contains_alpha_spaces({ name }) {
    return `${sentence(name)} phải chứa chữ cái hoặc dấu cách.`;
  },
  /**
   * The value have no symbol
   * @see {@link https://formkit.com/essentials/validation#contains_symbol}
   */
  contains_symbol({ name }) {
    return `${sentence(name)} phải chứa ký hiệu.`;
  },
  /**
   * The value have no uppercase
   * @see {@link https://formkit.com/essentials/validation#contains_uppercase}
   */
  contains_uppercase({ name }) {
    return `${sentence(name)} phải chứa chữ hoa.`;
  },
  /**
   * The value have no lowercase
   * @see {@link https://formkit.com/essentials/validation#contains_lowercase}
   */
  contains_lowercase({ name }) {
    return `${sentence(name)} phải chứa chữ thường.`;
  },
  /**
   *  The value have no numeric
   * @see {@link https://formkit.com/essentials/validation#contains_numeric}
   */
  contains_numeric({ name }) {
    return `${sentence(name)} phải chứa số.`;
  },
  /**
   * The value is not symbol
   * @see {@link https://formkit.com/essentials/validation#symbol}
   */
  symbol({ name }) {
    return `${sentence(name)} phải là một ký hiệu.`;
  },
  /**
   * The value is not uppercase
   * @see {@link https://formkit.com/essentials/validation#uppercase}
   */
  uppercase({ name }) {
    return `${sentence(name)} chỉ có thể chứa chữ hoa.`;
  },
  /**
   * The value is not lowercase
   * @see {@link https://formkit.com/essentials/validation#lowercase}
   */
  lowercase({ name }) {
    return `${sentence(name)} chỉ có thể chứa chữ thường.`;
  },
  /**
   * The date is not before
   * @see {@link https://formkit.com/essentials/validation#date-before}
   */
  date_before({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${sentence(name)} phải trước ${date(args[0])}.`;
    }
    return `${sentence(name)} phải trong quá khứ.`;
  },
  /**
   * The value is not between two numbers
   * @see {@link https://formkit.com/essentials/validation#between}
   */
  between({ name, args }) {
    if (isNaN(args[0]) || isNaN(args[1])) {
      return `Trường này đã được thiết lập sai và không thể gửi.`;
    }
    const [a, b] = order(args[0], args[1]);
    return `${sentence(name)} phải ở giữa ${a} và ${b}.`;
  },
  /**
   * The confirmation field does not match
   * @see {@link https://formkit.com/essentials/validation#confirm}
   */
  confirm({ name }) {
    return `${sentence(name)} không khớp.`;
  },
  /**
   * The value is not a valid date
   * @see {@link https://formkit.com/essentials/validation#date-format}
   */
  date_format({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${sentence(name)} không phải ngày hợp lệ, hãy sử dụng định dạng ${args[0]}`;
    }
    return "Trường này đã được thiết lập sai và không thể gửi.";
  },
  /**
   * Is not within expected date range
   * @see {@link https://formkit.com/essentials/validation#date-between}
   */
  date_between({ name, args }) {
    return `${sentence(name)} phải ở giữa khoảng từ ${date(args[0])} đến ${date(
      args[1]
    )}.`;
  },
  /**
   * Shown when the user-provided value is not a valid email address.
   * @see {@link https://formkit.com/essentials/validation#email}
   */
  email: "Hãy nhập một địa chỉ email hợp lệ.",
  /**
   * Does not end with the specified value
   * @see {@link https://formkit.com/essentials/validation#ends-with}
   */
  ends_with({ name, args }) {
    return `${sentence(name)} không kết thúc với ${list(args)}.`;
  },
  /**
   * Is not an allowed value
   * @see {@link https://formkit.com/essentials/validation#is}
   */
  is({ name }) {
    return `${sentence(name)} không phải một giá trị được cho phép.`;
  },
  /**
   * Does not match specified length
   * @see {@link https://formkit.com/essentials/validation#length}
   */
  length({ name, args: [first = 0, second = Infinity] }) {
    const min = Number(first) <= Number(second) ? first : second;
    const max = Number(second) >= Number(first) ? second : first;
    if (min == 1 && max === Infinity) {
      return `${sentence(name)} phải có độ dài tối thiểu một ký tự.`;
    }
    if (min == 0 && max) {
      return `${sentence(name)} phải có độ dài tối đa ${max} ký tự.`;
    }
    if (min === max) {
      return `${sentence(name)} nên dài ${max} ký tự.`;
    }
    if (min && max === Infinity) {
      return `${sentence(name)} phải có độ dài tối thiểu ${min} ký tự.`;
    }
    return `${sentence(
      name
    )} phải có độ dài tối đa trong khoảng từ ${min} đến ${max} ký tự.`;
  },
  /**
   * Value is not a match
   * @see {@link https://formkit.com/essentials/validation#matches}
   */
  matches({ name }) {
    return `${sentence(name)} không phải một giá trị được cho phép.`;
  },
  /**
   * Exceeds maximum allowed value
   * @see {@link https://formkit.com/essentials/validation#max}
   */
  max({ name, node: { value }, args }) {
    if (Array.isArray(value)) {
      return `${name} không thể lớn hơn ${args[0]}.`;
    }
    return `${sentence(name)} phải tối đa bằng ${args[0]}.`;
  },
  /**
   * The (field-level) value does not match specified mime type
   * @see {@link https://formkit.com/essentials/validation#mime}
   */
  mime({ name, args }) {
    if (!args[0]) {
      return "Định dạng tệp tin này không được phép.";
    }
    return `${sentence(name)} phải là một trong các dạng: ${args[0]}`;
  },
  /**
   * Does not fulfill minimum allowed value
   * @see {@link https://formkit.com/essentials/validation#min}
   */
  min({ name, node: { value }, args }) {
    if (Array.isArray(value)) {
      return `${name} không thể nhỏ hơn ${args[0]}.`;
    }
    return `${sentence(name)} phải tối thiểu bằng ${args[0]}.`;
  },
  /**
   * Is not an allowed value
   * @see {@link https://formkit.com/essentials/validation#not}
   */
  not({ name, node: { value } }) {
    return `"${value}" không phải giá trị ${name} được phép.`;
  },
  /**
   *  Is not a number
   * @see {@link https://formkit.com/essentials/validation#number}
   */
  number({ name }) {
    return `${sentence(name)} phải là một số.`;
  },
  /**
   * Require one field.
   * @see {@link https://formkit.com/essentials/validation#require-one}
   */
  require_one: ({ name, node, args: inputNames }) => {
    const labels = inputNames.map((name2) => {
      const dependentNode = node.at(name2);
      if (dependentNode) {
        return createMessageName(dependentNode);
      }
      return false;
    }).filter((name2) => !!name2);
    labels.unshift(name);
    return `${labels.join(" hoặc ")} cần có.`;
  },
  /**
   * Required field.
   * @see {@link https://formkit.com/essentials/validation#required}
   */
  required({ name }) {
    return `${sentence(name)} là bắt buộc.`;
  },
  /**
   * Does not start with specified value
   * @see {@link https://formkit.com/essentials/validation#starts-with}
   */
  starts_with({ name, args }) {
    return `${sentence(name)} không bắt đầu với ${list(args)}.`;
  },
  /**
   * Is not a url
   * @see {@link https://formkit.com/essentials/validation#url}
   */
  url() {
    return `Vui lòng nhập một URL hợp lệ.`;
  },
  /**
   * Shown when the date is invalid.
   */
  invalidDate: "Ngày đã chọn không hợp lệ."
};
var vi = { ui: ui44, validation: validation44 };
var ui45 = {
  /**
   * Shown on a button for adding additional items.
   */
  add: "添加",
  /**
   * Shown when a button to remove items is visible.
   */
  remove: "移除",
  /**
   * Shown when there are multiple items to remove at the same time.
   */
  removeAll: "移除全部",
  /**
   * Shown when all fields are not filled out correctly.
   */
  incomplete: "抱歉，部分字段未被正确填写。",
  /**
   * Shown in a button inside a form to submit the form.
   */
  submit: "提交",
  /**
   * Shown when no files are selected.
   */
  noFiles: "未选择文件",
  /**
   * Shown on buttons that move fields up in a list.
   */
  moveUp: "上移",
  /**
   * Shown on buttons that move fields down in a list.
   */
  moveDown: "下移",
  /**
   * Shown when something is actively loading.
   */
  isLoading: "加载中...",
  /**
   * Shown when there is more to load.
   */
  loadMore: "加载更多",
  /**
   * Shown on buttons that navigate state forward
   */
  next: "下一步",
  /**
   * Shown on buttons that navigate state backward
   */
  prev: "上一步",
  /**
   * Shown when adding all values.
   */
  addAllValues: "添加所有值",
  /**
   * Shown when adding selected values.
   */
  addSelectedValues: "添加所选值",
  /**
   * Shown when removing all values.
   */
  removeAllValues: "移除所有值",
  /**
   * Shown when removing selected values.
   */
  removeSelectedValues: "移除所选值",
  /**
   * Shown when there is a date to choose.
   */
  chooseDate: "选择日期",
  /**
   * Shown when there is a date to change.
   */
  changeDate: "更改日期",
  /**
   * Shown when there is something to close
   */
  close: "关闭",
  /**
   * Shown when there is something to open.
   */
  open: "打开"
};
var validation45 = {
  /**
   * The value is not an accepted value.
   * @see {@link https://formkit.com/essentials/validation#accepted}
   */
  accepted({ name }) {
    return `请接受${name}。`;
  },
  /**
   * The date is not after
   * @see {@link https://formkit.com/essentials/validation#date-after}
   */
  date_after({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${sentence(name)}必须晚于${date(args[0])}。`;
    }
    return `${sentence(name)}必须是未来的日期。`;
  },
  /**
   * The value is not a letter.
   * @see {@link https://formkit.com/essentials/validation#alpha}
   */
  alpha({ name }) {
    return `${sentence(name)}只能包含英文字母。`;
  },
  /**
   * The value is not alphanumeric
   * @see {@link https://formkit.com/essentials/validation#alphanumeric}
   */
  alphanumeric({ name }) {
    return `${sentence(name)}只能包含字母和数字。`;
  },
  /**
   * The value is not letter and/or spaces
   * @see {@link https://formkit.com/essentials/validation#alpha-spaces}
   */
  alpha_spaces({ name }) {
    return `${sentence(name)}只能包含字母和空格。`;
  },
  /**
   * The value have no letter.
   * @see {@link https://formkit.com/essentials/validation#contains_alpha}
   */
  contains_alpha({ name }) {
    return `${sentence(name)} 必须包含字母字符`;
  },
  /**
   * The value have no alphanumeric
   * @see {@link https://formkit.com/essentials/validation#contains_alphanumeric}
   */
  contains_alphanumeric({ name }) {
    return `${sentence(name)} 必须包含字母或数字。`;
  },
  /**
   * The value have no letter and/or spaces
   * @see {@link https://formkit.com/essentials/validation#contains_alpha-spaces}
   */
  contains_alpha_spaces({ name }) {
    return `${sentence(name)} 必须包含字母或空格。`;
  },
  /**
   * The value have no symbol
   * @see {@link https://formkit.com/essentials/validation#contains_symbol}
   */
  contains_symbol({ name }) {
    return `${sentence(name)} 必须包含符号。`;
  },
  /**
   * The value have no uppercase
   * @see {@link https://formkit.com/essentials/validation#contains_uppercase}
   */
  contains_uppercase({ name }) {
    return `${sentence(name)} 必须包含大写字母。`;
  },
  /**
   * The value have no lowercase
   * @see {@link https://formkit.com/essentials/validation#contains_lowercase}
   */
  contains_lowercase({ name }) {
    return `${sentence(name)} 必须包含小写字母。`;
  },
  /**
   *  The value have no numeric
   * @see {@link https://formkit.com/essentials/validation#contains_numeric}
   */
  contains_numeric({ name }) {
    return `${sentence(name)} 必须包含数字。`;
  },
  /**
   * The value is not symbol
   * @see {@link https://formkit.com/essentials/validation#symbol}
   */
  symbol({ name }) {
    return `${sentence(name)} 必须是符号。`;
  },
  /**
   * The value is not uppercase
   * @see {@link https://formkit.com/essentials/validation#uppercase}
   */
  uppercase({ name }) {
    return `${sentence(name)} 只能包含大写字母。`;
  },
  /**
   * The value is not lowercase
   * @see {@link https://formkit.com/essentials/validation#lowercase}
   */
  lowercase({ name }) {
    return `${sentence(name)} 只能包含小写字母。`;
  },
  /**
   * The date is not before
   * @see {@link https://formkit.com/essentials/validation#date-before}
   */
  date_before({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${sentence(name)}必须早于${date(args[0])}。`;
    }
    return `${sentence(name)}必须是过去的日期。`;
  },
  /**
   * The value is not between two numbers
   * @see {@link https://formkit.com/essentials/validation#between}
   */
  between({ name, args }) {
    if (isNaN(args[0]) || isNaN(args[1])) {
      return `该字段未被正确设置而无法提交。`;
    }
    const [a, b] = order(args[0], args[1]);
    return `${sentence(name)}必须在${a}和${b}之间。`;
  },
  /**
   * The confirmation field does not match
   * @see {@link https://formkit.com/essentials/validation#confirm}
   */
  confirm({ name }) {
    return `${sentence(name)}不匹配。`;
  },
  /**
   * The value is not a valid date
   * @see {@link https://formkit.com/essentials/validation#date-format}
   */
  date_format({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${sentence(name)}不是合法日期，请使用 ${args[0]} 格式`;
    }
    return "该字段未被正确设置而无法提交";
  },
  /**
   * Is not within expected date range
   * @see {@link https://formkit.com/essentials/validation#date-between}
   */
  date_between({ name, args }) {
    return `${sentence(name)}必须在${date(args[0])}和${date(args[1])}之间`;
  },
  /**
   * Shown when the user-provided value is not a valid email address.
   * @see {@link https://formkit.com/essentials/validation#email}
   */
  email: "请输入合法的电子邮件地址。",
  /**
   * Does not end with the specified value
   * @see {@link https://formkit.com/essentials/validation#ends-with}
   */
  ends_with({ name, args }) {
    return `${sentence(name)}必须以${list(args)}结尾。`;
  },
  /**
   * Is not an allowed value
   * @see {@link https://formkit.com/essentials/validation#is}
   */
  is({ name }) {
    return `${sentence(name)}是不允许的。`;
  },
  /**
   * Does not match specified length
   * @see {@link https://formkit.com/essentials/validation#length}
   */
  length({ name, args: [first = 0, second = Infinity] }) {
    const min = Number(first) <= Number(second) ? first : second;
    const max = Number(second) >= Number(first) ? second : first;
    if (min == 1 && max === Infinity) {
      return `${sentence(name)}至少要有一个字符。`;
    }
    if (min == 0 && max) {
      return `${sentence(name)}必须少于或等于${max}个字符。`;
    }
    if (min === max) {
      return `${sentence(name)}必须包含${max}个字符。`;
    }
    if (min && max === Infinity) {
      return `${sentence(name)}必须多于或等于${min}个字符。`;
    }
    return `${sentence(name)}必须介于${min}和${max}个字符之间。`;
  },
  /**
   * Value is not a match
   * @see {@link https://formkit.com/essentials/validation#matches}
   */
  matches({ name }) {
    return `${sentence(name)}是不允许的。`;
  },
  /**
   * Exceeds maximum allowed value
   * @see {@link https://formkit.com/essentials/validation#max}
   */
  max({ name, node: { value }, args }) {
    if (Array.isArray(value)) {
      return `${name}不得多于${args[0]}个值。`;
    }
    return `${name}不得大于${args[0]}。`;
  },
  /**
   * The (field-level) value does not match specified mime type
   * @see {@link https://formkit.com/essentials/validation#mime}
   */
  mime({ name, args }) {
    if (!args[0]) {
      return "没有允许的文件格式。";
    }
    return `${sentence(name)}的类型必须为：${args[0]}`;
  },
  /**
   * Does not fulfill minimum allowed value
   * @see {@link https://formkit.com/essentials/validation#min}
   */
  min({ name, node: { value }, args }) {
    if (Array.isArray(value)) {
      return `${name}不得少于${args[0]}个值。`;
    }
    return `${sentence(name)}不得小于${args[0]}。`;
  },
  /**
   * Is not an allowed value
   * @see {@link https://formkit.com/essentials/validation#not}
   */
  not({ name, node: { value } }) {
    return `"${value}"不是一个合法的${name}。`;
  },
  /**
   *  Is not a number
   * @see {@link https://formkit.com/essentials/validation#number}
   */
  number({ name }) {
    return `${sentence(name)}必须为数字。`;
  },
  /**
   * Require one field.
   * @see {@link https://formkit.com/essentials/validation#require-one}
   */
  require_one: ({ name, node, args: inputNames }) => {
    const labels = inputNames.map((name2) => {
      const dependentNode = node.at(name2);
      if (dependentNode) {
        return createMessageName(dependentNode);
      }
      return false;
    }).filter((name2) => !!name2);
    labels.unshift(name);
    return `${labels.join("或")}${labels}需要。`;
  },
  /**
   * Required field.
   * @see {@link https://formkit.com/essentials/validation#required}
   */
  required({ name }) {
    return `${sentence(name)}不得留空。`;
  },
  /**
   * Does not start with specified value
   * @see {@link https://formkit.com/essentials/validation#starts-with}
   */
  starts_with({ name, args }) {
    return `${sentence(name)}必须以${list(args)}开头。`;
  },
  /**
   * Is not a url
   * @see {@link https://formkit.com/essentials/validation#url}
   */
  url() {
    return `请输入有效的 URL。`;
  },
  /**
   * Shown when the date is invalid.
   */
  invalidDate: "所选日期无效。"
};
var zh = { ui: ui45, validation: validation45 };
var ui46 = {
  /**
   * Shown on a button for adding additional items.
   */
  add: "新增",
  /**
   * Shown when a button to remove items is visible.
   */
  remove: "移除",
  /**
   * Shown when there are multiple items to remove at the same time.
   */
  removeAll: "移除全部",
  /**
   * Shown when all fields are not filled out correctly.
   */
  incomplete: "很抱歉，部分欄位填寫錯誤",
  /**
   * Shown in a button inside a form to submit the form.
   */
  submit: "提交",
  /**
   * Shown when no files are selected.
   */
  noFiles: "尚未選取檔案",
  /**
   * Shown on buttons that move fields up in a list.
   */
  moveUp: "上移",
  /**
   * Shown on buttons that move fields down in a list.
   */
  moveDown: "下移",
  /**
   * Shown when something is actively loading.
   */
  isLoading: "載入中...",
  /**
   * Shown when there is more to load.
   */
  loadMore: "載入更多",
  /**
   * Show on buttons that navigate state forward
   */
  next: "下一個",
  /**
   * Show on buttons that navigate state backward
   */
  prev: "上一個",
  /**
   * Shown when adding all values.
   */
  addAllValues: "加入全部的值",
  /**
   * Shown when adding selected values.
   */
  addSelectedValues: "加入選取的值",
  /**
   * Shown when removing all values.
   */
  removeAllValues: "移除全部的值",
  /**
   * Shown when removing selected values.
   */
  removeSelectedValues: "移除選取的值",
  /**
   * Shown when there is a date to choose.
   */
  chooseDate: "選擇日期",
  /**
   * Shown when there is a date to change.
   */
  changeDate: "變更日期",
  /**
   * Shown when there is something to close
   */
  close: "關閉",
  /**
   * Shown when there is something to open.
   */
  open: "開放"
};
var validation46 = {
  /**
   * The value is not an accepted value.
   * @see {@link https://formkit.com/essentials/validation#accepted}
   */
  accepted({ name }) {
    return `請接受 ${name}`;
  },
  /**
   * The date is not after
   * @see {@link https://formkit.com/essentials/validation#date-after}
   */
  date_after({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${sentence(name)} 必須晚於 ${date(args[0])}`;
    }
    return `${sentence(name)} 必須晚於今日`;
  },
  /**
   * The value is not a letter.
   * @see {@link https://formkit.com/essentials/validation#alpha}
   */
  alpha({ name }) {
    return `${sentence(name)} 欄位儘能填寫英文字母`;
  },
  /**
   * The value is not alphanumeric
   * @see {@link https://formkit.com/essentials/validation#alphanumeric}
   */
  alphanumeric({ name }) {
    return `${sentence(name)} 欄位僅能填寫英文字母與數字`;
  },
  /**
   * The value is not letter and/or spaces
   * @see {@link https://formkit.com/essentials/validation#alpha-spaces}
   */
  alpha_spaces({ name }) {
    return `${sentence(name)} 欄位儘能填寫英文字母與空白`;
  },
  /**
   * The date is not before
   * @see {@link https://formkit.com/essentials/validation#date-before}
   */
  date_before({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${sentence(name)} 必須早於 ${date(args[0])}.`;
    }
    return `${sentence(name)} 必須早於今日`;
  },
  /**
   * The value is not between two numbers
   * @see {@link https://formkit.com/essentials/validation#between}
   */
  between({ name, args }) {
    if (isNaN(args[0]) || isNaN(args[1])) {
      return `欄位值錯誤，無法提交`;
    }
    const [a, b] = order(args[0], args[1]);
    return `${sentence(name)} 必須介於 ${a} 和 ${b}.`;
  },
  /**
   * The confirmation field does not match
   * @see {@link https://formkit.com/essentials/validation#confirm}
   */
  confirm({ name }) {
    return `${sentence(name)} 與目標不一致`;
  },
  /**
   * The value is not a valid date
   * @see {@link https://formkit.com/essentials/validation#date-format}
   */
  date_format({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${sentence(name)} 不是有效的日期，請使用 ${args[0]} 格式`;
    }
    return "欄位值錯誤，無法提交";
  },
  /**
   * Is not within expected date range
   * @see {@link https://formkit.com/essentials/validation#date-between}
   */
  date_between({ name, args }) {
    return `${sentence(name)} 必須介於 ${date(args[0])} 和 ${date(args[1])}`;
  },
  /**
   * Shown when the user-provided value is not a valid email address.
   * @see {@link https://formkit.com/essentials/validation#email}
   */
  email: "請輸入有效的 email",
  /**
   * Does not end with the specified value
   * @see {@link https://formkit.com/essentials/validation#ends-with}
   */
  ends_with({ name, args }) {
    return `${sentence(name)} 的結尾必須是 ${list(args)}`;
  },
  /**
   * Is not an allowed value
   * @see {@link https://formkit.com/essentials/validation#is}
   */
  is({ name }) {
    return `${sentence(name)} 欄位的值不合規則`;
  },
  /**
   * Does not match specified length
   * @see {@link https://formkit.com/essentials/validation#length}
   */
  length({ name, args: [first = 0, second = Infinity] }) {
    const min = Number(first) <= Number(second) ? first : second;
    const max = Number(second) >= Number(first) ? second : first;
    if (min == 1 && max === Infinity) {
      return `${sentence(name)} 欄位必須至少包含一個字`;
    }
    if (min == 0 && max) {
      return `${sentence(name)} 的字數必須小於等於 ${max}`;
    }
    if (min === max) {
      return `${sentence(name)} 的字數必須為 ${max}`;
    }
    if (min && max === Infinity) {
      return `${sentence(name)} 的字數必須大於等於 ${min}`;
    }
    return `${sentence(name)} 的字數必須介於 ${min} 和 ${max}`;
  },
  /**
   * Value is not a match
   * @see {@link https://formkit.com/essentials/validation#matches}
   */
  matches({ name }) {
    return `${sentence(name)} 欄位的值無效`;
  },
  /**
   * Exceeds maximum allowed value
   * @see {@link https://formkit.com/essentials/validation#max}
   */
  max({ name, node: { value }, args }) {
    if (Array.isArray(value)) {
      return `不能超過 ${args[0]} 個 ${name}.`;
    }
    return `${sentence(name)} 必須小於等於 ${args[0]}.`;
  },
  /**
   * The (field-level) value does not match specified mime type
   * @see {@link https://formkit.com/essentials/validation#mime}
   */
  mime({ name, args }) {
    if (!args[0]) {
      return "非有效的檔案格式";
    }
    return `${sentence(name)} 可接受的檔案格式為: ${args[0]}`;
  },
  /**
   * Does not fulfill minimum allowed value
   * @see {@link https://formkit.com/essentials/validation#min}
   */
  min({ name, node: { value }, args }) {
    if (Array.isArray(value)) {
      return `不可少於 ${args[0]} 個 ${name}`;
    }
    return `${name} 必須大於等於 ${args[0]}`;
  },
  /**
   * Is not an allowed value
   * @see {@link https://formkit.com/essentials/validation#not}
   */
  not({ name, node: { value } }) {
    return `“${value}” 不是 ${name} 欄位可接受的值`;
  },
  /**
   *  Is not a number
   * @see {@link https://formkit.com/essentials/validation#number}
   */
  number({ name }) {
    return `${sentence(name)} 欄位必須是數字`;
  },
  /**
   * Require one field.
   * @see {@link https://formkit.com/essentials/validation#require-one}
   */
  require_one: ({ name, node, args: inputNames }) => {
    const labels = inputNames.map((name2) => {
      const dependentNode = node.at(name2);
      if (dependentNode) {
        return createMessageName(dependentNode);
      }
      return false;
    }).filter((name2) => !!name2);
    labels.unshift(name);
    return `${labels.join("或")}${labels}需要。`;
  },
  /**
   * Required field.
   * @see {@link https://formkit.com/essentials/validation#required}
   */
  required({ name }) {
    return `${sentence(name)} 是必要欄位`;
  },
  /**
   * Does not start with specified value
   * @see {@link https://formkit.com/essentials/validation#starts-with}
   */
  starts_with({ name, args }) {
    return `${sentence(name)} 的開頭必須是 ${list(args)}`;
  },
  /**
   * Is not a url
   * @see {@link https://formkit.com/essentials/validation#url}
   */
  url() {
    return `請輸入有效的 url`;
  },
  /**
   * Shown when the date is invalid.
   */
  invalidDate: "選取的日期無效"
};
var zhTW = { ui: ui46, validation: validation46 };
var i18nNodes = /* @__PURE__ */ new Set();
var activeLocale = null;
function createI18nPlugin(registry) {
  return function i18nPlugin(node) {
    i18nNodes.add(node);
    if (activeLocale)
      node.config.locale = activeLocale;
    node.on("destroying", () => i18nNodes.delete(node));
    let localeKey = parseLocale(node.config.locale, registry);
    let locale = localeKey ? registry[localeKey] : {};
    node.on("prop:locale", ({ payload: lang }) => {
      localeKey = parseLocale(lang, registry);
      locale = localeKey ? registry[localeKey] : {};
      node.store.touch();
    });
    node.on("prop:label", () => node.store.touch());
    node.on("prop:validationLabel", () => node.store.touch());
    node.hook.text((fragment, next) => {
      const key = fragment.meta?.messageKey || fragment.key;
      if (has(locale, fragment.type) && has(locale[fragment.type], key)) {
        const t = locale[fragment.type][key];
        if (typeof t === "function") {
          fragment.value = Array.isArray(fragment.meta?.i18nArgs) ? t(...fragment.meta.i18nArgs) : t(fragment);
        } else {
          fragment.value = t;
        }
      }
      return next(fragment);
    });
  };
}
function parseLocale(locale, availableLocales) {
  if (has(availableLocales, locale)) {
    return locale;
  }
  const [lang] = locale.split("-");
  if (has(availableLocales, lang)) {
    return lang;
  }
  for (const locale2 in availableLocales) {
    return locale2;
  }
  return false;
}
function changeLocale(locale) {
  activeLocale = locale;
  for (const node of i18nNodes) {
    node.config.locale = locale;
  }
}

// packages/i18n/src/index.ts
var locales = {
  ar,
  az,
  bg,
  bs,
  ca,
  cs,
  da,
  de,
  el,
  en,
  es,
  fa,
  fi,
  fr,
  fy,
  he,
  hr,
  hu,
  id,
  it,
  ja,
  kk,
  ko,
  lt,
  lv,
  nb,
  nl,
  pl,
  pt,
  ro,
  ru,
  sk,
  sl,
  sr,
  sv,
  tet,
  tg,
  th,
  tr,
  uk,
  uz,
  vi,
  zh,
  "zh-TW": zhTW,
  is,
  mn
};

export { ar, az, bg, bs, ca, changeLocale, createI18nPlugin, cs, da, date, de, el, en, es, fa, fi, fr, fy, he, hr, hu, id, is, it, ja, kk, ko, list, locales, lt, lv, mn, nb, nl, order, pl, pt, ro, ru, sentence, sk, sl, sr, sv, tet, tg, th, tr, uk, uz, vi, zh, zhTW };
//# sourceMappingURL=out.js.map
//# sourceMappingURL=index.mjs.map