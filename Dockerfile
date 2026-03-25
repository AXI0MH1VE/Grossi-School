# ---------------------------------------------------------------
# Stage 1 — Build
# Pin to GCC 14 (Debian Bookworm-backed) for reproducible,
# auditable builds. Avoid :latest — it is a floating tag that
# introduces non-deterministic CVE exposure.
# Supported tags: https://hub.docker.com/r/library/gcc/tags
# ---------------------------------------------------------------
FROM gcc:14-bookworm AS builder

# Copy source and set working directory
COPY . /usr/src/myapp
WORKDIR /usr/src/myapp

# Compile application; -O2 enables standard optimizations
RUN g++ -O2 -o myapp main.cpp

# ---------------------------------------------------------------
# Stage 2 — Runtime
# Use a minimal Debian slim image.  The GCC toolchain and all
# its OS-layer dependencies are NOT carried into this stage,
# eliminating the critical/high CVEs reported by the scanner.
# ---------------------------------------------------------------
FROM debian:bookworm-slim AS runtime

# Create a non-root user for least-privilege execution
RUN groupadd --system appgroup && \
    useradd --system --gid appgroup appuser

WORKDIR /app

# Copy only the compiled binary from the builder stage
COPY --from=builder /usr/src/myapp/myapp .

# Run as non-root
USER appuser

# This command runs your application
CMD ["./myapp"]

LABEL Name=grossischool Version=0.0.1
