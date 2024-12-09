# latex-template

A LaTeX template repository which provides cleaner builds, spellchecking, BibTeX checks, and summary statistics.

## To use

After cloning the repository, run `make` to compile and view the PDF or `make full` for a more comprehensive build (intended to be run less frequently for publishable versions).

- The basic build generates the PDF while filtering out all output aside from warnings and errors.

- The comprehensive build also runs a spellcheck, maintaining a whitelist specific to your project (`make spellcheck`); and it produces various auxiliary data and checks (`make aux`), including a list of unused references, a check for correctly embedded fonts, summary statistics, and wordclouds.
By default, the auxiliary data including the spellcheck whitelist are under version control so that they can be tracked and published with major versions of the document.

- You can also `make arxiv` to create a ready-to-upload `.zip` file for arXiv (via [arxiv_latex_cleaner](https://github.com/google-research/arxiv-latex-cleaner)).

- When pdflatex fails, `make` should exit gracefully and inform you of the error (if not, it's a bug)!

## Requirements

This repository has been tested on Mac and Linux.
You will need a full distribution of TeX Live (e.g. `texlive-full`), which ships with some auxiliary command line tools. Run the following to make sure everything is installed:
```
pdflatex -v
texfot -v
checkcites -v
```

For arXiv, you will need `pip` and Python3 (`make arxiv` runs `pip install arxiv-latex-cleaner`).
If you want the wordclouds, you will additionally need the [`wordcloud_cli` Python tool](https://github.com/amueller/word_cloud), which you can install with `pip install wordcloud`.

## Why yet another LaTeX template?

Many other LaTeX build systems exist; I've used `latexmk`, but its output is unhelpful and it doesn't include much of the other auxiliary functionality here. Overleaf is much easier to use, but lacking version control, it awkwardly merges collaborative edits without tracking who did what, and has several concurrency and availability bugs.

The repository enforces a separation between source files (`src/`), build files (`build/`), scripts (`scripts/`), and auxiliary data (`/data`, i.e., build script inputs and outputs).
The whitelist shipped with the repository in `data/.aspell.en.pws` includes lots of CS-specific words.

## Known limitations

It is currently necessary for the main file to be `main.tex` and for there to be a single references file named `ref.bib` (as in the template `src/`).
Other configurations (e.g. multiple bibliographies via `multibib`) aren't supported yet.
The Makefile doesn't attempt to optimize the build for performance, so may not be appropriate for a larger project like a book.

## Issues

If you use this repository as a template for your LaTeX project, I would love to hear about what worked and what didn't. Please file an issue.
