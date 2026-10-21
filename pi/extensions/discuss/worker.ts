import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";
import { parseResponse } from "./core.ts";

export default function discussionWorker(pi: ExtensionAPI): void {
  const submitted = new Set<string>();
  const allowed = new Set([
    "read",
    "grep",
    "find",
    "ls",
    "submit_discussion_response",
  ]);
  pi.on("tool_call", event => {
    if (!allowed.has(event.toolName))
      return { block: true, reason: "Discussion workers are read-only." };
  });
  pi.registerTool({
    name: "submit_discussion_response",
    label: "Submit discussion response",
    description:
      "Submit exactly one final response for the assigned discussion turn. An author proposes a complete revision; a reviewer accepts it unconditionally or requests specific changes. Both may request user input. This ends your turn.",
    parameters: Type.Object({
      turnId: Type.String({ minLength: 1, maxLength: 100 }),
      revision: Type.Integer({ minimum: 1, maximum: 20 }),
      decision: Type.Union([
        Type.Literal("propose"),
        Type.Literal("accept"),
        Type.Literal("request_changes"),
        Type.Literal("needs_user_input"),
      ]),
      body: Type.String({
        minLength: 1,
        maxLength: 24_000,
        description:
          "Full proposal or review, including rationale, addressed objection IDs, and unverified assumptions. For needs_user_input, include the precise question.",
      }),
      objections: Type.Array(
        Type.Object({
          id: Type.String({ minLength: 1, maxLength: 80 }),
          text: Type.String({ minLength: 1, maxLength: 2_000 }),
        }),
        {
          maxItems: 30,
          description:
            "Unresolved objections with stable IDs. Must be empty for accept; nonempty for request_changes.",
        },
      ),
    }),
    async execute(_id, params) {
      const response = parseResponse(params);
      if (submitted.has(response.turnId))
        throw new Error("Already submitted this turn");
      if (response.decision === "accept" && response.objections.length)
        throw new Error("Acceptance must have no unresolved objections");
      if (
        response.decision === "request_changes" &&
        response.objections.length === 0
      )
        throw new Error("List specific objections when requesting changes");
      submitted.add(response.turnId);
      return {
        content: [{ type: "text", text: "Response submitted." }],
        details: response,
        terminate: true,
      };
    },
  });
}
