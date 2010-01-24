use strict;
use warnings;

package TAP::Parser::SourceHandler::ForkingPerl;

use Config;
use Try::Tiny;
use IO::Select;
use Class::Load qw(load_class);
use TAP::Parser::IteratorFactory;
use TAP::Parser::Iterator::ForkedProcess;

use parent 'TAP::Parser::SourceHandler::Perl';

TAP::Parser::IteratorFactory->register_handler(__PACKAGE__);

sub can_handle {
    my $class = shift;
    $class->SUPER::can_handle(@_) + 0.05;
}

sub _iterator_hooks {
    my ($class, $source, $libs) = @_;

    my ($setup, $teardown) = $class->SUPER::_iterator_hooks($source, $libs);

    return (
        sub {
            @ARGV = @{ $source->test_args || [] };
            $setup->(@_);
        },
        $teardown,
    );
}

sub _preload_inc {
    my ($class, $source) = @_;
    return (
        (split $Config{path_sep} => (($source->config_for($class) || {})->{preload_inc} || '')),
        't/lib',
    );
}

sub _preload_modules {
    my ($class, $source) = @_;

    my @mods = split q{,} => (($source->config_for($class) || {})->{preload} || '');
    for my $mod (@mods) {
        try {
            load_class($mod);
        }
        catch {
            die "failed to load $mod: $_";
        }
    }
}

sub _get_command_for_switches {
    my ($class, $source, $switches) = @_;

    die "switches not supported" if @{ $switches || [] };

    return $class->SUPER::_get_command_for_switches($source, $switches);
}

sub _run {
    my ($class, $source, $libs, $switches) = @_;

    my @preload_inc = $class->_preload_inc($source);

    {
        local @INC = (@preload_inc, @{ $libs || [] }, @INC);
        $class->_preload_modules($source);
    }

    return $class->SUPER::_run($source, $libs, $switches);
}

sub _create_iterator {
    my ($class, $source, $command, $setup, $teardown) = @_;

    return TAP::Parser::Iterator::ForkedProcess->new({
        command  => $command,
        merge    => $source->merge,
        setup    => $setup,
        teardown => $teardown,
        file     => ${ $source->raw },
    });
}

1;
