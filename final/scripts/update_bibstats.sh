: '
Script to count and save the number of bibtex entries of each type,
as well as the list of unused bibtex entries.

Thanks to:
    https://unix.stackexchange.com/q/39039/46442
    https://tex.stackexchange.com/a/232771/28267
'

# Environment variable to make 'sort' cross-platform
export LC_ALL=C

if [ ! -d build ]; then
    echo "build directory not found -- run make build first."
    exit 1
fi

echo "    updating data/bibentries.txt"
echo "===== Bib entries =====" > data/bibentries.txt
cat src/ref.bib \
    | grep -oh "@\w*" \
    | sort \
    | uniq -c \
    | sort -bnr \
    >> data/bibentries.txt
cat src/ref.bib \
    | grep -oh "@\w*" \
    | wc -l \
    | awk '{$1=$1;print}' \
    | sed 's_^_ _' \
    | sed 's_$_ total_' \
    >> data/bibentries.txt
echo "===== By venue =====" >> data/bibentries.txt
cat src/ref.bib \
    | grep -oh -E 'booktitle(.*)=(.*)|journal(.*)=(.*)' \
    | sed 's/.*=.*"\(.*\)"/\1/' \
    | sed 's/.*=.*{\(.*\)}/\1/' \
    | sed -r 's/[0-9]+(th|st|nd|rd) //' \
    | sed 's/first |second |third //I' \
    | sed 's/biennial //I' \
    | sort \
    | uniq -c \
    | sort -bnr \
    >> data/bibentries.txt

echo "    updating data/bibunused.txt"
cd build \
    && checkcites --unused main.aux \
    > ../data/bibunused.txt
