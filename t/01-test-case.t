#!perl

use Test::More tests => 3;

use strict; use warnings;
use Calendar::Persian;

my ($calendar);

eval { $calendar = Calendar::Persian->new(-1390, 1, 1); };
like($@, qr/ERROR: Invalid year \[\-1390\]./);

eval { $calendar = Calendar::Persian->new(1390, 13, 1); };
like($@, qr/ERROR: Invalid month \[13\]./);

eval { $calendar = Calendar::Persian->new(1390, 12, 32); };
like($@, qr/ERROR: Invalid day \[32\]./);