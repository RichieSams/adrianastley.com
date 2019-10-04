.PHONY: build serve

ifeq ($(OS),Windows_NT)
	EXT=.exe
else
	EXT=
endif

build:
	./sitegen$(EXT) build -c site_gen_config.yaml

serve:
	./sitegen$(EXT) serve -c site_gen_config.yaml -p 3456
