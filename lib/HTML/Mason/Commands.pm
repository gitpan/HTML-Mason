# Copyright (c) 1998 by Jonathan Swartz. All rights reserved.
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

package HTML::Mason::Commands;

use strict;
use Date::Manip;
use File::Basename;
use HTML::Mason::Utils;
use HTML::Mason::Tools qw(read_file chop_slash);
use HTML::Mason::Config;
use IO;
use URI::Escape;

use vars qw($INTERP);

#
# Convert relative paths to absolute, handle . and ..
#
my $process_comp_path = sub {
    my ($compPath) = @_;
    if ($compPath !~ m@^/@) {
	$compPath = chop_slash($INTERP->locals->{parentPath}) . "/" . $compPath;
    }
    while ($compPath =~ s@/[^/]+/\.\.@@) {}
    while ($compPath =~ s@/\./@/@) {}
    return $compPath;
};

#
# Construct a CGI-style option string from a hash.
#
my $construct_option_string = sub {
    my (%options) = @_;
    my ($key,$value,$ostr);
    return '' if (!%options);
    while (($key,$value) = each(%options)) {
	if (!ref($value)) {
	    $ostr .= "$key=".uri_escape($value)."&";
	} elsif (ref($value) eq 'ARRAY') {
	    foreach (@$value) {
		$ostr .= "$key=".uri_escape($_)."&";
	    }
	} elsif (ref($value) eq 'HASH') {
	    my %h = %$value;
	    foreach (keys(%h)) {
		$ostr .= "$key=".uri_escape($_)."&$key=".uri_escape($h{$_})."&";
	    }
	} else {
	    die "cannot pass ".ref($value)." reference in option string\n";
	}
    }
    chop($ostr);
    return $ostr;
};

sub mc_abort
{
    $INTERP->{exec_state}->{abort_flag} = 1;
    $INTERP->{exec_state}->{abort_retval} = $_[0];
    die "aborted";
}

sub mc_cache
{
    my (%options) = @_;
    return undef if !$INTERP->use_data_cache;
    $options{cache_file} = $INTERP->data_cache_filename($INTERP->locals->{truePath});
    if ($options{keep_in_memory}) {
	$options{memory_cache} = $INTERP->{data_cache_store};
	delete($options{keep_in_memory});
    }
   
    $options{action} = $options{action} || 'retrieve';
    $options{key} = $options{key} || 'main';
	my $results = HTML::Mason::Utils::access_data_cache(%options);
	if ($options{action} eq 'retrieve') {
		$INTERP->write_system_log('CACHE_READ',$options{key},
		defined $results ? 1 : 0);
	}
    return $results;
}

sub mc_cache_self
{
    my (%options) = @_;
    
    return 0 if !$INTERP->use_data_cache;
    return 0 if $INTERP->locals->{inCacheSelfFlag};
    my (%retrieveOptions,%storeOptions);
    foreach (qw(key expire_if keep_in_memory)) {
	if (exists($options{$_})) {
	    $retrieveOptions{$_} = $options{$_};
	}
    }
    foreach (qw(key expire_at expire_next expire_in)) {
	if (exists($options{$_})) {
	    $storeOptions{$_} = $options{$_};
	}
    }
    my $result = mc_cache(action=>'retrieve',%retrieveOptions);
    if (!defined($result)) {
	#
	# Reinvoke the component with inCacheSelfFlag=1 and collect
	# output in $result.
	#
	my $lref = $INTERP->{stack}->[0];
	my %saveLocals = %$lref;
	$lref->{sink} = sub { $result .= $_[0] };
	$lref->{inCacheSelfFlag} = 1;
	my $sub = $lref->{callFunc};
	my %args = %{$lref->{callArgs}};
	&$sub(%args);
	$INTERP->{stack}->[0] = {%saveLocals};
	mc_cache(action=>'store',value=>$result,%storeOptions);
    } else {
	#
	# Hack! http header is technically a side-effect, so we must
	# call it explicitly.
	#
	$INTERP->call_hooks(name=>'http_header') if ($INTERP->depth==1);
    }
    mc_out($result);
    return 1;
}

sub mc_caller ()
{
    if ($INTERP->depth <= 1) {
	return undef;
    } else {
	return $INTERP->{stack}->[1]->{truePath};
    }
}

sub mc_call_stack ()
{
    return map($_->{truePath},@{$INTERP->{stack}});
}

sub mc_comp
{
    my ($compPath, %args) = @_;

    $compPath = &$process_comp_path($compPath);
    my ($result,@result);
    if (wantarray) {
	@result = $INTERP->exec_next($compPath, %args);
    } else {
	$result = $INTERP->exec_next($compPath, %args);
    }
    return wantarray ? @result : $result;
}

sub mc_comp_exists
{
    my ($compPath, %args) = @_;

    $compPath = &$process_comp_path($compPath);
    return 1 if ($INTERP->load($compPath));
    if ($args{ALLOW_HANDLERS}) {
	# This hack implements the ALLOW_HANDLERS flag for
	# backward compatibility with Scribe.  Looks for home and
	# dhandler files when component not found.  Hopefully can
	# remove someday soon.
	my $p = $compPath;
	return 1 if $INTERP->load("$p/home");
	while (!$INTERP->load("$p/dhandler") && $p =~ /\S/) {
	    my ($basename,$dirname) = fileparse($p);
	    $p = substr($dirname,0,-1);
	}
	return 1 if $p =~ /\S/;
    }
    return 0;
}

sub mc_comp_source
{
    my ($compPath) = @_;
    
    $compPath = &$process_comp_path($compPath);
    return $INTERP->comp_root.$compPath;
}

#
# Version of DateManip::UnixDate that uses interpreter's notion
# of current time and caches daily results.
#
sub mc_date ($)
{
    my ($format) = @_;

    my $time = $INTERP->current_time();
    if ($format =~ /%[^yYmfbhBUWjdevaAwEDxQF]/ || $time ne 'real' || !defined($INTERP->data_cache_dir)) {
	$time = 'now' if $time eq 'real';
	return UnixDate($time,$format);
    } else {
	my %cacheOptions = (cache_file=>($INTERP->data_cache_filename('_global')),key=>'mc_date_formats',memory_cache=>($INTERP->{data_cache_store}));
	my $href = HTML::Mason::Utils::access_data_cache(%cacheOptions);
	if (!$href) {
	    my %dateFormats;
	    my @formatChars = qw(y Y m f b h B U W j d e v a A w E D x Q F);
	    my @formatVals = split("\cA",UnixDate('now',join("\cA",map("%$_",@formatChars))));
	    my $i;
	    for ($i=0; $i<@formatChars; $i++) {
		$dateFormats{$formatChars[$i]} = $formatVals[$i];
	    }
	    $href = {%dateFormats};
	    HTML::Mason::Utils::access_data_cache(%cacheOptions,action=>'store',value=>$href,expire_next=>'day');
	}
	$format =~ s/%(.)/$href->{$1}/g;
	return $format;
    }
}

sub mc_file ($)
{
    my ($file) = @_;
    if (substr($file,0,1) ne '/') {
	$file = $INTERP->static_file_root . "/" . $file;
    }
    $INTERP->call_hooks(type=>'start_file',params=>[$file]);
    my $content = read_file($file);
    $INTERP->call_hooks(type=>'end_file',params=>[$file]);
    return $content;
}

sub mc_file_root ()
{
    return $INTERP->static_file_root;
}

sub mc_form_hidden (%)
{
    my (%args) = @_;
    my $hidden = '<input type="hidden" name="%s" value="%s">'."\n";
    my $fstr;
    while (my ($key,$value) = each(%args)) {
	if (!ref($value)) {
	    $fstr .= sprintf($hidden,$key,$value);
	} elsif (ref($value) eq 'ARRAY') {
	    foreach (@$value) {
		$fstr .= sprintf($hidden,$key,$_);
	    }
	} elsif (ref($value) eq 'HASH') {
	    my %h = %$value;
	    foreach (keys(%h)) {
		$fstr .= sprintf($hidden,$key,$_);
		$fstr .= sprintf($hidden,$key,$h{$_});
	    }
	} else {
	    die "mc_hidden_inputs: cannot pass ".ref($value)." reference in option string\n";
	}
    }
    return $fstr;
}

sub mc_hlink ($%)
{
    my ($url, %options) = @_;
    my $ostr = &$construct_option_string(%options);
    return $ostr ? "$url?$ostr" : $url;
}

sub mc_out ($)
{
    $INTERP->locals->{sink}->($_[0]);
}

sub mc_pack
{
    my ($type,@args) = @_;
    die "mc_pack: unknown thunk type '$type'\n" if ($type !~ /(text|file|comp|code)$/);
    die "mc_pack: not enough arguments\n" if !@args;
    return [$type,@args];
}

sub mc_suppress_hooks ($)
{
    foreach my $hookname (@_) {
	$INTERP->suppress_hooks(name=>$hookname);
    }
}

sub mc_time
{
    my $time = $INTERP->current_time;
    $time = time() if $time eq 'real';
    return $time;
}

sub mc_unpack
{
    my ($thunk) = @_;
    die "mc_unpack: not a proper thunk\n" if (ref($thunk) ne 'ARRAY');
    my ($type,@args) = @$thunk;
    die "mc_unpack: not enough data in thunk\n" if !defined(@args);
    if ($type eq 'text') {
	return $args[0];
    } elsif ($type eq 'file') {
	return mc_file($args[0]);
    } elsif ($type eq 'comp') {
	return mc_comp(@args);
    } elsif ($type eq 'code') {
	my $sub = $args[0];
	die "mc_unpack: argument for code type is not a code reference\n" if ref($sub) ne 'CODE';
	return &$sub();
    } else {
	die "mc_unpack: unknown thunk type '$type'\n";
    }
}

sub mc_var ($)
{
    my ($field) = @_;
    return $INTERP->{vars}->{$field};
}
1;

__END__
