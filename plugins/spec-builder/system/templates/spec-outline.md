# <Product Name> Specification

Status: Draft v0.1.0
Last updated: <YYYY-MM-DD>

<!-- This is the specification skeleton. Sections are filled during the draft workflow.
     Structure follows the Symphony pattern: problem → model → behavior → tests → plan. -->

---

## Table of Contents

1. [Problem Statement](#1-problem-statement)
2. [Goals and Non-Goals](#2-goals-and-non-goals)
3. [System Overview](#3-system-overview)
4. [Core Domain Model](#4-core-domain-model)
5. [Feature Specifications](#5-feature-specifications)
6. [Cross-Cutting Concerns](#6-cross-cutting-concerns)
7. [Test Matrix](#7-test-matrix)
8. [Implementation Checklist](#8-implementation-checklist)
9. [Changelog](#9-changelog)

---

## 1. Problem Statement

<!-- What problem does this product solve? Why do existing solutions fall short? -->

## 2. Goals and Non-Goals

### 2.1 Goals

<!-- Measurable, testable objectives. Use active voice. -->

### 2.2 Non-Goals

<!-- Explicit exclusions. "This product does NOT..." -->

## 3. System Overview

### 3.1 Main Components

<!-- High-level component list with one-sentence descriptions. -->

### 3.2 Abstraction Levels

<!-- How the system layers: policy → configuration → coordination → execution → integration. -->

### 3.3 External Dependencies

<!-- What external systems, services, or tools does this depend on? -->

## 4. Core Domain Model

### 4.1 Entities

<!-- One subsection per entity. Fields, types, constraints. -->

### 4.2 Relationships

<!-- How entities connect. Cardinality, lifecycle coupling. -->

### 4.3 State Machines

<!-- State diagrams for stateful entities. States, transitions, triggers, guards. -->

### 4.4 Stable Identifiers and Normalization Rules

<!-- How entities are identified. Naming conventions. Uniqueness constraints. -->

## 5. Feature Specifications

<!-- One top-level subsection per major feature area.
     Each feature section includes: behavior, state machines (if any),
     protocols/interfaces, error handling, configuration. -->

### 5.1 <Feature Area 1>

#### 5.1.1 Behavior
#### 5.1.2 Protocols and Interfaces
#### 5.1.3 Error Handling
#### 5.1.4 Configuration

## 6. Cross-Cutting Concerns

### 6.1 Authentication and Authorization
### 6.2 Observability
### 6.3 Configuration Management
### 6.4 Error Handling Philosophy

## 7. Test Matrix

### 7.1 Unit Test Requirements

<!-- Pure logic, no I/O, fast (<100ms). -->

### 7.2 Integration Test Requirements

<!-- Multi-component, real dependencies. -->

### 7.3 System Test Requirements

<!-- End-to-end flows. -->

| Requirement | Spec Section | Test Level | Test Description | Priority |
|-------------|-------------|-----------|-----------------|----------|
| | | | | |

## 8. Implementation Checklist

<!-- Ordered by dependency. Each item references a spec section. -->

### Phase 1: Foundation

- [ ] 1.1 <item> (Section X.Y) — Deps: none — Complexity: small

### Phase 2: Core

- [ ] 2.1 <item> (Section X.Y) — Deps: 1.1 — Complexity: medium

## 9. Changelog

| Version | Date | Changes |
|---------|------|---------|
| 0.1.0 | <date> | Initial structure |
