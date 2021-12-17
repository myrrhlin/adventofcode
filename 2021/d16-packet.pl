#! /usr/bin/env perl

# https://adventofcode.com/2021/day/14

use 5.26.0;
use warnings;
use feature 'signatures', 'postderef';
no warnings 'experimental::signatures';
no warnings 'portable';
use autodie;

use Getopt::Long;
use Path::Tiny;
use Carp::Always;
use Data::Printer;
use List::Util qw<sum product min max>;

my %opt;
GetOptions(\%opt, 
  'test',
  'debug',
  'v|verbose',
) or die "couldn't parse options: @ARGV";

my $file = $ARGV[0] || 'd16.lis';

my %cnt;
$cnt{_lines} = my @lines = grep /^\S/, $opt{test} ? 
  do {local $/; split /\n/, <DATA>} 
  : path($file)->lines({chomp => 1});

#my $input = join '', @lines;

# convert string of 1011 to an integer
sub b2dec { oct '0b'. join '', @_ }

our $debug = 0;
{
  my (@bytes, $bi, $bits); # bytestream, byte index, buffer of unread bits
  sub set_bytestream { 
    ($bi, $bits, @bytes) = (0, '', @_);
  }
  sub getbi { $bi * 8 - length($bits) }   # how many bits have been read so far
  sub getbits ($n) {
    while (length $bits < $n) {
      # $bi points at the next byte to read
      die "no more bytes! bi=$bi" if $bi >= @bytes;
      $bits .= sprintf '%08b', $bytes[$bi++];
    }
    my $read = substr($bits, 0, $n, '');
    say "read $n bits: $read ; buffer $bits plus ",@bytes - $bi," bytes remain" if $opt{debug};
    return $read;
  }
  sub getbitv ($n) {
    my $read = getbits($n);
    return b2dec($read);
  }
}

sub gtop ($a, $b) { $a > $b ? 1 : 0 }
sub ltop ($a, $b) { $a < $b ? 1 : 0 }
sub eqop ($a, $b) { $a == $b ? 1 : 0 }

sub readpacket {
  my $bindex = getbi();
  my %pkt = (
    ver => getbitv(3),
    type_id => getbitv(3),
  );
  $pkt{version_sum} = $pkt{ver};
  if ($pkt{type_id} == 4) {  # "literal" packet
    $pkt{type} = 'literal';
    my @hdig = (getbitv(5));
    push @hdig, getbitv(5) while $hdig[-1] & 16;
    # $pkt{_digits} = \@hdig;
    my $hex = join '', map {sprintf('%x', $_ & 15)} @hdig;
    $pkt{_hex} = $hex;
    warn "literal too big: $hex is ", length($hex), " digits" if length($hex)>8;
    $pkt{value} = hex("0x$hex");
  } else {  # "operator" packet
    $pkt{type} = 'operator';
    $pkt{operation} = {
      0 => 'sum',
      1 => 'product',
      2 => 'min',
      3 => 'max',
      5 => 'gtop',
      6 => 'ltop',
      7 => 'eqop',
    }->{$pkt{type_id}};
    my $mode = $pkt{mode_id} = getbitv(1);
    say "operator pkt type $pkt{type_id} mode $mode" if $opt{debug};
    my @subp;
    if ($mode) {
      $pkt{subpacket_mode} = 'packet_count';
      my $npacket = $pkt{subpacket_expected} = getbitv(11);
      push @subp, readpacket() until @subp == $npacket;
    } else {
      $pkt{subpacket_mode} = 'bit_length';
      my $bitlength = $pkt{subpacket_bitlength} = getbitv(15);
      my $sbi = getbi();
      push @subp, readpacket() until getbi() - $sbi >= $bitlength;
      die "subpacket lengths did not meet declared length $bitlength" 
        unless getbi - $sbi == $bitlength;
    }
    $pkt{subpackets} = \@subp;
    $pkt{version_sum} += sum map {$_->{version_sum}} @subp;
    my @vals = map {$_->{value}} @subp;
    $pkt{value} = eval "$pkt{operation} \@vals";
    say "evaluated '$pkt{operation}' subpacket vals @vals : $pkt{value}";
  }
  $pkt{bit_length} = getbi() - $bindex;
  if ($opt{v}) {
    print "read $pkt{bit_length} bits for $pkt{type} packet type $pkt{type_id} with ";
    if ($pkt{type} eq 'operator') {
      print scalar($pkt{subpackets}->@*), ' subpackets, ';
    }
    print "value $pkt{value}";
    say " and version_sum $pkt{version_sum}";
  }
  return \%pkt;
}

while (my $input = shift @lines) {
  my @bytes;
  my $count = 0;
  ($input) = split ' ', $input;
  if ($input =~ /^[01]+$/) {
    @bytes = map {oct("0b$_")} grep {$_} split /(\w{8})/, $input;
  } elsif ($input =~ /^[0-9a-fA-F]+$/) {
    @bytes = map hex, grep {$_} split /(\w{2})/, $input;
  }
  say "\ninput $input is ", scalar(@bytes), ' bytes';
  set_bytestream(@bytes);
  my $p = readpacket();
  $p->{packet_number} = ++$count;
  p $p if $opt{debug};
  say "final version sum: $p->{version_sum} and value: $p->{value}";
}


exit;

__DATA__

110100101111111000101000
d2fe28
38006F45291200
EE00D40C823060
8A004A801A8002F478
620080001611562C8802118E34
C0015000016115A2E0802F182340
A0016C880162017C3686B18A3D4780

C200B40A82 finds the sum of 1 and 2, resulting in the value 3.
04005AC33890 finds the product of 6 and 9, resulting in the value 54.
880086C3E88112 finds the minimum of 7, 8, and 9, resulting in the value 7.
CE00C43D881120 finds the maximum of 7, 8, and 9, resulting in the value 9.
D8005AC2A8F0 produces 1, because 5 is less than 15.
F600BC2D8F produces 0, because 5 is not greater than 15.
9C005AC2F8F0 produces 0, because 5 is not equal to 15.
9C0141080250320F1802104A08 produces 1, because 1 + 3 = 2 * 2.

