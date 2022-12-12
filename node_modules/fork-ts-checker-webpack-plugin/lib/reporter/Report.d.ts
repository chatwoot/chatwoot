import { Dependencies } from './Dependencies';
import { Issue } from '../issue';
interface Report {
    getDependencies(): Promise<Dependencies>;
    getIssues(): Promise<Issue[]>;
    close(): Promise<void>;
}
export { Report };
