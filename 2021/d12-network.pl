#! /usr/bin/env perl

# https://adventofcode.com/2021/day/12

use 5.26.0;
use warnings;
use feature 'signatures', 'postderef';
no warnings 'experimental::signatures';
use autodie;

use Getopt::Long;
use Path::Tiny;
use Carp::Always;
use Data::Printer;
use List::Util qw<uniq>;

my %opt;
GetOptions(\%opt, 
  'test',
  'v|verbose',
  'doublesmall',
) or die "couldn't parse options: @ARGV";
$opt{doublesmall} //= 0;

my $file = $ARGV[0] || 'd12.lis';

my %cnt;
$cnt{_lines} = my @lines = grep /^\S/, $opt{test} ? 
  do {local $/; split /\n/, <DATA>} 
  : path($file)->lines({chomp => 1});

my %link;  # list of edges connected to each node
my @paths; # valid paths to end

sub nodily {
  return -1 if $a eq 'start' || $b eq 'end';
  return 1 if $a eq 'end' || $b eq 'start';
  return $a cmp $b;
}

# add all edges to inventory of each node
foreach my $line (@lines) {
  my @caves = sort nodily split /\-/, $line;
  foreach my $node (@caves) {
    my @nodes = grep {$_ ne $node} @caves;
    $link{$node}->@* = sort nodily uniq $link{$node}->@*, @nodes;
  }
}

# given a path (in-progress), list possible nodes for next link
sub nextlinks {
  my @branch = @_;
  my %cnt;
  $cnt{$_}++ for @branch;
  my $small_repeated = grep {$cnt{$_} > 1} grep /^[a-z]+$/, keys %cnt;
  my $tail = $branch[-1];
  my @smalls = grep !/^start$/, grep /^[a-z]+$/, $link{$tail}->@*;
  my @nexts  = grep /^[A-Z]+$/, $link{$tail}->@*;  # larges first
  push @nexts, grep {($cnt{$_}//0) + $small_repeated < 1 + $opt{doublesmall}} @smalls;
  say join('-',@branch), ' +(',join('|',@nexts),')' if $opt{v};
  return @nexts;
}

# given a path (in progress), check each valid link for end, or recurse
sub find_end (@seq) {
  return unless my @choices = nextlinks(@seq);
  foreach my $link (@choices) {
    if ($link eq 'end') {
      # only save paths that reach the 'end'
      push @paths, [@seq, $link];
      next;
    }
    find_end(@seq, $link);
  }
}

find_end('start');

say join('-', @$_) for @paths;
say scalar(@paths), ' paths to end';

exit;

__DATA__

dc-end
HN-start
start-kj
dc-start
dc-HN
LN-dc
HN-end
kj-sa
kj-HN
kj-dc

