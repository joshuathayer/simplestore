package SimpleStore::Disk;

use strict;
use Fcntl;
use IO::AIO;
use JSON;
use Data::Dumper;
use Devel::StackTrace;
use AnyEvent;
use Carp;

# disk access stuff for the stores.
our $sigdie;
our $csigdie;

sub new {
    my ($class, $path) = @_;

    die("must instantiate SimpleStore::Disk with a path") unless ($path);
    my @c = caller;
    my ($type) = $c[0] =~ /^.*?::(.*)/;

    my $self = {};
    bless $self, $class;

    $self->{path} = $path;
    $self->{is_open} = 0;
    $self->{fh} = undef;
    $self->{type} = $type;

    return $self;

};

sub open {
    my ($self, $cb) = @_;

    if ($self->{is_open}) { $cb->(); return; }
    $sigdie = $SIG{__DIE__};
    warn("sigdie $sigdie");
    aio_open $self->{path}, O_RDWR|O_CREAT, 0666, sub {
        eval {
            local $SIG{__DIE__} = $sigdie;
            warn("sigdie $SIG{__DIE__}");
            my $fh = shift;
            if (defined($fh)) {
                $self->{is_open} = 1;
                $self->{fh} = $fh;
                $cb->();
            } else {
                warn("FILE FAILED TO OPEN");
                die("failed to open file: $!\n");
            }
        };
    };
}

sub write {
    my ($self, $data, $cb) = @_;

    $self->open(sub {
        my $dat = encode_json({type=>$self->{type}, data=>$data});
        aio_write($self->{fh}, 0, undef, $dat, 0, sub {
           $self->close($cb);
       }); 
    });
}

sub read {
    my ($self, $cb) = @_;

    # aio_read seems to set its own sigdie in its callback
    # then (i think) it tries to flush a closed filehandle 
    # in its END block, which brings things down hard.
    # so we put our own sig die handler aside here, to reinstall
    # it later, in a handler which closes the filehandle and then 
    # calls the sub we've put in $sigdie
    #$sigdie = $SIG{__DIE__};

    my $data;
    $self->open(sub {
        my $size = -s $self->{fh};
        if ($size == 0) {
            $self->close(sub {
                $cb->(undef);
                return;
            });
        }

        $csigdie = sub {
            #delete $self->{fh};
            warn("I AM HERE IN CSIGDIE");
            warn("sigdie $SIG{__DIE__}");
            die(@_);
            #$self->close(sub{
            #    warn("close callback calling die");
            #    die($@);
            #});
        };

        aio_read($self->{fh}, 0, $size, $data, 0, $self->read_cb($data, $cb));

    });
}
            
sub read_cb {
    my ($self, $data, $cb) = @_;


    eval {
            $SIG{__DIE__} = $sigdie;
        # XXX local $SIG{__DIE__} = $csigdie;
        # this is somewhat nuanced
        # IO::AIO was complaining in its END block
        # which only does a call to flush. by closing
        # its filehandle before it gets to its END block,
        # things run better. i'm not 100% what's going on
        #$SIG{__DIE__} = sub{
        #    $self->close(sub{
        #};
        warn("i am in read_cb");
        $data = decode_json($data);
        warn("i am in read_cb 2");
        my $otype = $data->{type};
        if ($otype ne $self->{type}) {
            die("opened type ($otype) does not match implied type ($self->{type})")
        }
    };
    return if $@;
    $cb->($data->{data});
};

sub close {
    my ($self, $cb) = @_;
    $self->{is_open} = undef;
    aio_close($self->{fh}, $cb);
}
1;
