# Final Presentation & Demo Plan

## Slide Outline
1. **Problem Context & Requirements** — Recap course goals (secure SDLC, DevSecOps) and the Secure Online Voting System vision.
2. **Architecture** — Show component diagram, data flow, trust boundaries, and OWASP/NIST mapping.
3. **Security Controls** — Highlight JWT/RBAC, hashing, IaC policies, monitoring stack, and incident response plan.
4. **DevSecOps Pipeline** — Present GitHub Actions workflows, OWASP ZAP/Trivy reports, and IaC validation.
5. **Monitoring & Observability** — Show Prometheus dashboards, Loki log snippets, Falco alerts.
6. **Compliance & Reporting** — Summarize NIST CSF, CIS checks, Zel compliance.
7. **Demo Flow & Next Steps** — Walkthrough (register, login, vote, check logs) + future work.

## Demo Script
1. Start `docker-compose up` to spin up backend + DB.
2. Run frontend dev server, register a voter, and capture JWT token.
3. Cast a vote, explain unique constraint enforcement and audit log entry.
4. Log in as admin (seed via DB) and run `tally` endpoint, show hashed results.
5. Navigate to Grafana dashboard & Loki logs to prove observability.
6. Review GitHub Action log screenshots for CI checks.

## Questions to Prepare
- How does the system handle double voting?
- Where are secrets stored and rotated?
- What happens if Falco detects suspicious behavior?
