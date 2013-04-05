# Copyright (c) 2013, Mitchell Cooper
package Evented::Query;

use warnings;
use strict;

use EventedObject;
use parent 'EventedObject';

# creates a new query object.
sub new {
    my ($class, %opts) = @_;
    my $query = $class->SUPER::new(%opts);
    return $query;
}

###########
### SQL ###
###########

# returns a list of SQL query arguments.
sub sql_arguments {
    my $query = shift;
}

# compiles to SQL and stores it.
sub sql_compile {
    my ($query, $sql) = shift;
    
    # call generator.
    if ($query->{generator}) {
        $sql = $query->{generator}->($query);
    }
    
    # return the SQL query.
    $query->{compiled} = 1;
    $query->{sql_data} = $sql;
    
    return $query;
}

# returns compiled SQL string.
sub sql_data {
    my $query = shift;
    
    $query->sql_compile if !$query->{compiled};
    
    return $query->{sql_data};
}

##############################
### SELECT QUERY INTERFACE ###
##############################


# set query select columns.
sub select {
    my ($query, @select) = @_;
    
    # if there are no values, assume all.
    @select = '*' if scalar @select == 0;
    
    # set the select columns.
    $query->{select_columns} = \@select;
    
    # it's a select query.
    $query->{generator} = \&_select_sql;
    
    return $query;
}

# set select target table.
sub from {
    my ($query, $table) = @_;
    $query->{target_table} = $table;
    return $query;
}


# set select order by column and ordering format.
sub order_by {
    my ($query, $column, $format) = @_;
    
    # default to ascending.
    $format ||= 'ASC';
    
    return $query;
}

# set select row return limit.
sub limit {
    my $query = shift;
    $query->{select_row_limit} = shift;
    return $query;
}

# convert select columns to the proper format.
sub _select_fmt {
    my ($query, @final) = shift;
    
    # backtick each column name.
    foreach my $column (@{$query->{select_columns}}) {
    
        # select all.
        if ($column eq '*') {
            @final = '*';
            last;
        }
        
        # function; do not backtick.
        if ($column =~ m/\(/) {
            push @final, $column;
        }
        
        # add backticks.
        push @final, _bt($column);
        
    }

    # return as a comma-separated string.
    return join ', ', @final;
}

# creates a select query.
sub _select_sql {
    my $query = shift;
    
    # generate select columns.
    my $items = $query->_select_fmt();
    
    # fetch the table and backtick it.
    my $table = _bt($query->{target_table});

    # conditionals, ordering, and return limit.
    my $where = _space($query->_where_sql);
    my $order = _space($query->_order_by_sql);
    my $limit = _space($query->_limit_sql);

    # create query.
    my $sql = "SELECT $items FROM $table$where$order$limit";
    
    # return complete query.
    return $sql;
    
}

sub _order_by_sql {
    return '';
}

sub _limit_sql {
    my $query = shift;
    return if !defined $query->{select_row_limit};
    return 'LIMIT '.$query->{select_row_limit};
}

###################################
### GENERAL SQL QUERY INTERFACE ###
###################################

sub where {
    my $query = shift;
    
    return $query;
}

# compiles and executes SQL query.
sub execute {
    my $query = shift;
    
    # we haven't compiled yet.
    if (!$query->{compiled}) {
        $query->sql_compile();
    }
    
    # execute the code.
    #if ($query->{db}) return $query->{db}->blah
    
}

# returns the number of rows fetched by select.
sub select_num_rows {

}

sub _where_sql {
    return '';
}

##############
### EVENTS ###
##############

sub on_select_hash {
}

sub on_select_array {
}

#############
### OTHER ###
#############

# add/escape backticks.
sub _bt {
    my $string = shift;
    $string =~ s/\`/\\\`/g;
    return "`$string`";
}

# add prefixing space if needed.
sub _space {
    my $string = shift;
    return '' if !defined $string || !length $string;
    return " $string";
}

1
