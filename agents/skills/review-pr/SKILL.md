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

Keep the response focused on the decision. If no comments are warranted, say so.
State material limits on your recommendation.

Review only. Do not modify code, post comments, or submit a review unless I
explicitly ask.
