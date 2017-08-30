#! /bin/sh
set -e
## get package lists
rm -rf 50-lists
mkdir 50-lists
cd 50-lists

for distro in tumbleweed leap; do
## set URLs
  case $distro in
    "leap") URL="distribution/leap/42.3";;
    "tumbleweed") URL="tumbleweed";;
    *) continue;;
  esac

## get package descriptions
  echo "Generating POT file for ${distro}..."
  python3 ../50-tools/repomd2gettext.py http://download.opensuse.org/${URL}/repo/oss/suse "${distro}" | msguniq > "${distro}-packages._pot"

  echo "OK"
done

## Merge distros
rm -f *.pot
echo "$(echo "$(cat tumbleweed-packages._pot) $(tail -n +8 leap-packages._pot)" | msguniq | grep -v "#-#-#-#")" > _packages.pot
#cat _packages.pot | msggrep -X -i -e "^tumbleweed/patterns\|^leap/patterns" -o patterns.pot
#msgcat --unique -o __packages.pot patterns.pot _packages.pot && mv __packages.pot _packages.pot

echo "Splitting started: $(date)"
for i in patterns {a..z}; do
  I=${i^^}
  echo -n "$i "
  cat _packages.pot | msggrep -X -e "^tumbleweed/$i\|^leap/$i\|^tumbleweed/$I\|^leap/$I" -o $i.pot
  msgcat --unique -o __packages.pot $i.pot _packages.pot && mv __packages.pot _packages.pot
done
tail -n +8 a.pot >> _packages.pot && mv _packages.pot a.pot

for ii in aspell ghc gnome golang google gstreamer gtk kde leechcraft libreoffice libqt lib mate myspell perl php python rubygem tesseract texlive-specs texlive wx xfce4 yast2; do
  firstChar=${ii:0:1}
  echo -n "$ii "
  msggrep -X -e "^tumbleweed/$ii\|^leap/$ii" "$firstChar.pot" -o $ii.pot --no-wrap
  msgcat --unique -o _$firstChar.pot $ii.pot $firstChar.pot && mv _$firstChar.pot $firstChar.pot
done
echo ""
echo "Splitting finished: $(date)"

echo "Statistics: "
for i in *.pot; do echo -n "$i: "; mv $i ../50-pot/$i; msgfmt --statistics -o /dev/null ../50-pot/$i; done
cd ..
rm -rf 50-lists

exit 0
