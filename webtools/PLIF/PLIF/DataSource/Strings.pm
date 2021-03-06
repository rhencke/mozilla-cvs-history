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

package PLIF::DataSource::Strings;
use strict;
use vars qw(@ISA);
use PLIF::DataSource;
use PLIF::Exception;
@ISA = qw(PLIF::DataSource);
1;

sub provides {
    my $class = shift;
    my($service) = @_;
    # XXX this class should provide a 'clear caches' service (as should some others)
    return ($service eq 'dataSource.strings.customised' or
            $service eq 'setup.events.start' or
            $service eq 'setup.events.end' or
            $service eq 'setup.install' or
            $service eq 'dispatcher.output.generic' or
            $service eq 'dispatcher.output' or
            $service eq 'dataSource.strings.default' or
            $class->SUPER::provides($service));
}

sub databaseName {
    return 'default';
}

__DATA__

sub init {
    my $self = shift;
    $self->SUPER::init(@_);
    $self->{loadedNegotiationEngine} = 0;
    $self->{variantsCache} = {};
    $self->{stringsCache} = {};
    $self->{enabled} = 1;
}

# returns ($type, $version, $string)
sub getCustomisedString {
    my $self = shift;
    my($args) = @_;
    # error handling makes code ugly :-)
    if ($self->{enabled}) {
        my $variant;
        if (defined($args->{'session'})) {
            $variant = $args->{'session'}->selectVariant($args->{'protocol'});
        }
        if (not defined($variant)) {
            # default session or $args->{'session'} didn't care, get stuff from
            # $args->{'app'}->input instead
            $variant = $self->selectVariant($args->{'app'}, $args->{'protocol'});
        }
        if (not defined($self->{stringsCache}->{$variant})) {
            $self->{stringsCache}->{$variant} = {};
        }
        if (not defined($self->{stringsCache}->{$variant}->{$args->{'name'}})) {
            my @results;
            try {
                @results = $self->getString($args->{'app'}, $variant, $args->{'name'});
            } except {
                # ok, so, er, it seems that didn't go to well
                # XXX do we want to do an error here or something?
                $self->warn(4, "While I was looking for the string '$args->{'name'}' in protocol '$args->{'protocol'}' using variant '$variant', I failed with: @_");
            };
            if (@results) {
                $self->{stringsCache}->{$variant}->{$args->{'name'}} = \@results;
                ($args->{'type'}, $args->{'version'}, $args->{'string'}) = @results;
                return 1;
            } else {
                return;
            }
        } else {
            ($args->{'type'}, $args->{'version'}, $args->{'string'}) = @{$self->{stringsCache}->{$variant}->{$args->{'name'}}};
            return 1;
        }
    } else {
        $self->dump(9, "String datasource is disabled, skipping");
        return;
    }
}

sub selectVariant {
    my $self = shift;
    my($app, $protocol) = @_;
    my $choice;
    # Find list of options from DB.
    my $variants = $self->variants($app, $protocol);
    if (scalar(@$variants) > 0) {
        if (!$self->{loadedNegotiationEngine}) {
            require HTTP::Negotiate; import HTTP::Negotiate; # DEPENDENCY
            require HTTP::Headers; import HTTP::Headers; # DEPENDENCY
            $self->{loadedNegotiationEngine} = 1;
        }
        # Initialize the fake header
        my $request = new HTTP::Headers;
        foreach my $header (['Accept', $self->acceptType($app, $protocol)],
                            ['Accept-Encoding', $self->acceptEncoding($app, $protocol)],
                            ['Accept-Charset', $self->acceptCharset($app, $protocol)],
                            ['Accept-Language', $self->acceptLanguage($app, $protocol)]) {
            # only add headers that exist -- HTTP::Negotiate isn't very bullet-proof :-)
            if ($header->[1]) { # check if the header exists
                $request->header(@$header); # if so, add it to the headers object
            }
        }
        # Do Content Negotiation :-D
        # $HTTP::Negotiate::DEBUG = 1; # enable debugging
        $choice = choose($variants, $request);
    }
    if (not defined($choice)) {
        $choice = 0; # XXX we could maybe not hard code the default variant some how...
    }
    return $choice;
}

# Variants returns an arrayref or arrayrefs, typically to be passed to
# HTTP::Negotiate, containing:
#    variant id, quality, content type, encoding, character set,
#    language, size
# Note that we don't support 'size', since doing so would require the
# unbelivably slow operation of calculating the length of the every
# possible string for everyone. No thanks. ;-)
sub variants {
    my $self = shift;
    my($app, $protocol) = @_;
    if (not defined($self->{variantsCache}->{$protocol})) {
        try {
            $self->{variantsCache}->{$protocol} = $self->getVariants($app, $protocol);
        } except {
            # ok, so, er, it seems that didn't go to well
            # XXX do we want to do an error here or something?
            $self->warn(4, "While I was looking for the variants, I failed with: @_");
            $self->{variantsCache}->{$protocol} = []; # no variants here, no sir!
        };
    }
    return $self->{variantsCache}->{$protocol};
}

# setup.events.start
sub setupStarting {
    my $self = shift;
    my($app) = @_;
    $self->{enabled} = 0;
}

# setup.events.end
sub setupEnding {
    my $self = shift;
    my($app) = @_;
    $self->{enabled} = 1;
}

# setup.install
sub setupInstall {
    my $self = shift;
    my($app) = @_;
    my $oldStrings = [];
    # get all strings (variant id, variant name, variant protocol, string name, string version)
    $app->output->setupProgress('strings.versionCheck');
    my $strings = $self->getAllStringVersions($app); # arrayref of arrayrefs
    foreach my $string (@$strings) {
        # get version of default for $string->name in $string->protocol
        my($variantID, $variantName, $variantProtocol, $stringName, $stringVersion) = @$string;
        my($defaultStringType, $defaultStringVersion, $defaultStringData) = $app->getSelectingService('dataSource.strings.default')->getDefaultString({
            'app' => $app,
            'protocol' => $variantProtocol,
            'name' => $stringName,
        });
        # if version < default string's version
        if ($stringVersion < $defaultStringVersion) {
            # XXX this is a numeric comparison because I am assuming
            # that versions are simply integers. There is no reason
            # this should actually be the case, so we may wish to
            # implement a service for comparing versions and then use
            # that here.
            push(@$oldStrings, [@$string, $defaultStringVersion]);
        }
    }
    if (scalar(@$oldStrings) > 0) {
        # output array
        $app->output->setupNewStringReport($oldStrings);
    }
    return;
}

# dispatcher.output.generic (used by the setupInstall method above
# assuming you are using a generic output system)
sub outputSetupNewStringReport {
    my $self = shift;
    my($app, $output, $oldStrings) = @_;
    $output->output('setup.newStringReport', {
        'oldStrings' => $oldStrings,
    });
}

# dispatcher.output
sub strings {
    return (
            'setup.newStringsReport' => 'If some of the strings that are customised in this local installation have had their defaults changed, then this output will be triggered in addition to the various setup.progress calls and so on. It has one entry in the data hash. oldStrings, which is an array of arrays containing the variant id, the variant name, the variant protocol, the string name, the string version number, and the new version number of the default string. Details about exactly what changed should be found in the documentation.',
            );
}

# dataSource.strings.default
sub getDefaultString {
    my $self = shift;
    my($args) = @_;
    if ($args->{'protocol'} eq 'stdout') {
        if ($args->{'name'} eq 'setup.newStringsReport') {
            $args->{'type'} = 'COSES';
            $args->{'version'} = 1;
            $args->{'string'} = '<text>Note: The following strings have had their defaults updated since you last customised them:<br/><set variable="string" value="(oldStrings)" source="values" order="lexical"><text value="string (string.3) in variant (string.1)"/> (<text value="protocol (string.2)"/>): yours=<text value="(string.4)"/>, new=<text value="(string.5)"/><br/></set></text>';
            return 1;
        }
    }
    return; # nope, sorry
}


# Get the relevant headers from the input service:

sub acceptType {
    my $self = shift;
    my($app, $protocol) = @_;
    return $app->input->getMetaData('acceptType');
}

sub acceptEncoding {
    my $self = shift;
    my($app, $protocol) = @_;
    return $app->input->getMetaData('acceptEncoding');
}

sub acceptCharset {
    my $self = shift;
    my($app, $protocol) = @_;
    return $app->input->getMetaData('acceptCharset');
}

sub acceptLanguage {
    my $self = shift;
    my($app, $protocol) = @_;
    return $app->input->getMetaData('acceptLanguage');
}


# "Low Level" API

sub getString {
    my $self = shift;
    # my($app, $variant, $string) = @_;
    $self->notImplemented();
    # return type, version, data
}

sub getVariants {
    my $self = shift;
    # my($app, $protocol) = @_;
    $self->notImplemented();
    # return id, quality, type, encoding, charset, language
}

sub getVariant {
    my $self = shift;
    # my($app, $id) = @_;
    $self->notImplemented();
    # return name, protocol, quality, type, encoding, charset, language, description, translator
}

sub getVariantStrings {
    my $self = shift;
    # my($app, $variant) = @_;
    $self->notImplemented();
    # return ( string => [ type, version, data ] )*;
}

sub getStringVariants {
    my $self = shift;
    # my($app, $string) = @_;
    $self->notImplemented();
    # return ( variant => [ type, version, data ] )*;
}

sub getDescribedVariants {
    my $self = shift;
    # my($app) = @_;
    $self->notImplemented();
    # return { id => { name, protocol, quality, type, encoding, charset, language, description, translator } }*
}

sub getAllStringVersions {
    my $self = shift;
    # my($app) = @_;
    $self->notImplemented();
    # return ( variant id, variant name, variant protocol, string id, string name, string version )*
}

# an undefined $id means "add me please"
sub setVariant {
    my $self = shift;
    # my($app, $id, $name, $protocol, $quality, $type, $encoding, $charset, $language, $description, $translator) = @_;
    $self->notImplemented();
}

sub setString {
    my $self = shift;
    # my($app, $variant, $string, $type, $version, $data) = @_;
    # if $data = '' then delete the relevant string from the database
    $self->notImplemented();
}
