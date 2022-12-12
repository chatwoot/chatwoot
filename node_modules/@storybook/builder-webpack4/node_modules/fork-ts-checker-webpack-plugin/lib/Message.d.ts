import { Issue } from './issue';
export interface Message {
    diagnostics: Issue[];
    lints: Issue[];
}
