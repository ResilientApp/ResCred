: '
Script to update data/totals.txt with total size of all input files
'

# Environment variable to make 'sort' cross-platform
export LC_ALL=C

echo "    updating data/totals.txt"
echo "===== Totals =====" > data/totals.txt
echo "   words   chars file" >> data/totals.txt
{
    find src -name "*.tex";
    find src -name "*.bib";
} \
    | xargs wc -w -c \
    | sort \
    >> data/totals.txt
