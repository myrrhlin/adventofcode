#! /usr/bin/env perl

# https://adventofcode.com/2021/day/10

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
  'v|verbose',
) or die "couldn't parse options: @ARGV";

my %cnt;

my $file = $ARGV[0] || 'd10.lis';

$cnt{_lines} = my @lines = grep /^\S/, $opt{test} ? 
  do {local $/; split /\n/, <DATA>} 
  : path($file)->lines({chomp => 1});

my %pairs = (
  '(' => ')',
  '[' => ']',
  '{' => '}',
  '<' => '>',
);
my %score1 = (
  ')' => 3,
  ']' => 57,
  '}' => 1197,
  '>' => 25137,
);
my %score2 = (
  ')' => 1,
  ']' => 2,
  '}' => 3,
  '>' => 4,
);

sub classify ($line) {
  my @open;
  foreach my $c (split //, $line) {
    my $p = $open[-1];
    if ($pairs{$c}) {
      push @open, $c;
      next;
    } elsif ($c eq $pairs{$p}) {
      pop @open;
      next;
    } else {
      return "corrupted at $c expected $pairs{$p}";
    }
  }
  return "valid" unless @open;
  my @closes = map {$pairs{$_}} reverse @open;
  my $score = 0;
  $score = $score * 5 + $score2{$_} for @closes;
  my $closing = join '', @closes;
  return "incomplete closing $closing scores $score";
}

sub median (@list) {
  use integer;
  my @el = sort {$a <=> $b} @list;
  my $len = @el;
  $el[($len-1)/2]
}


my $score1;
my @score2;
foreach my $line (@lines) {
  my $res = classify($line);
  say $line, ' : ', $res if $opt{v};
  my ($w) = split ' ', $res;
  $cnt{$w}++;
  if ($res =~ /corrupted at (.) /) {
    $score1 += $score1{$1};
  } elsif ($res =~ /incomplete closing \S+ scores (\d+)$/) {
    push @score2, $1;
  }
}
p %cnt;

say "final score1: $score1";
say "final score2: ", median(@score2);

exit;

__DATA__

[({(<(())[]>[[{[]{<()<>>
[(()[<>])]({[<{<<[]>>(
{([(<{}[<>[]}>{[]{[(<()>
(((({<>}<{<{<>}{[]{[]{}
[[<[([]))<([[{}[[()]]]
[{[{({}]{}}([{[{{{}}([]
{<[[]]>}<{[{[{[]{()[[[]
[<(<(<(<{}))><([]([]()
<{([([[(<>()){}]>(<<{{
<{([{{}}[<[[[<>{}]]]>[]]

