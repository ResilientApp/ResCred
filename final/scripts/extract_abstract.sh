: '
Script to find abstract body and produce a mostly plain-text abstract
(ready to upload to a conference submission system).

Preserves $-enclosed tex; removes \begin..\end, \keywords, \emph.

Also removes other \ tex commands, but only in a limited manner:
at most one per line, only if it occurs before the first $.
'

TARGET="data/abstract_plain.tex"

echo "    updating $TARGET"
awk '/\\begin{abstract}/,/\\end{abstract}/' src/*.tex \
    | sed 's/\\begin{.*}//g' \
    | sed 's/\\end{.*}//g' \
    | sed 's/\\keywords{.*}//g' \
    | sed 's/\\emph{\(.*\)}/\1/g' \
    | sed 's/^\([^\$]*\)\\[a-zA-Z]*/\1/g' \
    | sed 'N;/^\n$/D;P;D;' \
    | awk ' /^$/ { print "\n"; } /./ { printf("%s ", $0); } END { print ""; } ' \
    | sed -e ':a' -e 'N' -e '$!ba' -e 's/^\n*//' \
    > $TARGET
