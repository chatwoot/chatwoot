export default async function (_, _nuxt) {
  const { addPluginTemplate } = await import('@nuxt/kit')

  const nuxt = (this && this.nuxt) || _nuxt

  nuxt.options.css.push('floating-vue/dist/style.css')

  addPluginTemplate({
    filename: 'floating-vue.mjs',
    getContents: () => `
      import { defineNuxtPlugin } from '#imports'
      import FloatingVue from 'floating-vue'
      
      export default defineNuxtPlugin((nuxtApp) => {
        // @TODO cutomization
        nuxtApp.vueApp.use(FloatingVue)
      })
    `,
  })

  // @TODO remove when floating-ui supports native ESM
  nuxt.options.build.transpile.push('floating-vue', '@floating-ui/core', '@floating-ui/dom')

  // SSR support for v-tooltip directive
  nuxt.options.vue.compilerOptions.directiveTransforms = nuxt.options.vue.compilerOptions.directiveTransforms || {}
  nuxt.options.vue.compilerOptions.directiveTransforms.tooltip = () => ({
    props: [],
    needRuntime: true,
  })
}
