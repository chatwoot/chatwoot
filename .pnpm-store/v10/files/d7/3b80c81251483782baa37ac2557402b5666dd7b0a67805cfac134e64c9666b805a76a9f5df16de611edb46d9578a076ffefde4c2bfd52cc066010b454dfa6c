import type { PluginCommand } from 'histoire'
import fs from 'node:fs'
import path from 'pathe'
import launchEditor from 'launch-editor'

export default {
  id: 'histoire:plugin-vue:generate-story',
  label: 'Generate Vue 3 story from component',
  icon: 'https://vuejs.org/logo.svg',
  searchText: 'generate create',
  async serverAction (params) {
    const targetFile = path.join(path.dirname(params.component), params.fileName)

    if (fs.existsSync(targetFile)) {
      throw new Error(`File ${targetFile} already exists`)
    }

    const { component, componentName, isTs } = await getComponentInfo(params.component)

    const content = `<script setup${isTs ? ' lang="ts"' : ''}>
import ${componentName} from './${component}'
</script>

<template>
  <Story>
    <Variant title="Default">
      <${componentName} />
    </Variant>
  </Story>
</template>
`

    await fs.promises.writeFile(targetFile, content, 'utf-8')

    launchEditor(targetFile)
  },
  clientSetupFile: '@histoire/plugin-vue/dist/commands/generate-story.client.js',
} as PluginCommand

async function isComponentTs (component: string) {
  const componentContent = await fs.promises.readFile(component, 'utf-8')
  return componentContent.includes('lang="ts"')
}

async function getComponentInfo (file: string) {
  const component = path.basename(file)
  const componentName = component.replace(path.extname(component), '')
  const isTs = await isComponentTs(file)

  return {
    component,
    componentName,
    isTs,
  }
}
