# Pro-Like Deliberation

`pro-like-deliberation` is a Codex skill overlay for users who want slower, clearer, and more defensive reasoning on demand.

It does not change the underlying model. It changes the workflow shape of the answer: more explicit framing, stronger assumption handling, clearer failure-mode thinking, and a visible separation between what is verified and what is inferred.

## What It Changes

When you invoke this skill explicitly, it pushes the model toward a more deliberate decision-making pattern.

In practice, that means it changes the answer in these ways:

- It frames the real task before jumping to a conclusion.
- It surfaces missing constraints and decision-critical assumptions.
- It compares materially different options when ambiguity matters.
- It forces a live disconfirming check instead of only building a case for the chosen answer.
- It separates verified facts from judgment and inference.
- It ends with a practical next check instead of a false sense of certainty.

For high-stakes or ambiguous prompts, that usually produces a more auditable answer shape than a normal fast-path response.

## What It Does Not Change

This skill is intentionally narrow about what it claims.

It does **not**:

- turn Codex into a true Pro model
- upgrade the underlying model family
- unlock hidden reasoning budget, hidden compute, or parallel test-time compute
- guarantee better answers on every prompt
- add automatic complex-task activation
- guarantee host-side implicit routing

This repository packages a workflow overlay, not a model capability upgrade.

## Invocation Model

The supported contract is **explicit invocation**.

Use it when you want the model to reason more carefully than usual, for example:

- a durable product or engineering decision
- a risky tradeoff with incomplete information
- a review where weak assumptions could cause bad downstream choices
- a comparison where the strongest failure reason matters as much as the recommendation

Typical invocation forms:

- `Use $pro-like-deliberation to assess whether we should ship this change next week.`
- `用 $pro-like-deliberation 帮我判断这个方案是否值得做。`
- `Use $pro-like-deliberation and answer with Decision / Assumptions / Disconfirmers / Verified vs inferred / Next check.`

Unsupported contract:

- automatic complex-task activation
- implicit routing promises
- “install it and it will silently take over all hard prompts”

## Compatibility And Precedence

This skill is an overlay, not a replacement.

Recommended precedence:

1. direct user instructions
2. project-local rules such as `AGENTS.md`
3. narrower domain or process skills
4. `pro-like-deliberation`

That means you should still defer to narrower skills when they are the real source of truth.

Examples:

- OpenAI API guidance should still defer to a narrower OpenAI-docs workflow.
- Debugging work should still use a dedicated debugging workflow.
- TDD, review, and source-verification requirements should still be honored.

The goal is not to flatten every task into one generic “think harder” mode. The goal is to add a stronger reasoning shell where it helps.

## Heavy Path

On a complex or high-stakes prompt, the heavy path aims to make the reasoning process more inspectable.

It pushes the answer through four stages:

1. qualify and frame the real decision
2. compare alternatives and name likely failure points
3. stress the current view with a live disconfirming check
4. close with verified-versus-inferred separation and a next step

This path is meant for cases where a fast answer could sound confident while still skipping important uncertainty.

## Lightweight Path

Not every prompt needs ceremony.

If the prompt is routine and you invoke the skill anyway, the lightweight path keeps the answer direct:

- answer the request
- avoid ritualized scaffolding
- stay shorter than the heavy path
- do not force alternatives when they add no value

So the same skill can support both:

- a full, explicit decision memo on a hard judgment call
- a short rewrite or tightening pass on a simple sentence

## Response Contract

When the task warrants the heavy path, the preferred visible contract is:

- `Decision`
- `Assumptions`
- `Disconfirmers`
- `Verified vs inferred`
- `Next check`

That structure is the main behavioral signature of this skill.

Why it matters:

- `Decision` prevents endless hedging
- `Assumptions` makes hidden premises visible
- `Disconfirmers` forces the answer to confront what could invalidate it
- `Verified vs inferred` reduces the risk of presenting judgment as fact
- `Next check` turns uncertainty into an actionable follow-up

## Installation

This repository is meant to be copied into a Codex skill directory.

Typical install shape:

1. create a skill folder named `pro-like-deliberation`
2. copy `SKILL.md`, `templates.md`, and `agents/openai.yaml` into that folder
3. keep `README.md` and `LICENSE` with the repo for documentation and distribution

Example destination:

- `${CODEX_HOME:-$HOME/.codex}/skills/pro-like-deliberation`

If your environment already uses a different Codex skill root, keep the folder name `pro-like-deliberation` and preserve the relative path `agents/openai.yaml`.

## Usage Examples

English:

- `Use $pro-like-deliberation to decide whether we should replace service A with service B next month.`
- `Use $pro-like-deliberation to compare these two architecture options before recommending one.`
- `Use $pro-like-deliberation and tell me the strongest reason your recommendation could be wrong.`

Chinese:

- `用 $pro-like-deliberation 帮我判断这个上线方案该不该过。`
- `用 $pro-like-deliberation 比较这两个商业方案，并说明最可能失败的点。`
- `用 $pro-like-deliberation 先区分已验证事实和推断，再给结论。`

Good fit:

- roadmap decisions
- architecture choices
- go/no-go launches
- risk reviews
- high-stakes comparisons

Less useful:

- trivial formatting tasks
- simple factual lookups that already have a narrower source-of-truth skill
- cases where the user explicitly wants the shortest possible answer and no extra reasoning shell

## Validation Status

This package is documented and distributed as an **explicit-invocation-only** skill.

Current validated boundaries:

- local package structure validates successfully
- the skill is packaged for explicit `$pro-like-deliberation` usage
- this repository does not claim auto-trigger support
- this repository does not claim any hidden model upgrade

What this status does **not** prove:

- universal host-side implicit routing
- automatic activation on all difficult prompts
- parity with proprietary Pro-tier model variants

That boundary is intentional. This project is trying to improve reasoning discipline, not to overstate what a local skill file can do.

## License

This project is released under the `MIT` license.

Contribution baseline:

- preserve the explicit-invocation-only contract
- do not add true-Pro, hidden-compute, or auto-trigger marketing claims
- keep changes falsifiable and easy to verify

