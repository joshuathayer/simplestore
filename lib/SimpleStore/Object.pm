package SimpleStore::Object;

use SimpleStore::Disk;

use strict;

sub new {
    my $class = shift;
    my $path = shift;
    my %rest = @_;


    die("must instantiate SimpleStore::Object with a path to a directory") unless $path and -d $path;

    my $self = {};
    bless $self, $class;

    if ($rest{onerror}) {
        $self->{onerror} = $rest{onerror};
    }
    $self->{path} = $path;
    $self->{disk} = SimpleStore::Disk->new($self->{path}, %rest);

    return $self;
}

sub get {
    my ($self, $name, $cb) = @_;

    my $path = "$self->{path}/$name\.ss";
    my $d = SimpleStore::Disk->new($path, onerror=> $self->{onerror});
    $d->read($cb);
}

sub set {
    my ($self, $name, $item, $cb) = @_;

    my $path = "$self->{path}/$name\.ss";
    my $d = SimpleStore::Disk->new($path, onerror => $self->{onerror});
    $d->write($item, $cb);
}


1;
