// RPC transport fixture: prompt preflight delays acceptance while abort reports idle.
let buffer = "";
const emit = record => process.stdout.write(JSON.stringify(record) + "\n");
process.stdin.on("data", chunk => {
  buffer += chunk.toString();
  const lines = buffer.split("\n");
  buffer = lines.pop() ?? "";
  for (const line of lines) {
    const command = JSON.parse(line);
    const respond = data => emit({ type: "response", id: command.id, command: command.type, success: true, data });
    if (command.type === "get_state") respond({ isStreaming: false });
    else if (command.type === "prompt") {
      // Signal the test that prompt preflight has begun, without acknowledging it.
      emit({ type: "agent_start" });
      setTimeout(() => {
        respond({ disposition: "started" });
        emit({ type: "agent_settled" });
      }, 2000);
    } else if (command.type === "abort") respond();
    else if (command.type === "get_messages") respond({ messages: [] });
  }
});
process.stdin.on("end", () => process.exit(0));
