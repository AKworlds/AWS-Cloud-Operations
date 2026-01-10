# Decision 05: Network IP Assignment

## Context

Need consistent internal addressing for automation while maintaining flexibility for scaling and management.

## Options Considered

1. **Dynamic IPs Only** - Simple but unpredictable
2. **Static IPs Only** - Predictable but inflexible
3. **Hybrid Approach** - Static private, dynamic public

## Decision

**Hybrid IP Assignment**

## Implementation

```
┌─────────────────────────────────────────┐
│           VPC: 10.0.0.0/16              │
│  ┌─────────────────────────────────┐    │
│  │    Private Subnet: 10.0.1.0/24  │    │
│  │                                  │    │
│  │    Instance: 10.0.1.100 (static)│    │
│  │    ↓                            │    │
│  │    ENI with Elastic IP          │    │
│  └─────────────────────────────────┘    │
└─────────────────────────────────────────┘
```

### Configuration Details

| Component | Assignment | Rationale |
|-----------|------------|-----------|
| Private IP | Static (10.0.1.100) | Scripts, monitoring, internal DNS |
| Public IP | Elastic IP | External access when needed |
| Security Groups | Instance-attached | Stateful firewall rules |

## Security Groups

```
Inbound:
- SSH (22): Admin CIDR only
- HTTPS (443): VPC CIDR

Outbound:
- HTTPS (443): 0.0.0.0/0 (AWS APIs, updates)
- NTP (123): 0.0.0.0/0 (time sync)
```

## Trade-offs

- Elastic IPs have cost when unattached
- Static IPs require tracking/documentation
- Less flexibility than full dynamic

## Lessons Learned

Predictable addressing enables automation. Worth the small overhead for operational simplicity.
