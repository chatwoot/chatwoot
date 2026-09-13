# Ask prompt composition

`Captain::Apropos::Prompt` owns the ordered composition of Liquid fragments in
`enterprise/app/views/captain/apropos/prompts/`. Prompts teach the execution model
before role responsibilities and operational contracts. Tool access is unchanged.

## Roles

- Coordinator and delegated workers: shared foundation, role, planning, data semantics,
  language, retrieval, reasoning, library, actions, recovery, workspace, and coverage.
- Query specialist: shared foundation and data semantics, then its retrieval contract,
  WootQL reference, and live typed resource schema.
- Tool-free reasoning: shared foundation, then the bounded reasoning role. No tools
  or parent history are supplied, even though the prompt explains neighboring roles.
- Execution/query errors: focused recovery fragments, consistent with the standing policy.

`Prompt::PARTS` is the single ordering manifest. `Prompt.parts(role, variables)`
returns named rendered fragments for inspection; `Prompt.render` joins those same
fragments. Liquid parsing/rendering is strict: missing files or variables fail rather
than silently dropping instructions. Templates are server-owned and do not evaluate
Liquid contained in user data or query schema values.
Rendering follows [Liquid's strict variable and filter handling](https://github.com/Shopify/liquid#undefined-variables-and-filters).

## Context and handoffs

The coordinator receives task, input, and run_context as JSON. The query specialist
receives retrieval_request and run_context. Context contains account ID, UTC time,
remaining shared agent/query calls, and delegation depth. These are invocation-start
snapshots, not per-tool-call updates. Histories and workspace contents are not copied
to the query specialist. A delegated worker receives its explicit task/input as before.

For query handoffs, the coordinator is instructed to distinguish Objective, Retrieve,
and Downstream inside the existing request string. This is guidance, not a new parser
or compulsory workflow. The specialist executes the retrieval contract while knowing
why Scheme needs the rows. It must explain unsupported retrievals rather than silently
substituting a different dataset.

Exact callable contracts still belong to the catalog, core primitive registry, result
schema, and tool definitions. The shared prompts explain responsibilities and costs;
they do not duplicate the full capability catalog into every role.

## Updating prompts

Edit the relevant fragment rather than adding another rule to a service heredoc.
Keep shared facts in shared fragments and tool recovery consistent with standing guidance.
Check every role's rendered composition, including strict variable substitution.
New invocations read current templates; an already-running model invocation is not
retroactively updated. There is no conversation-level prompt freeze or new prompt UI.
