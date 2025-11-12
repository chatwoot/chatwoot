import type { ClientCommandOptions } from 'histoire'
import { sendEvent, openStory } from 'histoire/plugin'
import { paramCase } from 'change-case'

export default {
  prompts: [
    {
      field: 'component',
      label: 'Choose a component',
      type: 'select',
      options: async (search) => sendEvent('listVueComponents', { search }),
      required: true,
    },
    {
      field: 'fileName',
      label: 'File name',
      type: 'text',
      required: true,
      defaultValue: (answers) => answers.component?.replace(/.+\/(.+?)\.vue$/, '$1.story.vue'),
    },
  ],
  clientAction: (params) => {
    const index = params.component.lastIndexOf('/')
    const dirname = params.component.substring(0, index + 1)
    const file = `${dirname}${params.fileName}`
    const storyId = paramCase(file.toLowerCase())
    openStory(storyId)
  },
} as ClientCommandOptions
