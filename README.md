# Claude Code custom configuration

## Commands

### ecpt

> Systematic implementation using Explore-Plan-Code-Test methodology

```bash
> /ecpt "my demand"
```

### debug

> Systematic debugging (repro → hypotheses → minimal fix → tests → verification)

```bash
> /debug "my bug"
```

## MCP servers

### context7

[Website](https://context7.com)

Install:

```bash
$ claude mcp add --transport http context7 https://mcp.context7.com/mcp --header "CONTEXT7_API_KEY: YOUR_API_KEY"
```
