# hackstack

SRC=src

build:
	blogofile build --src-dir $(SRC)

serve:
	blogofile serve --src-dir $(SRC)

push:
	git push

# Activate venv (can't do it here because subshells):
# . ../blogo/bin/activate
