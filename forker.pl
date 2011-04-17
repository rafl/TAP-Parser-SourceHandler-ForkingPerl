#!/usr/bin/env perl

use strict;
use warnings;

use IO::Select;
use Term::ANSIColor;
use POSIX qw( _exit );

my $args = {
  file     => 'fucked.pl',
  setup    => sub { },
  teardown => sub { },
};

pipe my $err_in, my $err_out;
pipe my $in,     my $out;

my $pid = fork;
unless ( $pid ) {
  #  eval q{END { _exit 0 }};

  close $err_in or die $!;
  close $in     or die $!;

  close STDOUT or die $!;
  close STDERR or die $!;

  open STDOUT, '>&=', $out     or die $!;
  open STDERR, '>&=', $err_out or die $!;

  $args->{setup}->();
  do $args->{file} or die $! // $@;
  $args->{teardown}->();

  #  _exit 0;
  exit;
}

close $err_out or die $!;
close $out     or die $!;

print "Parent is $$, child is $pid\n";

my $sel = IO::Select->new(
  [ $err_in, sub { colored( $_[0], 'red' ) } ],
  [ $in,     sub { $_[0] } ],
);

while ( $sel->count ) {
  for my $h ( $sel->can_read ) {
    my $got = sysread $h->[0], my $buf, 4096;
    die "I/O error" unless defined $got;
    unless ( $got ) {
      $sel->remove( $h );
      next;
    }
    print $h->[1]( $buf );
  }
}

my $rc = waitpid $pid, 0;

END {
  print "END in $$\n";
}

# vim:ts=2:sw=2:sts=2:et:ft=perl

