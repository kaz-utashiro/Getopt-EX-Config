package Getopt::EX::Config;

use v5.14;
use warnings;

our $VERSION = '0.01';

use Exporter 'import';
our @EXPORT = qw(&config );
our @EXPORT_OK = qw(&C &config &getopt &split_argv &mod_argv);

use Getopt::Long qw(GetOptionsFromArray);
Getopt::Long::Configure qw(bundling);

use List::Util qw(first);

our $config;

sub new {
    my $class = shift;
    $config = ref $_[0] eq 'HASH' ? shift : { @_ };
    bless $config, $class;
}

sub load { goto &deal_with }

sub deal_with {
    my $obj = shift;
    my($my_argv, $argv) = split_argv(shift);
    getopt($my_argv, $obj, @_) if @$my_argv;
}

######################################################################

sub C {
    goto &config;
}

sub config {
    while (my($k, $v) = splice @_, 0, 2) {
	my @names = split /\./, $k;
	my $c = $config // die "config is not initialized.\n";
	my $name = pop @names;
	for (@names) {
	    $c = $c->{$_} // die "$k: invalid name.\n";
	}
	exists $c->{$name} or die "$k: invalid name.\n";
	$c->{$name} = $v;
    }
    ();
}

use Getopt::EX::Func;
*arg2kvlist = \&Getopt::EX::Func::arg2kvlist;

sub getopt {
    my $argv = shift;
    my $opt = shift;
    return if @{ $argv //= [] } == 0;
    GetOptionsFromArray(
	$argv,
	"config|C=s" => sub { config arg2kvlist($_[1]) },
	@_ )
	or die "Option parse error.\n";
}

sub mod_argv {
    my($mod, $argv) = splice @_, 0, 2;
    ($mod, split_argv($argv), @_);
}

sub split_argv {
    my $argv = shift;
    my @my_argv;
    if (@$argv and $argv->[0] !~ /^-M/ and
	defined(my $i = first { $argv->[$_] eq '--' } keys @$argv)) {
	splice @$argv, $i, 1; # remove '--'
	@my_argv = splice @$argv, 0, $i;
    }
    (\@my_argv, $argv);
}

1;

=encoding utf-8

=head1 NAME

Getopt::EX::Config - Getopt::EX module configuration interface

=head1 SYNOPSIS

    greple -Mfoo --config foo=yabaa,bar=dabba,baz=doo -- ...

    greple -Mfoo::config(foo=yabaa,bar=dabba,baz=doo) ...

    greple -Mfoo --module-option ... -- ...

=head1 VERSION

Version 0.01

=head1 DESCRIPTION

This module provides an interface to define configuration information
for C<Getopt::EX> modules.  In the traditional way, in order to set
options for a module, it was necessary to define dedicated command
line options for them.  To do so, it is necessary to avoid name
conflicts with existing command options or with other modules used
together.

Using this module, it is possible to define configuration information
only for the module and to define module-specific command options.

You can create config object like this:

    my $config = Getopt::EX::Config->new(
        col   => 1,
        char  => 0,
        width => 0,
        code  => 1,
        name  => 1,
        align => 1,
    );

This call returns hash object and each member can be accessed like
C<< $config->{width} >>.

Then use this object in module startup funciton C<intialize> or
C<finalize>.

    sub finalize {
        our($mod, $argv) = @_;
        $config->deal_with($argv);
    }

If you want to make module private option, say C<--char> and
C<--width> to set C<< $config->{xxxx} >> values, C<deal_with> method
takes C<Getopt::Long> style option specifications.

    sub finalize {
        our($mod, $argv) = @_;
        $config->deal_with(
            $argv,
            "char!" => \$config->{char},
            "width!" => \$config->{width},
        );
    }

    greple -Mcharcode --config char=1 -- ...

    greple -Mcharcode --char -- ...

=head1 SEE ALSO

L<Getopt::EX>

=head1 AUTHOR

Kazumasa Utashiro

=head1 COPYRIGHT

The following copyright notice applies to all the files provided in
this distribution, including binary files, unless explicitly noted
otherwise.

Copyright ©︎ 2025 Kazumasa Utashiro

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
