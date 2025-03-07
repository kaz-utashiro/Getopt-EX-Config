package Getopt::EX::Config;

use v5.14;
use warnings;

our $VERSION = '0.9904';

use Data::Dumper;
use Getopt::Long qw(GetOptionsFromArray);
Getopt::Long::Configure qw(bundling);

use List::Util qw(first);
use Hash::Util qw(lock_keys);

our %CONFIG;

sub import {
    my $class = shift;
    my $caller = caller;
    my @names = @_ ? @_ : 'config';
    no strict 'refs';
    for my $name (@names) {
	*{"$caller\::$name"} = sub {
	    $CONFIG{$caller}->config(@_);
	};
    };
}

sub new {
    my $class = shift;
    my $config = ref $_[0] eq 'HASH' ? shift : { @_ };
    my $caller = caller;
    $CONFIG{$caller} = bless $config, $class;
    $config;
}

sub object {
    $CONFIG{+caller};
}

sub deal_with {
    my $obj = shift;
    if ($obj eq __PACKAGE__) {
	$obj = $CONFIG{+caller} // die;
    }
    my($my_argv, $argv) = split_argv(shift);
    $obj->getopt($my_argv, @_) if @$my_argv;
    return $obj;
}

use Getopt::EX::Func;
*arg2kvlist = \&Getopt::EX::Func::arg2kvlist;

sub getopt {
    my $obj = shift;
    my $argv = shift // [];
    return if @{ $argv } == 0;
    GetOptionsFromArray(
	$argv,
	$obj,
	"config|C=s" => sub {
	    $obj->config(arg2kvlist($_[1]));
	},
	@_
    ) or die "Option parse error.\n";
}

sub config {
    my $obj = shift;
    if (@_ == 1) {
	$obj->get(@_);
    } else {
	$obj->set(@_);
    }
}

######################################################################

sub set {
    my $c = shift;
    while (my($k, $v) = splice @_, 0, 2) {
	my @names = split /\./, $k;
	my $name = pop @names;
	for (@names) {
	    $c = $c->{$_} // die "$k: invalid name.\n";
	}
	exists $c->{$name} or die "$k: invalid name.\n";
	if (ref $c->{$name}) {
	    ${$c->{$name}} = $v;
	} else {
	    $c->{$name} = $v;
	}
    }
    ();
}

sub get :lvalue {
    my $c = shift;
    my $key = shift;
    if (ref $c->{$key}) {
	${$c->{$key}};
    } else {
	$c->{$key};
    }
}

sub mod_argv {
    my($mod, $argv) = splice @_, 0, 2;
    ($mod, split_argv($argv), @_);
}

sub split_argv {
    my $argv = shift;
    my @my_argv;
    if (@$argv and
	$argv->[0] !~ /^-M/ and
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

    example -Mfoo::config(foo=yabaa,bar=dabba) ...

    example -Mfoo::config(foo=yabba) --config bar=dabba ... -- ...

    example -Mfoo::config(foo=yabba) --bar=dabba ... -- ...

    example -Mfoo --foo=yabaa --bar=dabba -- ...

=head1 VERSION

Version 0.9904

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

    use Getopt::EX::Config;
    my $config = Getopt::EX::Config->new(
        char  => 0,
        width => 0,
        code  => 1,
        name  => "Franky",
    );

This call returns hash object and each member can be accessed like
C<< $config->{width} >>.

You can set these configuration values by calling C<config()> function
with module declaration.

    example -Mfoo::config(width,code=0) ...

Parameter list is given by key-value pairs, and C<1> is assumed when
value is not given.  Above code set C<width> to C<1> and C<code> to
C<0>.

Also module specific options can be taken care of by calling
C<deal_with> method from module startup funciton C<intialize> or
C<finalize>.

    sub finalize {
        our($mod, $argv) = @_;
        $config->deal_with($argv);
    }

Then you can use C<--config> module option like this:

    example -Mfoo --config width,code=0 -- ...

The module startup function is executed between the C<initialize()>
and C<finalize()> calls.  Therefore, if you want to give priority to
module-specific options over the startup function, you must call
C<deal_with> in the C<finalize()> function.

If you want to make module private option, say C<--width> to set C<<
$config->{width} >> value, C<deal_with> method takes C<Getopt::Long>
style option specifications.

    sub finalize {
        our($mod, $argv) = @_;
        $config->deal_with(
            $argv,
            "width!",
            "code!",
            "name=s",
        );
    }

Then you can use module private option like this:

    example -Mcharcode --width --no-code --name=Benjy -- ...

The reason why it is not necessary to specify the destination of the
value is that the hash object is passed when calling the
C<Getopt::Long> library.  The above code is equivalent to the
following code.  See L<Getopt::Long/Storing options values in a hash>
for detail.

    sub finalize {
        our($mod, $argv) = @_;
        $config->deal_with(
            $argv,
            "width!" => \$config->{width},
            "code!"  => \$config->{code},
            "name=s" => \$config->{name},
        );
    }

=head1 FUNCTIONS

=over 7

=item B<config>(I<key> => I<value>, ...)

This module exports the function C<config> by default.  As explained
above, this is why the C<config> function can be executed with module
declaration.

If you want to use a function with a different name, specify it
explicitly.  In the following example, the function C<set> is defined
and can be used in the same way as C<config>.

    use Getopt::EX::Config qw(config set);

=item B<config>(I<key>)

The C<config> function may also be used to refer parameters in the
program.  In this case, specify single argument.

    my $width = config('width');

Parameter value references can also be used as left-hand side values,
so values can be assigned.

    config('width') = 42;

=back

=head1 METHODS

=over 7

=item B<new>(I<key-value list>)

=item B<new>(I<hash reference>)

Return configuration object.

Call with key-value list like this:

    my $config = Getopt::EX::Config->new(
        char  => 0,
        width => 0,
        code  => 1,
        name  => "Franky",
    );

Or call with hash reference.

    my %config = (
        char  => 0,
        width => 0,
        code  => 1,
        name  => "Franky",
    );
    my $config = Getopt::EX::Config->new(\%config);

In this case, C<\%config> and C<$config> should be identical.

=item B<deal_with>

You can get argument reference in C<initialize()> or C<finalize()>
function declared in C<Getopt::EX> module.  Call C<deal_with> method
with that reference.

    sub finalize {
        our($mod, $argv) = @_;
        $config->deal_with($argv);
    }

You can define module specific options by giving L<Getopt::Long> style
definition with that call.

    sub finalize {
        our($mod, $argv) = @_;
        $config->deal_with($argv,
                           "width!", "code!", "name=s");
    }

=back

=head1 SEE ALSO

L<Getopt::EX>

L<Getopt::Long>

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
