import * as _formkit_validation from '@formkit/validation';
import { FormKitValidationMessages } from '@formkit/validation';
import { FormKitPlugin } from '@formkit/core';

/**
 * Note: We are choosing not to implement via Intl.Locale because the support is
 * not yet good enough to be used without polyfill consideration, and that
 * polyfill is 36.3Kb min + gzip — larger than all of FormKit.
 *
 * https://formatjs.io/docs/polyfills/intl-locale/
 *
 * Instead we use a very minimal solution that should provide very good support
 * for all users, and we're happy to expand this package if we see areas where
 * localization is not quite good enough. Also, once support for Intl.Locale
 * becomes better, we would expect this package to switch much of it's
 * underlying locale parsing logic to nose native APIs.
 */
/**
 * A registry of locale messages — this is simply a keyed/value object with
 * string keys (message name) and either string values (for simple returns) or
 * functions that receive a context object.
 *
 * @public
 */
interface FormKitLocaleMessages {
    [index: string]: string | ((...args: any[]) => string);
}
/**
 * A locale is just a collection of locale message registries, they are keyed
 * by the type (like a namespace) ex: "validation" or "ui". Plugin authors
 * can declare their own types too.
 *
 * @public
 */
interface FormKitLocale {
    ui: FormKitLocaleMessages;
    [index: string]: FormKitLocaleMessages;
}
/**
 * The locale registry is just a key-value pair of locale indexes ('ar', 'en',
 * 'it', etc.) to their respective locales.
 *
 * @public
 */
interface FormKitLocaleRegistry {
    [index: string]: FormKitLocale;
}
/**
 * Create a new internationalization plugin for FormKit.
 *
 * @param registry - The registry of {@link @formkit/i18n#FormKitLocaleRegistry | FormKitLocales}.
 *
 * @returns {@link @formkit/core#FormKitPlugin | FormKitPlugin}
 *
 * @public
 */
declare function createI18nPlugin(registry: FormKitLocaleRegistry): FormKitPlugin;
/**
 * Change the active locale of all FormKit instances (global).
 * @param locale - The locale to change to
 */
declare function changeLocale(locale: string): void;

declare const ar: {
    ui: FormKitLocaleMessages;
    validation: FormKitValidationMessages;
};

declare const az: {
    ui: FormKitLocaleMessages;
    validation: FormKitValidationMessages;
};

declare const bg: {
    ui: FormKitLocaleMessages;
    validation: FormKitValidationMessages;
};

declare const bs: {
    ui: FormKitLocaleMessages;
    validation: FormKitValidationMessages;
};

declare const ca: {
    ui: FormKitLocaleMessages;
    validation: FormKitValidationMessages;
};

declare const cs: {
    ui: FormKitLocaleMessages;
    validation: FormKitValidationMessages;
};

declare const da: {
    ui: FormKitLocaleMessages;
    validation: FormKitValidationMessages;
};

declare const de: {
    ui: FormKitLocaleMessages;
    validation: FormKitValidationMessages;
};

declare const el: {
    ui: FormKitLocaleMessages;
    validation: FormKitValidationMessages;
};

declare const en: {
    ui: FormKitLocaleMessages;
    validation: FormKitValidationMessages;
};

declare const es: {
    ui: FormKitLocaleMessages;
    validation: FormKitValidationMessages;
};

declare const fa: {
    ui: FormKitLocaleMessages;
    validation: FormKitValidationMessages;
};

declare const fi: {
    ui: FormKitLocaleMessages;
    validation: FormKitValidationMessages;
};

declare const fr: {
    ui: FormKitLocaleMessages;
    validation: FormKitValidationMessages;
};

declare const fy: {
    ui: FormKitLocaleMessages;
    validation: FormKitValidationMessages;
};

declare const he: {
    ui: FormKitLocaleMessages;
    validation: FormKitValidationMessages;
};

declare const hr: {
    ui: FormKitLocaleMessages;
    validation: FormKitValidationMessages;
};

declare const hu: {
    ui: FormKitLocaleMessages;
    validation: FormKitValidationMessages;
};

declare const id: {
    ui: FormKitLocaleMessages;
    validation: FormKitValidationMessages;
};

declare const is: {
    ui: FormKitLocaleMessages;
    validation: FormKitValidationMessages;
};

declare const it: {
    ui: FormKitLocaleMessages;
    validation: FormKitValidationMessages;
};

declare const ja: {
    ui: FormKitLocaleMessages;
    validation: FormKitValidationMessages;
};

declare const kk: {
    ui: FormKitLocaleMessages;
    validation: FormKitValidationMessages;
};

declare const ko: {
    ui: FormKitLocaleMessages;
    validation: FormKitValidationMessages;
};

declare const lt: {
    ui: FormKitLocaleMessages;
    validation: FormKitValidationMessages;
};

declare const lv: {
    ui: FormKitLocaleMessages;
    validation: FormKitValidationMessages;
};

declare const mn: {
    ui: FormKitLocaleMessages;
    validation: FormKitValidationMessages;
};

declare const nb: {
    ui: FormKitLocaleMessages;
    validation: FormKitValidationMessages;
};

declare const nl: {
    ui: FormKitLocaleMessages;
    validation: FormKitValidationMessages;
};

declare const pl: {
    ui: FormKitLocaleMessages;
    validation: FormKitValidationMessages;
};

declare const pt: {
    ui: FormKitLocaleMessages;
    validation: FormKitValidationMessages;
};

declare const ro: {
    ui: FormKitLocaleMessages;
    validation: FormKitValidationMessages;
};

declare const ru: {
    ui: FormKitLocaleMessages;
    validation: FormKitValidationMessages;
};

declare const sk: {
    ui: FormKitLocaleMessages;
    validation: FormKitValidationMessages;
};

declare const sl: {
    ui: FormKitLocaleMessages;
    validation: FormKitValidationMessages;
};

declare const sr: {
    ui: FormKitLocaleMessages;
    validation: FormKitValidationMessages;
};

declare const sv: {
    ui: FormKitLocaleMessages;
    validation: FormKitValidationMessages;
};

declare const tet: {
    ui: FormKitLocaleMessages;
    validation: FormKitValidationMessages;
};

declare const tg: {
    ui: FormKitLocaleMessages;
    validation: FormKitValidationMessages;
};

declare const th: {
    ui: FormKitLocaleMessages;
    validation: FormKitValidationMessages;
};

declare const tr: {
    ui: FormKitLocaleMessages;
    validation: FormKitValidationMessages;
};

declare const uk: {
    ui: FormKitLocaleMessages;
    validation: FormKitValidationMessages;
};

declare const uz: {
    ui: FormKitLocaleMessages;
    validation: FormKitValidationMessages;
};

declare const vi: {
    ui: FormKitLocaleMessages;
    validation: FormKitValidationMessages;
};

declare const zh: {
    ui: FormKitLocaleMessages;
    validation: FormKitValidationMessages;
};

declare const zhTW: {
    ui: FormKitLocaleMessages;
    validation: FormKitValidationMessages;
};

/**
 * Given a string, convert it to sentence case.
 *
 * @param str - The string to sentence case.
 *
 * @returns `string`
 *
 * @public
 */
declare function sentence(str: string): string;
/**
 * Creates an oxford-comma separated list of items.
 *
 * @param items - the items to list out.
 * @param conjunction - in the list "x, y, and z", "and" is the conjunction.
 * Defaults to "or".
 *
 * @returns `string`
 *
 * @public
 */
declare function list(items: string[], conjunction?: string): string;
/**
 * Given a string or a date, return a nice human-readable version.
 *
 * @param date - A string or a date.
 *
 * @returns `string`
 *
 * @public
 */
declare function date(date: string | Date): string;
/**
 * Orders two variables from smallest to largest.
 *
 * @param first - The first number or string.
 * @param second - The second number or string.
 *
 * @returns `[smaller: number | string, larger: number | string]`
 *
 * @public
 */
declare function order(first: string | number, second: string | number): [smaller: number | string, larger: number | string];

/**
 * Export all the available locales at once.
 *
 * @public
 */
declare const locales: {
    ar: {
        ui: FormKitLocaleMessages;
        validation: _formkit_validation.FormKitValidationMessages;
    };
    az: {
        ui: FormKitLocaleMessages;
        validation: _formkit_validation.FormKitValidationMessages;
    };
    bg: {
        ui: FormKitLocaleMessages;
        validation: _formkit_validation.FormKitValidationMessages;
    };
    bs: {
        ui: FormKitLocaleMessages;
        validation: _formkit_validation.FormKitValidationMessages;
    };
    ca: {
        ui: FormKitLocaleMessages;
        validation: _formkit_validation.FormKitValidationMessages;
    };
    cs: {
        ui: FormKitLocaleMessages;
        validation: _formkit_validation.FormKitValidationMessages;
    };
    da: {
        ui: FormKitLocaleMessages;
        validation: _formkit_validation.FormKitValidationMessages;
    };
    de: {
        ui: FormKitLocaleMessages;
        validation: _formkit_validation.FormKitValidationMessages;
    };
    el: {
        ui: FormKitLocaleMessages;
        validation: _formkit_validation.FormKitValidationMessages;
    };
    en: {
        ui: FormKitLocaleMessages;
        validation: _formkit_validation.FormKitValidationMessages;
    };
    es: {
        ui: FormKitLocaleMessages;
        validation: _formkit_validation.FormKitValidationMessages;
    };
    fa: {
        ui: FormKitLocaleMessages;
        validation: _formkit_validation.FormKitValidationMessages;
    };
    fi: {
        ui: FormKitLocaleMessages;
        validation: _formkit_validation.FormKitValidationMessages;
    };
    fr: {
        ui: FormKitLocaleMessages;
        validation: _formkit_validation.FormKitValidationMessages;
    };
    fy: {
        ui: FormKitLocaleMessages;
        validation: _formkit_validation.FormKitValidationMessages;
    };
    he: {
        ui: FormKitLocaleMessages;
        validation: _formkit_validation.FormKitValidationMessages;
    };
    hr: {
        ui: FormKitLocaleMessages;
        validation: _formkit_validation.FormKitValidationMessages;
    };
    hu: {
        ui: FormKitLocaleMessages;
        validation: _formkit_validation.FormKitValidationMessages;
    };
    id: {
        ui: FormKitLocaleMessages;
        validation: _formkit_validation.FormKitValidationMessages;
    };
    it: {
        ui: FormKitLocaleMessages;
        validation: _formkit_validation.FormKitValidationMessages;
    };
    ja: {
        ui: FormKitLocaleMessages;
        validation: _formkit_validation.FormKitValidationMessages;
    };
    kk: {
        ui: FormKitLocaleMessages;
        validation: _formkit_validation.FormKitValidationMessages;
    };
    ko: {
        ui: FormKitLocaleMessages;
        validation: _formkit_validation.FormKitValidationMessages;
    };
    lt: {
        ui: FormKitLocaleMessages;
        validation: _formkit_validation.FormKitValidationMessages;
    };
    lv: {
        ui: FormKitLocaleMessages;
        validation: _formkit_validation.FormKitValidationMessages;
    };
    nb: {
        ui: FormKitLocaleMessages;
        validation: _formkit_validation.FormKitValidationMessages;
    };
    nl: {
        ui: FormKitLocaleMessages;
        validation: _formkit_validation.FormKitValidationMessages;
    };
    pl: {
        ui: FormKitLocaleMessages;
        validation: _formkit_validation.FormKitValidationMessages;
    };
    pt: {
        ui: FormKitLocaleMessages;
        validation: _formkit_validation.FormKitValidationMessages;
    };
    ro: {
        ui: FormKitLocaleMessages;
        validation: _formkit_validation.FormKitValidationMessages;
    };
    ru: {
        ui: FormKitLocaleMessages;
        validation: _formkit_validation.FormKitValidationMessages;
    };
    sk: {
        ui: FormKitLocaleMessages;
        validation: _formkit_validation.FormKitValidationMessages;
    };
    sl: {
        ui: FormKitLocaleMessages;
        validation: _formkit_validation.FormKitValidationMessages;
    };
    sr: {
        ui: FormKitLocaleMessages;
        validation: _formkit_validation.FormKitValidationMessages;
    };
    sv: {
        ui: FormKitLocaleMessages;
        validation: _formkit_validation.FormKitValidationMessages;
    };
    tet: {
        ui: FormKitLocaleMessages;
        validation: _formkit_validation.FormKitValidationMessages;
    };
    tg: {
        ui: FormKitLocaleMessages;
        validation: _formkit_validation.FormKitValidationMessages;
    };
    th: {
        ui: FormKitLocaleMessages;
        validation: _formkit_validation.FormKitValidationMessages;
    };
    tr: {
        ui: FormKitLocaleMessages;
        validation: _formkit_validation.FormKitValidationMessages;
    };
    uk: {
        ui: FormKitLocaleMessages;
        validation: _formkit_validation.FormKitValidationMessages;
    };
    uz: {
        ui: FormKitLocaleMessages;
        validation: _formkit_validation.FormKitValidationMessages;
    };
    vi: {
        ui: FormKitLocaleMessages;
        validation: _formkit_validation.FormKitValidationMessages;
    };
    zh: {
        ui: FormKitLocaleMessages;
        validation: _formkit_validation.FormKitValidationMessages;
    };
    'zh-TW': {
        ui: FormKitLocaleMessages;
        validation: _formkit_validation.FormKitValidationMessages;
    };
    is: {
        ui: FormKitLocaleMessages;
        validation: _formkit_validation.FormKitValidationMessages;
    };
    mn: {
        ui: FormKitLocaleMessages;
        validation: _formkit_validation.FormKitValidationMessages;
    };
};

export { type FormKitLocale, type FormKitLocaleMessages, type FormKitLocaleRegistry, ar, az, bg, bs, ca, changeLocale, createI18nPlugin, cs, da, date, de, el, en, es, fa, fi, fr, fy, he, hr, hu, id, is, it, ja, kk, ko, list, locales, lt, lv, mn, nb, nl, order, pl, pt, ro, ru, sentence, sk, sl, sr, sv, tet, tg, th, tr, uk, uz, vi, zh, zhTW };
