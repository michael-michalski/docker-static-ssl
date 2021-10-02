ALPINE_ELIXIR_SSSL ?= michaelmichalski/elixir-sssl
RUSTLER_ALPINE_ELIXIR_SSSL ?= michaelmichalski/rustler-sssl

ifndef ALPINE_VERSION
override ALPINE_VERSION=3.11.3
endif
ifndef ERLANG_VERSION
override ERLANG_VERSION=24.1
endif
ifndef ELIXIR_VERSION
override ELIXIR_VERSION=v1.11.4
endif

rustler:
	docker build --squash --force-rm --target rustler --build-arg ELIXIR_VERSION=$(ELIXIR_VERSION) --build-arg ERLANG_VERSION=$(ERLANG_VERSION) --build-arg ALPINE_VERSION=$(ALPINE_VERSION) -t $(RUSTLER_ALPINE_ELIXIR_SSSL):latest -t $(RUSTLER_ALPINE_ELIXIR_SSSL):$(ALPINE_VERSION)-$(ERLANG_VERSION)-$(ELIXIR_VERSION) .

alpine-elixir:
	docker build --squash --force-rm --target alpine-elixir --build-arg ELIXIR_VERSION=$(ELIXIR_VERSION) --build-arg ERLANG_VERSION=$(ERLANG_VERSION) --build-arg ALPINE_VERSION=$(ALPINE_VERSION) -t $(ALPINE_ELIXIR_SSSL):latest -t $(ALPINE_ELIXIR_SSSL):$(ALPINE_VERSION)-$(ERLANG_VERSION)-$(ELIXIR_VERSION) .

buildx:
	docker buildx build --platform linux/amd64,linux/x86,linux/arm64,linux/arm --force-rm --target alpine-elixir --build-arg ELIXIR_VERSION=$(ELIXIR_VERSION) --build-arg ERLANG_VERSION=$(ERLANG_VERSION) --build-arg ALPINE_VERSION=$(ALPINE_VERSION) -t $(ALPINE_ELIXIR_SSSL):latest -t $(ALPINE_ELIXIR_SSSL):$(ALPINE_VERSION)-$(ERLANG_VERSION)-$(ELIXIR_VERSION) . --push

all: rustler ## Build the Docker image

clean: ## Clean up generated images
	@docker rmi --force $(IMAGE_NAME):$(VERSION) $(IMAGE_NAME):$(MIN_VERSION) $(IMAGE_NAME):$(MAJ_VERSION) $(IMAGE_NAME):latest

rebuild: clean all

push:
	docker push $(RUSTLER_ALPINE_ELIXIR_SSSL):latest
	docker push $(RUSTLER_ALPINE_ELIXIR_SSSL):$(ALPINE_VERSION)-$(ERLANG_VERSION)-$(ELIXIR_VERSION)
	docker push $(ALPINE_ELIXIR_SSSL):latest
	docker push $(ALPINE_ELIXIR_SSSL):$(ALPINE_VERSION)-$(ERLANG_VERSION)-$(ELIXIR_VERSION)
