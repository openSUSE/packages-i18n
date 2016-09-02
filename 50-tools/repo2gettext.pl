#!/usr/bin/perl
# Copyright (c) 2007, 2008, SUSE Linux Products GmbH
# Modified in 2015 for the needs of openSUSE project by Aleksandr Melentev <minton@opensuse.org>

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
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

use Locale::gettext;
use POSIX;     # Needed for setlocale()
use utf8;
use open qw(:std :utf8); # treat files and STD input as UTF-8*

my $indesc = 0;
my $descr = '';

my @date = localtime;
my $time = sprintf("%d-%02d-%02d %02d:%02d:%02d",$date[5]+1900,$date[4]+1,$date[3],$date[2],$date[1],$date[0]);

print "# This file was automatically generated\n";
print "msgid \"\"\n";
print "msgstr \"\"\n";
print "\"POT-Creation-Date: $time\\n\"\n";
print "\"PO-Revision-Date: YEAR-MO-DA HO:MI+ZONE\\n\"\n";
print "\"Content-Type: text/plain; charset=UTF-8\\n\"\n";
print "\"Content-Transfer-Encoding: 8-bit\\n\"\n";
print "\n";

sub formatAbsatz($)
{
    my $string = shift;

    $string =~ s/\n-/\@LINE\@-/g;
    $string =~ s/\n\*/\@LINE\@*/g;
    $string =~ s/\n/ /g;
    $string =~ s/\\/\@BACK\@/g;
    $string =~ s/\@LINE\@/\\n/g;
    $string =~ s/\"/\\\"/g;
    $string =~ s/\@BACK\@/\\\\/g;
    return "\"$string\"\n";
}

sub formatStr($) {
        my $string = shift;

        if ($string !~ m/\n/) {
                return formatAbsatz($string);
        }
        my $first = 1;
        my $out = '';
        foreach my $parag (split(/\n\n/, $string)) {
           if (!$first) {
                $out .= "\"\\n\\n\"\n";
           }
           $first = 0;
           $out .= formatAbsatz($parag);
        }
        return $out;
}


sub output($$)
{
	my $string = shift;
	my $comment = shift;
        my $out = formatStr($string);
	print "#. $comment\n";
	print "msgid \"\"\n";
	print $out;
	print "msgstr \"\"\n\n";
}

my @list;
if ($ARGV[0]) {
  open(LIST, $ARGV[0]);
  while ( <LIST> ) {
    chomp;
    push(@list, $_);
  }
  close(LIST);
  shift @ARGV;
}

my %sources;
my $name;
if ($ARGV[0]) {
    open(SOURCES, $ARGV[0]);
    while ( <SOURCES> ) {
	chomp;
	if (m/^=Pkg: (\S+) /) {
	    $name = $1;
	}
	if (m/^=Src: (\S+) /) {
	    $sources{$name} = $1;
	}
    }
    close(SOURCES);
    shift @ARGV;
}

sub ignore($)
{
  my $pack = shift;
  return 0 if scalar @list == 0;
  foreach (@list) {
    return 0 if ($pack eq $_)
  }
  return 1;
}

open(DESCR, "<:encoding(UTF-8)", $ARGV[0]);
shift @ARGV;
my $distro = $ARGV[0];
my $lastpack = '';
my $lastname;
while ( <DESCR> ) {
    if ($_ =~ m/^=Ver:/ || $_ =~ m/^#/) {
	next;
    }
    if ($_ =~ m/^=Pkg:\s*(\S+)\s/)  {
	$lastpack = $1;
	$lastname = $1;
	if ($sources{$lastpack} ne $lastpack) {
	    $lastname = $sources{$lastpack} . "/" . $lastpack;
	}
	next;
    }
    if ($_ =~ m/^=Sum:\s*(.*)\s*$/) {
        my $summary = $1;
        next if ignore($lastpack);
	output($summary, $distro . "/" . $lastname . "/summary");
	next;
    }
    if ($_ =~ m/^\+Des:/) {
	$indesc = 1;
	next;
    }
    if ($_ =~ m/^-Des:/) {
	$indesc = 0;
        if (!ignore($lastpack)) {
	  $descr =~ s,\s*Authors:\n--------[.\s\n]*,\@AUTHORS\@,g;
	  $descr =~ s,\@AUTHORS\@[\S\s\n]*,\@AUTHORS\@,g;
	  $descr =~ s,\@AUTHORS\@,,g;
	  output($descr, $distro . "/" . $lastname . "/description");
        }
	$descr = '';
	next;
    }

    if ($indesc == 1) {
	my $line = $_;
	chomp $line;
	if ($descr) {
	    $descr = $descr . "\n" . $line;
	} else {
	    $descr = $line;
	}
	next;
    }

    die "DIE " . $_;
}
