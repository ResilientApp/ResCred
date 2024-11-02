.PHONY: view build show-input-files pre post aux spellcheck full clean
.DEFAULT_GOAL: view

SRC_FILES = $(wildcard src/*.tex)
BIB_FILES = $(wildcard src/*.bib)
IMG_FILES = $(wildcard src/img/*) $(wildcard src/img/*/*)

PDFLATEX_EXIT = -interaction=nonstopmode -halt-on-error
TEXFOT_QUIET = --quiet --ignore "^This is pdfTeX" --ignore "^Output written on" --ignore "^Transcript written on"

INDENT = sed 's_^_    _'
RED = printf "\033[0;31m"
YELLOW = printf "\033[1;33m"
RESET = printf "\033[0m"

# Build and view the PDF
view: build
	open build/main.pdf

# Build the PDF
build: build/main.pdf

# Run pdflatex with prettified (less verbose) output
# Requires texfot (which I believe is installed by default with most distros)
build/main.pdf: $(SRC_FILES) $(BIB_FILES) $(IMG_FILES)
	cp -R src/ build/
	@echo "Entering build..."
	@cd build \
	&& pdflatex $(PDFLATEX_EXIT) main.tex > /dev/null \
	&& $(YELLOW) \
	&& bibtex --terse main.aux | $(INDENT) \
	&& $(RESET) \
	&& pdflatex main.tex > /dev/null \
	&& $(YELLOW) \
	&& texfot $(TEXFOT_QUIET) pdflatex main.tex | $(INDENT) \
	&& $(RESET) \
	|| ( $(RED) \
	&& printf "===== Error =====\n" | $(INDENT) \
	&& texfot $(TEXFOT_QUIET) pdflatex $(PDFLATEX_EXIT) main.tex | $(INDENT) \
	&& $(RESET) \
	&& cd .. \
	&& rm -rf build/ \
	&& exit 1 )

# Show all sources picked up by the Makefile (useful for debugging)
show-input-files:
	@echo "=== tex sources ==="
	@echo $(SRC_FILES)
	@echo "=== bib ==="
	@echo $(BIB_FILES)
	@echo "=== images and figures ==="
	@echo $(IMG_FILES)

# Auxiliary data from pre-build .tex/.bib files
pre:
	scripts/update_totals.sh
	scripts/extract_abstract.sh
	scripts/update_wordclouds.sh

# Auxiliary data from post-build .pdf/.aux files
post: build
	scripts/update_bibstats.sh || true
	scripts/update_fonts.sh

# Build all auxiliary data and stats
aux: pre post

# Run aspell (with input file of whitelisted words)
spellcheck:
	scripts/spellcheck.sh

# Build final version for publishing
full: clean spellcheck pre build post

# Build final version for submission to arXiv
# Creates ready-to-upload src_arXiv/ and arXiv.zip
arxiv: full
	pip install arxiv-latex-cleaner
	arxiv_latex_cleaner src --resize_images --im_size 500
	cp build/*.bbl src_arXiv/
	zip -vr arXiv.zip src_arXiv/ -x "*.DS_Store"

# Clean up
# Separating out build/ simplifies cleanup considerably.
# Notice we don't have to enumerate a long list of TeX-related files, like:
# rm -f *.aux *.toc *.out *.log *.bbl *.blg *.pdf *.temp *.lof *.lot
clean:
	rm -rf build/
	rm -f data/*.temp
	rm -rf src_arXiv/
	rm -f arXiv.zip
