use strict;
use warnings;

package TAP::Parser::SourceHandler::ForkingPerl;

use Config;
use IO::Select;
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

sub _preload_modules {
}

sub _get_command_for_switches {
    my ($class, $source, $switches) = @_;

    die "switches not supported" if @{ $switches || [] };

    return $class->SUPER::_get_command_for_switches($source, $switches);
}

sub _run {
    my ($class, $source, $libs, $switches) = @_;

    {
        local @INC = (@{ $libs || [] }, @INC);
        $class->_preload_modules;
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
