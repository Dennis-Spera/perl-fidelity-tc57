#!/usr/bin/perl
use lib '/home/administrator/Desktop/tb/module_release';
use TC57;
use Data::Dumper;

#--------------------------------------------------------------------------
#  Methods:
#
#   $data_ref = $object->_attach_tc57('tbb.ACQ.OUT.TC57.200629.110834');    
#
#   $object->_display_ua('dc_base2.des');
#
#   $object->_display_records(1);
#
#   $object->_display_entities('MSG BASEII_TC57_5_MCC',1); # not implemented yet return get_template
#
#   $object->_get_entity($record, 'MSG BASEII_TC57_5_MCC', 'recordType')
#
#   $object->_get_raw() # not implemented yet return get_template
#
#
#--------------------------------------------------------------------------

my $object = new TC57();
my $data_ref = $object->_attach_tc57('tbb.ACQ.OUT.TC57.200629.110834');

$object->_load_ua('dc_base2.des');

my @types = $object->_display_records(1);

#print Dumper $object->_display_records(1);
#$object->display_template('BASEII_TC57_5_MCC');

for my $record (@$data_ref) {

    if (( $object->_get_entity($record, 'MSG BASEII_TC57_5_MCC', 'recordType') eq '2' )  and 
        ( $object->_get_entity($record, 'MSG BASEII_TC57_5_MCC', 'transCompntSeqNbr') eq '5' )) 
    {
        if ( $object->_get_entity($record, 'MSG BASEII_TC57_5_MCC', 'POSServiceDataDE22') eq '000441895000') {
           print $object->_get_entity($record, 'MSG BASEII_TC57_5_MCC', 'authorizationAmt'),"\n";
        }

    }
}

