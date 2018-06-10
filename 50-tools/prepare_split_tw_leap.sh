#! /bin/sh
set -e
set -o pipefail

: ${VERBOSE:=0}

export LANG=C.utf8

# die: Echo arguments to stderr and exit with 1
die() { echo "$@" 1>&2 ; exit 1; }
log()
{
	[ "$VERBOSE" = 1 ] || return 0
	echo "$@"
}

move_if_changed()
{
	local src="$1"
	local dst="$2"

	local updated=1
	if [ -e "$dst" ]; then
		grep -v 'POT-Creation-Date:' "$src" > "$src.n"
		grep -v 'POT-Creation-Date:' "$dst" > "$dst.n"
		if cmp -s "$src.n" "$dst.n"; then
			updated=0
		fi
		rm -f "$src.n"
		rm -f "$dst.n"
	fi
	if [ "$updated" != 0 ]; then
	  mv "$src" "$dst"
	  if [ "$VERBOSE" = 1 ]; then
	    msgfmt --statistics -o /dev/null "$dst"
	  fi
	fi
}

if [ ! -r "$1" ]; then
  die "Usage: $0 URLS.TXT"
fi
urlfile="$1"
shift

# get package lists
rm -rf 50-lists
mkdir 50-lists
while read distro url; do
  case $distro in
    \#*) continue ;;
  esac

## get package descriptions
  log "Generating POT file for ${distro}..."
  python3 50-tools/repomd2gettext.py "$url" "$distro" | msguniq > "50-lists/${distro}-packages._pot"

  log "OK"
done < "$urlfile"

cd 50-lists

## Merge distros
rm -f *.pot
msgcat *._pot | grep -v "#-#-#-#" > _packages.pot
#cat _packages.pot | msggrep -X -i -e "^tumbleweed/patterns\|^leap/patterns" -o patterns.pot
#msgcat --unique -o __packages.pot patterns.pot _packages.pot && mv __packages.pot _packages.pot

log "Splitting started: $(date)"
for i in patterns {a..z}; do
  I=${i^^}
  log -n "$i "
  cat _packages.pot | msggrep -X -e "^[^\/]\+/\($i\|$I\)" -o $i.pot
  if [ -e "$i.pot" ]; then
    msgcat --unique --force-po -o __packages.pot $i.pot _packages.pot && mv __packages.pot _packages.pot
  fi
done
# move all the remaining packges in a
tail -n +8 a.pot >> _packages.pot && mv _packages.pot a.pot

for ii in aspell ghc gnome golang google gstreamer gtk kde leechcraft libreoffice libqt lib mate myspell perl php python rubygem tesseract texlive-specs texlive wx xfce4 yast2; do
  firstChar=${ii:0:1}
  [ -e "$firstChar.pot" ] || continue
  log -n "$ii "
  msggrep -X -e "^[^/]\+/$ii" "$firstChar.pot" -o $ii.pot --no-wrap
  if [ -e "$ii.pot" ]; then
    msgcat --unique -o _$firstChar.pot $ii.pot $firstChar.pot && mv _$firstChar.pot $firstChar.pot
  fi
done
log ""
log "Splitting finished: $(date)"

log "Statistics: "
for i in *.pot; do
  log -n "$i: "
  move_if_changed $i ../50-pot/$i
done
cd ..
rm -rf 50-lists

exit 0
