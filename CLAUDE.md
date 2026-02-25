# Claude Agent SDK Java Tutorial - Claude Code Instructions

## CRITICAL: Running Claude CLI Subprocesses from Claude Code

Claude Code 2.1.39+ blocks nested `claude` invocations via process tree detection. Any command that spawns `claude` CLI as a subprocess will fail silently with empty output.

**Use `~/scripts/claude-run.sh`** to run builds that invoke Claude CLI:
```bash
~/scripts/claude-run.sh ./mvnw test -pl some-module -Dtest="SomeIT"
```
The script uses `systemd-run` to escape the process tree. Works for Maven/Gradle builds where claude is invoked indirectly via the SDK. See `~/scripts/claude-run.sh` for details.

## CRITICAL: Agent Workflow (MANDATORY)

**DO NOT write tutorial content without using the agents.** This is not optional.

### Pre-Flight Checklist

Before writing ANY module content:

- [ ] Have I spawned the `technical-writer` agent? (REQUIRED before writing)
- [ ] Have I spawned the `code-sample-adapter` agent? (REQUIRED if converting code)
- [ ] Have I spawned the `doc-reviewer` agent? (REQUIRED before marking complete)

If you cannot check all applicable boxes, STOP and use the agents first.

### Agent Invocation

```
Task tool → subagent_type=general-purpose
Prompt: "You are the [agent-name] agent. Read ~/.claude/agents/[agent-name].md for your guidelines..."
```

---

## Java SDK API Architecture

This is a **generic Java SDK**, not Spring-specific. Avoid over-emphasizing Spring.

### Three APIs with Feature Parity

| API | Class | Factory | Programming Style |
|-----|-------|---------|-------------------|
| **One-shot** | `Query` | Static methods | Blocking, simple |
| **Blocking** | `ClaudeSyncClient` | `ClaudeClient.sync()` | Iterator-based |
| **Reactive** | `ClaudeAsyncClient` | `ClaudeClient.async()` | Flux/Mono |

**Both `ClaudeSyncClient` and `ClaudeAsyncClient` support the SAME features:**
- Multi-turn conversations
- Hooks (PreToolUse, PostToolUse)
- MCP server integration
- Permission callbacks

They differ ONLY in programming paradigm (blocking vs non-blocking).

### Deleted APIs (DO NOT USE)

- ~~`ReactiveQuery`~~ → Use `ClaudeAsyncClient`
- ~~`ClaudeSession`~~ / ~~`DefaultClaudeSession`~~ → Use `ClaudeSyncClient`
- ~~`CLITransport`~~ / ~~`ReactiveTransport`~~ → Internal, use clients

### Tutorial Code Guidelines

1. **Modules 01-02**: Use `Query` (one-shot API)
2. **Module 03**: Introduces `ClaudeSyncClient` (blocking multi-turn)
3. **Module 04**: Introduces `ClaudeAsyncClient` (reactive multi-turn with TurnSpec)
4. **Modules 05-09**: Configuration options (use sync client for simplicity)
5. **Modules 10-13**: Sessions & async patterns (show appropriate client for topic)
6. **Favor simplicity** - blocking API is more accessible for beginners
7. **Avoid Spring framing** - this SDK works with any Java application

### CRITICAL: Show Both Paradigms Equivalently

**Never imply one client has features the other lacks.** When documenting capabilities:

- Use `<Tabs>` with "Blocking" and "Reactive" tabs
- Show the SAME functionality in both paradigms
- Don't segregate features by client type

**Wrong:**
```
### Multi-Turn Conversation (sync)
### Reactive Streaming (async)
```
This falsely implies async can't do multi-turn!

**Correct:**
```
### Multi-Turn Conversation
<Tabs>
  <Tab title="Blocking">ClaudeSyncClient example</Tab>
  <Tab title="Reactive">ClaudeAsyncClient doing the SAME thing</Tab>
</Tabs>
```

### CRITICAL: Sync vs Async Client Positioning

- **Sync client**: blocking, simple sequential code
- **Async client**: reactive, composable, non-blocking chains

**Sync pattern:**
```java
try (ClaudeSyncClient client = ClaudeClient.sync()...) {
    String r1 = client.connectText("Hello");
    String r2 = client.queryText("Follow up");
}
```

**Async pattern (TurnSpec with flatMap):**
```java
client.connect("Hello").text()
    .flatMap(r1 -> client.query("Follow up").text())
    .doOnSuccess(System.out::println)
    .subscribe();  // Non-blocking
```

**TurnSpec methods:**
- `.text()` → `Mono<String>` - collected text, enables flatMap chaining
- `.textStream()` → `Flux<String>` - streaming text
- `.messages()` → `Flux<Message>` - all message types

**Reactive examples should:**
- Use `.subscribe()` (non-blocking), avoid `.block()`
- NO `doFinally` cleanup noise - client lifecycle is separate from request lifecycle

### CRITICAL: Example Quality Standards

**DO NOT write incomplete examples.** Every code sample must be:

1. **Complete and runnable** - No `// process response here` stubs
2. **Self-contained** - Show helper methods inline, not as "exercise for the reader"
3. **Easy to grok** - Reader should understand what's happening without guessing

**Bad Example:**
```java
client.connect("Hello");
printResponse(client);  // ← What does this do? Mystery!
```

**Good Example:**
```java
client.connect("Hello");
Iterator<ParsedMessage> response = client.receiveResponse();
while (response.hasNext()) {
    ParsedMessage msg = response.next();
    if (msg.isRegularMessage() && msg.asMessage() instanceof AssistantMessage am) {
        am.getTextContent().ifPresent(System.out::println);
    }
}
```

### CRITICAL: Spring WebFlux Warning

**NEVER mention "Spring WebFlux"** unless the tutorial specifically covers web tier integration.

- This is a generic Java SDK, not Spring-specific
- Spring users are a subset; non-Spring users shouldn't be alienated
- The reactive API (ClaudeAsyncClient) uses Project Reactor, which works anywhere
- Spring WebFlux can be a "Use Case" section in a dedicated module, not a default framing

---

## Code Verification

All code must compile:
```bash
mvn compile                      # Build all modules
mvn compile -pl doc-fragments -q # Verify doc code samples
```

## Module Structure

Each module should have:
- `pom.xml` - Maven build file
- `src/main/java/.../Example.java` - Standalone, runnable code (~50-100 lines)

## Key Files

| File | Purpose |
|------|---------|
| `~/community/mintlify-docs/plans/java-sdk-docs-plan.md` | Master plan |
| `doc-fragments/` | Compilable code fragments for docs |
| `~/.claude/agents/*.md` | Writing agent definitions |
