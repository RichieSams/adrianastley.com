.PHONY: build serve

ifeq ($(OS),Windows_NT)
EXT=.exe
export SHELL=cmd
else
EXT=
endif

SITEGEN_IMAGE=quay.io/richiesams/sitegen:1.0.0


build:
	docker run --rm -v $(CURDIR):/app -w /app $(SITEGEN_IMAGE) build -c site_gen_config.yaml

serve:
	docker run --rm -it -v $(CURDIR):/app -w /app -p 3456:3456 $(SITEGEN_IMAGE) serve -c site_gen_config.yaml -p 3456

clean:
	docker run --rm -v $(CURDIR):/app -w /app $(SITEGEN_IMAGE) rm -rf ./output
