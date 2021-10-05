.PHONY: build serve

ifeq ($(OS),Windows_NT)
EXT=.exe
RM_CMD=rmdir /q/s
else
EXT=
RM_CMD=rm -rf
endif

build:
	./sitegen$(EXT) build -c site_gen_config.yaml

serve:
	./sitegen$(EXT) serve -c site_gen_config.yaml -p 3456

clean:
	$(RM_CMD) output