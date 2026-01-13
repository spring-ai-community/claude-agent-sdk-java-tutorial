# Integration Testing Framework

Automated validation for Claude Agent SDK Java Tutorial modules using AI-powered testing.

## Overview

This framework runs each tutorial module and uses Claude (via the SDK itself) to validate that the output demonstrates the expected behavior. It's a pure Java ecosystem - no Python or regex patterns needed.

## Prerequisites

- **Java 21+**
- **JBang** - Lightweight Java script runner
- **Claude CLI** - Must be authenticated

### Install JBang

```bash
curl -Ls https://sh.jbang.dev | bash -s - app setup
```

### Verify Claude CLI

```bash
claude --version
```

## Quick Start

### Run a Single Module

```bash
cd integration-testing
jbang RunIntegrationTest.java module-01-hello-world
```

### Run All Tests

```bash
./integration-testing/scripts/run-integration-tests.sh
```

### List Available Modules

```bash
cd integration-testing
jbang RunIntegrationTest.java --list
```

## Directory Structure

```
integration-testing/
├── RunIntegrationTest.java      # Single JBang entry point
├── jbang-lib/
│   ├── IntegrationTestUtils.java   # Core test utilities
│   └── AIValidator.java            # AI validation using SDK
├── configs/                     # Per-module JSON configs
│   ├── module-01-hello-world.json
│   ├── module-02-query-api.json
│   └── ...
├── scripts/
│   └── run-integration-tests.sh    # Batch runner
├── logs/                        # Test output logs (timestamped)
└── docs/
    └── README.md                # This file
```

## How It Works

1. **Load Config** - Reads `configs/<module-id>.json`
2. **Build Module** - Runs `mvn compile -DskipTests -pl <module>`
3. **Run Module** - Runs `mvn exec:java -pl <module>` with timeout
4. **Capture Output** - Saves console output to timestamped log file
5. **AI Validation** - Uses Claude (Haiku) to analyze if output matches expected behavior
6. **Report Result** - PASS/FAIL with confidence score and reasoning

## Configuration Format

Each module has a JSON config file in `configs/`:

```json
{
  "moduleId": "module-01-hello-world",
  "displayName": "Module 01: Hello World",
  "timeoutSec": 120,
  "requiredEnv": [],
  "expectedBehavior": "Execute Query.text() with a simple math question and display Claude's response containing the answer"
}
```

### Fields

| Field | Required | Description |
|-------|----------|-------------|
| `moduleId` | Yes | Maven module directory name |
| `displayName` | Yes | Human-readable name for reports |
| `timeoutSec` | Yes | Max execution time (120 for simple, 300 for complex) |
| `requiredEnv` | No | Environment variables needed (Claude CLI auth assumed) |
| `expectedBehavior` | Yes | Description of what the module should demonstrate |

## Output Requirements

For AI validation to work well, tutorial modules should produce structured output:

```java
// Header (REQUIRED)
System.out.println("=== Module NN: Topic Name ===\n");

// Progress/interaction (RECOMMENDED)
System.out.println("You: " + question);
System.out.println("Claude: " + response);

// Footer (REQUIRED)
System.out.println("\n=== Done ===");
```

## Cost

AI validation uses Claude Haiku, which is very cost-effective:
- ~$0.001-0.002 per validation
- ~$0.03-0.05 for full test run (24 modules)

## Adding a New Module

1. Create config file: `configs/module-XX-name.json`
2. Ensure module produces structured output (header, content, footer)
3. Test: `jbang RunIntegrationTest.java module-XX-name`

## Troubleshooting

### "Claude CLI not found"

Install with: `npm install -g @anthropic-ai/claude-code`

### "Config not found"

Ensure you're in the `integration-testing` directory when running JBang.

### Build Failures

Check that the module compiles: `mvn compile -pl <module-id>`

### Timeout

Increase `timeoutSec` in the module's config file.

## CI/CD Integration

See `.github/workflows/integration-tests.yml` for GitHub Actions example.

```yaml
- name: Run Integration Tests
  run: ./integration-testing/scripts/run-integration-tests.sh
  env:
    ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
```
