#!/usr/bin/env tclsh8.5
#-----------------------------------------------------------
#
#  tclunit_xml
#
# Tclunit_XML is using the refactored and extend tclunit package
# to run testsuites or parse test logs and create jUnit compatible
# XML reports from it.
#
#  Matthias Kraft
#  June 19, 2012
#
#-----------------------------------------------------------
# XML converter for tclunit

append auto_path " /home/andym/git/tclunit"
package require tclunit 1.1
#source /home/andym/git/tclunit/tclunit/tclunit.tcl

namespace eval tclunit_xml {
    variable openedTags {} ;# list of tags to close
    variable suitename ""
}

proc tclunit_xml::escape_xml {text} {
    string map {& &amp; < &lt; > &gt; \" &quot;} $text
}

proc tclunit_xml::new_testsuite {filename} {
    variable openedTags
    variable suitename

    set suitename [get_module [lindex [split [file rootname [file tail $filename]] "."] 0]]

    close_tags

    puts [format {<testsuite name="%s">} $suitename]
    lappend openedTags testsuite
}

proc tclunit_xml::close_tags {} {
    variable openedTags

    foreach tag [lreverse $openedTags] {
	puts [format {</%s>} $tag]
    }

    set openedTags {}
}

proc tclunit_xml::testcase_skipped {filename testcase reason} {
    variable suitename
    puts [format {<testcase name="%s:%s" classname="%s">} \
	$suitename $testcase $suitename]
    puts [format {<skipped type="CASE_SKIPPED">%s</skipped>} [escape_xml $reason]]
    puts "</testcase>"
}

proc tclunit_xml::testcase_passed {filename testcase report {time 0}} {
    variable suitename

    puts [format {<testcase name="%s:%s" classname="%s" time="%s">} \
	$suitename $testcase $suitename $time]
    puts [format {<passed type="CASE_PASSED">%s</passed>} [escape_xml $report]]
    puts "</testcase>"
}

proc tclunit_xml::testcase_start {filename testcase {time 0}} {
    variable suitename
    puts [format {<testcase name="%s:%s" classname="%s"/>} \
    $suitename $testcase $suitename]
}

proc tclunit_xml::testcase_failed {filename testcase report {time 0}} {
    variable suitename
    puts [format {<testcase name="%s:%s" classname="%s" time="%s">} \
	$suitename $testcase $suitename $time]
    puts [format {<failure type="CASE_FAILED" message="%s FAILED">%s</failure>} \
	$testcase [escape_xml $report]]
    puts "</testcase>"
}

proc tclunit_xml::property {name value} {
    variable openedTags

    if {[lindex $openedTags end] ne "properties"} {
	puts "<properties>"
	lappend openedTags properties
    }
    puts [format {<property name="%s" value="%s"/>} [escape_xml $name] [escape_xml $value]]
}

proc tclunit_xml::log { value } {
    puts ">>>>>>>>>>>>> $value"
}

proc tclunit_xml::get_module { value } {
    set module(2) "VLAN"
    set module(11) "MVR"
    set module(13) "ARPInspec"
    set module(7) "LLDP"

    if {![info exists module($value)]} {
        set ret "module $value" 
    } else {
        set ret $module($value)
    }
}

proc tclunit_xml::main {args} {
    tclunit::configure \
	event init [namespace code close_tags] \
	event suite [namespace code new_testsuite] \
	event skipped [namespace code testcase_skipped] \
	event passed [namespace code testcase_passed] \
	event failed [namespace code testcase_failed] \
	event property [namespace code property] \
    event log [namespace code log]

    puts "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>"
    puts "<testsuites>"
    foreach path $args {
	tclunit::run_tests $path
    
    }
    close_tags
    puts "</testsuites>"
}

if {[info exists argv]} {
    tclunit_xml::main {*}$argv
}