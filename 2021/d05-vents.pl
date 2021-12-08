#! /usr/bin/env perl

# https://adventofcode.com/2021/day/5

use 5.26.0;
use feature 'signatures';
no warnings 'experimental::signatures';

use autodie;

use Path::Tiny;
use Carp::Always;
use Data::Printer;
use List::Util 'sum0', 'max';

my $do_diagonals = 1;

my %cnt;

my $file = $ARGV[0] || 'd05.lis';
my @lines = grep /^\d/, path($file)->lines({chomp => 1});
$cnt{_lines} = @lines;

my @vents;
for (@lines) {
  next unless m/^(\d+),(\d+) -> (\d+),(\d+)/;
  my ($x1, $y1, $x2, $y2) = ($1, $2, $3, $4);
  if (!$do_diagonals && $x1 != $x2 && $y1 != $y2) {
    warn "line neither horizontal nor vertical: $_";
    next;
  }
  push @vents, [$x1, $y1, $x2, $y2];
}
$cnt{_vents} = @vents;


my $graph = [];
# for x:y [ [0:0, 1:0, 2:0, ...], [0:1, 1:1, 2:1, ..], ...]
# so each arrayref is a row (constant y)

sub nrows {
  my $nrows = @$graph;
}
sub ncols {
  my $ncols = max map { scalar @{$graph->[$_]} } 0 .. nrows()-1;
}
sub col ($x) {
  my @col = map { $graph->[$_][$x] // 0 } 0 .. nrows()-1;
}

sub display {
  print '   |';
  printf('%2d ', $_) for 0 .. 19;
  say "\n   |", '-'x60;
  my $r = 0;
  foreach my $row (@$graph) {
    printf('%2d |', $r++);
    printf('%2s ', $_) for @$row;
    print "\n";
  }
}

sub plot ($x, $y) {
  # ensure data closer to origin exist (no undef elements)
  # if (nrows() < $y) {
    $graph->[$_] //= [] for 0 .. $y-1;
  $graph->[$y][$_] //= '' for 0 .. $x-1;
  $graph->[$y][$x]++;
}

sub drawvent ($vent) {
  my ($x1, $y1, $x2, $y2) = @$vent;
  say "drawing vent ($x1,$y1) -> ($x2,$y2)";
  my @ds;  # (integer) step for drawing (dx, dy)
  if    ($x1 < $x2) { $ds[0]++ }   # moving x-ward
  elsif ($x1 > $x2) { $ds[0]-- }
  if    ($y1 < $y2) { $ds[1]++ }   # moving y-ward
  elsif ($y1 > $y2) { $ds[1]-- }
  while (1) {
    plot($x1, $y1);
    last unless @ds;
    last if $x1 == $x2 && $y1 == $y2;
    ($x1, $y1) = ($x1 + $ds[0]//0, $y1 + $ds[1]//0);
  }
}
sub overlaps ($threshold = 2) {
  my $cnt = grep {$_ >= $threshold} map {@$_} @$graph;
}

p %cnt;

drawvent($_) for @vents;
display if ncols() <= 20;
say "graph has ", nrows(), ' rows and ',ncols(), ' columns';
say overlaps(), " overlapping vents";

exit;

__DATA__

0,9 -> 5,9
8,0 -> 0,8
9,4 -> 3,4
2,2 -> 2,1
7,0 -> 7,4
6,4 -> 2,0
0,9 -> 2,9
3,4 -> 1,4
0,0 -> 8,8
5,5 -> 8,2

