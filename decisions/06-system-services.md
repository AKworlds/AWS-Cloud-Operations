# Decision 06: System Services Configuration

## Context

Need monitoring, management, and compliance verification without installing heavy agents or third-party tools.

## Options Considered

1. **Third-party Monitoring Stack** - Feature-rich but complex
2. **Open Source Tools** - Flexible but maintenance overhead
3. **AWS Native Services** - Integrated but AWS-specific

## Decision

**Five AWS Native Services**

## Service Configuration

### 1. CloudWatch Agent
**Purpose**: System metrics and custom application logs

```yaml
Metrics Collected:
  - CPU utilization (per-core)
  - Memory usage
  - Disk I/O (per-volume)
  - Network throughput

Log Groups:
  - /var/log/messages
  - /var/log/simulation/*.log
```

### 2. Systems Manager Agent
**Purpose**: Patch management, remote access, automation

- No SSH bastion needed
- Session logging to S3
- Automated patching windows

### 3. CloudWatch Alarms
**Purpose**: Proactive alerting

| Alarm | Threshold | Action |
|-------|-----------|--------|
| CPU > 95% | 5 min | SNS notification |
| Disk > 85% | 1 min | SNS + auto-cleanup |
| Memory > 90% | 5 min | SNS notification |

### 4. AWS Inspector
**Purpose**: Vulnerability scanning

- Weekly automated scans
- CVE database checks
- Compliance benchmarks

### 5. Checkpoint Service (Custom)
**Purpose**: Simulation state preservation

```bash
# Cron job every 30 minutes
*/30 * * * * /opt/scripts/checkpoint.sh
```

Limits maximum data loss to 30 minutes on any failure.

## Trade-offs

- AWS lock-in for monitoring
- Learning curve for CloudWatch Insights
- Some advanced features require additional cost

## Lessons Learned

Native tools reduce integration complexity. The overhead of managing separate monitoring infrastructure wasn't worth it for this workload.
