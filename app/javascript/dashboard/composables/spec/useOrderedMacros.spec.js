import { useOrderedMacros } from '../useOrderedMacros';
import { useMapGetter } from 'dashboard/composables/store';
import { useUISettings } from 'dashboard/composables/useUISettings';

vi.mock('dashboard/composables/store');
vi.mock('dashboard/composables/useUISettings');

const macros = [
  { id: 1, name: 'Resolve' },
  { id: 2, name: 'Mark as spam' },
  { id: 3, name: 'Remove team' },
];

const updateUISettings = vi.fn();

const mockSettings = (savedOrder, currentMacros = macros) => {
  useMapGetter.mockImplementation(getter =>
    getter === 'macros/getMacros' ? { value: currentMacros } : { value: null }
  );
  useUISettings.mockReturnValue({
    uiSettings: {
      value: savedOrder ? { macros_display_order: savedOrder } : {},
    },
    updateUISettings,
  });
};

describe('useOrderedMacros', () => {
  beforeEach(() => {
    updateUISettings.mockClear();
  });

  it('keeps the store order when nothing has been arranged', () => {
    mockSettings(null);

    const { orderedMacros } = useOrderedMacros();

    expect(orderedMacros.value.map(({ id }) => id)).toEqual([1, 2, 3]);
  });

  it('keeps the store order when the saved order is empty', () => {
    mockSettings([]);

    const { orderedMacros } = useOrderedMacros();

    expect(orderedMacros.value.map(({ id }) => id)).toEqual([1, 2, 3]);
  });

  it('sorts macros by the saved order', () => {
    mockSettings([3, 1, 2]);

    const { orderedMacros } = useOrderedMacros();

    expect(orderedMacros.value.map(({ id }) => id)).toEqual([3, 1, 2]);
  });

  it('pushes macros missing from the saved order to the end', () => {
    mockSettings([3]);

    const { orderedMacros } = useOrderedMacros();

    expect(orderedMacros.value.map(({ id }) => id)).toEqual([3, 1, 2]);
  });

  it('ignores saved ids that no longer exist', () => {
    mockSettings([99, 2, 1], [macros[0], macros[1]]);

    const { orderedMacros } = useOrderedMacros();

    expect(orderedMacros.value.map(({ id }) => id)).toEqual([2, 1]);
  });

  it('returns an empty list when there are no macros', () => {
    mockSettings([3, 1, 2], []);

    const { orderedMacros } = useOrderedMacros();

    expect(orderedMacros.value).toEqual([]);
  });

  it('saves the new order as ids when written to', () => {
    mockSettings([1, 2, 3]);

    const { orderedMacros } = useOrderedMacros();
    orderedMacros.value = [macros[2], macros[0], macros[1]];

    expect(updateUISettings).toHaveBeenCalledWith({
      macros_display_order: [3, 1, 2],
    });
  });
});
