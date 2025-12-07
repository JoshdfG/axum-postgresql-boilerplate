# Use Rust nightly to support edition2024
FROM rustlang/rust:nightly AS builder

# Install build dependencies including OpenSSL and pkg-config
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    pkg-config \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /usr/src/app

# Copy the entire project for building (simplified approach)
COPY . .

# Build the application in release mode
RUN cargo build --release

# Use a minimal Debian image for runtime
FROM debian:bookworm-slim

# Install only required runtime dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    libssl3 \
    libpq5 \
    ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Create a non-root user to run the application
RUN groupadd -r appuser && useradd -r -g appuser appuser

# Copy the built binary from the builder stage
# Note: Adjust the binary name if it's not "backend"
COPY --from=builder /usr/src/app/target/release/[your_app_name] /usr/local/bin/app

# Create a directory for any app data and set proper permissions
RUN mkdir -p /var/lib/app && chown -R appuser:appuser /var/lib/app

# Switch to non-root user
USER appuser

# Expose the port
EXPOSE 8080 

# Set environment variables
ENV PORT=8080 \
    RUST_LOG=info

# Run the application with full path
CMD ["/usr/local/bin/app"]
