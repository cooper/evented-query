use warnings;
use strict;
use feature 'say';
use lib '../evented-object';
use Evented::Query;

my $query = Evented::Query->new();

$query->select->from('someTable')->limit(1)->order_by('identifier', 'desc');
$query->where(
    ['some_var',  'is equal to', 'some value'],
    ['last_time', 'is less than', time()]
);


say $query->sql_data;
say "args: @{[$query->sql_arguments]}";
