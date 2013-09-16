package DBIx::Class::Validation::Structure;

use strict;
use warnings;
use 5.008_005;
our $VERSION = '0.05';

use Email::Valid;
use HTML::TagFilter;

use base qw/DBIx::Class/;

sub validate {
   my $self = shift;
   my @check_columns = @_;

   my $check_columns = { map{ $_ => 1 } @check_columns } || {};

   my $source = $self->result_source;
   my %data = $self->get_columns;
   my $columns = $source->columns_info;

   # Get Hash with unique columns as keys
   my $uniques = get_uniques($source);

   # Get Hash of Primary keys
   my @primary_key = $source->primary_columns();
   my %unique_search_columns;
   foreach ( @primary_key ) {
    $unique_search_columns{$_} = { '!=' => $data{$_} } if defined $data{$_};
   }

	my ($error, @error_list, $stmt);

   for my $column ( keys %$columns ) {

      if ( ( not keys %$check_columns ) or $check_columns->{$column} ) {

         if ($columns->{$column}{validation_function} and ref $columns->{$column}{validation_function} eq 'CODE' ) {
            ($data{$column}, $error) = $columns->{$column}{validation_function}(
               info => $columns->{$column},
               value => $data{$column},
            );
               if ( $error-> { msg } ) { push @error_list, { $column => $error->{ msg } }; }
         } else {
            my $mand = (defined $columns->{$column}{is_nullable} and $columns->{$column}{is_nullable} == 1 or ( defined $columns->{$column}{is_auto_increment} and $columns->{$column}{is_auto_increment} == 1 ) ) ? 0 : 1;
            my $val_type = (defined $columns->{$column}{val_override}) ? $columns->{$column}{val_override} : $columns->{$column}{data_type};

            if ($val_type eq 'email') {
               ($data{$column}, $error) = _val_email( $mand, $data{$column} );
                  if ( $error-> { msg } ) { push @error_list, { $column => $error->{ msg } }; }
            } elsif ($val_type eq 'varchar' or $val_type eq 'text') {
               ($data{$column}, $error) = _val_text( $mand, $columns->{$column}{size}, $data{$column} );
                  if ( $error-> { msg } ) { push @error_list, { $column => $error->{ msg } }; }
            } elsif ($val_type eq 'password') {
               ($data{$column}, $error) = _val_password( $mand, $columns->{$column}{size}, $data{$column} );
                  if ( $error-> { msg } ) { push @error_list, { $column => $error->{ msg } }; }
            } elsif ($val_type eq 'selected') {
            
               if ($columns->{$column}{data_type} eq 'varchar' or $columns->{$column}{data_type} eq 'text') {
                  ($data{$column}, $error) = _val_text( 0, $columns->{$column}{size}, $data{$column} );
                     if ( $error-> { msg } ) { push @error_list, { $column => $error->{ msg } }; }
               } else {
                  ($data{$column}, $error) = _val_int( 0, $data{$column} );
                     if ( $error-> { msg } ) { push @error_list, { $column => $error->{ msg } }; }
               }
               ($data{$column}, $error) = _val_selected( $data{$column} );
                  if ( $error-> { msg } ) { push @error_list, { $column => $error->{ msg } }; }
            } elsif ($val_type eq 'integer' or $val_type =~ /int/g) {
               ($data{$column}, $error) = _val_int( $mand, $data{$column} );
                  if ( $error-> { msg } ) { push @error_list, { $column => $error->{ msg } }; }
            } elsif ($val_type eq 'number') {
               ($data{$column}, $error) = _val_number( $mand, $columns->{$column}{size}, $data{$column} );
                  if ( $error-> { msg } ) { push @error_list, { $column => $error->{ msg } }; }
            } else {
               ($data{$column}, $error) = _val_text( $mand, $columns->{$column}{size}, $data{$column} );
                  if ( $error-> { msg } ) { push @error_list, { $column => $error->{ msg } }; }
            }

            # If the column is auto_increment and there is no value set, set it to undef
            $data{$column} = undef if $columns->{$column}{is_auto_increment} and not $data{$column};

            if ( $uniques->{$column} and not defined $unique_search_columns{$column} ) {
               # Columns for unique search
               my %this_unique_search_columns = %unique_search_columns;
               $this_unique_search_columns{ $column } = $data{$column};

               push @error_list, { $column => "already exists" } if $source->resultset->count(\%this_unique_search_columns);
            }
         }
      }
   }

   $self->set_columns(\%data);

	if (@error_list) {
      return { 'errors' => \@error_list };
   }
   return {};
}

sub get_uniques {
   my %unique_constraints = shift->unique_constraints();

   my @uniques; 
   @uniques = ( @uniques, @{$_} ) foreach ( values %unique_constraints );

   # Make sure you have unique 'uniques'
   return { map { $_ => 1 } @uniques };
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

# =============== Validatators ===============

sub _val_email { 
	my ($mand, $value) = @_;
   if (not defined $value) { $value = ''; }
	if ( !Email::Valid->address($value) && $mand ) { 
		return ( undef, { msg => 'address is blank or not valid' }	);
	} elsif ( !Email::Valid->address($value) && $value ) {
		return ( undef, { msg => 'address is blank or not valid' }	);
	} else {
		return $value;
	}
}

sub _val_text {
	my ($mand, $len, $value) = @_;

	# To ensure the text is correctly encoded etc. SZ 7/12/12
	#my $decoder = Encode::Guess->guess($value);	# First guess the decoder
	#if (ref($decoder)){
	#	$value = $decoder->decode($value);	# If a decoder is found, then decode.
	#}
	#$value = Encode::encode_utf8($value);	# If there is no decoder, assume its UTF8

	if ($mand && (!$value || $value =~ /bogus="1"/)) {  #tiny mce
		return (undef, { msg => 'cannot be blank' });
	} elsif ($len && length($value) && (length($value) > $len) ) {
		return (undef, { msg => 'is limited to '.$len.' characters' });
	} elsif ($value && $value !~ /^([\w \.\,\-\'\"\!\$\#\%\=\&\:\+\(\)\?\;\n\r\<\>\/\@äÄöÖüÜßéÉáÁíÍ]*)$/) {
		return (undef, { msg => 'can only use letters, 0-9 and -.,\'\"!&#$?:()=%<>;/@ (do not cut and paste from a Word document, you must Save As text only)' });
	} else {
		my $tf = new HTML::TagFilter;
		if ($value) {	# This is to prevent empty strings from returning as the last regex match.
			return ($tf->filter($1));	# $1 is a tricky value. If value is blank $1 will be the last regex match.
		} else {
			return '';	# Take that $1. Conditional statement to the face.
		}
	}
}

# _val_password is the same as _val_text but it also allows {}s
sub _val_password {
	my ($mand, $len, $value) = @_;

	# To ensure the text is correctly encoded etc. SZ 7/12/12
	#my $decoder = Encode::Guess->guess($value);	# First guess the decoder
	#if (ref($decoder)){
	#	$value = $decoder->decode($value);	# If a decoder is found, then decode.
	#}
	#$value = Encode::encode_utf8($value);	# If there is no decoder, assume its UTF8

	if ($mand && (!$value || $value =~ /bogus="1"/)) {  #tiny mce
		return (undef, { msg => 'cannot be blank' });
	} elsif ($len && length($value) && (length($value) > $len) ) {
		return (undef, { msg => 'is limited to '.$len.' characters' });
	} elsif ($value && $value !~ /^([\w \.\,\-\'\"\!\$\#\%\=\&\:\+\(\)\{\}\?\;\n\r\<\>\/\@äÄöÖüÜßéÉáÁíÍ]*)$/) {
		return (undef, { msg => 'can only use letters, 0-9 and -.,\'\"!&#$?:()=%<>;/@ (do not cut and paste from a Word document, you must Save As text only)' });
	} else {
		my $tf = new HTML::TagFilter;
		if ($value) {	# This is to prevent empty strings from returning as the folder name.
			return ($tf->filter($1));	# $1 is a tricky value. If value is blank $1 will be the name of the folder from the instance script.
		} else {
			return '';	# Take that $1. Conditional statement to the face.
		}
	}
}

sub _val_int {
	my ($mand, $value) = @_;
	if ( ( $value ne '0' or not defined $value) && !$value && $mand ) {
		return (undef, { msg => 'cannot be blank' });
	} elsif ( ( $value or $value eq '0' ) and $value !~ /^[-]?\d+$/) {
		return (undef, { msg => 'can only use numbers' });
	} else {
    	return ($value);
	}
}

sub _val_selected {
	my ($value) = @_;
	if (! defined $value or $value eq '') {
		return (undef, { msg => 'must be selected' });
	} else {
		return $value;
	}
}

sub _val_number {
	my ($mand, $len, $value) = @_;
	if ((!defined $value or $value eq '') && $mand) {
		return (undef, { msg => 'cannot be blank' });
	} elsif ($len && (length($value) > $len) ) {
		return (undef, { msg => 'is limited to '.$len.' characters' });
	} elsif ($value && $value !~ /^([-\.]*\d[\d\.-]*)$/) {
		return (undef, { msg => 'can only use numbers and . or -' });
	} else {
		if ($value ne '') {	# This is to prevent empty strings from returning as the folder name.
			return ($1);	# $1 is a tricky value. If value is blank $1 will be the name of the folder from the instance script.
		} else {
			return '';	# Take that $1. Conditional statement to the face.
		}
	}
}


1;
__END__

=encoding utf-8

=head1 NAME

DBIx::Class::Validation::Structure - DBIx::Class Validation based on the column meta data

=head1 SYNOPSIS

  package MyApp::Schema::Result::Artist;
  use base qw/DBIx::Class::Core/;

  __PACKAGE__->load_components(qw/Validation::Structure/);

  __PACKAGE__->table('artist');
  __PACKAGE__->add_columns(qw/ artistid name /);
  __PACKAGE__->set_primary_key('artistid');
  __PACKAGE__->has_many(cds => 'MyApp::Schema::Result::CD');


=head1 DESCRIPTION

DBIx::Class::Validation::Structure is DBIx::Class Validation based on the column meta data set in add_columns or add_column.

=head1 AUTHOR

Sean Zellmer E<lt>sean@lejeunerenard.comE<gt>

=head1 COPYRIGHT

Copyright 2013- Sean Zellmer

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=over 8

=item L<DBIx::Class>

=item L<DBIx::Class::Validation>

=item L<Email::Valid>

=item L<HTML::TagFilter>

=back

=cut
