import { getGlobal } from '../../lib/get-global'
import type { Analytics } from '../analytics'

const env = getGlobal()

// The code below assumes the inspector extension will use Object.assign
// to add the inspect interface on to this object reference (unless the
// extension code ran first and has already set up the variable)
const inspectorHost: {
  attach: (analytics: Analytics) => void
} = ((env as any)['__SEGMENT_INSPECTOR__'] ??= {})

export const attachInspector = (analytics: Analytics) =>
  inspectorHost.attach?.(analytics as any)
