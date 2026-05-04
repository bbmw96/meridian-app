FROM elixir:1.17-alpine AS builder

RUN apk add --no-cache git build-base

ENV MIX_ENV=prod

WORKDIR /app

COPY mix.exs mix.lock ./
RUN mix local.hex --force && \
    mix local.rebar --force && \
    mix deps.get --only prod && \
    mix deps.compile

COPY . .

RUN mix compile && \
    mix release meridian_realtime

FROM alpine:3.19

RUN apk add --no-cache libstdc++ openssl ncurses-libs

RUN addgroup -S meridian && adduser -S meridian -G meridian

WORKDIR /app

COPY --from=builder /app/_build/prod/rel/meridian_realtime .

RUN chown -R meridian:meridian /app
USER meridian

EXPOSE 4001

HEALTHCHECK --interval=15s --timeout=5s --start-period=15s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:4001/health || exit 1

CMD ["./bin/meridian_realtime", "start"]
