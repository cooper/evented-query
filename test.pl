use warnings;
use strict;
use feature 'say';
use lib '../evented-object';
use Evented::Query;

my $query = Evented::Query->new();

$query->select->from('someTable')->limit(1);

say $query->sql_compile->sql_data;
