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

package PLIF::Service::GenericOutputs;
use strict;
use vars qw(@ISA);
use PLIF::Service;
@ISA = qw(PLIF::Service);
1;

sub provides {
    my $class = shift;
    my($service) = @_;
    return ($service eq 'dispatcher.output.generic' or 
            $service eq 'dispatcher.output' or 
            $service eq 'dataSource.strings.default' or
            $class->SUPER::provides($service));
}

__DATA__

# dispatcher.output.generic
sub outputAcknowledge {
    my $self = shift;
    my($app, $output) = @_;
    $output->output('acknowledge', {});
}

# dispatcher.output.generic
# this is typically used by input devices
sub outputRequest {
    my $self = shift;
    my($app, $output, $argument, @defaults) = @_;
    $output->output('request', {
        'command' => $app->command,
        'argument' => $argument,
        'defaults' => \@defaults,
    });
}

# dispatcher.output.generic
sub outputReportFatalError {
    my $self = shift;
    my($app, $output, $error) = @_;
    $output->output('error', {
        'error' => $error,
    });   
}

sub outputRedirect {
    my $self = shift;
    my($app, $output, $uri) = @_;
    $output->output('redirect', {
        'target' => $uri,
    });
}

# dispatcher.output
sub strings {
    return (
            'acknowledge' => 'A generic output merely acknowledging that something happened',
            'request' => 'A prompt for user input (only required for interactive protocols, namely stdout)',
            'error' => 'The message given to the user when something goes horribly wrong',
            'redirect' => 'Tells the user to go see something else',
            );
}

# dataSource.strings.default
sub getDefaultString {
    my $self = shift;
    my($args) = @_;
    if ($args->{'name'} eq 'error') {
        $self->dump(9, 'Looks like an error occured, because the string \'error\' is being requested');
    }
    if ($args->{'protocol'} eq 'stdout') {
        if ($args->{'name'} eq 'acknowledge') {
            $args->{'type'} = 'COSES';
            $args->{'version'} = '1';
            $args->{'string'} = '<text xmlns="http://bugzilla.mozilla.org/coses">Acknowledged.<br/></text>';
            return 1;
        } elsif ($args->{'name'} eq 'request') {
            $args->{'type'} = 'COSES';
            $args->{'version'} = '1';
            $args->{'string'} = '<text xmlns="http://bugzilla.mozilla.org/coses">\'<text value="(argument)"/>\'<if lvalue="(defaults.length)" condition=">" rvalue="0"> (default: \'<set variable="default" value="(defaults)" source="keys" order="default"><text value="(defaults.(default))"/><if lvalue="(default)" condition="!=" rvalue="0">\', \'</if></set>\')</if>? </text>';
            return 1;
        } elsif ($args->{'name'} eq 'error') {
            $args->{'type'} = 'COSES';
            $args->{'version'} = '1';
            $args->{'string'} = '<text xmlns="http://bugzilla.mozilla.org/coses">Error:<br/><text value="(error)"/><br/></text>';
            return 1;
        } 
    } elsif ($args->{'protocol'} eq 'http') {
        if ($args->{'name'} eq 'acknowledge') {
            $args->{'type'} = 'COSES';
            $args->{'version'} = '1';
            $args->{'string'} = '<text xmlns="http://bugzilla.mozilla.org/coses">Status: 200 OK<br/>Content-Type: text/plain<br/><br/>Acknowledged.</text>';
            return 1;
        } elsif ($args->{'name'} eq 'error') {
            $args->{'type'} = 'COSES';
            $args->{'version'} = '1';
            $args->{'string'} = '<text xmlns="http://bugzilla.mozilla.org/coses">Status: 500 Internal Error<br/>Content-Type: text/plain<br/><br/>Error:<br/><text value="(error)"/></text>';
            return 1;
        }
    }
    return;
}
