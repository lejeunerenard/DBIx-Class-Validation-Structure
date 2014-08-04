use strict;

use lib './local/lib/perl5';
use lib qw{ ./t/lib };


use Test::More;
use DBIx::Class::Validation::Structure;

# ----- Testing _val_email -----
use Data::Dumper;
# Blank and mandatory
is_deeply([DBIx::Class::Validation::Structure::_val_email(1,'')], [ undef, { msg => 'address is blank or not valid' } ], 'Is Mandatory and a blank value should give "blank or not valid" error');
# Malformated email
is_deeply([DBIx::Class::Validation::Structure::_val_email(0,'test')], [ undef, { msg => 'address is blank or not valid' } ], 'Is NOT Mandatory and a invalid value should give "blank or not valid" error');
# Undef and non-mandatory email
is_deeply([DBIx::Class::Validation::Structure::_val_email(0,undef)], [ '' ], 'Is NOT Mandatory and is undefined should return blank');
# Blank and non-mandatory email
is_deeply([DBIx::Class::Validation::Structure::_val_email(0,'')], [ '' ], 'Is NOT Mandatory and is blank should return blank');
# Properly formatted email
is_deeply([DBIx::Class::Validation::Structure::_val_email(0,'test@example.com')], [ 'test@example.com' ], 'Is NOT Mandatory and a valid value should return the value');

# ----- Testing _val_text -----

# Blank and mandatory
is_deeply([DBIx::Class::Validation::Structure::_val_text(1,32,'')], [ undef, { msg => 'cannot be blank' } ], 'Is Mandatory and a blank value should give "cannot be blank" error');
# Over length at 8 chars
is_deeply([DBIx::Class::Validation::Structure::_val_text(0,8,'abcdefghij')], [ undef, { msg => 'is limited to 8 characters' } ], 'Is non-Mandatory, length limited to 8 and a 10 character value should give "is limited to 8" error');
# Malformated text
is_deeply([DBIx::Class::Validation::Structure::_val_text(0,8,'Ç')], [ undef, { msg => 'can only use letters, 0-9 and -.,\'\"!&#$?:()=%<>;/@ (do not cut and paste from a Word document, you must Save As text only)' } ], 'Is NOT Mandatory and a invalid value should give "can only use letters..." error');
# Undef and non-mandatory text
is_deeply([DBIx::Class::Validation::Structure::_val_text(0,8,undef)], [ '' ], 'Is NOT Mandatory and is undefined should return blank');
# Blank and non-mandatory text
is_deeply([DBIx::Class::Validation::Structure::_val_text(0,8,'')], [ '' ], 'Is NOT Mandatory and is blank should return blank');
# Properly formatted text
is_deeply([DBIx::Class::Validation::Structure::_val_text(0,32,'Hello this is a test.')], [ 'Hello this is a test.' ], 'Is NOT Mandatory and a valid value should return the value');

# ----- Testing _val_password -----

# Blank and mandatory
is_deeply([DBIx::Class::Validation::Structure::_val_password(1,32,'')], [ undef, { msg => 'cannot be blank' } ], '_val_password: Is Mandatory and a blank value should give "cannot be blank" error');
# Over length at 8 chars
is_deeply([DBIx::Class::Validation::Structure::_val_password(0,8,'abcdefghij')], [ undef, { msg => 'is limited to 8 characters' } ], '_val_password: Is non-Mandatory, length limited to 8 and a 10 character value should give "is limited to 8" error');
# Malformated password
is_deeply([DBIx::Class::Validation::Structure::_val_password(0,8,'Ç')], [ undef, { msg => 'can only use letters, 0-9 and -.,\'\"!&#$?:()=%<>;/@ (do not cut and paste from a Word document, you must Save As text only)' } ], '_val_password: Is NOT Mandatory and a invalid value should give "can only use letters..." error');
# Undef and non-mandatory password
is_deeply([DBIx::Class::Validation::Structure::_val_password(0,8,undef)], [ '' ], '_val_password: Is NOT Mandatory and is undefined should return blank');
# Blank and non-mandatory password
is_deeply([DBIx::Class::Validation::Structure::_val_password(0,8,'')], [ '' ], '_val_password: Is NOT Mandatory and is blank should return blank');
# Properly formatted password
is_deeply([DBIx::Class::Validation::Structure::_val_password(0,32,'Hello this is a test.')], [ 'Hello this is a test.' ], '_val_password: Is NOT Mandatory and a valid value should return the value');
# Properly formatted password with {}s
is_deeply([DBIx::Class::Validation::Structure::_val_password(0,32,'$hash{asdfkl}')], [ '$hash{asdfkl}' ], '_val_password: Is NOT Mandatory and a valid (with {}s) value should return the value');

# ----- Testing _val_int -----

# Blank and mandatory
is_deeply([DBIx::Class::Validation::Structure::_val_int(1,'')], [ undef, { msg => 'cannot be blank' } ], '_val_int: Is Mandatory and a blank value should give "cannot be blank." error');
# Malformated int
is_deeply([DBIx::Class::Validation::Structure::_val_int(0,'df')], [ undef, { msg => 'can only use numbers' } ], '_val_int: Is NOT Mandatory and a invalid value should give "can only use letters..." error');
# Blank and non-mandatory int
is_deeply([DBIx::Class::Validation::Structure::_val_int(0,'')], [ '' ], '_val_int: Is NOT Mandatory and is blank should return blank');
# Properly formatted int
is_deeply([DBIx::Class::Validation::Structure::_val_int(0,-32)], [ -32 ], '_val_int: Is NOT Mandatory and a valid value should return the value');

# ----- Testing _val_selected -----

# Blank
is_deeply([DBIx::Class::Validation::Structure::_val_selected('')], [ undef, { msg => 'must be selected' } ], '_val_selected: A blank value should give "must be selected" error');
# Not Blank
is_deeply([DBIx::Class::Validation::Structure::_val_selected(3)], [ 3 ], '_val_selected: A Valid value should return the value');

# ----- Testing _val_number -----

# Blank and mandatory
is_deeply([DBIx::Class::Validation::Structure::_val_number(1, 8, '')], [ undef, { msg => 'cannot be blank' } ], '_val_number: Is Mandatory and a blank value should give "cannot be blank." error');
# Malformated number
is_deeply([DBIx::Class::Validation::Structure::_val_number(0, 8,'df')], [ undef, { msg => 'can only use numbers and . or -' } ], '_val_number: Is NOT Mandatory and a invalid value should give "can only use..." error');
# Blank and non-mandatory number
is_deeply([DBIx::Class::Validation::Structure::_val_number(0,8,'')], [ '' ], '_val_number: Is NOT Mandatory and is blank should return blank');
# Over length number
is_deeply([DBIx::Class::Validation::Structure::_val_number(0,8,349237402348250)], [ undef, { msg => 'is limited to 8 characters' } ], '_val_number: Is NOT Mandatory and a valid value but over length should return the "is limited" error');
# Over length number again
is_deeply([DBIx::Class::Validation::Structure::_val_number(0,10,349237402348250)], [ undef, { msg => 'is limited to 10 characters' } ], '_val_number: Is NOT Mandatory and a valid value but over length should return the "is limited" error');
# Properly formatted number
is_deeply([DBIx::Class::Validation::Structure::_val_number(0,8,-32)], [ -32 ], '_val_number: Is NOT Mandatory and a valid value should return the value');

done_testing;
