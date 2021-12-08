#! /usr/bin/env perl

# https://adventofcode.com/2021/day/2

use 5.26.0;

use Path::Tiny;
use Data::Printer;

my %cnt;

my $file = $ARGV[0] || 'd02.lis';

foreach (path($file)->lines) {
  next if /^#/;
  $cnt{_lines}++;
  my ($dir, $dist) = split ' ';
  $cnt{"d_$dir"} += $dist;
  if ($dir eq 'up') {
    $cnt{aim} -= $dist;
  } elsif ($dir eq 'down') {
    $cnt{aim} += $dist;
  } elsif ($dir eq 'forward') {
    $cnt{depth_b} += $cnt{aim}*$dist;
  }
}
$cnt{depth_a} = $cnt{d_down}-$cnt{d_up};
$cnt{_product_a} = $cnt{depth_a} * $cnt{d_forward};
$cnt{_product_b} = $cnt{depth_b} * $cnt{d_forward};
p %cnt;
