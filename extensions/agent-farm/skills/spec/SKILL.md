---
name: spec
description: Create a formal product specification. Use when gathering requirements to draft a formal Product Specification (spec) with requirements and acceptance criteria in a GitHub Issue.
---

# Create a Product Spec

## Instructions

1. **Understand Requirements:** Ensure you have enough context from the user to define the feature, its requirements, and testable acceptance criteria.
2. **Agentic Clarity:** Downstream autonomous agents (`tpm`, `engineer`, `qa`) will read this spec. You MUST write deterministic, measurable requirements.
   - Avoid ambiguous verbs like "handle", "manage", or "support". Use precise actions ("export function X", "render button Y").
   - Make zero assumptions. If a specific library or framework should be used, name it explicitly.
   - Acceptance Criteria must be testable boundaries (e.g., "Given X, when Y, then Z happens").
3. **Format the Spec:** Use the Markdown template below. It is **mandatory** to use `- [ ]` checkboxes for the Requirements and Acceptance Criteria sections.
4. **Publish to GitHub Issues:**
   - If an issue does not exist, create a new one using `mcp_github_create_issue` with the generated spec as the body.
   - If the issue exists, update it using `mcp_github_update_issue`.
   - **Do not write the spec to local files.** The GitHub Issue is the single source of truth.

## Spec Template

```markdown

## 📝 Product Specification

**Title:** [Feature Title]
**Type:** [Feature | Bug | Enhancement]
**Priority:** [P1 | P2 | P3]
**Requested By:** [Product Owner / User]

### 🎯 Problem Statement
[Describe the problem or need based on the user's input]

### ✅ Requirements
- [ ] Requirement 1: [Description]
- [ ] Requirement 2: [Description]

### 🧪 Acceptance Criteria
- [ ] Criteria 1: [Measurable condition]
- [ ] Criteria 2: [Measurable condition]

### 🚫 Out of Scope
- [Explicitly excluded item]

### 🔗 Dependencies
- [List any dependencies on other features or issues]
```