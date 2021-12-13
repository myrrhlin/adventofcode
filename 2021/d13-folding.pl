#! /usr/bin/env perl

# https://adventofcode.com/2021/day/13

use 5.26.0;
use warnings;
use feature 'signatures', 'postderef';
no warnings 'experimental::signatures';
use autodie;

use Getopt::Long;
use Path::Tiny;
use Carp::Always;
use Data::Printer;
use List::Util qw<uniq pairs max>;

my %opt;
GetOptions(\%opt, 
  'test',
  'v|verbose',
) or die "couldn't parse options: @ARGV";

my $file = $ARGV[0] || 'd13.lis';

my %cnt;
$cnt{_lines} = my @lines = grep /^\S/, $opt{test} ? 
  do {local $/; split /\n/, <DATA>} 
  : path($file)->lines({chomp => 1});

$cnt{folds} = my @folds = grep s/^fold along //, @lines;
$cnt{coords} = my @coords = grep /^\d+,\d+/, @lines;

sub foldto {
  my ($fold, $x, $y) = @_;
  my ($dir, $line) = split /=/, $fold;
  if ($dir eq 'x') {
    return $x, $y if $x < $line;
    return (2*$line - $x), $y
  } else { #dir eq 'y'
    return $x, $y if $y < $line;
    return $x, (2*$line - $y);
  }
}

sub sorter {
  my ($ax, $ay) = split /,/,$a;
  my ($bx, $by) = split /,/,$b;
  # $ay <=> $by || $ax <=> $bx;  # y-sort
  $ax <=> $bx || $ay <=> $by;  # x-sort
}
sub ncols {
  1+ max map {(split /,/)[0]} @_;
}
sub nrows {
  1+ max map {(split /,/)[1]} @_;
}
sub display {
  my @data = @_;
  my $row = ' ' x (ncols @data);
  my @graph = ($row) x (nrows @data);
  my @pcoords = map {split /,/} @data; 
  while (@pcoords) { 
    my ($x, $y) = splice @pcoords, 0, 2;
    substr($graph[$y], $x, 1) = '#';
  }
  say for @graph;
}

my @dots = sort sorter @coords;
foreach my $fold (@folds) {
  say scalar(@dots), ' dots with ', ncols(@dots), ' cols, ', nrows(@dots), ' rows';
  say "folding across $fold";
  @dots = uniq sort sorter map {join ',', @$_} pairs map { foldto($fold, split /,/, $_) } @dots;
}
say scalar(@dots), ' dots remain with ', ncols(@dots), ' cols, ', nrows(@dots), ' rows';
display(@dots);


exit;

__DATA__

6,10
0,14
9,10
0,3
10,4
4,11
6,0
6,12
4,1
0,13
10,12
3,4
3,0
8,4
1,10
2,14
8,10
9,0

fold along y=7
fold along x=5

