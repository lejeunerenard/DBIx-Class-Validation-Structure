use strict;
use warnings;
package DBIx::Class::Validation::DBStruct;

BEGIN {
   use base qw/DBIx::Class Data::Dumper/;
   use Carp qw/croak/;
};

sub validate {
   my $self = shift;
   my $source = $self->result_source;
   my $columns = $source->columns_info;

   print "Columns: ".Dumper($columns)."\n";
   for my $column ( keys %$columns ) {
      
   }
}

sub insert {
   my $self = shift;
   my $result = $self->validate;
   # If errors return the result
   if ($result->{errors}) {
      return $result;
   } else {
   # Else do the normal insert
      $self->next::method(@_);
   }
}

sub update {
   my $self = shift;
   my $columns = shift;

   $self->set_inflated_columns($columns) if $columns;

   my $result = $self->validate;
   # If errors return the result
   if ($result->{errors}) {
      return $result;
   } else {
      # Else do the normal update
      $self->next::method(@_);
   }
}

1;
