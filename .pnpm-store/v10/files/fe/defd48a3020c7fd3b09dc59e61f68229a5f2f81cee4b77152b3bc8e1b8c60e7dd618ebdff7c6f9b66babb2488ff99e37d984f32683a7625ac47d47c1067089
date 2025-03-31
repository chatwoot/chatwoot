import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import fs from 'fs-extra'
import { globbySync } from 'globby'

export default defineConfig({
  plugins: [
    vue(),
    {
      name: 'histoire:preserve:import.meta',
      enforce: 'pre',
      transform(code) {
        if (code.includes('import.meta')) {
          return {
            code: code.replace(/import\.meta/g, 'import__meta'),
          }
        }
      },
      closeBundle() {
        try {
          const files = globbySync('./dist/bundled/**/*.js')
          for (const file of files) {
            const content = fs.readFileSync(file, 'utf-8')
            if (content.includes('import__meta')) {
              fs.writeFileSync(file, content.replace(/import__meta/g, 'import.meta'), 'utf-8')
            }
          }
        }
        catch (e) {
          console.error(e)
        }
      },
    },
  ],

  resolve: {
    alias: {
      'floating-vue': '@histoire/vendors/floating-vue',
      '@iconify/vue': '@histoire/vendors/iconify',
      'pinia': '@histoire/vendors/pinia',
      'scroll-into-view-if-needed': '@histoire/vendors/scroll',
      'vue-router': '@histoire/vendors/vue-router',
      '@vueuse/core': '@histoire/vendors/vue-use',
      'vue': '@histoire/vendors/vue',
    },
  },

  build: {
    emptyOutDir: false,
    outDir: 'dist/bundled',
    lib: {
      entry: '',
      formats: ['es'],
    },
    rollupOptions: {
      external: [
        /\$histoire/,
        /@histoire/,
        // eslint-disable-next-line ts/no-var-requires, ts/no-require-imports
        ...Object.keys(require('./package.json').dependencies),
      ],

      input: [
        'src/app/api.ts',
        'src/app/index.ts',
        'src/app/sandbox.ts',
      ],

      output: {
        // manualChunks (id) {
        //   if (id.includes('node_modules')) {
        //     return 'vendor'
        //   }
        // },
        entryFileNames: '[name].js',
        chunkFileNames: '[name].js',
        assetFileNames: '[name][extname]',
        // hoistTransitiveImports: false,
        preserveModules: true,
        preserveModulesRoot: 'src/app',
      },
      treeshake: false,
      preserveEntrySignatures: 'strict',
    },
    cssCodeSplit: false,
    minify: false,
  },
})
