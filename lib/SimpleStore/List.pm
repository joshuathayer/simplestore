package SimpleStore::List;

use SimpleStore::Disk;

use strict;

sub new {
    my $class = shift;
    my $path = shift;
    my %rest = @_;

    use Data::Dumper;
        print STDERR Dumper \%rest;

    die("must instantiate SimpleStore::List with a path") unless $path;

    my $self = {};
    bless $self, $class;

    if ($rest{onerror}) {
       $self->{onerror} = $rest{onerror};
    }
     

    $self->{items} = [];
    $self->{path} = $path;
    $self->{disk} = SimpleStore::Disk->new(
        $self->{path},
        onerror => $self->{onerror},
    );

    return $self;
}

sub push {
    my ($self, $item, $cb) = @_;

    push(@{$self->{items}}, $item);
    $self->{disk}->write($self->{items}, $cb);
}

sub unshift {
    my ($self, $item, $cb) = @_;

    unshift(@{$self->{items}}, $item);
    $self->{disk}->write($self->{items}, $cb);
}

sub pop {
    my ($self, $item, $cb) = @_;

    pop @{$self->{items}}, $item;
    $self->{disk}->write($self->{items}, $cb);
}

sub shift {
    my ($self, $item, $cb) = @_;

    shift @{$self->{items}}, $item;
    $self->{disk}->write($self->{items}, $cb);
}

sub get {
    my ($self, $cb) = @_;
    eval {
        $self->{disk}->read( $cb );
    };
    if ($@) {
        if (defined($self->{onerror})) {
            $self->{onerror}->($cb);
        };
    }
}

1;
