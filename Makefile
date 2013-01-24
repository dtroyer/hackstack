# hackstack

SRC=src

build:
	blogofile build --src-dir $(SRC)

serve:
	blogofile serve --src-dir $(SRC)

push:
	git push
