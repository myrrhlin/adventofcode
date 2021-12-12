#! /usr/bin/env perl

# https://adventofcode.com/2021/day/4

use 5.26.0;
use warnings;
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
) or die "couldn't parse options: @ARGV";

my $file = $ARGV[0] || 'd04.lis';

my %cnt;
$cnt{_lines} = my @lines = grep !/^#/, $opt{test} ?
  do {local $/; split /\n/, <DATA>}
  : path($file)->lines({chomp => 1});

# a "board" is an arrayref of (probably) 25 different positive integers.
# as numbers are called, we'll mark out numbers on each board
# (replacing them with zeroes) until each one has achieved a complete
# row or column marked, at which point it "wins" - we stop changing 
# it and can compute an arbitrary "score" for its end state.

my @boards;  # arrayrefs for each board

# --------------------------- parse the input
# note: the input file uses zero-indexed integers for everything, so 
# we'll shift everything by $zero, so that we can use 0 for "marking".
# this choice means we don't have to use undef for marking, and saves
# a lot of finicky code dealing with undef values.
my $zero = 1;
my @calls = map {$zero+$_} split /,/, shift @lines;
push @lines, shift @lines;  # ensure a blank last line
$cnt{_calls} = @calls;

my $board = [];
while (@lines) {
  my $line = shift @lines;
  next if $line =~ /^#/;
  $line =~ s/^\s+|\s+$//g;
  if (!$line && @$board) { # blank line, new board
    push @boards, $board;
    $board = [];
  } elsif ($line =~ /^\d/) {
    push @$board, map {$zero+$_} split ' ', $line;
  } else { die "unexpecetd line: $line" }
}
$cnt{_boards} = @boards;


sub size_of ($board) {
  # handle arbitrary sized boards
  state $squares = { reverse map { $_ => $_**2 } 5 .. 12 };
  my $size = $squares->{scalar @$board} || die "cannot size matrix len".scalar(@$board);
  return $size;
}
sub elem_i ($board, $r, $c) { 
  my $size = size_of($board);
  return $r * $size + $c;
}
sub elem ($board, $r, $c) { 
  my $i = elem_i($board, $r, $c);
  return $board->[$i];
}
sub rows_of ($board) {
  my $size = size_of($board);
  my @copy = @$board;
  my @rows;
  push @rows, [splice @copy, 0, $size] while @copy;
  return @rows;
}
sub cols_of ($board) {
  my $size = size_of($board);
  my @cols;
  foreach my $c (0 .. $size-1) {
    foreach my $r (0 .. $size-1) {
      push @{$cols[$c]}, elem($board, $r, $c);
    }
  }
  return @cols;
}
sub diag_of ($board) {
  my $size = size_of($board);
  my @ind = map {$_ * ($size+1)} 0 .. $size-1;
  return my @diag = map {$board->[$_]} @ind;
}
sub rdiag_of ($board) {
  my $size = size_of($board);
  my @ind = map {$_ * ($size-1)} 1 .. $size;
  return my @diag = map {$board->[$_]} @ind;
}

sub markboard ($board, $call) {
  foreach my $i (0 .. (@$board-1)) {
    if ($board->[$i] == $call) {
      $board->[$i] = 0;  # 0 element means marked
      return $i;
    }
  }
  return;  # not found
}
sub win ($board) {
  foreach my $col (cols_of($board)) {
    # a win is all zeroes
    return 'win' unless grep {$_} @$col;
  }
  foreach my $row (rows_of($board)) {
    return 'win' unless grep {$_} @$row;
  }
  return;  # diagonals dont count
  my @e = diag_of($board);
  return 'win' unless grep {$_} @e;
  @e = rdiag_of($board);
  return 'win' unless grep {$_} @e;
}
sub subscore ($board) {
  die "cant score unwon board" unless win($board);
  my @unmarked = map {$_ -$zero} grep {$_} @$board;
  return sum0 @unmarked;
}

sub report ($board) {
  my $size = size_of($board);
  say "board has size $size and subscore ", subscore($board);
  my @rows = map {sprintf('%3u 'x @$_, @$_)} rows_of($board);
  p @rows;
}

my @woncall = (0) x @boards; # which call did each board finish on?

foreach my $call (@calls) {
  $cnt{calls}++;

  my ($checked, @winners);
  foreach my $i (0 .. @boards-1) {
    next if $woncall[$i];
    $checked++;
    next unless my $marked = markboard($boards[$i], $call);
    if (win($boards[$i])) {
      push @winners, $i;
      $woncall[$i] = $cnt{calls};
    }
  }
  say "called $call for $checked unfinished boards";
  next unless @winners;

  say "winner boards with called $call: @winners";
  for (@winners) {
    report($boards[$_]);
    say "score: ", subscore($boards[$_]) * ($call-$zero);
  }
  last unless grep {!$_} @woncall;
}
p %cnt;

# say "number of boards finished on call number:";
# p @woncall;


__DATA__

7,4,9,5,11,17,23,2,0,14,21,24,10,16,13,6,15,25,12,22,18,20,8,19,3,26,1

22 13 17 11  0
 8  2 23  4 24
21  9 14 16  7
 6 10  3 18  5
 1 12 20 15 19

 3 15  0  2 22
 9 18 13 17  5
19  8  7 25 23
20 11 10 24  4
14 21 16 12  6

14 21 17 24  4
10 16 15  9 19
18  8 23 26 20
22 11 13  6  5
 2  0 12  3  7

