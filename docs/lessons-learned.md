# Lessons Learned

## Key Takeaways from Building Compliance-Ready AWS Infrastructure

### 1. Question "Best Practices" for Your Context

The default recommendation for compute workloads is often general-purpose instances. For CFD simulations, this was wrong. Understanding that CFD is floating-point and memory intensive led to HPC instances and 94% cost savings.

**Takeaway**: Best practices are starting points, not final answers.

### 2. Compliance Doesn't Have to Mean Complexity

Initial assumption was that ITAR/DFARS would require expensive third-party solutions. AWS native tools (KMS, CloudTrail, Inspector) met all requirements without additional complexity.

**Takeaway**: Check what native tools can do before adding complexity.

### 3. Storage is Not One-Size-Fits-All

Single-volume thinking wasted money. Different data has different:
- Performance requirements
- Lifecycle patterns
- Recovery needs

Three-volume architecture saved 80% on storage costs.

**Takeaway**: Match storage to workload characteristics.

### 4. Design for Failure

The checkpoint system was added after a 40-hour simulation crashed at hour 38. Now maximum data loss is 30 minutes regardless of failure type.

**Takeaway**: Ask "what happens when this fails?" during design.

### 5. Document Decisions, Not Just Configurations

Knowing WHAT was configured is less valuable than knowing WHY. Decision records make future modifications safer because the original reasoning is preserved.

**Takeaway**: Future you will thank present you for documenting rationale.

## What I Would Do Differently

1. **Start with workload analysis** - Would have saved weeks of iteration
2. **Implement checkpointing from day one** - Not after the first crash
3. **Use Infrastructure as Code** - Manual setup worked but doesn't scale

## Skills Developed

- AWS service selection and optimization
- HPC workload characteristics
- ITAR/DFARS compliance requirements
- Cost optimization strategies
- Storage architecture design
