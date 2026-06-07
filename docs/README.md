# Docs

Architecture diagrams and explanations of how the IDP works end-to-end.

## Files

- **e2e-architecture.md** — Full diagram showing every step from engineer request to running service, including how it maps to real tools and on-prem equivalents.
- **demo.gif** — (generated) Terminal recording of the full demo flow.

## How to Generate the GIF

Run the demo script and record it:

```bash
# Using asciinema + agg
asciinema rec demo.cast
./demo.sh
agg demo.cast docs/demo.gif

# Or using terminalizer
terminalizer record demo
terminalizer render demo -o docs/demo.gif
```

Place the generated `demo.gif` in this folder and it will show up in the main README.

## Key Concepts Explained Here

- How the request pipeline flows from engineer to infrastructure
- Why every service gets the same architecture (golden path)
- How resilience is built in (multi-AZ, health checks, auto-replacement)
- How the same workflow applies to cloud and on-prem targets
