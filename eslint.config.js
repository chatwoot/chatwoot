import js from "@eslint/js";
import vue from "eslint-plugin-vue";
import prettier from "eslint-plugin-prettier";
import vitestGlobals from "eslint-plugin-vitest-globals";
import vueI18n from "@intlify/eslint-plugin-vue-i18n";
import importPlugin from "eslint-plugin-import";

/** @type {import("eslint").FlatConfig[]} */
export default [
  js.configs.recommended,
  vue.configs["vue3-recommended"],
  vueI18n.configs.recommended,
  vitestGlobals.configs.recommended,
  {
    files: ["**/*.{js,vue}"],
    plugins: {
      vue,
      prettier,
      "vitest-globals": vitestGlobals,
      "@intlify/vue-i18n": vueI18n,
      import: importPlugin,
    },
    languageOptions: {
      ecmaVersion: "latest",
      sourceType: "module",
    },
    env: {
      browser: true,
      node: true,
    },
    globals: {
      bus: true,
      vi: true,
    },
    rules: {
      "prettier/prettier": "error",
      camelcase: "off",
      "no-param-reassign": "off",
      "import/no-extraneous-dependencies": "off",
      "import/prefer-default-export": "off",
      "import/no-named-as-default": "off",
      "import/no-unresolved": "off",
      "vue/multi-word-component-names": "off",
      "vue/next-tick-style": ["error", "callback"],
      "vue/block-order": [
        "error",
        {
          order: ["script", "template", "style"],
        },
      ],
      "vue/no-unused-properties": [
        "error",
        {
          groups: ["props"],
          deepData: false,
        },
      ],
      "vue/max-attributes-per-line": [
        "error",
        {
          singleline: { max: 20 },
          multiline: { max: 1 },
        },
      ],
      "vue/html-self-closing": [
        "error",
        {
          html: { void: "always", normal: "always", component: "always" },
          svg: "always",
          math: "always",
        },
      ],
      "vue/no-v-html": "off",
      "no-console": "error",
      "@intlify/vue-i18n/no-dynamic-keys": "warn",
      "@intlify/vue-i18n/no-unused-keys": [
        "warn",
        { extensions: [".js", ".vue"] },
      ],
    },
  },
  {
    files: ["**/*.spec.{j,t}s?(x)"],
    env: {
      "vitest-globals/env": true,
    },
  },
  {
    files: ["**/*.story.vue"],
    rules: {
      "vue/no-undef-components": [
        "error",
        { ignorePatterns: ["Variant", "Story"] },
      ],
      "vue/no-bare-strings-in-template": "off",
      "no-console": "off",
    },
  },
];
