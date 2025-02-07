#!/usr/local/bin/perl
###################################################################
#
# FILE:    cmpl.pl
# PURPOSE: generate completion strings for singular emacs mode
# AUTHOR: obachman
####
$Usage = <<EOT;
$0 [-Singular binary] [-hlp file] [cmpl 'hlp|cmd|lib'] [-help]
Generates completion strings for singular emacs mode and prints it to STDOUT
EOT

#
# default settings of command-line arguments
#
$Singular = "../Singular/Singular";
$hlp = "../doc/singular.info";
$cmpl = "cmd";
$ex_dir= "../examples";
%symbol = (cmd=>"singular-commands-alist",
	   hlp=>"singular-help-topics-alist",
	   lib=>"singular-standard-libraries-alist",
	    ex=>"singular-examples-alist");

#
# parse command line options
#
while (@ARGV && $ARGV[0] =~ /^-/)
{
  $_ = shift(@ARGV);
  if (/^-S(ingular)?$/)  { $Singular = shift(@ARGV); next;}
  if (/^-hlp$/)          { $hlp = shift(@ARGV); next;}
  if (/^-c(mpl)?$/)      { $cmpl = shift(@ARGV); next;}
  if (/^-e(x_dir)?$/)    { $ex_dir = shift(@ARGV); next;}
  if (/^-h(elp)?$/)      { print $Usage; exit;}
  die "Unrecognized option: $_\n$Usage";
}

#
# get array of strings
#
if ($cmpl eq 'cmd')
{
  $strings = `$Singular -tq --exec='reservedName();\$'`;
  die "Error in execution of: $Singular -tq --exec='reservedName();\$': $!\n"
    if ($?);
  @strings = map "(\"$_\")", split(/\s+/, $strings);
}
elsif ($cmpl eq 'lib')
{
  # Sort libraries in REVERSE order! (Menu is created from bottom to
  # top in singular.el)
  @strings = map "(\"$_\")", sort {$b cmp $a} split(/\s+/, <>);
}
elsif ($cmpl eq 'hlp')
{
  open(FH, "<$hlp") || die "Can not open file $hlp: $!\n";
  while (<FH>)
  {
    if (/Node: Index/)
    {
      while (<FH>)
      {
	last if /\* Menu:/;
      }
      <FH>;
      while (<FH>)
      {
	last if /^\s*$/;
  	if ( /^\* (.*):\s*(.*).\s*/ ) {
          $node = $1; $rawNode = $2;
	  # remove duplicate counter from node
	  $node =~ s/(.*) <\d+>$/$1/;
  	  # quote characters special to Emacs
  	  $node =~ s/([\"#\\])/\\\1/g;    #'
  	  $rawNode =~ s/([\"#\\])/\\\1/g; #'
	  # only the first occurrence of $node is inserted to @string!
          # all subsequent entries are discarded.
	  push @strings, "(\"$node\" . \"$rawNode\")" if $node ne $prev;
	  $prev = $node;
  	}
      }
      last;
    }
  }
  close(FH);
}
elsif ($cmpl eq 'ex')
{
  @strings = <$ex_dir/*.sing>;
  map {$_ =~ s|.*/(.*?)\.sing$|(\"$1\")|;} @strings;
}
else
{
  die "Error: Can not make completion list for $cmpl\n $Usage";
}
print STDOUT <<EOT;
; Do not edit this file: It was automatically generated by $0
(setq $symbol{$cmpl}
  '(
EOT
#' prevents breaking of fontification

foreach $string (@strings)
{
  print STDOUT "    $string\n";
}

print STDOUT "))\n";

