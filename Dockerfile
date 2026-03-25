# ---------------------------------------------------------------
# Stage 1 — Build
# alpine:3.21 + build-base supplies GCC/G++ on a minimal Alpine
# base (~7 MB). Alpine ships far fewer OS packages than Debian,
# reducing the CVE attack surface from 48 (Bookworm) to near-zero.
# Pinned digest reference: https://hub.docker.com/_/alpine/tags
# ---------------------------------------------------------------
FROM alpine:3.21 AS builder

# build-base installs gcc, g++, make, and musl-dev in one layer.
# --no-cache avoids writing the apk index to the image layer,
# keeping the build stage as lean as possible.
RUN apk add --no-cache build-base

# Copy source and set working directory
COPY . /usr/src/myapp
WORKDIR /usr/src/myapp

# Compile with -O2 optimizations and -static so the binary is
# fully self-contained and does not depend on any runtime libs
# present in the builder that won't be in the final image.
RUN g++ -O2 -static -o myapp main.cpp

# ---------------------------------------------------------------
# Stage 2 — Runtime
# Bare alpine:3.21 — no compiler, no build tools, no glibc.
# Only the compiled binary is copied across from the build stage.
# This resolves the 1 critical CVE flagged on debian:bookworm-slim
# by eliminating Debian's dependency tree entirely.
# ---------------------------------------------------------------
FROM alpine:3.21 AS runtime

# Create a non-root user and group (Alpine uses addgroup/adduser)
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /app

# Copy only the statically linked binary — no other dependencies
COPY --from=builder /usr/src/myapp/myapp .

# Enforce least-privilege: never run containers as root
USER appuser

CMD ["./myapp"]

LABEL Name=grossischool Version=0.0.1
