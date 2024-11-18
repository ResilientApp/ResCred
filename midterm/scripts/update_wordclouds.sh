: '
Script to update the wordcloud image.
Requires the wordcloud_cli python tool:
    pip install wordcloud
    https://github.com/amueller/word_cloud

Excludes the input file header.tex (if present).
Does not currently filter out usepackage and newcommand arguments,
so these are best included in header.tex.

Generates intermediate .temp files in data/ which can be inspected
to see what is filtered out from the source files.

The blacklist (words to exclude) is in data/wordcloud_omit.txt.
Additional words can be added to the top of the file.
'

if ! command -v wordcloud_cli &> /dev/null
then
    echo "    skipping wordclouds -- wordcloud_cli could not be found" >&2
    echo "    hint: try 'pip install wordcloud'" >&2
    exit 0
fi

echo "    updating data/ALL.tex.temp"
mv src/header.tex data/header.tex.temp
cat src/*.tex > data/ALL.tex.temp
mv data/header.tex.temp src/header.tex

echo "    updating data/ALL.txt.temp"
cat data/ALL.tex.temp \
    | sed 's/^%.*//' \
    | sed 's/\\label{.*}/ /g' \
    | sed 's/\\Cref{.*}/ /g' \
    | sed 's/\\ref{.*}/ /g' \
    | sed 's/\\eqref{.*}/ /g' \
    | sed 's/\\cite{.*}/ /g' \
    | sed 's/\\begin{.*}/ /g' \
    | sed 's/\\end{.*}/ /g' \
    | sed 's/\\[a-zA-Z]*//g' \
    | sed 's/_/ /g' \
    | sed 's/'\''/ /g' \
    > data/ALL.txt.temp

echo "    updating data/BIB.txt.temp"
cat src/*.bib \
    | grep -o -E '(\btitle|\bauthor).*=.*' \
    | sed 's/.*=//' \
    > data/BIB.txt.temp

echo "    updating data/wordcloud.png"
wordcloud_cli --text data/ALL.txt.temp \
    --width 2000 --height 1000 \
    --imagefile data/wordcloud.png \
    --random_state 1 \
    --stopwords data/wordcloud_omit.txt \
    --min_word_length 2

if [ -s data/BIB.txt.temp ]; then
    echo "    updating data/wordcloud_refs.png"
    wordcloud_cli --text data/BIB.txt.temp \
        --width 2000 --height 1000 \
        --imagefile data/wordcloud_refs.png \
        --random_state 1 \
        --stopwords data/wordcloud_omit.txt \
        --min_word_length 2
else
    echo "    skipping data/wordcloud_refs.png (empty .bib input)"
fi
