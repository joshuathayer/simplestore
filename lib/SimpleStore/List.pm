package SimpleStore::List;

use strict;

use SimpleStore::Disk;
use Data::Dumper;

use constant DEBUG => 0;

our $INSTANCES = {};

sub new {
    my $class = shift;
    my $path = shift;
    my %rest = @_;

    die("must instantiate SimpleStore::List with a path") unless $path;

    return $INSTANCES->{$path} if $INSTANCES->{$path};

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

    $INSTANCES->{$path} = $self;
    return $self;
}

sub _read_and {
    my ($self, $cb) = @_;

    if ($self->{loaded}) {
        warn("LIST: already loaded") if DEBUG;
        $cb->();
    } else {
        # what happens when this file doesn't already exist?
        # XXX read really needs an "error" callback
        $self->{disk}->read( sub {
            my ($items) = @_;
            $items = [] unless $items;
            ($self->{items}) = $items;
            $self->{loaded} = 1;
            warn("LIST: not loaded. loading: " . Dumper $items) if DEBUG;
            $cb->();
        });
    }
}

sub replace {
    my ($self, $with, $cb) = @_;
    warn("in replace") if DEBUG;
    warn(Dumper $with);
    $self->_read_and(sub {
        warn("in replace callback") if DEBUG;
        $self->{items} = $with;
        $self->{disk}->write($self->{items}, $cb);
    });
}

sub clear {
    my ($self, $cb) = @_;
    warn("in clear") if DEBUG;
    $self->_read_and(sub {
        warn("in clear callback") if DEBUG;
        $self->{items} = [];    
        $self->{disk}->write($self->{items}, $cb);
    });
}

sub push {
    my ($self, $item, $cb) = @_;

    $self->_read_and(sub {
        push(@{$self->{items}}, $item);
        warn(Dumper $self->{items}) if DEBUG;
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
    $self->_read_and(sub { $cb->($self->{items}) });
}

#sub get-orig-not-sure-if-its-needed {
#    my ($self, $cb) = @_;
#    eval {
#        $self->{disk}->read( $cb );
#    };
#    if ($@) {
#        if (defined($self->{onerror})) {
#            $self->{onerror}->($cb);
#        };
#    }
#}

1;
