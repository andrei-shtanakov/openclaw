import { describe, expect, it } from "vitest";
import {
  buildParseArgv,
  getFlagValue,
  getCommandPath,
  getPrimaryCommand,
  getPositiveIntFlagValue,
  getVerboseFlag,
  hasHelpOrVersion,
  hasFlag,
  shouldMigrateState,
  shouldMigrateStateFromPath,
} from "./argv.js";

describe("argv helpers", () => {
  it.each([
    {
      name: "help flag",
      argv: ["node", "orchid", "--help"],
      expected: true,
    },
    {
      name: "version flag",
      argv: ["node", "orchid", "-V"],
      expected: true,
    },
    {
      name: "normal command",
      argv: ["node", "orchid", "status"],
      expected: false,
    },
    {
      name: "root -v alias",
      argv: ["node", "orchid", "-v"],
      expected: true,
    },
    {
      name: "root -v alias with profile",
      argv: ["node", "orchid", "--profile", "work", "-v"],
      expected: true,
    },
    {
      name: "root -v alias with log-level",
      argv: ["node", "orchid", "--log-level", "debug", "-v"],
      expected: true,
    },
    {
      name: "subcommand -v should not be treated as version",
      argv: ["node", "orchid", "acp", "-v"],
      expected: false,
    },
    {
      name: "root -v alias with equals profile",
      argv: ["node", "orchid", "--profile=work", "-v"],
      expected: true,
    },
    {
      name: "subcommand path after global root flags should not be treated as version",
      argv: ["node", "orchid", "--dev", "skills", "list", "-v"],
      expected: false,
    },
  ])("detects help/version flags: $name", ({ argv, expected }) => {
    expect(hasHelpOrVersion(argv)).toBe(expected);
  });

  it.each([
    {
      name: "single command with trailing flag",
      argv: ["node", "orchid", "status", "--json"],
      expected: ["status"],
    },
    {
      name: "two-part command",
      argv: ["node", "orchid", "agents", "list"],
      expected: ["agents", "list"],
    },
    {
      name: "terminator cuts parsing",
      argv: ["node", "orchid", "status", "--", "ignored"],
      expected: ["status"],
    },
  ])("extracts command path: $name", ({ argv, expected }) => {
    expect(getCommandPath(argv, 2)).toEqual(expected);
  });

  it.each([
    {
      name: "returns first command token",
      argv: ["node", "orchid", "agents", "list"],
      expected: "agents",
    },
    {
      name: "returns null when no command exists",
      argv: ["node", "orchid"],
      expected: null,
    },
  ])("returns primary command: $name", ({ argv, expected }) => {
    expect(getPrimaryCommand(argv)).toBe(expected);
  });

  it.each([
    {
      name: "detects flag before terminator",
      argv: ["node", "orchid", "status", "--json"],
      flag: "--json",
      expected: true,
    },
    {
      name: "ignores flag after terminator",
      argv: ["node", "orchid", "--", "--json"],
      flag: "--json",
      expected: false,
    },
  ])("parses boolean flags: $name", ({ argv, flag, expected }) => {
    expect(hasFlag(argv, flag)).toBe(expected);
  });

  it.each([
    {
      name: "value in next token",
      argv: ["node", "orchid", "status", "--timeout", "5000"],
      expected: "5000",
    },
    {
      name: "value in equals form",
      argv: ["node", "orchid", "status", "--timeout=2500"],
      expected: "2500",
    },
    {
      name: "missing value",
      argv: ["node", "orchid", "status", "--timeout"],
      expected: null,
    },
    {
      name: "next token is another flag",
      argv: ["node", "orchid", "status", "--timeout", "--json"],
      expected: null,
    },
    {
      name: "flag appears after terminator",
      argv: ["node", "orchid", "--", "--timeout=99"],
      expected: undefined,
    },
  ])("extracts flag values: $name", ({ argv, expected }) => {
    expect(getFlagValue(argv, "--timeout")).toBe(expected);
  });

  it("parses verbose flags", () => {
    expect(getVerboseFlag(["node", "orchid", "status", "--verbose"])).toBe(true);
    expect(getVerboseFlag(["node", "orchid", "status", "--debug"])).toBe(false);
    expect(getVerboseFlag(["node", "orchid", "status", "--debug"], { includeDebug: true })).toBe(
      true,
    );
  });

  it.each([
    {
      name: "missing flag",
      argv: ["node", "orchid", "status"],
      expected: undefined,
    },
    {
      name: "missing value",
      argv: ["node", "orchid", "status", "--timeout"],
      expected: null,
    },
    {
      name: "valid positive integer",
      argv: ["node", "orchid", "status", "--timeout", "5000"],
      expected: 5000,
    },
    {
      name: "invalid integer",
      argv: ["node", "orchid", "status", "--timeout", "nope"],
      expected: undefined,
    },
  ])("parses positive integer flag values: $name", ({ argv, expected }) => {
    expect(getPositiveIntFlagValue(argv, "--timeout")).toBe(expected);
  });

  it("builds parse argv from raw args", () => {
    const cases = [
      {
        rawArgs: ["node", "orchid", "status"],
        expected: ["node", "orchid", "status"],
      },
      {
        rawArgs: ["node-22", "orchid", "status"],
        expected: ["node-22", "orchid", "status"],
      },
      {
        rawArgs: ["node-22.2.0.exe", "orchid", "status"],
        expected: ["node-22.2.0.exe", "orchid", "status"],
      },
      {
        rawArgs: ["node-22.2", "orchid", "status"],
        expected: ["node-22.2", "orchid", "status"],
      },
      {
        rawArgs: ["node-22.2.exe", "orchid", "status"],
        expected: ["node-22.2.exe", "orchid", "status"],
      },
      {
        rawArgs: ["/usr/bin/node-22.2.0", "orchid", "status"],
        expected: ["/usr/bin/node-22.2.0", "orchid", "status"],
      },
      {
        rawArgs: ["nodejs", "orchid", "status"],
        expected: ["nodejs", "orchid", "status"],
      },
      {
        rawArgs: ["node-dev", "orchid", "status"],
        expected: ["node", "orchid", "node-dev", "orchid", "status"],
      },
      {
        rawArgs: ["orchid", "status"],
        expected: ["node", "orchid", "status"],
      },
      {
        rawArgs: ["bun", "src/entry.ts", "status"],
        expected: ["bun", "src/entry.ts", "status"],
      },
    ] as const;

    for (const testCase of cases) {
      const parsed = buildParseArgv({
        programName: "orchid",
        rawArgs: [...testCase.rawArgs],
      });
      expect(parsed).toEqual([...testCase.expected]);
    }
  });

  it("builds parse argv from fallback args", () => {
    const fallbackArgv = buildParseArgv({
      programName: "orchid",
      fallbackArgv: ["status"],
    });
    expect(fallbackArgv).toEqual(["node", "orchid", "status"]);
  });

  it("decides when to migrate state", () => {
    const nonMutatingArgv = [
      ["node", "orchid", "status"],
      ["node", "orchid", "health"],
      ["node", "orchid", "sessions"],
      ["node", "orchid", "config", "get", "update"],
      ["node", "orchid", "config", "unset", "update"],
      ["node", "orchid", "models", "list"],
      ["node", "orchid", "models", "status"],
      ["node", "orchid", "memory", "status"],
      ["node", "orchid", "agent", "--message", "hi"],
    ] as const;
    const mutatingArgv = [
      ["node", "orchid", "agents", "list"],
      ["node", "orchid", "message", "send"],
    ] as const;

    for (const argv of nonMutatingArgv) {
      expect(shouldMigrateState([...argv])).toBe(false);
    }
    for (const argv of mutatingArgv) {
      expect(shouldMigrateState([...argv])).toBe(true);
    }
  });

  it.each([
    { path: ["status"], expected: false },
    { path: ["config", "get"], expected: false },
    { path: ["models", "status"], expected: false },
    { path: ["agents", "list"], expected: true },
  ])("reuses command path for migrate state decisions: $path", ({ path, expected }) => {
    expect(shouldMigrateStateFromPath(path)).toBe(expected);
  });
});
