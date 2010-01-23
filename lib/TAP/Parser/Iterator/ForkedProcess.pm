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

        close STDOUT;
        close STDERR;
        open STDOUT, '>&', $out;
        open STDERR, '>&', $err_out;

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
