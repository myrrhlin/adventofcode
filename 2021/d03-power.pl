#! /usr/bin/env perl

# https://adventofcode.com/2021/day/3

use 5.26.0;
use warnings;

use Path::Tiny;

my $file = $ARGV[0] || 'd03.lis';
my @lines = grep !m/^#/, path($file)->lines({chomp => 1});
# each line is a string representing a binary number

# convert string of 1011 to an integer
sub b2dec { return eval('0b'. join '', @_) }

sub common_bit {
  my $pos = shift;
  my $sample_cnt = @_;
  my $set_cnt = grep {substr($_, $pos, 1) eq '1'} @_;
  return 2*$set_cnt >= $sample_cnt ? '1' : '0';
}
sub uncommon_bit {
  my $common = common_bit(@_);
  return $common ? '0' : '1';
}
sub match_bit {
  my ($pos, $val, $sample) = @_;
  return substr($sample, $pos, 1) eq $val ? 1 : 0;
}

# how many binary digits does each sample have?
my $blen = length $lines[0];

# count how many samples have each bit position set
my @bit_set;
foreach (@lines) {
  my @bits = split '';
  for (my $i = 0; $i < @bits; $i++) {
    next unless $bits[$i];
    $bit_set[$i]++;
  }
}
say scalar(@lines), " samples, bit_set is: @bit_set";
# for each bit position, find most common bit value
my @common_bits = map {2*$_ >= @lines ? '1' : '0'} @bit_set;
# @common_bits = map {common_bit($_, @lines)} 0.. $blen-1;
my $gamma = b2dec(@common_bits);
say "most common: @common_bits  gamma rate: $gamma";
# and the converse
my @rare_bits = map {$_? '0':'1'} @common_bits;
my $epsilon = b2dec(@rare_bits);
say "uncommon: @rare_bits  epsilon rate: $epsilon";
say "product: ", $epsilon * $gamma;

# now filter all samples, using each bit position successively, until only one sample remains
my @samples = @lines;
foreach my $i (0 .. $blen-1) {
  my $match = common_bit($i, @samples);
  @samples = grep {match_bit($i,$match,$_)} @samples;
  last if @samples == 1;
}
die "samples insufficiently filtered" unless @samples ==1;
my $oxy_rating = b2dec($samples[0]);
say "sample: @samples   oxy rating: $oxy_rating";

# and again, but for the least common
@samples = @lines;
foreach my $i (0 .. $blen-1) {
  my $match = uncommon_bit($i, @samples);
  @samples = grep {match_bit($i,$match,$_)} @samples;
  last if @samples == 1;
}
die "samples insufficiently filtered" unless @samples ==1;
my $co2_rating = b2dec($samples[0]);
say "sample: @samples   CO2 rating: $co2_rating";

say "product: ", $oxy_rating * $co2_rating;

__END__

