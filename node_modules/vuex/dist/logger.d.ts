/**
 * Types for the logger plugin.
 * This file must be put alongside the JavaScript file of the logger.
 */

import { Payload, Plugin } from "../types/index";

export interface LoggerOption<S> {
  collapsed?: boolean;
  transformer?: (state: S) => any;
  mutationTransformer?: <P extends Payload>(mutation: P) => any;
}

export default function createLogger<S>(option: LoggerOption<S>): Plugin<S>;
