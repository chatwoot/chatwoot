/**
 * A zero-byte file is refused everywhere it can be picked, and until now a paste was the one
 * entry point that dropped it without a word. The silence is deliberate and comes from upstream
 * (PR #13135): the macOS Numbers app puts an invalid zero-byte attachment on the clipboard
 * beside the copied cells, so warning on every dropped file would fire on every spreadsheet
 * paste, about a file the person never chose.
 *
 * What separates the two cases is text, and it was measured rather than assumed (macOS,
 * Chromium 153):
 *
 *   - a Numbers copy, one cell or a range, reports `text/plain`, `text/html`, `text/rtf` and
 *     `Files`, the file being `image.png` of `image/png`. Its size is almost always 0 and not
 *     always: reading the pasteboard directly gave 0 bytes on nine reads across three copies,
 *     and twice the same gesture produced a real PNG (4972 and 10594 bytes) that nobody could
 *     reproduce on command afterwards. Whatever decides that, this rule does not rest on it:
 *     the decision is made on the text beside the file, so an empty artifact is dropped in
 *     silence and a filled one is an ordinary attachment;
 *   - a file copied in Finder reports `Files` alone. The macOS pasteboard does carry the file
 *     name as text, and the browser suppresses every text flavour once a file URL is present,
 *     so the paste event sees no text at all.
 *
 * So the rule is: drop empty files as before, and say so only when the clipboard carried no
 * text. A rich copy that happens to bring an empty attachment stays as quiet as it is today.
 */
import { isFileEmpty } from 'shared/helpers/FileHelper';

const TEXT_TYPES = ['text/plain', 'text/html', 'text/rtf'];

export const clipboardCarriesText = transfer =>
  Array.from(transfer?.types || []).some(type => TEXT_TYPES.includes(type));

export const splitFilesBySize = files => {
  const all = Array.from(files || []).filter(Boolean);

  // `isFileEmpty` is the same predicate the four entry points that already explain themselves
  // use, so a paste cannot drift from them on what counts as empty.
  return {
    files: all.filter(file => !isFileEmpty(file)),
    empty: all.filter(isFileEmpty),
  };
};

/**
 * The files worth attaching, plus whether the caller should explain what it dropped. One alert
 * per paste, not one per file: two empty files pasted together are one thing that happened.
 */
export const usableFilesFromTransfer = transfer => {
  const { files, empty } = splitFilesBySize(transfer?.files);

  return {
    files,
    shouldAlertEmpty: empty.length > 0 && !clipboardCarriesText(transfer),
  };
};
