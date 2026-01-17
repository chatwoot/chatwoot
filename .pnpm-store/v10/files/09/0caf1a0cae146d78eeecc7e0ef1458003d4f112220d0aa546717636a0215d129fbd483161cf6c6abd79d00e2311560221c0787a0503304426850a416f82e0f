import type { Context } from '../context.js'
import { getInjectedImport } from '../util/vendors.js'

export const resolvedMarkdownFiles = (ctx: Context) => {
  const filesJs = ctx.markdownFiles.map(f => `${JSON.stringify(f.relativePath)}: () => import(${JSON.stringify(`virtual:md:${f.id}`)})`).join(',')
  return `import { reactive } from ${process.env.HISTOIRE_DEV ? `'vue'` : getInjectedImport('@histoire/vendors/vue')}
export const markdownFiles = reactive({${filesJs}})
if (import.meta.hot) {
  if (!window.__hst_md_hmr) {
    window.__hst_md_hmr = (newModule) => {
      markdownFiles[newModule.relativePath] = () => newModule
    }
  }

  import.meta.hot.accept(newModule => {
    Object.assign(markdownFiles, newModule.markdownFiles)
  })
}`
}
