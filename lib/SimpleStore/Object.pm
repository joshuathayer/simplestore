package SimpleStore::Object;

use SimpleStore::Disk;

use strict;

sub new {
    my ($class, $path) = @_;

    die("must instantiate SimpleStore::Object with a path to a directory") unless $path and -d $path;

    my $self = {};
    bless $self, $class;

    $self->{path} = $path;
    $self->{disk} = SimpleStore::Disk->new($self->{path});

    return $self;
}

sub get {
    my ($self, $name, $cb) = @_;

    my $path = "$self->{path}/$name\.ss";
    my $d = SimpleStore::Disk->new($path);
    $d->read($cb);
}

sub set {
    my ($self, $name, $item, $cb) = @_;

    my $path = "$self->{path}/$name\.ss";
    my $d = SimpleStore::Disk->new($path);
    $d->write($item, $cb);
}


1;
