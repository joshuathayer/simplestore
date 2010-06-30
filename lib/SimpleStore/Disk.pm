package SimpleStore::Disk;

use strict;
use Fcntl;
use IO::AIO;
use JSON;

# disk access stuff for the stores.

sub new {
    my ($class, $path) = @_;

    die("must instantiate SimpleStore::Disk with a path") unless $path;

    my $self = {};
    bless $self, $class;

    $self->{path} = $path;
    $self->{is_open} = 0;
    $self->{fh} = undef;

    return $self;

};

sub open {
    my ($self, $cb) = @_;

    if ($self->{is_open}) { $cb->(); return; }

    aio_open $self->{path}, O_RDWR|O_CREAT, 0666, sub {
        my $fh = shift;
        if ($fh) {
            $self->{is_open} = 1;
            $self->{fh} = $fh;
            $cb->();
        } else {
            die("failed to open file: $!\n");
        }
    };

}

sub write {
    my ($self, $data, $cb) = @_;

    $self->open(sub {
        my $dat = encode_json($data);
        aio_write($self->{fh}, 0, undef, $dat, 0, sub {
           $self->close($cb);
       }); 
    });
}

sub read {
    my ($self, $cb) = @_;
    my $dat;

    $self->open(sub {
        my $size = -s $self->{fh};
        aio_read($self->{fh}, 0, $size, $dat, 0, sub {
            $cb->(decode_json($dat));
        });
    });
}

sub close {
    my ($self, $cb) = @_;
    $self->{is_open} = undef;
    aio_close($self->{fh}, $cb);
}
1;
