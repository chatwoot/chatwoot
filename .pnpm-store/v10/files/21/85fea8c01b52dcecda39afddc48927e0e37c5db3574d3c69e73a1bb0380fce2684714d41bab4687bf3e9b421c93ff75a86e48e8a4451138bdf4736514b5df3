import process from 'node:process';

const ASCII_ETX_CODE = 0x03; // Ctrl+C emits this code

class StdinDiscarder {
	#activeCount = 0;

	start() {
		this.#activeCount++;

		if (this.#activeCount === 1) {
			this.#realStart();
		}
	}

	stop() {
		if (this.#activeCount <= 0) {
			throw new Error('`stop` called more times than `start`');
		}

		this.#activeCount--;

		if (this.#activeCount === 0) {
			this.#realStop();
		}
	}

	#realStart() {
		// No known way to make it work reliably on Windows.
		if (process.platform === 'win32' || !process.stdin.isTTY) {
			return;
		}

		process.stdin.setRawMode(true);
		process.stdin.on('data', this.#handleInput);
		process.stdin.resume();
	}

	#realStop() {
		if (!process.stdin.isTTY) {
			return;
		}

		process.stdin.off('data', this.#handleInput);
		process.stdin.pause();
		process.stdin.setRawMode(false);
	}

	#handleInput(chunk) {
		// Allow Ctrl+C to gracefully exit.
		if (chunk[0] === ASCII_ETX_CODE) {
			process.emit('SIGINT');
		}
	}
}

const stdinDiscarder = new StdinDiscarder();

export default stdinDiscarder;
