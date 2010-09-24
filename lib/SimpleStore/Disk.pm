package SimpleStore::Disk;

use strict;
use Fcntl;
use AnyEvent::AIO;
use IO::AIO;
use JSON;
use Data::Dumper;
use Carp;

# disk access stuff for the stores.
our $sigdie;
our $csigdie;

sub new {
    my $class = shift;
    my $path = shift;
    my (%rest) = @_;


    die("must instantiate SimpleStore::Disk with a path") unless ($path);
    my @c = caller;
    my ($type) = $c[0] =~ /^.*?::(.*)/;

    my $self = {};
    bless $self, $class;

    $self->{path} = $path;
    $self->{is_open} = 0;
    $self->{fh} = undef;
    $self->{type} = $type;
    if ($rest{onerror}) {
        warn("Disk installing onerror handler");
        $self->{onerror} = $rest{onerror};
    }

    return $self;

};

sub open {
    my ($self, $cb) = @_;

    if ($self->{is_open}) { $cb->(); return; }

    aio_open $self->{path}, O_RDWR|O_CREAT, 0666, sub {
            my $fh = shift;

            if (defined($fh)) {
                $self->{is_open} = 1;
                $self->{fh} = $fh;
                # this can eventually call aio_read, which can die. so it's important
                # to have the original sigdie handler reinstalled
                $cb->();
            } else {
                croak("failed to open file: $!\n");
            }
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
    # jt 20101021 no need to do this here, we do it in open()
    # even if the file is already open

    my $data;
    $self->open(sub {
        # ok, file is open
        my $size = -s $self->{fh};
        if ($size == 0) {
            $self->close(sub {
                $cb->(undef);
            });
        } else {

	        # we hack up the sigdie handler for inside 
	        # the aio_read callback. see comment there.
	        #$csigdie = sub {
	        #   warn("I AM HERE IN CSIGDIE: @_");
	        #   warn("sigdie $SIG{__DIE__}");
	        #   aio_close($self->{fh});
	        #    warn("called aio_close, calling die now");
	        #    #die("die called in hacked-up aio_read die handler");
	        #};
	
	        warn("trying to read $size bytes");
            if (not ($size)) {
                warn("empty read");
                $cb->(undef);
                return;
            }
	        my $r = aio_read($self->{fh}, 0, $size, $data, 0, sub {  $self->read_cb($data, $cb) });
        }	
    });
}
            
sub read_cb {
    my ($self, $data, $cb) = @_;

    if (not ($data)) {
        warn("no data read");
        $cb->(undef);
        return;
    }

    warn("data is $data");

    eval {
        # this is somewhat nuanced
        # IO::AIO was complaining in its END block
        # which only does a call to flush. by closing
        # its filehandle before it gets to its END block,
        # things run better. i'm not 100% what's going on

        local $SIG{__DIE__};

        # when data is bad json, this die()s, as it shold
        # but that's setting up all sorts of bad stuff
        $data = decode_json($data);
        my $otype = $data->{type};
        if ($otype ne $self->{type}) {
            die("opened type ($otype) does not match implied type ($self->{type})")
        }

    };

    if ($@) {
        carp("i stumbled across an error");
        aio_close($self->{fh});
        if ($self->{onerror}) {
            $self->{onerror}->($cb);
            return;
        } else {
            croak($@);
        }
    }
    
    $cb->($data->{data});
};

sub close {
    my ($self, $cb) = @_;
    $self->{is_open} = undef;
    aio_close($self->{fh}, $cb);
}
1;
