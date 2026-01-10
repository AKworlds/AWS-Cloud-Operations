# Decision 02: Compute Instance Selection

## Context

CFD simulations were running on general-purpose instances (m5.24xlarge), taking 48+ hours per simulation at $384 per run.

## Options Considered

1. **m5.24xlarge** - Current general-purpose instance
2. **c5.24xlarge** - Compute-optimized
3. **hpc7a.48xlarge** - HPC-optimized with AMD EPYC

## Decision

**HPC7a.48xlarge**

## Rationale

- **Architecture**: AMD EPYC 4th Gen processors optimized for tightly-coupled workloads
- **Network**: 300 Gbps EFA for inter-node communication
- **Performance**: CFD simulations reduced from 48+ hours to 6-8 hours
- **Cost Efficiency**: $21 per simulation vs $384 (94% reduction)

## Cost Analysis

| Instance | vCPUs | Runtime | Cost/Hour | Total Cost |
|----------|-------|---------|-----------|------------|
| m5.24xlarge | 96 | 48 hrs | $8.00 | $384 |
| hpc7a.48xlarge | 192 | 6-8 hrs | $3.50 | ~$21 |

## Trade-offs

- Limited availability (specific regions/AZs)
- Requires placement groups for multi-node
- Newer instance family, less documentation

## Lessons Learned

General-purpose instances aren't always the safe choice. Understanding workload characteristics (CFD = floating-point intensive, memory-bound) led to significant savings.
