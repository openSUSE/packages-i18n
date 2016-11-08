#!/bin/bash
# Merging script for package translations
# Usage validation
[ $# -gt 1 ] && {
    echo "Too many arguments"
    echo "Usage: 50-tools/merge_pots.sh [<lang name>]"
    exit 1
}
# Set lang name
langs=""
if [ -z $1 ]
then
    for i in *; do
        if [ -d $i/po ]
        then langs="$langs $i";
        fi
    done
else
    if [ -d $1/po ]
    then langs=$1
    else
        echo "Language not found!"
        exit 2
    fi
fi

# Check we are in the right place
echo "Now working in $(pwd) branch"
[ -d 50-pot ] || {
    echo "Pot directory not found!"
    exit 2
    }

echo "Syncing started"
# Get the list of resources' names
pots=$(cd 50-pot && ls -1 *.pot | sed -e 's,\.pot,,')
for lang in $langs; do
# Save all the translations
    msgcat  --use-first --force-po -o $lang/$lang.po $lang/po/*.$lang.po
#  echo ""
    for pot in $pots; do
# Merge all available languages
        echo -n "$pot.$lang.po "
        [ -f $lang/po/$pot.$lang.po ] || { 
            msginit --no-translator -i 50-pot/$pot.pot -o $lang/po/$pot.$lang.po --locale=$lang && git add $lang/po/$pot.$lang.po
        }
        msgmerge -C $lang/$lang.po -U --previous $lang/po/$pot.$lang.po 50-pot/$pot.pot
    done
    echo -n "$lang " && msgfmt -o /dev/null --statistics $lang/$lang.po && rm -f $lang/$lang.po
    git add $lang/po/*.po
    git commit -m "$lang merged"
done
echo Done!
exit 0
