package TAP::Parser::Iterator::ForkedProcess;

use parent 'TAP::Parser::Iterator::Process';

sub _initialize {
    my ($self, $args) = @_;

    pipe my $err_in, my $err_out;
    pipe my $in, my $out;

    my $pid = fork;
    unless ($pid) {
        close $err_in;
        close $in;

        close \*STDOUT or die $!;
        close \*STDERR or die $!;
        open \*STDOUT, '>&=', $out or die $!;
        open \*STDERR, '>&=', $err_out or die $!;

        if (exists $INC{'Test/Builder.pm'}) {
            # stop inheriting the T::B handles from the parent. that way we can
            # test ourselfs with plain Test::More, without subtests we run won't
            # mess things up.
            my $builder = Test::Builder->new;
            delete $builder->{Opened_Testhandles};
            $builder->_open_testhandles;
            $builder->reset_outputs;
            $builder->current_test(0);
=for me
        # this is probably better, because it's api, but it's more fragile
        Test::Builder->new->output($out);
        Test::Builder->new->failure_output($err_out);
        Test::Builder->new->todo_output($out);
        Test::Builder->new->current_test(0);
=cut
        }

        $args->{setup}->();
        do $args->{file};
        $args->{teardown}->();

        exit;
    }

    close $err_out;
    close $out;

    $self->{out} = $in;
    $self->{err} = $err_in;
    $self->{sel} = IO::Select->new($in, $err_in);
    $self->{pid} = $pid;
    $self->{exit} = undef;
    $self->{chunk_size} = 65536;

    return $self;
}

1;
