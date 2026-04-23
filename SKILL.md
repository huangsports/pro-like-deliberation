---
name: pro-like-deliberation
description: Use when the user explicitly invokes `$pro-like-deliberation` or explicitly asks for slower, deeper, or more defensive reasoning on a task that benefits from visible framing, assumption management, and verified-versus-inferred separation.
---

# Pro-Like Deliberation

## Overview

This skill is a Pro-like deliberation overlay. It improves the workflow shape of reasoning, not the underlying model, hidden reasoning budget, or compute allocation.

Use it to make reasoning slower, more explicit, and more defensible when the user intentionally wants that behavior.

Do not present it as:
- a true Pro mode
- a model upgrade
- a hidden reasoning unlock

## Compatibility And Precedence

This skill is an overlay, not a replacement.

Always respect this order:
1. Direct user instructions
2. Project-local rules such as `AGENTS.md`
3. Narrower domain or process skills
4. This deliberation overlay

If a narrower skill is clearly more specific, defer to it and layer this skill only where it adds value.

Do not suppress required workflows such as:
- brainstorming
- TDD
- debugging
- review
- required browsing or source verification

## Invocation

Supported entry paths:

1. the user explicitly invokes `$pro-like-deliberation`
2. the user explicitly asks for slower, deeper, more rigorous, or more defensive reasoning

Not part of the supported contract:

1. automatic complex-task activation
2. host-side implicit routing
3. local-installation-only assumptions about silent skill loading

## Heavy Path

### Stage 1: Qualify And Frame

1. State the actual task and success condition.
2. Surface missing constraints or assumptions that matter.
3. Decide whether full deliberation is warranted.

### Stage 2: Compare Alternatives

1. Compare materially distinct options when ambiguity matters.
2. State the strongest reason each option could fail.
3. Name the strongest live disconfirming consideration under a `Disconfirmers` heading.
4. Choose a current working direction and explain why.

### Stage 3: Stress The Working View

Check for:
- scope mistakes
- unverified claims
- missing edge cases
- whether a different expert lens changes the conclusion
- what evidence would invalidate the current view

### Stage 4: Close Carefully

1. Distinguish verified facts from inferred judgment.
2. Disclose residual uncertainty, limits, or next checks when needed.
3. Avoid presenting inference as direct observation.

## Response Contract

### Heavy path

Expose, in compact form:
- `Decision`
- `Assumptions`
- `Disconfirmers`
- `Verified vs inferred`
- `Next check`

When the task is materially ambiguous or high-stakes, prefer those exact headings so the deliberation contract is observable and auditable.

### Lightweight path

Keep it direct:
- answer the request
- do not add ritualized scaffolding
- do not force alternatives when they add no value
- stay noticeably shorter than the heavy path

## Red Flags

If you notice these patterns, slow down:
- you are about to answer a durable decision from weak context
- you are treating an inference as if it were verified
- you are skipping uncertainty because the answer sounds fluent
- you are adding ceremony to a routine prompt

## Default Behavior

When explicitly invoked on a complex task, bias toward:
- clearer framing
- stronger assumption management
- explicit failure-mode thinking
- visible verified-versus-inferred separation

When explicitly invoked on a routine task, bias toward:
- brevity
- directness
- minimal ceremony

