# Production-Ready AWS Cloud Operations Environment
A secure, compliance-ready AWS environment designed for aerospace CFD simulations. Built to meet ITAR and DFARS requirements while optimizing for high-performance computing workloads.

## Overview
This project demonstrates building AWS infrastructure that balances:
- **Performance**: HPC-optimized compute for CFD simulations
- **Security**: FIPS 140-2 validated encryption, comprehensive audit trails
- **Cost**: 94% reduction in compute costs through proper instance selection
- **Reliability**: Checkpoint system limiting data loss to 30 minutes

## Architecture
```
┌─────────────────────────────────────────────────────────────┐
│                        AWS Cloud                            │
│  ┌─────────────────────────────────────────────────────┐   │
│  │           EC2 (HPC7a.48xlarge)                      │   │
│  │  ┌──────────┬──────────┬──────────────┐            │   │
│  │  │  Root    │  Scratch │  Checkpoint  │            │   │
│  │  │  100GB   │  1000GB  │    500GB     │            │   │
│  │  └──────────┴──────────┴──────────────┘            │   │
│  │         All volumes AES-256 encrypted               │   │
│  └─────────────────────────────────────────────────────┘   │
│                CloudWatch │ KMS │ Systems Manager          │
└─────────────────────────────────────────────────────────────┘
```

## Key Decisions
| Decision | Choice | Rationale |
|----------|--------|-----------|
| [Operating System](decisions/01-operating-system.md) | Amazon Linux 2023 | FIPS 140-2 validated, AWS-optimized |
| [Compute Instance](decisions/02-compute-instance.md) | HPC7a.48xlarge | 94% cost reduction for CFD workloads |
| [Storage Architecture](decisions/03-storage-architecture.md) | Three-volume design | Lifecycle-matched storage reduces costs 80% |
| [Encryption](decisions/04-encryption.md) | AES-256-GCM with KMS | ITAR/DFARS compliance |
| [Network Configuration](decisions/05-network-config.md) | Hybrid IP assignment | Flexibility + consistency |
| [System Services](decisions/06-system-services.md) | Five critical services | Monitoring, security, compliance |

## Results
- Simulation runtime: 48+ hours → 6-8 hours
- Compute cost: $384 → $21 per simulation (94% reduction)
- Maximum data loss on failure: 30 minutes
- Compliance: Full ITAR/DFARS audit trail

## Technologies
- AWS (EC2, EBS, VPC, CloudWatch, KMS, Systems Manager)
- Amazon Linux 2023
- HPC7a instances
- EBS io2 Block Express

## Documentation
- [Lessons Learned](docs/lessons-learned.md)
- [Compliance Notes](docs/compliance-notes.md)

## Screenshots
Configuration screenshots available in `/screenshots`

## Connect
- **Portfolio**: [amadukamara.com](https://amadukamara.com)
- **LinkedIn**: [linkedin.com/in/akmara](https://www.linkedin.com/in/akmara)

---

## Terraform Implementation

This entire environment has been reproduced as Infrastructure as Code using Terraform. Every AWS resource — the VPC, KMS encryption, three-volume storage, IAM roles, CloudWatch monitoring, and EC2 instance — is defined in `.tf` files and deployable with a single command.

**[View the Terraform implementation →](https://github.com/AKworlds/Terraform-Update)**

```bash
terraform init
terraform apply -var-file="terraform.tfvars"
```
