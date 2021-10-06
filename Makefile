.PHONY: build serve

ifeq ($(OS),Windows_NT)
EXT=.exe
RM_CMD=rmdir /q/s
export SHELL=cmd
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

upload:
	ssh dev@45.56.79.149 rm -rf /dockervols/site-html/*
	scp -r output/* dev@45.56.79.149:/dockervols/site-html