// Test fixture standing in for `pi --mode json -p`. Not part of the extension manifest.
const args = process.argv.slice(2);
const task = args.at(-1) ?? "";
const emit = (event) => process.stdout.write(`${JSON.stringify(event)}\n`);
const assistant = (content, extra = {}) => emit({
  type: "message_end",
  message: { role: "assistant", content, model: "fake/model", stopReason: "stop", usage: { input: 10, output: 5, cacheRead: 1, cacheWrite: 0, totalTokens: 16, cost: { total: 0.01 } }, ...extra },
});

emit({ type: "session", version: 3 });
if (task.includes("[exit-nonzero]")) { process.stderr.write("fake pi crashed"); process.exit(2); }
if (task.includes("[model-error]")) { assistant([], { stopReason: "error", errorMessage: "rate limited" }); process.exit(0); }
if (task.includes("[hang]")) { assistant([{ type: "text", text: "starting" }]); setInterval(() => {}, 1000); }
else {
  assistant([{ type: "text", text: "Looking around." }, { type: "toolCall", name: "read", arguments: { path: "/tmp/x", content: "y".repeat(500) } }]);
  emit({ type: "message_end", message: { role: "toolResult", content: [{ type: "text", text: "huge tool output ".repeat(1000) }] } });
  // Wait so concurrency tests can observe overlapping children.
  setTimeout(() => {
    assistant([{ type: "text", text: JSON.stringify({ args, env: process.env.PI_SUBAGENT ?? null, cwd: process.cwd() }) }]);
  }, task.includes("[slow]") ? 150 : 0);
}
