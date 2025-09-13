{
  description = "Cilium development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { 
          inherit system;
          config.allowUnfree = true;
        };
        
        # Go version required by Cilium
        go = pkgs.go;
        
        # LLVM/Clang version for eBPF compilation
        llvmPackages = pkgs.llvmPackages_18;
        
        # Custom build of bpftool
        bpftool = pkgs.bpftools;
        
        # Unwrapped clang for BPF compilation (avoids wrapper issues)
        clang-unwrapped = pkgs.llvmPackages_18.clang-unwrapped;
        llvm-unwrapped = pkgs.llvmPackages_18.llvm;
        
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            # Core development tools
            go
            go-tools
            gopls
            delve
            golangci-lint
            gofumpt
            
            # eBPF/BPF development
            clang-unwrapped  # Use unwrapped clang for BPF
            llvm-unwrapped   # Use unwrapped LLVM
            llvmPackages.lld
            llvmPackages.bintools
            bpftool
            elfutils
            libelf
            
            # Container/Kubernetes tools
            docker
            docker-compose
            kubectl
            kind
            helm
            
            # Build tools
            gnumake
            cmake
            pkg-config
            automake
            autoconf
            libtool
            gcc  # Host compiler for non-BPF code
            
            # Protobuf and code generation
            protobuf
            protoc-gen-go
            protoc-gen-go-grpc
            
            # Testing tools
            etcd
            consul
            
            # Networking tools
            iproute2
            iptables
            ipset
            tcpdump
            netcat-gnu
            curl
            wget
            jq
            yq-go
            
            # Documentation
            mdbook
            hugo
            
            # Development utilities
            git
            gh
            tmux
            ripgrep
            fd
            bat
            tree
            htop
            
            # Python for scripts
            python3
            python3Packages.pyyaml
            python3Packages.jinja2
            
            # Static analysis
            shellcheck
            yamllint
            
            # Required libraries
            glibc
            glibc.static
            zlib
            openssl
            libseccomp
            libcap
          ];
          
          shellHook = ''
            # Set up environment variables for Cilium development
            export GOPATH="$HOME/go"
            export PATH="$GOPATH/bin:$PATH"
            
            # eBPF/BPF compilation flags - use unwrapped versions
            export LLC="${llvm-unwrapped}/bin/llc"
            export CLANG="${clang-unwrapped}/bin/clang"
            export NATIVE_ARCH="$(uname -m)"
            
            # Disable wrapper flags for BPF compilation
            export HOST_CC="${pkgs.gcc}/bin/gcc"
            export HOST_CXX="${pkgs.gcc}/bin/g++"
            
            # Cilium specific environment variables
            export CILIUM_BUILDER_IMAGE="quay.io/cilium/cilium-builder:latest"
            export K8S_VERSION="1.30"
            export CILIUM_DEV=1
            
            # Kind cluster configuration
            export KIND_CLUSTER_NAME="cilium-dev"
            export KUBECONFIG="$HOME/.kube/config-$KIND_CLUSTER_NAME"
            
            # Set proper permissions for docker if needed
            if command -v docker &> /dev/null; then
              if ! docker info &> /dev/null; then
                echo "⚠️  Docker daemon is not running or you don't have permissions"
                echo "   Run: sudo systemctl start docker"
                echo "   Or add yourself to docker group: sudo usermod -aG docker $USER"
              else
                echo "✅ Docker is available"
              fi
            fi
            
            # Check if kind cluster exists
            if command -v kind &> /dev/null; then
              if kind get clusters 2>/dev/null | grep -q "^$KIND_CLUSTER_NAME$"; then
                echo "✅ Kind cluster '$KIND_CLUSTER_NAME' exists"
              else
                echo "ℹ️  Kind cluster '$KIND_CLUSTER_NAME' not found"
                echo "   Create it with: make kind"
              fi
            fi
            
            # Print tool versions
            echo ""
            echo "🛠️  Development Environment Ready!"
            echo "================================="
            echo "Go version:    $(go version | cut -d' ' -f3)"
            echo "Clang version: $(clang --version | head -n1)"
            echo "LLC version:   $(llc --version | head -n2 | tail -n1)"
            echo "Make version:  $(make --version | head -n1)"
            echo ""
            echo "📚 Quick Commands:"
            echo "  make build              - Build Cilium binaries"
            echo "  make kind               - Create Kind development cluster"
            echo "  make kind-image-fast    - Build and load images into Kind"
            echo "  make tests-privileged   - Run privileged tests"
            echo "  make lint               - Run linters"
            echo ""
            
            # Create required directories if they don't exist
            mkdir -p "$HOME/.kube"
            mkdir -p "$GOPATH/bin"
            
            # Source bash completion if available
            if [ -n "$BASH" ] && [ -f /etc/bash_completion ]; then
              source /etc/bash_completion
            fi
          '';
          
          # Prevent garbage collection of the shell dependencies
          GC_DONT_GC = 1;
          
          # Additional environment variables
          GOOS = "linux";
          CGO_ENABLED = "1";
          
          # Locale settings
          LANG = "en_US.UTF-8";
          LC_ALL = "en_US.UTF-8";
        };
        
        # Additional development shells for specific tasks
        devShells.minimal = pkgs.mkShell {
          buildInputs = with pkgs; [
            go
            gnumake
            git
            clang-unwrapped
            llvm-unwrapped
            gcc
          ];
          
          shellHook = ''
            echo "Minimal Cilium development environment"
            export GOPATH="$HOME/go"
            export PATH="$GOPATH/bin:$PATH"
            export LLC="${llvm-unwrapped}/bin/llc"
            export CLANG="${clang-unwrapped}/bin/clang"
            export HOST_CC="${pkgs.gcc}/bin/gcc"
            export HOST_CXX="${pkgs.gcc}/bin/g++"
          '';
        };
        
        devShells.testing = pkgs.mkShell {
          buildInputs = with pkgs; [
            go
            gnumake
            kind
            kubectl
            docker
            etcd
            consul
            clang-unwrapped
            llvm-unwrapped
            bpftool
          ];
          
          shellHook = ''
            echo "Cilium testing environment"
            export GOPATH="$HOME/go"
            export PATH="$GOPATH/bin:$PATH"
            export LLC="${llvm-unwrapped}/bin/llc"
            export CLANG="${clang-unwrapped}/bin/clang"
            export HOST_CC="${pkgs.gcc}/bin/gcc"
            export HOST_CXX="${pkgs.gcc}/bin/g++"
            export CILIUM_DEV=1
            export KIND_CLUSTER_NAME="cilium-test"
          '';
        };
      });
}
