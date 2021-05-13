# packages-i18n
Translations of openSUSE packages descriptions

This repository is set up for migrating package translations from good old svn.opensuse.org instance to the new and shiny [openSUSE Weblate](https://l10n.opensuse.org/) instance.

All the scripts (see `50-tools/`) used to split the main repo descriptions file into gettext messages and preparing the `*.pot` files for translators (see `50-pot/`) will be hosted here as well as translations themselves, which can be made with or without Weblate's help.


Calling `make` in the top directory is what you need in most cases. It generates metadata for Tumbleweed.

You need to update `package-translations` package afterwards.
