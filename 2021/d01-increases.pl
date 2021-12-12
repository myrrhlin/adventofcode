#! /usr/bin/env perl

# https://adventofcode.com/2021/day/1

use 5.26.0;
use warnings;

use Path::Tiny;

my $window = int( $ARGV[0] || 1 );
die "window cannot be less than 1" unless $window > 0;

my @nums = map {0+$_} path('d01.lis')->lines({ chomp => 1 });
say "examining ", scalar(@nums), " integers with window size $window";

my $cnt;

for (my $i = $window-1; $i < @nums; $i++) {
  next unless $nums[$i] > $nums[$i-$window];
  $cnt++;
  # say "elem $i  $nums[$i] was larger than $nums[$i-$window]"
}
say $cnt, ' increases';

