#!/bin/bash
for pot in 50-pot/*.pot; do
    bn="${pot##*/}"
    bn="${bn%.pot}"
    for lang in */po; do
	lang="${lang%/po}"
	o="$lang/po/$bn.$lang.po"
	[ -e "$o" ] || continue
	if msgmerge -q --previous -s --lang="$lang" -o "$o".new "$o" "$pot"; then
	    mv "$o".new "$o"
	fi
    done
done
