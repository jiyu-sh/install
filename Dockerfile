FROM rust:slim AS chef

# install `cargo-chef` for caching dependencies
RUN cargo install cargo-chef

WORKDIR /app

FROM chef AS planner

COPY . .

# generate the recipe for caching dependencies
RUN cargo chef prepare --recipe-path recipe.json

FROM chef AS builder

COPY --from=planner /app/recipe.json recipe.json

# build dependencies based on the recipe
RUN cargo chef cook --release --recipe-path recipe.json

COPY . .

RUN cargo build --release

FROM debian:trixie-slim

COPY --from=builder /app/target/release/jiyu-install .

# copy the install script to be served
COPY --from=builder /app/install.sh .

# copy the install directory to be served
COPY --from=builder /app/install ./install

EXPOSE 10946

ENTRYPOINT ["./jiyu-install"]
