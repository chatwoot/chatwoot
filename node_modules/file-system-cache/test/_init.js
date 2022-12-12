import fs from "fs-extra";
import fsPath from "path";

const BASE_PATH = "./test/samples";
const deleteFolder = () => fs.removeSync(fsPath.resolve(BASE_PATH));

beforeEach(() => deleteFolder());
afterEach(() => deleteFolder());
