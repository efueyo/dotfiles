import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";

type CommandRule = {
  label: string;
  pattern: RegExp;
};

const commandRules: CommandRule[] = [
  { label: "recursive or forced file removal", pattern: /\brm\s+(?:[^\n;&|]*\s)?-(?:[^\s]*r[^\s]*f|[^\s]*f[^\s]*r)\b|\brm\s+[^\n;&|]*--recursive\b/i },
  { label: "privileged command", pattern: /(?:^|[;&|]\s*|\s)sudo\s+/im },
  { label: "world-writable permissions", pattern: /\b(?:chmod|chown)\b[^\n;&|]*\b777\b/i },
  { label: "destructive git reset", pattern: /\bgit\s+(?:-[^\s]+\s+)*reset\s+--hard\b/i },
  { label: "git clean", pattern: /\bgit\s+(?:-[^\s]+\s+)*clean\s+[^\n;&|]*-[^\s]*[fdxX]/i },
  { label: "force push", pattern: /\bgit\s+(?:-[^\s]+\s+)*push\b[^\n;&|]*(?:--force(?:-with-lease)?\b|-f\b)/i },
  { label: "GitHub review or merge", pattern: /\bgh\b[^\n;&|]*\bpr\s+(?:merge|review)\b/i },
  { label: "GitHub mutation", pattern: /\bgh\b[^\n;&|]*\b(?:pr|issue)\s+(?:create|edit|comment|close|reopen|delete)\b/i },
  { label: "Jira mutation", pattern: /\bacli\b[^\n;&|]*\b(?:create|edit|transition|comment|delete|assign|move|update|remove)\b/i },
  {
    label: "Datadog mutation",
    pattern: /\bpup\b[^\n;&|]*\b(?:monitors?|downtimes?|incidents?|dashboards?|synthetics?|users?|teams?|service-accounts?|api-keys?|application-keys?)\s+(?:create|update|edit|delete|cancel|mute|unmute|resolve|archive|restore)\b/i,
  },
  {
    label: "Kubernetes mutation",
    pattern: /\bkubectl\b[^\n;&|]*\b(?:apply|create|delete|patch|edit|replace|scale|annotate|label|taint|drain|cordon|uncordon|exec)\b|\bkubectl\b[^\n;&|]*\brollout\s+restart\b/i,
  },
  { label: "Helm mutation", pattern: /\bhelm\b[^\n;&|]*\b(?:install|upgrade|rollback|uninstall)\b/i },
];

const hardProtectedPath = /(?:^|\/)(?:\.git|node_modules)(?:\/|$)/;
const sensitivePath = /(?:^|\/)(?:\.env(?:\.[^/]*)?|credentials?(?:\.[^/]*)?|secrets?(?:\.[^/]*)?)(?:$|\/)/i;

function normalizePath(path: string): string {
  return path.replace(/^@/, "").replaceAll("\\", "/");
}

async function confirm(
  ctx: ExtensionContext,
  title: string,
  details: string,
): Promise<{ block: true; reason: string } | undefined> {
  if (!ctx.hasUI) {
    return { block: true, reason: `${title} blocked because confirmation UI is unavailable` };
  }

  const allowed = await ctx.ui.confirm(title, details);
  if (!allowed) return { block: true, reason: `${title} rejected by user` };
  return undefined;
}

export default function safetyExtension(pi: ExtensionAPI): void {
  pi.on("tool_call", async (event, ctx) => {
    if (event.toolName === "write" || event.toolName === "edit") {
      const rawPath = (event.input as { path?: unknown }).path;
      if (typeof rawPath !== "string") return;

      const path = normalizePath(rawPath);
      if (hardProtectedPath.test(path)) {
        ctx.ui.notify(`Blocked write to protected path: ${path}`, "warning");
        return { block: true, reason: `Writes to protected path "${path}" are not allowed` };
      }

      if (sensitivePath.test(path)) {
        return confirm(ctx, "Sensitive file write", `Allow ${event.toolName} to modify ${path}?`);
      }
      return;
    }

    if (event.toolName !== "bash") return;
    const command = (event.input as { command?: unknown }).command;
    if (typeof command !== "string") return;

    const matches = [...new Set(commandRules.filter((rule) => rule.pattern.test(command)).map((rule) => rule.label))];
    if (matches.length === 0) return;

    const preview = command.length > 1_200 ? `${command.slice(0, 1_200)}\n…` : command;
    return confirm(ctx, "Potentially destructive command", `${matches.join(", ")}\n\n${preview}`);
  });
}
