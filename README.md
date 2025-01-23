
# NAME

Getopt::EX::Config - Getopt::EX module configuration interface

# SYNOPSIS

    greple -Mfoo --config foo=yabaa,bar=dabba,baz=doo -- ...

    greple -Mfoo::config(foo=yabaa,bar=dabba,baz=doo) ...

    greple -Mfoo --module-option ... -- ...

# VERSION

Version 0.01

# DESCRIPTION

This module provides an interface to define configuration information
for `Getopt::EX` modules.  In the traditional way, in order to set
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
`$config->{width}`.

Then use this object in module startup funciton `intialize` or
`finalize`.

    sub finalize {
        our($mod, $argv) = @_;
        $config->deal_with($argv);
    }

If you want to make module private option, say `--char` and
`--width` to set `$config->{xxxx}` values, `deal_with` method
takes `Getopt::Long` style option specifications.

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

# SEE ALSO

[Getopt::EX](https://metacpan.org/pod/Getopt%3A%3AEX)

# AUTHOR

Kazumasa Utashiro

# COPYRIGHT

The following copyright notice applies to all the files provided in
this distribution, including binary files, unless explicitly noted
otherwise.

Copyright ©︎ 2025 Kazumasa Utashiro

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
