import { computed, getCurrentInstance } from 'vue';
import Vue from 'vue';
import VueI18n from 'vue-i18n';

let i18nInstance = VueI18n;

export function useI18n() {
  if (!i18nInstance) throw new Error('vue-i18n not initialized');

  const i18n = i18nInstance;

  const instance = getCurrentInstance();
  const vm = instance?.proxy || instance || new Vue({});

  const locale = computed({
    get() {
      return i18n.locale;
    },
    set(v) {
      i18n.locale = v;
    },
  });

  return {
    locale,
    t: vm.$t.bind(vm),
    tc: vm.$tc.bind(vm),
    d: vm.$d.bind(vm),
    te: vm.$te.bind(vm),
    n: vm.$n.bind(vm),
  };
}
