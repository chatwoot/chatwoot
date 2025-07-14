import v8 from 'node:v8';
import { r as runBaseTests } from '../chunks/base.wKnmhRYd.js';
import { c as createForksRpcOptions, u as unwrapSerializableConfig } from '../chunks/utils.Cn0zI1t3.js';
import 'vite-node/client';
import '../chunks/execute.PoofJYS5.js';
import 'node:fs';
import 'node:url';
import 'node:vm';
import '@vitest/utils/error';
import 'pathe';
import 'vite-node/utils';
import '../path.js';
import 'node:path';
import '@vitest/mocker';
import 'node:module';
import '@vitest/utils';
import '../chunks/utils.C8RiOc4B.js';

class ForksBaseWorker {
  getRpcOptions() {
    return createForksRpcOptions(v8);
  }
  async executeTests(method, state) {
    const exit = process.exit;
    state.ctx.config = unwrapSerializableConfig(state.ctx.config);
    try {
      await runBaseTests(method, state);
    } finally {
      process.exit = exit;
    }
  }
  runTests(state) {
    return this.executeTests("run", state);
  }
  collectTests(state) {
    return this.executeTests("collect", state);
  }
}
var forks = new ForksBaseWorker();

export { forks as default };
