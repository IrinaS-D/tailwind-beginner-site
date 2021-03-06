FROM elixir:1.12.3-alpine AS elixir-builder

RUN apk add git

RUN mix local.hex --force \
  && mix local.rebar --force

EXPOSE 4000
# Default EPMD port
EXPOSE 4369

ARG MIX_ENV=prod
RUN echo ${MIX_ENV}
ENV MIX_ENV=$MIX_ENV
ENV PORT=4000

WORKDIR /root/app

# We load these things one by one so that we can load the deps first and
#   cache those layers, before we do the app build itself
ADD ./priv ./priv
ADD ./mix.exs ./mix.lock ./
ADD ./config ./config
ADD ./apps/admin/mix.exs ./apps/admin/
ADD ./apps/app/mix.exs ./apps/app/
ADD ./apps/content/mix.exs ./apps/content/
ADD ./apps/core/mix.exs ./apps/core/
ADD ./apps/object_storage/mix.exs ./apps/object_storage/

RUN mix deps.get
RUN mix deps.compile

ADD ./apps /root/app/apps

# Leave off here so that we can built assets and compile the elixir app in parallel

FROM node:16.10.0 AS asset-builder

# Build assets in a node container
ADD ./apps/app/assets/ /root/app/apps/app/assets/

WORKDIR /root/app/apps/app/assets/
COPY --from=0 /root/app/ /root/app/
RUN npm install

ADD ./apps /root/app/apps
RUN npm run deploy

FROM elixir-builder

ADD ./apps /root/app/apps

# Resume compilation of the elixir app
RUN MAKE=cmake mix compile

# Copy in the built assets & fingerprint them
COPY --from=asset-builder /root/app/apps/app/priv/static/ /root/app/apps/app/priv/static
RUN mix phx.digest

CMD elixir --name ${NAME:=legendary}@$(hostname -f) -S mix phx.server
