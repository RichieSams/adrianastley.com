.PHONY: build serve

build:
	./sitegen.exe build -c site_gen_config.yaml

serve:
	./sitegen.exe serve -c site_gen_config.yaml -p 3456
