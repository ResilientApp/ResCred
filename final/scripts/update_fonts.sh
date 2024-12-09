: '
Script to produce a table of all fonts in the final pdf.
In particular, the table includes whether the fonts are embedded --
this should be "yes" for all fonts.

Further info:
https://www.karlrupp.net/2016/01/embed-all-fonts-in-pdfs-latex-pdflatex/
'

if [ ! -d build ]; then
    echo "build directory not found -- run make build first."
    exit 1
fi

echo "    updating data/fonts.txt"
pdffonts build/main.pdf | sed 's/\+/ /' | awk '{$1=$9=""; print $0}' > data/fonts.txt
