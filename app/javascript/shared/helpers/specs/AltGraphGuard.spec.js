import { isAltGraphEvent } from '../KeyboardHelpers';

// Mirrors what a browser reports for a keydown. getModifierState is what both
// tinykeys and this guard read.
const keyEvent = ({
  key,
  code,
  ctrl = false,
  alt = false,
  altGraph = false,
}) => ({
  key,
  code,
  ctrlKey: ctrl,
  altKey: alt,
  getModifierState: modifier =>
    ({ Control: ctrl, Alt: alt, AltGraph: altGraph })[modifier] ?? false,
});

describe('#isAltGraphEvent', () => {
  it('detects AltGr typing an accented character', () => {
    // AltGr+A on a Polish layout: Windows reports Ctrl+Alt and produces "ą",
    // which would otherwise match $mod+Alt+KeyA (add attachment).
    expect(
      isAltGraphEvent(
        keyEvent({
          key: 'ą',
          code: 'KeyA',
          ctrl: true,
          alt: true,
          altGraph: true,
        })
      )
    ).toBe(true);
    // AltGr+E produces "ę" and would match $mod+Alt+KeyE (resolve and next).
    expect(
      isAltGraphEvent(
        keyEvent({
          key: 'ę',
          code: 'KeyE',
          ctrl: true,
          alt: true,
          altGraph: true,
        })
      )
    ).toBe(true);
  });

  it('detects AltGr however the platform reports the companion modifiers', () => {
    expect(
      isAltGraphEvent(keyEvent({ key: 'ł', code: 'KeyL', altGraph: true }))
    ).toBe(true);
    expect(
      isAltGraphEvent(
        keyEvent({ key: 'ł', code: 'KeyL', alt: true, altGraph: true })
      )
    ).toBe(true);
  });

  it('leaves Ctrl+Alt alone when no AltGraph state is reported', () => {
    // A purposely pressed Ctrl+Alt+A on a layout without AltGr keeps working.
    expect(
      isAltGraphEvent(
        keyEvent({ key: 'a', code: 'KeyA', ctrl: true, alt: true })
      )
    ).toBe(false);
  });

  it('leaves plain Alt+<letter> shortcuts alone', () => {
    expect(
      isAltGraphEvent(keyEvent({ key: 'l', code: 'KeyL', alt: true }))
    ).toBe(false);
  });

  it('leaves unmodified and Ctrl-only keystrokes alone', () => {
    expect(isAltGraphEvent(keyEvent({ key: 'l', code: 'KeyL' }))).toBe(false);
    expect(
      isAltGraphEvent(keyEvent({ key: 'l', code: 'KeyL', ctrl: true }))
    ).toBe(false);
  });

  it('also drops a deliberate chord that the browser reports as AltGraph', () => {
    // Documents the accepted tradeoff: a single keydown carries no signal that
    // separates AltGr from a purposely pressed Ctrl+Alt, so typing wins. See
    // the note on isAltGraphEvent before changing this.
    expect(
      isAltGraphEvent(
        keyEvent({
          key: 'a',
          code: 'KeyA',
          ctrl: true,
          alt: true,
          altGraph: true,
        })
      )
    ).toBe(true);
  });

  it('treats events without getModifierState as non-AltGr', () => {
    expect(
      isAltGraphEvent({ key: 'a', code: 'KeyA', ctrlKey: true, altKey: true })
    ).toBe(false);
  });
});
