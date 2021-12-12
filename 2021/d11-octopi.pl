#! /usr/bin/env perl

# https://adventofcode.com/2021/day/11

use 5.26.0;
use feature 'signatures', 'postderef';
no warnings 'experimental::signatures';

use autodie;

use Getopt::Long;
use Path::Tiny;
use Carp::Always;
use Data::Printer;
use List::Util qw<sum0 min reduce>;

my %opt;
GetOptions(\%opt, 
  'test',
  'time=i',
  'sync',
  'v|verbose',
) or die "couldn't parse options: @ARGV";
my $stopsync = $opt{sync};
my $stoptime = $opt{time};
$stoptime ||= 100 unless $stopsync;

my %cnt;

my $file = $ARGV[0] || 'd11.lis';

$cnt{_lines} = my @lines = grep /^\S/, $opt{test} ? 
  do {local $/; split /\n/, <DATA>} 
  : path($file)->lines({chomp => 1});

my $xrng = $cnt{lengths} = length($lines[0]);
my $yrng = @lines;
# @lines represent a grid, we'll map x,y coords onto it
# upper left is 0,0, upper right is 9,0, lower right is 9,N

my @school = map {split //, $_} @lines;  # assume its a rectangle

sub i2xy ($i) { use integer; return $i % $xrng, $i / $xrng }
sub xy2i ($x, $y) { $y*$xrng + $x }

# indexes of surrounding locations
sub iisurrounds ($i) {
  my ($x, $y) = i2xy($i);
  my @i;
  if ($i >= $xrng) {
    push @i, $i-$xrng-1 if $x > 0;  # upper left
    push @i, $i-$xrng;              # above
    push @i, $i-$xrng+1 if $x < $xrng-1;  # upper right
  }
  push @i, $i-1 if $x>0;            # left
  push @i, $i+1 if $x<$xrng-1;      # right
  if ($y < $yrng-1) {
    push @i, $i+$xrng-1 if $x > 0;  # lower left
    push @i, $i+$xrng;  # below
    push @i, $i+$xrng+1 if $x < $xrng-1;  # lower right
  }
  return @i;
}

sub flashall {
  return unless 
    my @flashing = grep {$school[$_] > 9} 0 .. $#school;
  say scalar(@flashing), ' octopi are flashing';
  $cnt{flash} += @flashing;
  $school[$_] = 0 for @flashing;
  $school[$_] &&= $school[$_]+1 for map {iisurrounds($_)} @flashing;
  return @flashing;
}

sub display {
  my @copy = @school;
  while (my @line = splice(@copy, 0, $xrng)) {
    say join '', @line;
  }
}

my $t;
TIMESTEP: while (1) {
  $t++;
  $school[$_]++ for 0 .. $#school;   # everybody gains energy
  my $flashing = 0;
  while (my $flashed = flashall()) { # some went off
    $flashing += $flashed;
    next unless $flashing == @school;
    say "ALL octopi flashed at time $t";
    last TIMESTEP if $stopsync;
    last;
  }
  say "after time $t there have been $cnt{flash} flashes";
  display() if ! $t%10 && $xrng < 20;
  last if $stoptime && $t >= $stoptime;
}
p %cnt;

exit;

__DATA__

5483143223
2745854711
5264556173
6141336146
6357385478
4167524645
2176841721
6882881134
4846848554
5283751526

