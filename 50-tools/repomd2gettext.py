#
# Copyright (c) 2017 SUSE Linux GmbH
#
# This file is part of repomd2po.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

"""
This file parses the XML metadata of repomd repositories and
"""

from datetime import datetime
import requests
import sys
import os
import re
import zlib
from lxml import etree as xml
from urllib.parse import unquote


REPOMD_NAMESPACES = {'md': "http://linux.duke.edu/metadata/common",
                     'repo': "http://linux.duke.edu/metadata/repo",
                     'rpm': "http://linux.duke.edu/metadata/rpm"}


def gettextQuote(string):
    """
    @returns quoted string for use in gettext PO(T) files.
    """

    # TODO: Handle newline, tab, some unicode (?)
    return '"{}"'.format(string.replace('\\', '\\\\')
                         .replace('"', '\\"')
                         # Only kept to be bug-compatible to not lose any
                         # existing translations. Normally '\n' -> '\\n' is fine,
                         # but the old script only kept newlines if followed
                         # by '-', '*' or another newline.
                         .replace('\n-', '\\n-')
                         .replace('\n*', '\\n*')
                         .replace('\n\n', '\\n\\n')
                         .replace('\n', ' '))


def gettextDateTimeUTC(when):
    """
    Formats when to be used in PO headers.
    """

    return when.strftime("%Y-%m-%d %H:%M+0000")


def readMetadata(data):
    """
    Reads XML from data, returns dict of
    packagename => {'summary': "...", 'description': "...", 'sourcepkg': "..."}
    """
    tree = xml.fromstring(data)

    packages = {}

    package_iter = xml.XPath('/md:metadata/md:package', namespaces=REPOMD_NAMESPACES)
    name_xpath = xml.XPath('string(./md:name/text())', namespaces=REPOMD_NAMESPACES)
    summary_xpath = xml.XPath('string(./md:summary/text())', namespaces=REPOMD_NAMESPACES)
    description_xpath = xml.XPath('string(./md:description/text())', namespaces=REPOMD_NAMESPACES)
    sourcepkg_xpath = xml.XPath('string(./md:format/rpm:sourcerpm/text())', namespaces=REPOMD_NAMESPACES)
    category_xpath = xml.XPath('string(./md:format/rpm:provides/rpm:entry[@name="pattern-category()"]/@ver)', namespaces=REPOMD_NAMESPACES)

    for package in package_iter(tree):
        name = name_xpath(package)
        if name in packages:
            continue
        sourcepkg = '-'.join(sourcepkg_xpath(package).split("-")[:-2])
        packages[name] = {'summary': summary_xpath(package),
                          'description': description_xpath(package),
                          'category': unquote(category_xpath(package)),
                          'sourcepkg': sourcepkg}
    return packages


def gettextForPackage(packagename, package, distro):
    if packagename != package['sourcepkg'] and package['sourcepkg']:
        packagename = "{}/{}".format(package['sourcepkg'], packagename)

    if distro.startswith('SLE'):
        distro = 'SLE'

    if distro == 'SLE' and not packagename.startswith('pattern'):
        return None

    comment = "{}/{}".format(distro, packagename)
    ret = ""
    if package['summary'] != "":
        ret += """\n#. {comment}/summary
msgid {summary}
msgstr ""
""".format(comment=comment, summary=gettextQuote(package['summary']))

    if package['description'] != "":
        ret += """\n#. {comment}/description
msgid {description}
msgstr ""
""".format(comment=comment, description=gettextQuote(package['description']))

    if package['category'] != "":
        ret += """\n#. {comment}/category
msgid {category}
msgstr ""
""".format(comment=comment, category=gettextQuote(package['category']))


    return ret


def fetchPrimaryXML(baseurl):
    repoindex_req = requests.get(baseurl + "/repodata/repomd.xml")
    repoindex = xml.fromstring(repoindex_req.content)
    path_primary = repoindex.xpath("string(./repo:data[@type='primary']/repo:location/@href)",
                                   namespaces=REPOMD_NAMESPACES)
    primary_req = requests.get(baseurl + "/" + path_primary)
    return zlib.decompress(primary_req.content, wbits=zlib.MAX_WBITS|32)


def main(argv):
    if len(argv) != 3:
        print("Usage: repomd2gettext.py repourl distroname")
        return 1

    distro = argv[2]
    md = readMetadata(fetchPrimaryXML(argv[1]))

    timestamp = datetime.utcnow()
    header = """msgid ""
msgstr ""
"Project-Id-Version: repomd2gettext\\n"
"POT-Creation-Date: {}\\n"
"MIME-Version: 1.0\\n"
"Content-Type: text/plain; charset=UTF-8\\n"
"Content-Transfer-Encoding: 8bit\\n"
""".format(gettextDateTimeUTC(timestamp))

    print(header)

    for packagename, package in md.items():
        text = gettextForPackage(packagename, package, distro)
        if text:
            print(text)

    return 0


sys.exit(main(sys.argv))
