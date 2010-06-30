use strict;
use lib ('../lib/');

use SimpleStore::List;
use Data::Dumper;

my $list = SimpleStore::List->new("/tmp/list.ss");

$list->push("this is a bit of data", sub {
    $list->unshift("this is unshifted", sub {
        $list->get(sub {
            print Dumper @_;
        });
    });
});


