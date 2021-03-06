# -*- Mode: perl; tab-width: 4; indent-tabs-mode: nil; -*-
#
# This file is MPL/GPL dual-licensed under the following terms:
#
# The contents of this file are subject to the Mozilla Public License
# Version 1.1 (the "License"); you may not use this file except in
# compliance with the License. You may obtain a copy of the License at
# http://www.mozilla.org/MPL/
#
# Software distributed under the License is distributed on an "AS IS"
# basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See
# the License for the specific language governing rights and
# limitations under the License.
#
# The Original Code is PLIF 1.0.
# The Initial Developer of the Original Code is Ian Hickson.
#
# Alternatively, the contents of this file may be used under the terms
# of the GNU General Public License Version 2 or later (the "GPL"), in
# which case the provisions of the GPL are applicable instead of those
# above. If you wish to allow use of your version of this file only
# under the terms of the GPL and not to allow others to use your
# version of this file under the MPL, indicate your decision by
# deleting the provisions above and replace them with the notice and
# other provisions required by the GPL. If you do not delete the
# provisions above, a recipient may use your version of this file
# under either the MPL or the GPL.

package PLIF::Service::TemplateToolkit;
use strict;
use vars qw(@ISA %CACHE);
use PLIF::Service;
use PLIF::Exception;
@ISA = qw(PLIF::Service);
%CACHE = ();
1;

sub provides {
    my $class = shift;
    my($service) = @_;
    return ($service eq 'string.expander.TemplateToolkit' or
            $service eq 'string.expander.TemplateToolkitCompiled' or
            $class->SUPER::provides($service));
}

__DATA__

sub init {
    my $self = shift;
    my($app) = @_;
    $self->SUPER::init(@_);
    require Template; import Template; # DEPENDENCY
    eval {
        package PLIF::Service::TemplateToolkit::Context;
        require Template::Context; import Template::Context; # DEPENDENCY
        require POSIX; import POSIX qw(strftime); # DEPENDENCY
    };
    local $Template::Config::STASH = 'Template::Stash::Context'; # Don't use Template::Stash::XS as we can't currently get a hash back out of it
    $self->{template} = Template->new({
        'CONTEXT' => PLIF::Service::TemplateToolkit::Context->new($app),
        'AUTO_RESET' => 0, # don't clear BLKSTACK between templates [1]
    });
    # [1] this shouldn't cause any problems assuming every template
    # leave()s the context correctly. We need it because we currently
    # treat each inclusion as effectively a totally new template, but
    # we want to do that without losing [%BLOCK%]s.
}

sub expand {
    my $self = shift;
    my($args) = @_;
    my $document;
    if (exists $CACHE{$args->{'name'}}) {
        $document = $CACHE{$args->{'name'}};
    } else {
        if ($args->{'type'} eq 'TemplateToolkitCompiled') {
            # what we have here is a potential Template::Document
            # let's try to evaluate it
            $document = eval $args->{'string'};
            if ($@) {
                $self->error(1, "Error loading compiled template: $@");
            }
            $CACHE{$args->{'name'}} = $document;
        } else { # $type eq 'TemplateToolkit'
            # what we have is a raw string
            $document = \$args->{'string'};
        }
    }
    # $self->{template}->context()->{'__PLIF__output'} = $args->{'output'}; # unused (it's a handle to the dataSource.strings service but we look one up instead of using it directly)
    $self->{template}->context()->{'__PLIF__session'} = $args->{'session'};
    $self->{template}->context()->{'__PLIF__protocol'} = $args->{'protocol'};
    $self->{template}->context()->{'__PLIF__app'} = $args->{'app'};
    $self->{template}->context()->{'__PLIF__app_refcount'}++;
    # ok, let's try to process it
    my $output = '';
    my $result = try {
        $self->{template}->process($document, $args->{'data'}, \$output);
    } finally {
        # prevent circular dependency
        if ($self->{template}->context()->{'__PLIF__app_refcount'}-- <= 0) {
            $self->{template}->context()->{'__PLIF__app'} = undef;
        }
    };
    # and now check for errors
    if (not $result) {
        my $exception = $self->{template}->error();
        if ($exception->isa('PLIF::Service::TemplateToolkit::Exception')) {
            $exception->PLIFException()->raise;
        } else {
            $self->error(1, "Error processing template: $exception");
        }
    }
    $args->{'string'} = $output;
}


package PLIF::Service::TemplateToolkit::Exception;
use strict;
use vars qw(@ISA);
@ISA = qw(Template::Exception);
1;

sub new {
    my $class = shift;
    my($PLIFException, $type, $info, $textref) = @_;
    bless [ $type, $info, $textref, $PLIFException ], $class;
}

sub PLIFException { $_[0]->[3]; }


package PLIF::Service::TemplateToolkit::Context;
use strict;
use vars qw(@ISA $URI_ESCAPES);
@ISA = qw(Template::Context);
1;

# subclass the real Context so that we go through PLIF for everything
sub new {
    my $class = shift;
    my($app) = @_;
    my $self = $class->SUPER::new({
        'FILTERS' => {
            'htmlcomment' => \&html_comment_filter, # for use in an html comment
            'xmlcomment' => \&xml_comment_filter, # for use in an xml comment
            'xml' => \&xml_filter, # for use in xml
            'cdata' => \&cdata_filter, # for use in an xml CDATA block
            'htmljs' => \&html_js_filter, # for use in strings in JS in HTML <script> blocks
            'js' => \&js_filter, # for use in strings in JS
            'css' => \&css_filter, # for use in strings in CSS
            'acronymise' => \&acronymise_filter, # convert strings into acryonyms (e.g. "Internet Explorer" to "IE")
            'substr' => [\&substr_filter_factory, 1], # substring function
            'uri' => \&uri_light_filter, # ensuring a theoretically valid URI
            'uriparameter' => \&uri_heavy_filter, # for use in embedding strings into a URI
            'padleft' => [\&pad_left_filter_factory, 1], # space padding string function
            'padright' => [\&pad_right_filter_factory, 1], # space padding string function
            'indentlines' => [\&indent_lines_filter_factory, 1], # different indents on different lines
        }
    });
    return $self;
}

# throw an exception, preserving PLIF exceptions
sub throw {
    my $self = shift;
    my($error, $info, $output) = @_;
    if (UNIVERSAL::isa($info, 'PLIF::Exception')) {
	die PLIF::Service::TemplateToolkit::Exception->new($info, $error, $info, $output);
    } else {
        $self->SUPER::throw($error, $info, $output);
    }
}

# catch an exception, preserving PLIF exceptions
sub catch {
    my $self = shift;
    my($error, $output) = @_;
    if (UNIVERSAL::isa($error, 'PLIF::Exception')) {
	return PLIF::Service::TemplateToolkit::Exception->new($error, 'PLIF', $error, $output);
    } else {
        $self->SUPER::catch($error, $output);
    }
}

# compile a template
sub template {
    my $self = shift;
    my($text) = @_;
    $self->{'__PLIF__app'}->assert(ref($text), 1, 'Internal error: tried to compile a template by name instead of going through normal channels (security risk)');
    return $self->SUPER::template(@_);
}

# insert another template
sub process {
    my $self = shift;
    my($strings, $params) = @_;

    # support multiple files for compatability with Template::Context->process()
    if (ref($strings) ne 'ARRAY') {
        $strings = [$strings];
    }

    # get data source
    my $app = $self->{'__PLIF__app'};
    my $session = $self->{'__PLIF__session'};
    my $protocol = $self->{'__PLIF__protocol'};
    my $dataSource = $self->{'__PLIF__app'}->getService('dataSource.strings');

    # expand strings and append
    my $result = '';
    string: foreach my $string (@$strings) {
        if (ref($string)) {
            # probably already compiled
            $result .= $self->SUPER::process($string, $params);
        } else {
            # iterate through the BLKSTACK list to see if any of the
            # Template::Documents we're visiting define this BLOCK
            foreach my $blocks (@{$self->{'BLKSTACK'}}) {
                if (defined($blocks)) {
                    my $template = $blocks->{$string};
                    if (defined($template)) {
                        if (ref $template eq 'CODE') {
                            $result .= &$template($self);
                        } elsif (ref $template) {
                            $result .= $template->process($self);
                        } else {
                            $self->throw('file', "invalid template reference: $template");
                        }
                        # ok, jump to next string
                        next string;
                    }
                }
            }
            # ok, it's not a defined block, do our own thing with it
            my $args = {
                'app' => $app,
                'session' => $session,
                'protocol' => $protocol,
                'name' => $string,
                'data' => $self->{'STASH'},
            };
            $dataSource->getExpandedString($args);
            $result .= $args->{'string'};
        }
    }

    return $result;
}

# insert another template but protecting the stash
sub include {
    my $self = shift;
    my($strings, $params) = @_;

    # localise the variable stash with any parameters passed
    my $stash = $self->{'STASH'};
    $self->{'STASH'} = $self->{'STASH'}->clone($params);

    # defer to process(), above
    my $result = eval { $self->process($strings, $params); };
    my $error = $@;

    # delocalise the variable stash
    $self->{'STASH'} = $self->{'STASH'}->declone();

    # propagate any error
    if (ref($error) or ($error ne '')) {
        die $error;
    }

    return $result;
}

# insert a string regardless of what it is without expanding it
sub insert {
    my $self = shift;
    my($strings) = @_;

    # support multiple files for compatability with Template::Context->insert()
    if (ref($strings) ne 'ARRAY') {
        $strings = [$strings];
    }

    # get data source
    my $app = $self->{'__PLIF__app'};
    my $session = $self->{'__PLIF__session'};
    my $protocol = $self->{'__PLIF__protocol'};
    my $dataSource = $self->{'__PLIF__app'}->getService('dataSource.strings');

    # concatenate the files
    my $result = '';
    foreach my $string (@$strings) {
        my($type, $version, $data) = $dataSource->getString($app, $session, $protocol, $string);
        $result .= $data;
    }

    return $result;
}


# FILTERS
# (are these right? XXX)

sub html_comment_filter {
    my $text = shift;
    $text =~ s/--/- - /go;
    return $text;
}

sub xml_comment_filter {
    my $text = shift;
    $text =~ s/--/- - /go;
    return $text;
}

sub xml_filter {
    my $text = shift;
    $text =~ s/&/&amp;/go;
    $text =~ s/</&lt;/go;
    $text =~ s/>/&gt;/go;
    $text =~ s/"/&quot;/go;
    $text =~ s/'/&apos;/go;
    return $text;
}

sub cdata_filter {
    my $text = shift;
    $text =~ s/ ]]> / ]]> ]]&gt; <![CDATA[ /gox; # escape the special "]]>" string
    return $text;
}

sub html_js_filter {
    my $text = shift;
    $text =~ s/([\\'"])/\\$1/go; # escape backslashes and quotes
    $text =~ s/\n/\\n/go; # escape newlines
    $text =~ s| </ | <\\/ |gox; # escape the special "</" string
    return $text;
}

sub js_filter {
    my $text = shift;
    $text =~ s/([\\'"])/\\$1/go; # escape backslashes and quotes
    $text =~ s/\n/\\n/go; # escape newlines
    return $text;
}

sub css_filter {
    my $text = shift;
    $text =~ s/([\\'"])/\\$1/go; # escape backslashes and quotes
    return $text;
}

sub acronymise_filter {
    my $text = shift;
    if ($text =~ m/\w\W+\w/os) {
        # more than one word
        # remove any non-word characters and truncate each word
        # to one character
        $text =~ s/\W*(\w)\w+\W*/$1/gos;
    } else {
        # just one word, remove any non-word characters
        $text =~ s/\W//gos;
    }
    return $text;
}

#------------------------------------------------------------------------
# substr_filter_factory($i, $l)                 [% FILTER substr(i, l) %]
#
# Create a filter to return the substring of text starting at index i
# and having length l.
#------------------------------------------------------------------------
sub substr_filter_factory {
    my ($context, $index, $length) = @_;
    $index = 0 unless defined $index;
    $length = 3 unless defined $length;
    return sub {
        my $text = shift;
        return substr($text, $index, $length);
    }
}

# This was based on the equivalent function in Template::Filters,
# which was copied from URI::Escape. The changes are that I no longer
# escape the "#" character, but do escape "'", "(" and ")".
sub uri_light_filter {
    my $text = shift;    
    # construct and cache a lookup table for escapes (faster than
    # doing a sprintf() for every character in every string each time)
    $URI_ESCAPES ||= { map { (chr($_), sprintf("%%%02X", $_)) } (0..255) };
    $text =~ s/([^;\/?:@&=+\$,A-Za-z0-9\-_.!~*#])/$URI_ESCAPES->{$1}/g;
    $text;
}

# This was based on the equivalent function in Template::Filters,
# which was copied from URI::Escape. The changes are that this escapes
# almost _everything_, making it suitable for escaping text which is
# to be put into URIs, e.g. into parameters.
sub uri_heavy_filter {
    my $text = shift;    
    # construct and cache a lookup table for escapes (faster than
    # doing a sprintf() for every character in every string each time)
    $URI_ESCAPES ||= { map { (chr($_), sprintf("%%%02X", $_)) } (0..255) };
    $text =~ s/([^A-Za-z0-9_.])/$URI_ESCAPES->{$1}/g;
    $text;
}

sub pad_left_filter_factory {
    my ($context, $width1, $width2) = @_;
    return pad_filter_factory($context, $width1, $width2, '%*s');
}

sub pad_right_filter_factory {
    my ($context, $width1, $width2) = @_;
    return pad_filter_factory($context, $width1, $width2, '%-*s');
}

sub pad_filter_factory {
    my ($context, $width1, $width2, $format) = @_;
    $width1 = 0 unless defined $width1;
    $width2 = $width1 unless defined $width2;
    return sub {
        my $text = shift;
        $text = '' unless defined $text;
        my @lines = split(/\n/, $text);
        my $line1 = sprintf($format, $width1, shift @lines);
        return join("\n", $line1, map{ sprintf($format, $width2, $_) } @lines);
    }
}

sub indent_lines_filter_factory {
    my ($context, $indent1, $indent2) = @_;
    $indent1 = 0 unless defined $indent1;
    $indent2 = $indent1 unless defined $indent2;
    return sub {
        my $text = shift;
        $text = '' unless defined $text;
        my @lines = split(/\n/, $text);
        my $line1 = (' ' x $indent1) . shift @lines;
        return join("\n", $line1, map{ (' ' x $indent2) . $_ } @lines);
    }
}
