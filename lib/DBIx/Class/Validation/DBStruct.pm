use strict;
use warnings;
package DBIx::Class::Validation::DBStruct;

BEGIN {
   use base qw/DBIx::Class/;
   use Carp qw/croak/;
};

sub validate {
   my $self = shift;
   my $source = $self->result_source;
   my %data = $self->get_columns;
   my $columns = $source->columns_info;

	my ($error, @error_list, $stmt);

   for my $column ( keys %$columns ) {
      if ($columns->{$column}{validation_function} and ref $columns->{$column}{validation_function} eq 'CODE' ) {
         ($data{$column}, $error) = $columns->{$column}{validation_function}({
            info => $columns->{$column},
            value => $data{$column},
         });
            if ( $error-> { msg } ) { push @error_list, { $column => $error->{ msg } }; }
      } else {
         my $mand = (defined $columns->{$column}{is_nullable} and $columns->{$column}{is_nullable} == 1 or ( defined $columns->{$column}{is_auto_increment} and $columns->{$column}{is_auto_increment} == 1 ) ) ? 0 : 1;
         my $val_type = (defined $columns->{$column}{val_override}) ? $columns->{$column}{val_override} : $columns->{$column}{data_type};

         if ($val_type eq 'email') {
            ($data{$column}, $error) = Validate::Validate::val_email( $mand, $data{$column} );
               if ( $error-> { msg } ) { push @error_list, { $column => $error->{ msg } }; }
         } elsif ($val_type eq 'varchar' or $val_type eq 'text') {
            ($data{$column}, $error) = Validate::Validate::val_text( $mand, $columns->{$column}{size}, $data{$column} );
               if ( $error-> { msg } ) { push @error_list, { $column => $error->{ msg } }; }
         } elsif ($val_type eq 'selected') {
         
            if ($columns->{$column}{data_type} eq 'varchar' or $columns->{$column}{data_type} eq 'text') {
               ($data{$column}, $error) = Validate::Validate::val_text( 0, $columns->{$column}{size}, $data{$column} );
                  if ( $error-> { msg } ) { push @error_list, { $column => $error->{ msg } }; }
            } else {
               ($data{$column}, $error) = Validate::Validate::val_int( 0, $data{$column} );
                  if ( $error-> { msg } ) { push @error_list, { $column => $error->{ msg } }; }
            }
            ($data{$column}, $error) = Validate::Validate::val_selected( $data{$column} );
               if ( $error-> { msg } ) { push @error_list, { $column => $error->{ msg } }; }
         } elsif ($val_type eq 'integer' or $val_type =~ /int/g) {
            ($data{$column}, $error) = Validate::Validate::val_int( $mand, $data{$column} );
               if ( $error-> { msg } ) { push @error_list, { $column => $error->{ msg } }; }
         } elsif ($val_type eq 'number') {
            ($data{$column}, $error) = Validate::Validate::val_number( $mand, $columns->{$column}{size}, $data{$column} );
               if ( $error-> { msg } ) { push @error_list, { $column => $error->{ msg } }; }
         } else {
            ($data{$column}, $error) = Validate::Validate::val_text( $mand, $columns->{$column}{size}, $data{$column} );
               if ( $error-> { msg } ) { push @error_list, { $column => $error->{ msg } }; }
         }
      }
   }

   $self->set_columns(\%data);

	if (@error_list) {
      return { 'errors' => \@error_list };
   }
   return {};
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
