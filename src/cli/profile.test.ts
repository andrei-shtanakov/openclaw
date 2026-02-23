import path from "node:path";
import { describe, expect, it } from "vitest";
import { formatCliCommand } from "./command-format.js";
import { applyCliProfileEnv, parseCliProfileArgs } from "./profile.js";

describe("parseCliProfileArgs", () => {
  it("leaves gateway --dev for subcommands", () => {
    const res = parseCliProfileArgs(["node", "orchid", "gateway", "--dev", "--allow-unconfigured"]);
    if (!res.ok) {
      throw new Error(res.error);
    }
    expect(res.profile).toBeNull();
    expect(res.argv).toEqual(["node", "orchid", "gateway", "--dev", "--allow-unconfigured"]);
  });

  it("still accepts global --dev before subcommand", () => {
    const res = parseCliProfileArgs(["node", "orchid", "--dev", "gateway"]);
    if (!res.ok) {
      throw new Error(res.error);
    }
    expect(res.profile).toBe("dev");
    expect(res.argv).toEqual(["node", "orchid", "gateway"]);
  });

  it("parses --profile value and strips it", () => {
    const res = parseCliProfileArgs(["node", "orchid", "--profile", "work", "status"]);
    if (!res.ok) {
      throw new Error(res.error);
    }
    expect(res.profile).toBe("work");
    expect(res.argv).toEqual(["node", "orchid", "status"]);
  });

  it("rejects missing profile value", () => {
    const res = parseCliProfileArgs(["node", "orchid", "--profile"]);
    expect(res.ok).toBe(false);
  });

  it.each([
    ["--dev first", ["node", "orchid", "--dev", "--profile", "work", "status"]],
    ["--profile first", ["node", "orchid", "--profile", "work", "--dev", "status"]],
  ])("rejects combining --dev with --profile (%s)", (_name, argv) => {
    const res = parseCliProfileArgs(argv);
    expect(res.ok).toBe(false);
  });
});

describe("applyCliProfileEnv", () => {
  it("fills env defaults for dev profile", () => {
    const env: Record<string, string | undefined> = {};
    applyCliProfileEnv({
      profile: "dev",
      env,
      homedir: () => "/home/peter",
    });
    const expectedStateDir = path.join(path.resolve("/home/peter"), ".orchid-dev");
    expect(env.ORCHID_PROFILE).toBe("dev");
    expect(env.ORCHID_STATE_DIR).toBe(expectedStateDir);
    expect(env.ORCHID_CONFIG_PATH).toBe(path.join(expectedStateDir, "orchid.json"));
    expect(env.ORCHID_GATEWAY_PORT).toBe("19001");
  });

  it("does not override explicit env values", () => {
    const env: Record<string, string | undefined> = {
      ORCHID_STATE_DIR: "/custom",
      ORCHID_GATEWAY_PORT: "19099",
    };
    applyCliProfileEnv({
      profile: "dev",
      env,
      homedir: () => "/home/peter",
    });
    expect(env.ORCHID_STATE_DIR).toBe("/custom");
    expect(env.ORCHID_GATEWAY_PORT).toBe("19099");
    expect(env.ORCHID_CONFIG_PATH).toBe(path.join("/custom", "orchid.json"));
  });

  it("uses ORCHID_HOME when deriving profile state dir", () => {
    const env: Record<string, string | undefined> = {
      ORCHID_HOME: "/srv/orchid-home",
      HOME: "/home/other",
    };
    applyCliProfileEnv({
      profile: "work",
      env,
      homedir: () => "/home/fallback",
    });

    const resolvedHome = path.resolve("/srv/orchid-home");
    expect(env.ORCHID_STATE_DIR).toBe(path.join(resolvedHome, ".orchid-work"));
    expect(env.ORCHID_CONFIG_PATH).toBe(path.join(resolvedHome, ".orchid-work", "orchid.json"));
  });
});

describe("formatCliCommand", () => {
  it.each([
    {
      name: "no profile is set",
      cmd: "orchid doctor --fix",
      env: {},
      expected: "orchid doctor --fix",
    },
    {
      name: "profile is default",
      cmd: "orchid doctor --fix",
      env: { ORCHID_PROFILE: "default" },
      expected: "orchid doctor --fix",
    },
    {
      name: "profile is Default (case-insensitive)",
      cmd: "orchid doctor --fix",
      env: { ORCHID_PROFILE: "Default" },
      expected: "orchid doctor --fix",
    },
    {
      name: "profile is invalid",
      cmd: "orchid doctor --fix",
      env: { ORCHID_PROFILE: "bad profile" },
      expected: "orchid doctor --fix",
    },
    {
      name: "--profile is already present",
      cmd: "orchid --profile work doctor --fix",
      env: { ORCHID_PROFILE: "work" },
      expected: "orchid --profile work doctor --fix",
    },
    {
      name: "--dev is already present",
      cmd: "orchid --dev doctor",
      env: { ORCHID_PROFILE: "dev" },
      expected: "orchid --dev doctor",
    },
  ])("returns command unchanged when $name", ({ cmd, env, expected }) => {
    expect(formatCliCommand(cmd, env)).toBe(expected);
  });

  it("inserts --profile flag when profile is set", () => {
    expect(formatCliCommand("orchid doctor --fix", { ORCHID_PROFILE: "work" })).toBe(
      "orchid --profile work doctor --fix",
    );
  });

  it("trims whitespace from profile", () => {
    expect(formatCliCommand("orchid doctor --fix", { ORCHID_PROFILE: "  jborchid  " })).toBe(
      "orchid --profile jborchid doctor --fix",
    );
  });

  it("handles command with no args after orchid", () => {
    expect(formatCliCommand("orchid", { ORCHID_PROFILE: "test" })).toBe("orchid --profile test");
  });

  it("handles pnpm wrapper", () => {
    expect(formatCliCommand("pnpm orchid doctor", { ORCHID_PROFILE: "work" })).toBe(
      "pnpm orchid --profile work doctor",
    );
  });
});
