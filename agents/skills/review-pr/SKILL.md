---
name: review-pr
description: Review a GitHub PR from just its number. Explain what it does, recommend whether to approve or leave comments, and draft worthwhile suggestions or implementation-gap comments.
---

# Review PR

Usage in pi: `/skill:review-pr <PR_NUMBER>`

Infer the repository from the current checkout. Follow its instructions and use
applicable review skills for the review process.

Help me decide:

1. What does this PR do, and what does it not change?
2. Should I approve it, approve with non-blocking suggestions, or withhold approval?
   Explain why.
3. What comments, if any, are worth leaving? Draft actionable comments about
   suggestions, improvements, or implementation gaps. Account for existing feedback
   so I don't repeat comments already made.

## Review beyond defects

Review correctness and security, then make a separate pass for behavioral
contracts, design complexity, asynchronous lifecycle, and test value. Do not
equate “no proven runtime bug” with “no worthwhile feedback.” Follow repository
rules; distinguish substantive design feedback from style preferences.

- **Behavioral contract:** Identify the intended outcome and eligibility rules.
  Challenge changed state allowlists, timing windows, and exclusions against that
  outcome. Tests and comments establish what is deliberate, not whether it
  satisfies the required outcome. Distinguish documented intent from inferred
  intent.
- **Design:** Check whether added wrappers, callbacks, state flags, and duplicated
  orchestration are necessary. Raise simplification suggestions only when you can
  name a concrete maintenance benefit and a viable simpler approach.
- **Async lifecycle:** For detached work, identify ownership, retry duration,
  error handling, cancellation, and shutdown behavior. Inspect the actual API
  before asserting latency or leaks. Distinguish scheduling retries from retries
  of the scheduled work.
- **Tests:** Identify the application regression each new test catches.
  Distinguish useful integration coverage from assertions of framework internals,
  incidental logs, or implementation structure. Do not dismiss integration tests
  merely because they exercise a framework.

Keep confirmed defects, non-blocking recommendations, and unresolved intent
questions distinct. A question must identify the specific behavioral ambiguity
and why resolving it matters. Do not manufacture comments to fill categories.
Apply these review dimensions to delegated reviews too, rather than asking only
for concrete bugs.

Respect requests for blind review. Otherwise, inspect existing feedback after
the independent pass to avoid duplication. Do not treat existing feedback as
automatically correct.

## Recommendation

Keep the response focused on the decision. If no comments are warranted, say so.
Before recommending approval, assess whether an unresolved contract question
materially limits confidence. Distinguish “no defects found” from an assessment
that also covers design and test quality. State material limits on your
recommendation, including dimensions you could not evaluate.

Review only. Do not modify code, post comments, or submit a review unless I
explicitly ask.
