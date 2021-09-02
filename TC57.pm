# to do:
#-----------------------------------------------------------------
# method to load ua into a data structure
# method to return data given record and data element  
# method to list record types 
# 
#-----------------------------------------------------------------

package TC57;
use Time::HiRes qw( usleep ualarm gettimeofday tv_interval nanosleep
                    clock_gettime clock_getres clock_nanosleep clock
                    stat lstat utime);

sub _load_ua {
my $self = shift;
my $file = shift;


# check if readable
$self->set_value( '_template_file', $file);

$self->_add( '_template', { value => [], type => 'string', access => 'rw'} );

my @def = qw[BASEII_TC57_0_BH BASEII_TC57_1_BH BASEII_TC57_0_Detail BASEII_TC57_3_CPS TC57_4_PMT0_MC BASEII_TC57_5_MCC BASEII_TC92_FT 
BASEII_TC91_BT BASEII_TC90_FH  BASEII_TC57_7_CHIP_RECORD BASEII_TC57_7_CHIP_RECORD_EXTENSION];
   
  foreach my $rec_type (@def) {
          $self->load_template($rec_type); 
  }   	
}

sub load_template {
my $self = shift;	
my $type = shift;
my $record_type;
my $ds_name;
my $processing=0;
my $package_name;
my $alias;
my $output;
my $fhh;
my @field_ary;

if ( $type eq 'BASEII_TC57_0_BH') { 
	$record_type = 'MSG BASEII_TC57_0_BH';
}
elsif ( $type eq 'BASEII_TC57_1_BH') { 
	  $record_type = 'MSG BASEII_TC57_1_BH';
}
elsif ( $type eq 'BASEII_TC57_0_Detail') { 
	  $record_type = 'MSG BASEII_TC57_0_Detail';	
}
elsif ( $type eq 'BASEII_TC57_3_CPS') { 
	  $record_type = 'MSG BASEII_TC57_3_CPS';	
}
elsif ( $type eq 'TC57_4_PMT0_MC') { 
	  $record_type = 'MSG TC57_4_PMT0_MC';	
}
elsif ( $type eq 'BASEII_TC57_5_MCC') { 
	  $record_type = 'MSG BASEII_TC57_5_MCC';	
}
elsif ( $type eq 'BASEII_TC90_FH') { 
	  $record_type = 'MSG BASEII_TC90_FH';	
}
elsif ( $type eq 'BASEII_TC91_BT') { 
	  $record_type = 'MSG BASEII_TC91_BT';
}
elsif ( $type eq 'BASEII_TC92_FT') { 
	  $record_type = 'MSG BASEII_TC92_FT';
}
elsif ( $type eq 'BASEII_TC57_7_CHIP_RECORD') { 
	  $record_type = 'MSG BASEII_TC57_7_CHIP';
}
elsif ( $type eq 'BASEII_TC57_7_CHIP_RECORD_EXTENSION') { 
	  $record_type = 'MSG BASEII_TC57_7_CHIP_EXT';
}

open my $fh,"<$self->{_template_file}" or $self->err( __PACKAGE__, __LINE__, {  errno      => '1012', 
   	      	                                                                errstr     => "not able to read $self->{_template_file}", 
   	      	                                                                force_exit => 1 });
	
  while (<$fh>) {
  	chomp;
  	$_ = $self->trim( $_);
  	if ( $_ =~ m{$record_type}) {
  		$processing = 1;
  		next;
  	}
  	next if ( $_ =~ m{^#}) and $processing;
  	
  	next if ( $_ =~ m{[\{]}) and $processing;
  	if ( $_ =~ m{[\}]} and $processing ) {
  	   $processing = 0;
  	   last;
  	}

  	if ( $processing ) {
  	my ( $name, $null, $offset, $length, $type, $format) = split ' ', $_;
  
        $format = 'not_defined' if $format eq '-';
        $name =~ s/\W//g;
        
        if ( defined($alias{$name}) ) {
            $alias = $alias{$name};	
        }
        else
          {
            $alias = 'not_defined';
          }
        
        # exception 100    
        if ( $name eq 'transactionTimeYY') {
          $type = 'date';
          $format = 'YY';
        }

        my $hash = {
              name   =>    $name,
              alias  =>    $alias,
              offset =>    $offset,
              length =>    $length,
              type   =>    $type,
              format =>    $format,
              data   =>    'not_defined',
        };

        push @field_ary, $hash;
    }

  }
my @x = @{$self->_get('_template')};
my $hash = { record => $record_type, fields => \@field_ary };
push @x, $hash;
$self->_set('_template', \@x);
}



sub _display_records {
my $self = shift;
my $method = shift;

  my $ref = $self->_get('_template');

  if (scalar(@$ref) == 0 ) {
     $self->err( __PACKAGE__, __LINE__, {  errno      => '1029', 
   	                                   errstr     => "_load_ua('file') must precede _display_records", 
   	                                   force_exit => 1 });
  } 


  if (!$method) {
      my $ary_ref = $self->_get('_template');
      foreach my $hash ( @$ary_ref) {
        print $$hash{record},"\n";
      }
  }

  if ($method) {
      my @data;
      my $ary_ref = $self->_get('_template');
      foreach my $hash ( @$ary_ref) {
        push @data, $$hash{record};
      }
      return(\@data);
  }
}

sub _display_ua {
my $self = shift;
my $file = shift;

# check if readable
$self->set_value( '_template_file', $file);
 
my @def = qw[BASEII_TC57_0_BH BASEII_TC57_1_BH BASEII_TC57_0_Detail BASEII_TC57_3_CPS TC57_4_PMT0_MC BASEII_TC57_5_MCC BASEII_TC92_FT 
BASEII_TC91_BT BASEII_TC90_FH  BASEII_TC57_7_CHIP_RECORD BASEII_TC57_7_CHIP_RECORD_EXTENSION];
   
  foreach my $rec_type (@def) {
          $self->display_template($rec_type); 
  }   	
}




sub _get_entity {
my $self = shift;
my $data = shift;
my $record = shift;
my $entity = shift;
my $status = undef;
#-----------------------------------------------------------------------
# data parameter is identified by either having a 9[1-3] in bytes 1-2 or
# 570[1-9] in bytes 1-4
# raise error if not detected
#-----------------------------------------------------------------------

if ( $data =~ m{^9[0-2]} or $data =~ m{^570[0-9]}) {
   $status = 'data-validated';
}
else
   {
    $self->err( __PACKAGE__, __LINE__, {  errno      => '1030', 
   	        	                  errstr     => "get_entity believes the data is not tc57 data", 
   	      	                          force_exit => 1 }); 
   }

#-----------------------------------------------------------------------
# record is validated if it is in the array of known record types
#-----------------------------------------------------------------------
my $ref = $self->_get('_template');
foreach my $recordType (@$ref) {

    if ( $record eq $$recordType{record}) {
      $status = 'record-validated';
    }
}

if ( $status eq 'record-validated') {
   $status = 'validate-entity';
}
else
   {
    $self->err( __PACKAGE__, __LINE__, {  errno      => '1030', 
   	        	                            errstr     => "get_entity believes the record is not valid", 
   	      	                              force_exit => 1 }); 
   }

#-----------------------------------------------------------------------
# entity is validated if it is in the list of entities per record
#-----------------------------------------------------------------------   

my $ref = $self->_get('_template');
foreach my $recordType (@$ref) {

  if ( $$recordType{record} eq $record ) {

     my $fields = $$recordType{fields};
     foreach my $field (@$fields) {
    
        if ( $$field{name} eq $entity ) {
           $status = 'entity-validated';
        }
     }
  }
}

if ( $status eq 'entity-validated') {
   $status = 'entity-validated';
}
else
   {
    $self->err( __PACKAGE__, __LINE__, {  errno      => '1030', 
   	        	                  errstr     => "get_entity believes the entity is not valid", 
   	      	                          force_exit => 1 }); 
   }

#print $status,"\n";
#-----------------------------------------------------------------------
# extract entity
#-----------------------------------------------------------------------

my $ref = $self->_get('_template');
foreach my $recordType (@$ref) {

  if ( $$recordType{record} eq $record ) {

    
     my $fields = $$recordType{fields};
     foreach my $field (@$fields) {
        if ( $$field{name} eq $entity ) {
               return substr( $data, $$field{offset}, $$field{length});
        }
     }

    

  }
}


}

=head1 
NAME
 display_template

DESCRIPTION

=cut

sub display_template {
my $self = shift;	
my $type = shift;
my $record_type;
my $ds_name;
my $processing=0;
my $package_name;
my $alias;
my $output;
my $fhh;

if ( $type eq 'BASEII_TC57_0_BH') { 
	$record_type = 'MSG BASEII_TC57_0_BH';
}
elsif ( $type eq 'BASEII_TC57_1_BH') { 
	  $record_type = 'MSG BASEII_TC57_1_BH';
}
elsif ( $type eq 'BASEII_TC57_0_Detail') { 
	  $record_type = 'MSG BASEII_TC57_0_Detail';	
}
elsif ( $type eq 'BASEII_TC57_3_CPS') { 
	  $record_type = 'MSG BASEII_TC57_3_CPS';	
}
elsif ( $type eq 'TC57_4_PMT0_MC') { 
	  $record_type = 'MSG TC57_4_PMT0_MC';	
}
elsif ( $type eq 'BASEII_TC57_5_MCC') { 
	  $record_type = 'MSG BASEII_TC57_5_MCC';	
}
elsif ( $type eq 'BASEII_TC90_FH') { 
	  $record_type = 'MSG BASEII_TC90_FH';	
}
elsif ( $type eq 'BASEII_TC91_BT') { 
	  $record_type = 'MSG BASEII_TC91_BT';
}
elsif ( $type eq 'BASEII_TC92_FT') { 
	  $record_type = 'MSG BASEII_TC92_FT';
}
elsif ( $type eq 'BASEII_TC57_7_CHIP_RECORD') { 
	  $record_type = 'MSG BASEII_TC57_7_CHIP';
}
elsif ( $type eq 'BASEII_TC57_7_CHIP_RECORD_EXTENSION') { 
	  $record_type = 'MSG BASEII_TC57_7_CHIP_EXT';
}

print "Record $record_type","\n";	

open my $fh,"<$self->{_template_file}" or $self->err( __PACKAGE__, __LINE__, {  errno      => '1012', 
   	      	                                                                errstr     => "not able to read $self->{_template_file}", 
   	      	                                                                force_exit => 1 });
	
  while (<$fh>) {
  	chomp;
  	$_ = $self->trim( $_);
  	if ( $_ =~ m{$record_type}) {
  		$processing = 1;
  		next;
  	}
  	next if ( $_ =~ m{^#}) and $processing;
  	
  	next if ( $_ =~ m{[\{]}) and $processing;
  	if ( $_ =~ m{[\}]} and $processing ) {
  	   $processing = 0;
  	   last;
  	}

  	if ( $processing ) {
  	my ( $name, $null, $offset, $length, $type, $format) = split ' ', $_;
  
    $format = 'not_defined' if $format eq '-';
  	$name =~ s/\W//g;
  	
  	if ( defined($alias{$name}) ) {
  	    $alias = $alias{$name};	
  	}
  	else
  	   {
  	     $alias = 'not_defined';
  	   }
  	
  	# exception 100    
  	if ( $name eq 'transactionTimeYY') {
  	   $type = 'date';
  	   $format = 'YY';
  	}
  	     	
  	print "\t{","\n";
  	print "\t  name   =>    ","\'$name\',","\n";
  	print "\t  alias  =>    ","\'$alias\',","\n";
  	print "\t  offset =>    ","\'$offset\',","\n";
  	print "\t  length =>    ","\'$length\',","\n";
  	print "\t  type   =>    ","\'$type\',","\n";
  	print "\t  format =>    ","\'$format\',","\n";
  	print "\t  data   =>    ","\'not_defined\',","\n";
  	print "\t},","\n";
  	}
  	
  }	

close $fh;	
print "\n","__end_of_record__","\n\n";
}

sub trim {
 my $self = shift;
 my $string = shift;
 $string =~ s/^\s+//;
 $string =~ s/\s+$//;
 return $string;
}

=head1 
NAME

DESCRIPTION
 returns a blessed reference to the class passed as a parameter
 essentially creating an instance of that class 
=cut
sub _attach_tc57 {
   my $self = shift;
   my $file = shift;
   my @data;

   if (! -r $file) {
        $self->err( __PACKAGE__, __LINE__, {  errno      => '2000',
                                              errstr     => "file: $file not readable",
                                              force_exit => 1 });
   }  
   $self->_add( '_tc57_file', { value => $file, type => 'string', access => 'rw'} ); 

   open my $fh,'<', $file;
   while (<$fh>) {
     chomp;
     push @data, $_;
   }
 return \@data;
}

=head1 
NAME
 new
CALLING
 use TC57;
 void $self->new();
KEYWORDS
 new object oriented class
CONTAINED
 $PERL5LIB/lib/Instance.pm
DESCRIPTION
 returns a blessed reference to the class passed as a paraameter
 essentially creating an instance of that class 
=cut
sub new {
   my $class = shift;
   my $self = {
    _instance         => "instance of $class",
    _template         => [],

   };

   $self->{ '_instance.meta' } =  {
                                  _value       => undef,
                                  _type        => undef,
                                  _access      => undef,
                                  _history     => undef
                                  };

   bless $self, $class;
   return $self;
}

=head1 
NAME
 set_value
CALLING
 use TC57;
 void $self->set_value( $key, $value);
KEYWORDS
 set_value object oriented class method
CONTAINED
 $PERL5LIB/lib/Instance.pm
DESCRIPTION
 predecessor to _add , _set and retained for backward
 compatibility. Will set an the value of an instance
 variable whether it exists or not.
=cut
sub set_value {
  my $self   = shift;
  my $key    = shift;
  my $value  = shift;
  $self->{ $key } = $value;
  return $self;
}

=head1 
NAME
 get_value
CALLING
 use TC57;
 void $self->get_value( $key);
KEYWORDS
 get_value object oriented class method
CONTAINED
 $PERL5LIB/lib/Instance.pm
DESCRIPTION
 predecessor to _get and retained for backward
 compatibility. Will get an the value of an instance
 variable.
=cut
sub get_value {
  my $self   = shift;
  my $key    = shift;
  unless ( defined( $self->{ $key } ))
   {
     print "Key $key is not a valid object attribute","\n";
     print "Exiting...","\n";
     exit(0);
   }
   return $self->{ $key };
}

=head1 
NAME
 _add
CALLING
 use TC57;
 void $self->_add( $key, $attr);
KEYWORDS
 _add object oriented class method assessor
CONTAINED
 $PERL5LIB/lib/Instance.pm
DESCRIPTION
 _add will create an instance variable to the object
 and set its initial value minimally. Additionally an
 additional instance variable is added as the same name 
 with .meta appended to it containing the value, type and
 access of the instance variable.
=cut
sub _add   {
  #
  # access -> read_only | read_write
  # type   -> real | integer | string | char
  #
  #
  my $self   = shift;
  my $key    = shift;
  my $attr   = shift;
  my $methodName = 'err';

  _validate_object_structure( $self,'_add');

  while ( my ($attr_key, $value) = each %$attr )
  {
     if ( $attr_key !~ m{value|type|access}i ) {
     
  	if ($self->can($methodName)) {
        	$self->err( __PACKAGE__, __LINE__, {  errno      => '1023', 
   	     	                                      errstr     => "violating key: $key", 
   	     	                                      force_exit => 1 });		
  	}
  	else {	
              print "compile error[",__LINE__,"]: invalid key: $key ","\n";
  	     }
     exit(1);
   } 
  }

  if (!defined($$attr{value})) {
  	if ($self->can($methodName)) {
        	$self->err( __PACKAGE__, __LINE__, {  errno      => '1020', 
   	     	                                      errstr     => "violating key: $key", 
   	     	                                      force_exit => 1 });		
  	}
  	else {	
              print "compile error[",__LINE__,"]: $key value not defined","\n" unless defined($$attr{value});
  	     }
   exit(1);
  }

  if (!defined($$attr{type})) {
  	if ($self->can($methodName)) {
        	$self->err( __PACKAGE__, __LINE__, {  errno      => '1021', 
   	     	                                      errstr     => "violating key: $key", 
   	     	                                      force_exit => 1 });		
  	}
  	else {	
              print "compile error[",__LINE__,"]: $key type not defined","\n" unless defined($$attr{type});
  	     }
   exit(1);
  }

  if (!defined($$attr{access})) {
  	if ($self->can($methodName)) {
        	$self->err( __PACKAGE__, __LINE__, {  errno      => '1022', 
   	     	                                      errstr     => "violating key: $key", 
   	     	                                      force_exit => 1 });		
  	}
  	else {	
              print "compile error[",__LINE__,"]: $key access not defined","\n" unless defined($$attr{access});
  	     }
   exit(1);
  }
  
  my @anon = (
               {
                 realtime =>  tv_interval($Init::T0),
                 value    =>  $$attr{value} ,
                 method   =>  '_add'  
               }          
    );

  $self->{ $key } = $$attr{value};
  $self->{ ${key}.'.meta' } =  {
                           _value       => $$attr{value},
                           _type        => lc($$attr{type}),
                           _access      => lc($$attr{access}),
                           _history     => \@anon
		     };
  
  return $self;
}

=head1 
NAME
 _set
CALLING
 use TC57;
 void $self->_set( $key, $value);
KEYWORDS
 _add _set object oriented class method assessor
CONTAINED
 $PERL5LIB/lib/Instance.pm
DESCRIPTION
 _set will update the instance variables value.
=cut
sub _set   {
   my $self   = shift;
   my $key    = shift;
   my $value  = shift;  # change to pass type($value)
   my $methodName = 'err';
   my $type = $self->{ ${key}.'.meta' }->{_type};
 
   _validate_object_structure( $self,'_set');

  if ( $self->{_trace} eq '1') {
   my $ary_ref = $self->{ ${key}.'.meta' }->{_history};

   my @anon = (
               {
                 realtime =>  Time::HiRes::tv_interval($Init::T0),
                 value    =>  $value,
                 method   =>  '_set'  
               }          
   );
   
   push @$ary_ref, @anon;
   $self->{ ${key}.'.meta' }->{_history} = \@$ary_ref;
  }

   if ( !defined($self->{$key})) {
  	if ($self->can($methodName)) {
        	$self->err( __PACKAGE__, __LINE__, {  errno      => '1024', 
   	     	                                      errstr     => "violating key: $key", 
   	     	                                      force_exit => 1 });		
  	}
  	else {	
              print "compile error[",__LINE__,"]: $key access not defined","\n" unless defined($$attr{access});
  	     }
   exit(1); 
   }

   $type = 'string' if $type eq 'not_defined';

   if  ( $self->{ ${key}.'.meta' }->{_type} eq 'string' and $type =~ m{integer|real} ) {
         if ($self->can($methodName)) {
                $self->err( __PACKAGE__, __LINE__, {  errno      => '1026',
                                                      errstr     => "violating key: $key",
                                                      force_exit => 1 });
        }
        else {
              print "compile error[",__LINE__,"]: $key access not defined","\n" unless defined($$attr{access});
             }
   exit(0);
   }


   if  ( $self->{ ${key}.'.meta' }->{_type} =~ m{integer|real|float} and $type eq 'string') {
         if ($self->can($methodName)) {
                $self->err( __PACKAGE__, __LINE__, {  errno      => '1027',
                                                      errstr     => "violating key: $key",
                                                      force_exit => 1 });
        }
        else {
              print "compile error[",__LINE__,"]: $key access not defined","\n" unless defined($$attr{access});
             }
   exit(0);
   }

   if ($self->{ ${key}.'.meta' }->{_access} =~ m{read_only|ro} ) {
         if ($self->can($methodName)) {
                $self->err( __PACKAGE__, __LINE__, {  errno      => '1025',
                                                      errstr     => "violating key: $key",
                                                      force_exit => 1 });
        }
        else {
              print "compile error[",__LINE__,"]: $key access not defined","\n" unless defined($$attr{access});
             }
   exit(1); 
   }

   $self->{ ${key}.'.meta' }->{_value} = $value;
   $self->{ $key} = $value;
   


 }

=head1 
NAME
 _get
CALLING
 use TC57;
 void $self->_get( $key);
KEYWORDS
 _add _set _get object oriented class method assessor
CONTAINED
 $PERL5LIB/lib/Instance.pm
DESCRIPTION
 _get will will retreive a instance variable value.
=cut
sub _get   {
# add check that var exists
  my $self   = shift;
  my $key    = shift;
  my $methodName = 'err';

  _validate_object_structure( $self,'_get');

  if ( !defined($self->{$key})) {
         if ($self->can($methodName)) {
                $self->err( __PACKAGE__, __LINE__, {  errno      => '1028',
                                                      errstr     => "violating key: $key",
                                                      force_exit => 1 });
        }
        else {
              print "compile error[",__LINE__,"]: $key not defined","\n" unless defined($self->{$key});
             }
  exit(1); 
  }
  
  # bug: return value at *.meta
  #my $hash = $self->{ ${key}.meta};
  #return $$hash{_value};
  return $self->{ $key};
}

=head1 
NAME
 _validate_object_structure
CALLING
 use TC57;
 void $self->_validate_object_structure();
KEYWORDS
 _add _set _get object oriented class method assessor
CONTAINED
 $PERL5LIB/lib/Instance.pm
DESCRIPTION
 this method validates the object model is valid and intact and no rules
 have been violated that weaken the structure
=cut
sub _validate_object_structure {
my $self = shift;
my $sub = shift;
my $methodName = 'err';

  foreach my $attr_key (keys %$self) {

     if ( $attr_key !~ m{.meta} and !defined ($self->{ ${attr_key}.'.meta' })) {
    	$self->prnt_trace(__LINE__, "*** warning instance variable $attr_key was not properly declared, identified by method $sub",{trace_level => 5});
     }
  }
}

=head1 
NAME
 prnt_trace
CALLING
 use TC57;
 void $self->prnt_trace();
KEYWORDS
 prnt_trace
CONTAINED
 .
DESCRIPTION
 this method presents a way to encapsulate printing
=cut

 sub prnt_trace {
 my $self = shift;
 my $line = shift;
 my $text = shift;
 my $hash = shift;
 my $tabs = '';
 
 $line = sprintf("%04d", $line);
 
 if ( defined($$hash{tabs}) ) {
 	$tabs = "\t" x $$hash{tabs};
    }
 
 if ( $self->{'_trace_file'} ) {
  open my $th, ">> $self->{'_trace_file'}" or $self->err( __PACKAGE__, __LINE__, {  errno      => '1012', 
        	                                                                    errstr     => "not able to write $self->{'_trace_file'}", 
   	     	                                                                    force_exit => 1 });
  print $th $self->get_sysdate('style2') . "[TRACE][$line] ${tabs}$text","\n";
  close $th;
 } 


 my $trace = $self->{'_trace'};
 if ( !defined($trace) ) {
    $trace = '0';
 }


 if ( $trace ne '0' and defined($trace)) {    
     print $self->get_sysdate('style2') . "[TRACE][$line] ${tabs}$text","\n";
 }
  
}

=head1 
NAME
 err
CALLING
 use Error;
 void $self->err( $package, $line, $hashref);
KEYWORDS
 error diagnostics dump
CONTAINED
 $PERL5LIB/lib/Error.pm
DESCRIPTION
   this routine is designed to alert of dbi and non-dbi errors by logical or'ing a perl statement 

=cut
sub err {
my $self       = shift;
my $package    = shift;
my $line       = shift;
my $hashref    = shift;
my $errstr     = $$hashref{errstr};
my $errno      = $$hashref{errno} ? $$hashref{errno} : '0';
my $force_exit = $$hashref{force_exit};
my $force_dump = $$hashref{force_dump};

# in certain circumstances err can be called when there is no error
# but because a statement returned 0 or false, it is interpeted as
# an error 

return if ( $errno eq '0' );
print "err [package{".$package.'}], '."[line{".$line.'}], ' .  "[error#{".$errno.'}], ' .  "[error string{".$errstr.'}]', "\n\n";

# print stack trace
my $i = 1;
print "Stack Trace:\n";
while ( (my @call_details = (caller($i++))) ){
    print $call_details[1].":".$call_details[2]." in function ".$call_details[3]."\n";
}
print "\n";

exit(0) if $force_exit;
   
}

1;
