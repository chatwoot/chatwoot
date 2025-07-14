import type { ClientCommand } from '@histoire/shared'
import { defineStore } from 'pinia'
import { ref } from 'vue'
import { executeCommand, getCommandContext } from '../util/commands.js'

export const useCommandStore = defineStore('command', () => {
  const selectedCommand = ref<ClientCommand | null>(null)
  const showPromptsModal = ref(false)

  function activateCommand(command: ClientCommand) {
    selectedCommand.value = command
    if (command.prompts?.length) {
      showPromptsModal.value = true
    }
    else {
      const params = command.getParams?.(getCommandContext()) ?? {}
      executeCommand(command, params)
    }
  }

  return {
    selectedCommand,
    showPromptsModal,
    activateCommand,
  }
})
