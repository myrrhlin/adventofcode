#! /usr/bin/env perl

# https://adventofcode.com/2021/day/6

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
  'count=i',
  'days=i',
  'test',
  'dist',
) or die "couldn't get options: @ARGV";
$opt{dist}++ if $opt{test};

my ($stopcount, $stopday) = ($opt{count}, $opt{days});
$stopday ||= 80 unless $stopcount;

my %cnt;

my $file = $ARGV[0] || 'd06.lis';

my @lines = grep /^\d/, $opt{test} ? 
  do {local $/; split /\n/, <DATA>} 
  : path($file)->lines({chomp => 1});
$cnt{_lines} = @lines;

my @count;

foreach my $timer (split /,/, shift @lines) {
  $count[$timer]++;
}
say "Initially, total fish: ", sum0 @count;
say "  numbers in each age (0-6): ", join ',', map {$_ // 0} @count;

my $days = 0;
while (1) {
  $days++;
  if (my $spawned = shift @count) {
    $count[6] += $spawned;
    $count[8] += $spawned;
  }
  my $total = sum0 @count;
  printf "after %2u days, total fish: %u\n", $days, $total;
  say "  numbers in each age (0-8): ", join ',', map {$_ // 0} @count if $opt{dist};
  last if $stopcount && $total >= $stopcount;
  last if $stopday   && $days == $stopday;
}

exit;

__DATA__

3,4,3,1,2

