# Decision 03: Storage Architecture

## Context

Single-volume approach was inefficient - paying for high IOPS on data that didn't need it, and risking data loss on simulation failures.

## Options Considered

1. **Single Large Volume** - Simple but expensive
2. **Two Volumes** - OS + Data separation
3. **Three Volumes** - Lifecycle-matched storage

## Decision

**Three-Volume Design**

```
┌──────────────────────────────────────────────────────┐
│                    EC2 Instance                       │
│  ┌────────────┬────────────────┬──────────────────┐  │
│  │   Root     │    Scratch     │   Checkpoint     │  │
│  │  100 GB    │   1000 GB      │    500 GB        │  │
│  │  gp3       │   io2 Block    │     gp3          │  │
│  │            │   Express      │                  │  │
│  └────────────┴────────────────┴──────────────────┘  │
└──────────────────────────────────────────────────────┘
```

## Volume Specifications

| Volume | Size | Type | IOPS | Purpose |
|--------|------|------|------|---------|
| Root | 100 GB | gp3 | 3,000 | OS, applications |
| Scratch | 1000 GB | io2 Block Express | 64,000 | Active simulation data |
| Checkpoint | 500 GB | gp3 | 3,000 | Recovery snapshots |

## Rationale

- **Root**: Baseline performance sufficient for OS operations
- **Scratch**: High IOPS needed only during active computation
- **Checkpoint**: Moderate performance for periodic saves

## Cost Impact

80% storage cost reduction by matching storage performance to actual needs rather than over-provisioning everything.

## Lessons Learned

Storage isn't one-size-fits-all. Different data has different performance requirements and lifecycles.
