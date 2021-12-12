#! /usr/bin/env perl

# https://adventofcode.com/2021/day/9

use 5.26.0;
use warnings;
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
  'v|verbose',
) or die "couldn't parse options: @ARGV";

my %cnt;

my $file = $ARGV[0] || 'd09.lis';

$cnt{_lines} = my @lines = grep /^\w/, $opt{test} ? 
  do {local $/; split /\n/, <DATA>} 
  : path($file)->lines({chomp => 1});

my $xrng = $cnt{lengths} = length($lines[0]);
my $yrng = @lines;
# @lines represent a grid, we'll map x,y coords onto it
# upper left is 0,0, upper right is 9,0, lower right is 9,N

my $cave = join '', @lines;  # assume its a rectangle

sub i2xy ($i) { use integer; return $i % $xrng, $i / $xrng }
sub xy2i ($x, $y) { $y*$xrng + $x }

sub ifloor ($i) { return unless defined $i; substr($cave, $i, 1) }

my %basin;  # key is $i of the minimum, value is array ref of $i that flow there

# indexes of surrounding locations
sub iisurrounds ($i) {
  my ($x, $y) = i2xy($i);
  my @i;
  push @i, $i-$xrng if $i>= $xrng;  # above
  push @i, $i-1 if $x>0;            # left
  push @i, $i+1 if $x<$xrng-1;      # right
  push @i, $i+$xrng if $y<$yrng-1;  # below
  return @i;
}
sub isurroundh ($i) { map {ifloor($_)} iisurrounds($i) }
sub iflow ($i) {
  state %to;  # remember where each location flows to
  my $h = ifloor($i);
  return if $h == 9;  # no flow from peaks

  return $to{$i} ||= do {
    # surrounding heights
    my %surr = map {$_ => ifloor($_)} iisurrounds($i);
    my $toh = min values %surr;  # lowest neighboring height
    # pick any of the lowest surrounds, at random, for destination
    my $at = {reverse %surr}->{$toh};
    if ($toh > $h) {
      # we found a minimum!
      $basin{$i} ||= [$i];
      $at = $i;  # flowmap stable point
    } elsif ($toh == $h) {
      # if this happens we might need recursion
      warn "no lower height for flow: from $i ($h) to surrounding @{[ keys %surr ]}";
      say "$i flow picking neighbor $at";
    }
    $at;
  };
}

# pass through to find the minima (stable points on flowmap)
for (my $i = 0; $i<length $cave; $i++) {
  my $to = iflow($i);
  next unless $opt{v};
  my $h = ifloor($i);
  print "surrounds for $i ($h): @{[ iisurrounds($i) ]}";
  say "  flow $i -> ", $to // 'NO', ' (', ifloor($to)//'',')';
}

# now use cached flowmap to assign to basins
for (my $i = 0; $i<length $cave; $i++) {
  next if $basin{$i};  # already got the minima listed
  next unless defined(my $dest = iflow($i));
  $dest = iflow($dest) until $basin{$dest};
  push @{$basin{$dest}}, $i;
}

# printf "basin %u : %s\n", $_, join ',',$basin{$_}->@*  for keys %basin;

my @minima = keys %basin;
say scalar(@minima), " minima: @minima";
my $risk = @minima + sum0 map {ifloor($_)} @minima;
say "total risk: $risk";

my @areas = reverse sort {$a <=> $b} map {scalar(@{$basin{$_}})} keys %basin;
foreach my $imin (keys %basin) {
  my $area = scalar @{$basin{$imin}};
  say "min $imin has area $area" if $area >= $areas[4];
}
my $product = reduce {$a * $b} splice @areas, 0, 3;
say "product $product";

exit;

__DATA__

2199943210
3987894921
9856789892
8767896789
9899965678

