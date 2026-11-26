import { ref } from 'vue';
import CaptainScenarios from 'dashboard/api/captain/scenarios';
import { useScenarioToolSuggestions } from './useScenarioToolSuggestions';

vi.mock('vue-router', () => ({
  useRoute: () => ({ params: { assistantId: '7' } }),
}));
vi.mock('dashboard/api/captain/scenarios', () => ({
  default: { suggestTools: vi.fn() },
}));

const NOTE_LINK = '[@Add Private Note](tool://add_private_note)';
const ORDERS_LINK = '[@Get Order History](tool://custom_get_order_history)';

const suggestion = (toolId, toolTitle, phrase) => ({
  tool_id: toolId,
  tool_title: toolTitle,
  phrase,
  replacement: `${phrase} using [@${toolTitle}](tool://${toolId})`,
});

describe('useScenarioToolSuggestions', () => {
  beforeEach(() => {
    CaptainScenarios.suggestTools.mockReset();
  });

  it('links each suggested phrase outside existing tool links and lets the admin remove one', async () => {
    const instruction = ref(
      `Use [@add a private note to the contact](tool://add_contact_note) for profile notes, then check order history and add a private note.`
    );
    CaptainScenarios.suggestTools.mockResolvedValue({
      data: {
        suggestions: [
          suggestion(
            'add_private_note',
            'Add Private Note',
            'add a private note'
          ),
          suggestion(
            'custom_get_order_history',
            'Get Order History',
            'order history'
          ),
          suggestion('update_priority', 'Update Priority', 'raise priority'),
        ],
      },
    });
    const { suggestions, linkMissingTools, removeSuggestion } =
      useScenarioToolSuggestions(instruction);

    expect(await linkMissingTools()).toBe(true);
    expect(CaptainScenarios.suggestTools).toHaveBeenCalledWith({
      assistantId: '7',
      instruction:
        'Use [@add a private note to the contact](tool://add_contact_note) for profile notes, then check order history and add a private note.',
    });
    expect(instruction.value).toBe(
      `Use [@add a private note to the contact](tool://add_contact_note) for profile notes, then check order history using ${ORDERS_LINK} and add a private note using ${NOTE_LINK}.`
    );
    expect(suggestions.value.map(item => item.toolId)).toEqual([
      'add_private_note',
      'custom_get_order_history',
    ]);

    removeSuggestion('custom_get_order_history');

    expect(instruction.value).toBe(
      `Use [@add a private note to the contact](tool://add_contact_note) for profile notes, then check order history and add a private note using ${NOTE_LINK}.`
    );
    expect(suggestions.value.map(item => item.toolId)).toEqual([
      'add_private_note',
    ]);
  });

  it('saves on the next attempt without checking the reviewed instruction again', async () => {
    const instruction = ref('Add a private note.');
    CaptainScenarios.suggestTools.mockResolvedValue({
      data: {
        suggestions: [
          suggestion(
            'add_private_note',
            'Add Private Note',
            'Add a private note'
          ),
        ],
      },
    });
    const { linkMissingTools } = useScenarioToolSuggestions(instruction);

    expect(await linkMissingTools()).toBe(true);
    expect(await linkMissingTools()).toBe(false);
    expect(CaptainScenarios.suggestTools).toHaveBeenCalledTimes(1);

    instruction.value = `${instruction.value} Then resolve it.`;
    CaptainScenarios.suggestTools.mockResolvedValue({
      data: { suggestions: [] },
    });

    expect(await linkMissingTools()).toBe(false);
    expect(CaptainScenarios.suggestTools).toHaveBeenCalledTimes(2);
  });

  it('does not block saving when the check fails', async () => {
    const instruction = ref('Add a private note.');
    CaptainScenarios.suggestTools.mockRejectedValue(new Error('timeout'));
    const { linkMissingTools, isChecking } =
      useScenarioToolSuggestions(instruction);

    expect(await linkMissingTools()).toBe(false);
    expect(instruction.value).toBe('Add a private note.');
    expect(isChecking.value).toBe(false);
  });
});
