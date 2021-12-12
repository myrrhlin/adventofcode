#! /usr/bin/env perl

# https://adventofcode.com/2021/day/8

use 5.26.0;
use warnings;
use feature 'signatures', 'postderef';
no warnings 'experimental::signatures';

use autodie;

use Getopt::Long;
use Path::Tiny;
use Carp::Always;
use Data::Printer;
use List::Util 'sum0';

my %opt;
GetOptions(\%opt, 
  'test',
) or die "couldn't parse options: @ARGV";

my %cnt;

my $file = $ARGV[0] || 'd08.lis';

$cnt{_lines} = my @lines = grep /^\w/, $opt{test} ? 
  do {local $/; split /\n/, <DATA>} 
  : path($file)->lines({chomp => 1});

my @display;  # hashrefs containing wiring data about each 4-digit display:
# patterns is arrayref of the segment patterns used for the 10 numerals
# digits is arrayref of the segment patterns for the display we are trying to read

# order segment pattern alphabetically
sub canon_seg { join '', sort split //, shift }

while (my @items = split ' ', shift @lines) {
  if ('|' eq $items[-1]) {  # continues on next line
    push @items, split ' ', shift @lines;
  }
  die 'bad format' unless $items[10] eq '|' && @items == 15;
  my @pats = map {canon_seg($_)} splice @items, 0, 10;
  shift @items;
  my @digits = map {canon_seg($_)} @items;
  push @display, {digits => \@digits, patterns => \@pats};
}
$cnt{_displays} = @display;


sub find_length ($len, @list) {
  for (my $i = 0; $i < @list; $i++) {
    return $i if length $list[$i] == $len;
  }
  return -1;
}
# number of segments lit for each numeral 0-9
#            0  1  2  3  4  5  6  7  8  9
my @nsegs = (6, 2, 5, 5, 4, 5, 6, 3, 7, 6);
# this function does an in-place re-ordering of arrayref of patterns:
# after this, patterns for numerals 1 4 7 8 are in corresponding positions 
# in the array, and all other positions have patterns that match the 
# required lengths.  we'll swap those around later once we deduce which 
# is which.
sub re_sort ($patterns) {
  foreach my $numeral (reverse 0 .. 9) { # (8, 7, 4, 1)
    my $saved = $patterns->[$numeral];
    next if length $saved == $nsegs[$numeral];
    my $pos = find_length($nsegs[$numeral], @$patterns);
    die 'length must exist!' unless $pos >= 0;
    $patterns->[$numeral] = $patterns->[$pos];
    $patterns->[$pos] = $saved;
  }
}
# replace some patterns in the digits with actual numerals 1 4 7 8
sub solve_easy_digits ($digits) {
  my %digitmap = (2 => 1, 4 => 4, 3 => 7, 7 => 8);
  @$digits = map {$digitmap{length $_} // $_} @$digits ;
}

sub solve_segments ($patterns) {
  my @segmap;  # we could save this, but don't need it externally...
  # segmap contains the letter that represents each segment (a .. g)
  $segmap[0] = eval "'$patterns->[7]' =~ tr/$patterns->[1]//dr";  # a
  foreach my $six (0, 6, 9) {
    my $nonseven = eval "'$patterns->[$six]' =~ tr/$patterns->[7]//dr";
    next unless length $nonseven == 4;
    $segmap[2] = eval "'abcdefg' =~ tr/$patterns->[$six]//dr";  # c
    unless ($six == 6) {  # identified the numeral 6
      ($patterns->[6], $patterns->[$six]) = ($patterns->[$six], $patterns->[6]);
    }
    last;
  }
  $segmap[5] = $patterns->[1] =~ s/$segmap[2]//r; # f
  foreach my $nine (0, 9) {
    my $nonfour = eval "'$patterns->[$nine]' =~ tr/$patterns->[4]//dr";
    next unless length $nonfour == 2;
    $segmap[4] = eval "'abcdefg' =~ tr/$patterns->[$nine]//dr";  # e
    unless ($nine == 9) {  # identified the numeral 9
      ($patterns->[9], $patterns->[$nine]) = ($patterns->[$nine], $patterns->[9]);
    }
    last;
  }
  $segmap[3] = eval "'abcdefg' =~ tr/$patterns->[0]//dr"; # d
  foreach my $two (2, 3, 5) {
    my $nonnine = eval "'$patterns->[$two]' =~ tr/$patterns->[9]//dr";
    next unless length $nonnine;  # nine has _all_ segments of the 3 and 5
    # we already knew which letter was segment e
    unless ($two == 2) {  # identified the numeral 2
      ($patterns->[2], $patterns->[$two]) = ($patterns->[$two], $patterns->[2]);
    }
    last;
  }
  # two segments left: b, g
  my $found = join '', sort grep defined, @segmap;
  foreach my $three (3, 5) {
    my $nonfound = eval "'$patterns->[$three]' =~ tr/$found//dr";
    next unless length $nonfound == 1;
    $segmap[6] = $nonfound;  # segment g
    unless ($three == 3) {  # identified the numeral 3
      ($patterns->[3], $patterns->[$three]) = ($patterns->[$three], $patterns->[3]);
    }
    last;
  }

  # only one segment left: b
  $found = join '', sort grep defined, @segmap;
  $segmap[1] = eval "'abcdefg' =~ tr/$found//dr";  # b
  #print STDERR 'segments: '; p @segmap;
  #print STDERR 'solved patterns: '; p $patterns;
}
sub set_reading ($display) {
  # by now, all patterns are in proper place, so we can just translate
  my %pmap = reverse map { $_ => $display->{patterns}[$_] } 0 .. 9;
  $display->{reading} = join '', map {$pmap{$_} // $_} @{$display->{digits}};
}


foreach my $disp (@display) {
  re_sort($disp->{patterns});
  solve_easy_digits($disp->{digits});
  solve_segments($disp->{patterns});
  set_reading($disp);
  say "reading $disp->{reading} came from patterns: @{$disp->{digits}}";
}

$cnt{easy_digits} = grep /^\d/, map {$_->{digits}->@*} @display;
$cnt{reading_sum} = sum0 map {$_->{reading}} @display;
p %cnt;

exit;

__DATA__

acedgfb cdfbe gcdfa fbcad dab cefabd cdfgeb eafb cagedb ab |
cdfeb fcadb cdfeb cdbaf

