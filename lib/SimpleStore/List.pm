package SimpleStore::List;

use SimpleStore::Disk;
use Data::Dumper;

use strict;

sub new {
    my $class = shift;
    my $path = shift;
    my %rest = @_;

    die("must instantiate SimpleStore::List with a path") unless $path;

    my $self = {};
    bless $self, $class;

    if ($rest{onerror}) {
       $self->{onerror} = $rest{onerror};
    }

    $self->{loaded} = 0;
     
    $self->{items} = [];
    $self->{path} = $path;
    $self->{disk} = SimpleStore::Disk->new(
        $self->{path},
        onerror => $self->{onerror},
    );

    return $self;
}

sub _read_and {
    my ($self, $cb) = @_;

    if ($self->{loaded}) {
        $cb->();
    } else {
        # what happens when this file doesn't already exist?
        $self->{disk}->read( sub {
            my ($items) = @_;
            $items = [] unless $items;
            ($self->{items}) = $items;
            $self->{loaded} = 1;
            $cb->();
        });
    }
}

sub push {
    my ($self, $item, $cb) = @_;

    $self->_read_and(sub {
        push(@{$self->{items}}, $item);
        $self->{disk}->write($self->{items}, $cb);
    });

}

sub unshift {
    my ($self, $item, $cb) = @_;

    $self->_read_and(sub {
        unshift(@{$self->{items}}, $item);
        $self->{disk}->write($self->{items}, $cb);
    });
}

sub pop {
    my ($self, $item, $cb) = @_;

    $self->_read_and(sub {
        pop @{$self->{items}}, $item;
        $self->{disk}->write($self->{items}, $cb);
    });
}

sub shift {
    my ($self, $item, $cb) = @_;

    $self->_read_and(sub {
        shift @{$self->{items}}, $item;
        $self->{disk}->write($self->{items}, $cb);
    });
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
