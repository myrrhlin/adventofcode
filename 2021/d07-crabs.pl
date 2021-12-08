#! /usr/bin/env perl

# https://adventofcode.com/2021/day/7

use 5.26.0;
use feature 'signatures';
no warnings 'experimental::signatures';

use autodie;

use Getopt::Long;
use Path::Tiny;
use Carp::Always;
use Data::Printer;
use List::Util 'sum0', 'reduce';

my %opt;
GetOptions(\%opt, 
  'test',
  'part2',   # select part 2's fuel cost
) or die "couldn't parse options: @ARGV";

my %cnt;

my $file = $ARGV[0] || 'd07.lis';

$cnt{_lines} = my @lines = grep /^\d/, $opt{test} ? 
  do {local $/; split /\n/, <DATA>} 
  : path($file)->lines({chomp => 1});

my @pos = map {split /,/,$_} @lines; 
say scalar(@pos), " crabs at initial positions: @pos";
my %fuel;  # record total fuel spent for a given end position

sub fcost ($dist) {
  state @costs;
  @costs = (1) unless @costs;
  return my $cost = $costs[$dist-1] ||= fcost($dist -1) + $dist;
}
sub binomial ($dist) {  # same result as fcost function
  use integer;
  return $dist * ($dist+1) /2;
}

sub fuel_of ($middle) {
  my @dist = map {abs($_ - $middle)} @pos;
  my $fuel = $opt{part2}
    ? sum0 map {fcost($_)} @dist
    : sum0 @dist;
  $fuel{$middle} = $fuel;
  say "for final position $middle  total fuel: $fuel";
  say "crab dist: ", map { sprintf('%2u,', $_) } @dist if @dist < 30;
  return $fuel;
}

my $sum = sum0 @pos;
my $avg = int $sum / scalar(@pos);  # starting guess

my $delta = (fuel_of($avg+1) > fuel_of($avg)) ? -1 : 1;

my $minpos = my $middle = $avg;
while (1) {
  my $oldfuel = $fuel{$middle};
  $middle += $delta;
  if (fuel_of($middle) < $oldfuel) {
    $minpos = $middle;
  } else {  # we found the minimum, there is only one
    last;
  }
}

p %fuel;
say "minimum position $minpos, fuel $fuel{$minpos}";

exit;

__DATA__

16,1,2,0,4,2,7,1,2,14

