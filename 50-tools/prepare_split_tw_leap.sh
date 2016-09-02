#! /bin/sh
set -e
## get package lists
rm -rf 50-lists
mkdir 50-lists
cd 50-lists

for distro in tumbleweed leap; do
## set URLs
  case $distro in
    "leap") URL="distribution/leap/42.1";;
    "tumbleweed") URL="tumbleweed";;
    *) continue;;
  esac

## get package descriptions
  curl -s http://downloadcontent.opensuse.org/$URL/repo/oss/suse/setup/descr/packages.en.gz | gzip -c -d > $distro-packages.en
  curl -s http://downloadcontent.opensuse.org/$URL/repo/oss/suse/setup/descr/packages.gz | gzip -c -d > $distro-packages
  echo "Generating $distro lists..."
  list=$distro;
  {
  IFS=$'\n'
  pkgnames=($(grep '=Pkg:' $list-packages|cut '-d ' -f2))
  srcpkgnames=($(grep '=Src:' $list-packages|cut '-d ' -f2))
  }
  pkg_num=${#pkgnames[*]}

  rm -f $list-*.list
  echo -n "" > pkg_$list.list
  echo -n "" > src_$list.list
  for ((i=0;i<$pkg_num;i++)); do
    echo "${srcpkgnames[$i]}" >> src_$list.list;
    echo "${pkgnames[$i]}" >> pkg_$list.list;
  done
  sort -fu src_$list.list > $list.new && mv $list.new src_$list.list
  sort -fu pkg_$list.list > $list.new && mv $list.new pkg_$list.list
  echo "$list has $(cat src_$list.list|wc -l) source packages with $(cat pkg_$list.list|wc -l) packages"

  echo -n "Converting $distro: "
  perl ../50-tools/repo2gettext.pl pkg_$list.list $distro-packages $distro-packages.en $distro > $distro-packages._pot
  #msguniq -o $distro-packages._pot $distro-packages._pot
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
