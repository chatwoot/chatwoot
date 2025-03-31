function npmRun(agent) {
  return (args) => {
    if (args.length > 1) {
      return [agent, "run", args[0], "--", ...args.slice(1)];
    } else {
      return [agent, "run", args[0]];
    }
  };
}
const yarn = {
  "agent": ["yarn", 0],
  "run": ["yarn", "run", 0],
  "install": ["yarn", "install", 0],
  "frozen": ["yarn", "install", "--frozen-lockfile"],
  "global": ["yarn", "global", "add", 0],
  "add": ["yarn", "add", 0],
  "upgrade": ["yarn", "upgrade", 0],
  "upgrade-interactive": ["yarn", "upgrade-interactive", 0],
  "execute": ["npx", 0],
  "uninstall": ["yarn", "remove", 0],
  "global_uninstall": ["yarn", "global", "remove", 0]
};
const pnpm = {
  "agent": ["pnpm", 0],
  "run": ["pnpm", "run", 0],
  "install": ["pnpm", "i", 0],
  "frozen": ["pnpm", "i", "--frozen-lockfile"],
  "global": ["pnpm", "add", "-g", 0],
  "add": ["pnpm", "add", 0],
  "upgrade": ["pnpm", "update", 0],
  "upgrade-interactive": ["pnpm", "update", "-i", 0],
  "execute": ["pnpm", "dlx", 0],
  "uninstall": ["pnpm", "remove", 0],
  "global_uninstall": ["pnpm", "remove", "--global", 0]
};
const bun = {
  "agent": ["bun", 0],
  "run": ["bun", "run", 0],
  "install": ["bun", "install", 0],
  "frozen": ["bun", "install", "--frozen-lockfile"],
  "global": ["bun", "add", "-g", 0],
  "add": ["bun", "add", 0],
  "upgrade": ["bun", "update", 0],
  "upgrade-interactive": ["bun", "update", 0],
  "execute": ["bun", "x", 0],
  "uninstall": ["bun", "remove", 0],
  "global_uninstall": ["bun", "remove", "-g", 0]
};
const COMMANDS = {
  "npm": {
    "agent": ["npm", 0],
    "run": npmRun("npm"),
    "install": ["npm", "i", 0],
    "frozen": ["npm", "ci"],
    "global": ["npm", "i", "-g", 0],
    "add": ["npm", "i", 0],
    "upgrade": ["npm", "update", 0],
    "upgrade-interactive": null,
    "execute": ["npx", 0],
    "uninstall": ["npm", "uninstall", 0],
    "global_uninstall": ["npm", "uninstall", "-g", 0]
  },
  "yarn": yarn,
  "yarn@berry": {
    ...yarn,
    "frozen": ["yarn", "install", "--immutable"],
    "upgrade": ["yarn", "up", 0],
    "upgrade-interactive": ["yarn", "up", "-i", 0],
    "execute": ["yarn", "dlx", 0],
    // Yarn 2+ removed 'global', see https://github.com/yarnpkg/berry/issues/821
    "global": ["npm", "i", "-g", 0],
    "global_uninstall": ["npm", "uninstall", "-g", 0]
  },
  "pnpm": pnpm,
  // pnpm v6.x or below
  "pnpm@6": {
    ...pnpm,
    run: npmRun("pnpm")
  },
  "bun": bun
};
function resolveCommand(agent, command, args) {
  const value = COMMANDS[agent][command];
  return constructCommand(value, args);
}
function constructCommand(value, args) {
  if (value == null)
    return null;
  const list = typeof value === "function" ? value(args) : value.flatMap((v) => {
    if (typeof v === "number")
      return args;
    return [v];
  });
  return {
    command: list[0],
    args: list.slice(1)
  };
}

export { COMMANDS, constructCommand, resolveCommand };
