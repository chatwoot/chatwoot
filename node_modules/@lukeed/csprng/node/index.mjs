import { randomBytes } from 'crypto';

export function random(len) {
	return randomBytes(len);
}
