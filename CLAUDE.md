# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Cilium is a CNCF Graduated project providing eBPF-based networking, observability, and security for cloud-native environments. It replaces traditional iptables-based networking with high-performance eBPF programs for Kubernetes clusters.

## Essential Commands

### Building
```bash
make build                    # Build all Cilium components
make debug                    # Build with debug symbols (no optimization)
make docker-cilium-image      # Build cilium-agent container image
make docker-operator-image    # Build cilium-operator container image
```

### Development (Kind-based workflow)
```bash
make kind                     # Create Kind cluster for development
make kind-image-fast          # Fast build and load images into Kind (Linux only with volume mounts)
make kind-install-cilium-fast # Quick install Cilium into Kind cluster
```

### Testing
```bash
make tests-privileged         # Run all tests including privileged ones
make integration-tests        # Run integration tests
make run_bpf_tests           # Run eBPF unit tests
go test ./pkg/...            # Run unit tests for specific packages
```

### Code Quality
```bash
make lint                     # Run all linters (golangci-lint + custom checks)
make precheck                 # Pre-commit checks (formatting, style)
make postcheck               # Post-build checks (docs, cmdref updates)
```

### Code Generation
```bash
make generate-api            # Generate OpenAPI client/server code
make generate-k8s-api        # Generate Kubernetes API code
make generate-bpf            # Generate BPF skeletons and configs
```

## High-Level Architecture

### Core Directory Structure
- `/pkg/` - Main Go packages containing core Cilium logic
  - `/pkg/datapath/` - eBPF dataplane implementation managing packet processing
  - `/pkg/policy/` - Network policy engine for L3-L7 security rules
  - `/pkg/endpoint/` - Endpoint lifecycle management for pods/containers
  - `/pkg/k8s/` - Kubernetes integration, watchers, and CRD handling
  - `/pkg/loadbalancer/` - Distributed load balancing implementation
  - `/pkg/hubble/` - Observability subsystem for flow monitoring
  - `/pkg/clustermesh/` - Multi-cluster connectivity implementation

- `/bpf/` - eBPF C programs compiled and loaded into kernel
  - Core dataplane programs: `bpf_lxc.c`, `bpf_host.c`, `bpf_overlay.c`
  - XDP programs for high-performance packet processing
  - Socket-level load balancing programs

- `/daemon/` - Cilium agent (main daemon) that runs on each node
- `/operator/` - Kubernetes operator for cluster-wide operations
- `/hubble-relay/` - Hubble relay for aggregating observability data

### Key Architectural Concepts

1. **eBPF-First Design**: Core networking logic runs in kernel via eBPF programs, avoiding userspace overhead
2. **Identity-Based Security**: Uses cryptographic identities instead of IP addresses for security policies
3. **Distributed Dataplane**: Each node runs independent eBPF programs synchronized via Kubernetes/etcd
4. **Policy Repository**: Network policies compiled from Kubernetes resources into eBPF maps
5. **Endpoint State Machine**: Complex lifecycle management for pod networking attachment

### Development Patterns

- **eBPF Development**: C code in `/bpf/` compiled with clang/llvm (>= 18.1), loaded via Go libraries
- **Kubernetes Integration**: Heavy use of client-go, informers, and code generation for CRDs
- **Modular Subsystems**: Each major feature (policy, loadbalancer, encryption) is a self-contained package
- **Cell Architecture**: Uses dependency injection pattern with "cells" for component initialization

## Testing Strategy

- **Unit Tests**: Standard Go tests, run with `go test`
- **Integration Tests**: Tests requiring kvstore or API server mocks
- **BPF Tests**: Separate test framework for eBPF programs using test runners
- **E2E Tests**: Full cluster tests in `/test/` using Ginkgo framework
- **Runtime Tests**: Live testing against real Kubernetes clusters

## Important Notes

- Always run `make precheck` before committing to catch formatting/style issues
- eBPF code changes require kernel headers and privileged tests
- Use Kind-based development workflow for rapid iteration
- The project uses Go modules with vendoring - run `go mod vendor` after dependency changes
- When modifying APIs, regenerate code with appropriate `make generate-*` commands


You are a technical analyst specializing in Cilium, an open-source cloud-native networking solution written in Go. You will analyze a specific code path or component from the Cilium codebase.

Here is the code path you need to analyze:

<code_path>
{{CODE_PATH}}
</code_path>

Your task is to create a comprehensive technical analysis that includes:

1. **Call Graph Creation**: Build a detailed call graph showing the function call hierarchy starting from the specified code path
2. **Function Analysis**: Provide in-depth explanations of each function's purpose and functionality
3. **Code Documentation**: Include actual code snippets from the Cilium repository

Before providing your final analysis, work through your approach in <code_analysis> tags inside your thinking block:
- Extract and list the specific functions, methods, or components mentioned in the code path
- Map out the logical flow and dependencies between these functions - which calls which, and in what order
- Identify the likely file paths where these functions are located within the Cilium codebase structure
- Plan what specific code snippets you'll need to find and quote for each function (signatures, key logic, data structures)
- Consider the architectural context and how this code path fits into Cilium's overall networking functionality
It's OK for this section to be quite long.

## Requirements

### Call Graph Format
- Use exact indentation with spaces and pipe characters (`|-`) as shown in technical documentation
- Include file paths in comments (e.g., `// pkg/datapath/loader/loader.go`)
- Maintain proper hierarchical structure with consistent nesting
- Cover all significant function calls in the execution flow

### Function Analysis Standards
- Explain each function's purpose and role within the Cilium architecture
- Include actual code snippets from the real Cilium codebase (never create fake or simplified code)
- Quote actual function signatures, key logic sections, and important code blocks
- Describe data structures, maps, and resources that each function initializes or manipulates
- Explain relationships between functions and data flow through the call chain
- Cover error handling, initialization sequences, and key data structures
- Address networking, Kubernetes integration, and configuration aspects where relevant

### Code Authenticity
- All code snippets must be from the actual Cilium repository
- Reference specific file paths for each function
- If you cannot access current code, clearly state this limitation
- Do not create pseudo-code or simplified examples

## Output Format

Your response must be in Korean and formatted as markdown, suitable for documentation purposes. Structure your response as follows:

1. **Call Graph Section**: Present the complete call graph using the specified indentation format
2. **Function Analysis Section**: Provide detailed explanations for each function, organized in the order they appear in the call graph
3. **Section Headers**: Use clear Korean markdown headers for organization

Example structure:
```markdown
# Cilium 코드 분석: [Code Path Name]

## 호출 그래프 (Call Graph)

## 함수별 상세 분석

### 함수명()
- **위치**: pkg/path/file.go
- **목적**: [function purpose]
- **코드 스니펫**: 
```go
[actual code]
```
- **설명**: [detailed explanation]
```

Begin your analysis of the provided code path. Your final output should consist only of the Korean markdown analysis and should not duplicate or rehash any of the planning work you did in the thinking block.
