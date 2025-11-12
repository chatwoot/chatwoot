# Migration Diagrams

Visual documentation for the Chatwoot Rails → TypeScript migration.

---

## Available Diagrams

### 1. [Architecture Diagrams](./ARCHITECTURE-DIAGRAM.md)

**What's inside**:
- Current Rails architecture overview
- Target TypeScript/NestJS architecture
- Migration transition state (dual-running)
- Layered architecture pattern
- Module architecture
- Request flow comparison (Rails vs NestJS)
- WebSocket architecture comparison
- Background jobs architecture
- Authentication flow
- Deployment architecture
- Data migration strategy

**Use this when**: You need to understand the overall system architecture, how components interact, or explain the migration approach to stakeholders.

**Key diagrams**:
- Migration transition state showing blue-green deployment
- Side-by-side Rails vs NestJS architecture comparison
- Production deployment topology

---

### 2. [Epic Dependency Graph](./EPIC-DEPENDENCY-GRAPH.md)

**What's inside**:
- Full dependency graph for all 22 epics
- Critical path highlighted
- Parallelization opportunities by phase
- Dependency matrix table
- Team allocation recommendations
- Risk mitigation strategies
- Blockers to watch for
- Milestone checkpoints
- Epic complexity vs risk matrix

**Use this when**: Planning work, allocating resources, understanding which epics can run in parallel, or identifying the critical path.

**Key diagrams**:
- Complete epic dependency graph (Mermaid)
- Critical path visualization (red boxes)
- Parallelization breakdown by phase
- Complexity/risk matrix

---

### 3. [Timeline Gantt Chart](./TIMELINE-GANTT.md)

**What's inside**:
- Full migration timeline (27-31 weeks)
- Optimistic scenario (27 weeks, 4 engineers)
- Realistic scenario (31 weeks, 3 engineers)
- Pessimistic scenario (35 weeks, 2-3 engineers)
- Phase-by-phase breakdown with deliverables
- Cutover timeline detail (Week 24)
- Resource loading chart
- Key dates and milestones

**Use this when**: Creating project schedules, estimating completion dates, planning sprints, or reporting progress to management.

**Key diagrams**:
- Interactive Gantt chart showing all 22 epics
- 3 timeline scenarios (optimistic/realistic/pessimistic)
- Production cutover detail (5% → 100%)
- Engineer resource loading over time

---

### 4. [Data Flow Diagrams](./DATA-FLOW-DIAGRAMS.md)

**What's inside**:
- HTTP request flow (Rails vs NestJS)
- WebSocket flow (ActionCable vs Socket.io)
- Background job flow (Sidekiq vs BullMQ)
- Authentication flow (login, refresh, logout)
- Integration flow (Facebook Messenger example)
- Real-time conversation flow
- Caching strategy flow
- Error handling flow
- Database query optimization examples
- Dual-running architecture during migration

**Use this when**: Debugging issues, understanding data flow, implementing new features, or explaining technical details to the team.

**Key diagrams**:
- Sequence diagrams for request/response flows
- WebSocket message delivery flow
- Background job processing with retry logic
- Complete conversation flow (user → API → DB → Socket → agents)

---

## Quick Reference

### By Use Case

| Need | Diagram File | Section |
|------|-------------|---------|
| Explain migration to stakeholders | ARCHITECTURE-DIAGRAM.md | Migration Transition State |
| Plan sprint work | EPIC-DEPENDENCY-GRAPH.md | Parallelization Opportunities |
| Estimate project timeline | TIMELINE-GANTT.md | Realistic Timeline |
| Understand request flow | DATA-FLOW-DIAGRAMS.md | HTTP Request Flow |
| Debug WebSocket issues | DATA-FLOW-DIAGRAMS.md | WebSocket Flow |
| Plan resource allocation | EPIC-DEPENDENCY-GRAPH.md | Team Allocation Recommendations |
| Report to management | TIMELINE-GANTT.md | Key Dates |
| Understand authentication | DATA-FLOW-DIAGRAMS.md | Authentication Flow |
| Plan deployment | ARCHITECTURE-DIAGRAM.md | Deployment Architecture |
| Identify critical path | EPIC-DEPENDENCY-GRAPH.md | Critical Path |

---

### By Role

#### **Project Manager**
- [Timeline Gantt Chart](./TIMELINE-GANTT.md) - Planning and scheduling
- [Epic Dependency Graph](./EPIC-DEPENDENCY-GRAPH.md) - Resource allocation
- [Architecture Diagram](./ARCHITECTURE-DIAGRAM.md) - Migration strategy

#### **Tech Lead**
- [Architecture Diagram](./ARCHITECTURE-DIAGRAM.md) - System design
- [Data Flow Diagrams](./DATA-FLOW-DIAGRAMS.md) - Technical implementation
- [Epic Dependency Graph](./EPIC-DEPENDENCY-GRAPH.md) - Risk assessment

#### **Software Engineer**
- [Data Flow Diagrams](./DATA-FLOW-DIAGRAMS.md) - Implementation details
- [Architecture Diagram](./ARCHITECTURE-DIAGRAM.md) - Component interaction
- [Epic Dependency Graph](./EPIC-DEPENDENCY-GRAPH.md) - Work dependencies

#### **DevOps Engineer**
- [Architecture Diagram](./ARCHITECTURE-DIAGRAM.md) - Deployment architecture
- [Timeline Gantt Chart](./TIMELINE-GANTT.md) - Cutover timeline
- [Data Flow Diagrams](./DATA-FLOW-DIAGRAMS.md) - Infrastructure flow

#### **QA Engineer**
- [Data Flow Diagrams](./DATA-FLOW-DIAGRAMS.md) - Test scenarios
- [Architecture Diagram](./ARCHITECTURE-DIAGRAM.md) - System boundaries
- [Epic Dependency Graph](./EPIC-DEPENDENCY-GRAPH.md) - Testing phases

---

## Diagram Formats

All diagrams use **Mermaid** syntax for version control and easy editing.

### Viewing Mermaid Diagrams

**Option 1: GitHub**
- GitHub natively renders Mermaid diagrams in markdown files
- Just view the files directly on GitHub

**Option 2: VS Code**
- Install "Markdown Preview Mermaid Support" extension
- Open markdown file and click preview

**Option 3: Online**
- Copy diagram code to [Mermaid Live Editor](https://mermaid.live/)
- Edit and export as PNG/SVG

**Option 4: Documentation Site**
- Most documentation tools (Docusaurus, VitePress, etc.) support Mermaid
- Diagrams render automatically

---

## Diagram Legend

### Colors

- 🔴 **Red**: Critical path, high risk, blockers
- 🟡 **Yellow**: Medium risk, warnings, feature flags
- 🟢 **Green**: Completed, success states, databases
- 🔵 **Blue**: Standard components, processes
- ⚪ **White**: Default state

### Icons

- 📦 **Cylinder**: Database, cache, storage
- 🔷 **Rectangle**: Service, module, component
- 🔶 **Diamond**: Decision point, conditional
- 🎯 **Milestone**: Key checkpoint, deliverable
- ⚡ **Lightning**: Async operation, event
- 🔒 **Lock**: Security, authentication

### Lines

- **Solid line** (→): Synchronous call, direct dependency
- **Dashed line** (⇢): Asynchronous call, event emission
- **Thick line**: Critical path, main flow
- **Thin line**: Secondary flow, optional

---

## Updating Diagrams

### When to Update

Update diagrams when:
- Architecture decisions change
- Epic scope changes
- Timeline adjusts
- Dependencies change
- New flows are introduced

### How to Update

1. Open the relevant `.md` file
2. Find the Mermaid code block (```mermaid)
3. Edit the diagram syntax
4. Test in [Mermaid Live Editor](https://mermaid.live/)
5. Commit changes with descriptive message

### Mermaid Syntax Reference

- [Mermaid Documentation](https://mermaid.js.org/)
- [Flowchart Syntax](https://mermaid.js.org/syntax/flowchart.html)
- [Sequence Diagram Syntax](https://mermaid.js.org/syntax/sequenceDiagram.html)
- [Gantt Chart Syntax](https://mermaid.js.org/syntax/gantt.html)

---

## Diagram Maintenance

### Version History

| Date | Change | Files Updated |
|------|--------|---------------|
| 2024-01-01 | Initial creation | All diagrams |
| TBD | Epic restructure 11→22 | EPIC-DEPENDENCY-GRAPH.md, TIMELINE-GANTT.md |

### Review Schedule

- **Weekly**: Review epic dependencies during sprint planning
- **Bi-weekly**: Update timeline based on actual progress
- **Monthly**: Review architecture diagrams for accuracy
- **After major changes**: Update all affected diagrams immediately

---

## Related Documentation

- [Migration Strategy](../02-migration-strategy.md) - Written description of approach
- [Epic Plans](../epics/) - Detailed epic breakdowns
- [Progress Tracker](../progress-tracker.md) - Live status tracking
- [Architecture Decisions](../ARCHITECTURE.md) - Rationale for tech choices

---

## Examples

### Example 1: Planning Sprint 5

**Goal**: Plan Epic 11 (Authentication) work

**Steps**:
1. Open [EPIC-DEPENDENCY-GRAPH.md](./EPIC-DEPENDENCY-GRAPH.md)
2. Find Epic 11 in dependency graph
3. Check "Depends On" → E03, E07 (must be complete)
4. Check "Blocks" → E14 (integrations depend on auth)
5. Check risk level → VERY HIGH
6. Open [TIMELINE-GANTT.md](./TIMELINE-GANTT.md)
7. See Epic 11 is 2 weeks, requires 1-2 engineers
8. Open [DATA-FLOW-DIAGRAMS.md](./DATA-FLOW-DIAGRAMS.md)
9. Review authentication flow diagrams
10. Plan sprint with 100% test coverage requirement

### Example 2: Explaining Architecture to CEO

**Goal**: Get executive buy-in for migration

**Steps**:
1. Open [ARCHITECTURE-DIAGRAM.md](./ARCHITECTURE-DIAGRAM.md)
2. Show "Migration Transition State" diagram
3. Explain blue-green deployment (zero downtime)
4. Show gradual rollout (5% → 100%)
5. Open [TIMELINE-GANTT.md](./TIMELINE-GANTT.md)
6. Show realistic timeline (31 weeks)
7. Show key milestones
8. Open [EPIC-DEPENDENCY-GRAPH.md](./EPIC-DEPENDENCY-GRAPH.md)
9. Show risk mitigation strategies
10. Explain instant rollback capability

### Example 3: Debugging WebSocket Issues

**Goal**: Fix message delivery problem

**Steps**:
1. Open [DATA-FLOW-DIAGRAMS.md](./DATA-FLOW-DIAGRAMS.md)
2. Go to "WebSocket Flow" section
3. Compare Rails ActionCable vs NestJS Socket.io
4. Review sequence diagram for message delivery
5. Check Redis adapter configuration
6. Review room join/leave logic
7. Open [ARCHITECTURE-DIAGRAM.md](./ARCHITECTURE-DIAGRAM.md)
8. Check WebSocket architecture section
9. Verify Redis Pub/Sub setup
10. Test with diagram as reference

---

## Tips

### Best Practices

✅ **Do**:
- Reference diagrams in PRs and documentation
- Update diagrams when architecture changes
- Use diagrams in sprint planning
- Share diagrams in technical discussions
- Export diagrams for presentations

❌ **Don't**:
- Let diagrams get out of sync with code
- Create diagrams without adding to this directory
- Ignore diagram review schedule
- Skip updating after major changes

### Common Mistakes

1. **Not updating dependencies**: When epic scope changes, update dependency graph
2. **Timeline drift**: Update Gantt chart weekly based on actual progress
3. **Missing new flows**: When adding features, add data flow diagrams
4. **Ignoring legend**: Use consistent colors and symbols

---

## Questions?

- **Architecture questions**: See [ARCHITECTURE.md](../ARCHITECTURE.md)
- **Epic questions**: See [epics/](../epics/) directory
- **Timeline questions**: Check [TIMELINE-GANTT.md](./TIMELINE-GANTT.md)
- **Flow questions**: Check [DATA-FLOW-DIAGRAMS.md](./DATA-FLOW-DIAGRAMS.md)
- **Other questions**: Ask in team channel or check [FAQ.md](../FAQ.md)

