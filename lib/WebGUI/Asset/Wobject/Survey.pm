package WebGUI::Asset::Wobject::Survey;

#-------------------------------------------------------------------
# WebGUI is Copyright 2001-2009 Plain Black Corporation.
#-------------------------------------------------------------------
# Please read the legal notices (docs/legal.txt) and the license
# (docs/license.txt) that came with this distribution before using
# this software.
#-------------------------------------------------------------------
# http://www.plainblack.com                     info@plainblack.com
#-------------------------------------------------------------------

use strict;
use Tie::IxHash;
use JSON;
use WebGUI::International;
use WebGUI::Form::File;
use WebGUI::Utility;
use base 'WebGUI::Asset::Wobject';
use WebGUI::Asset::Wobject::Survey::SurveyJSON;
use WebGUI::Asset::Wobject::Survey::ResponseJSON;
use Params::Validate qw(:all);
Params::Validate::validation_options( on_fail => sub { WebGUI::Error::InvalidParam->throw( error => shift ) } );

#-------------------------------------------------------------------

=head2 definition ( session, [definition] )

Returns an array reference of definitions. Adds tableName, className, properties to array definition.

=head3 definition

An array of hashes to prepend to the list

=cut

sub definition {
    my $class      = shift;
    my $session    = shift;
    my $definition = shift;
    my $i18n       = WebGUI::International->new( $session, 'Asset_Survey' );
    my %properties;
    tie %properties, 'Tie::IxHash'; ## no critic
    %properties = (
        templateId => {
            fieldType    => 'template',
            defaultValue => 'PBtmpl0000000000000061',
            tab          => 'display',
            namespace    => 'Survey',
            label        => $i18n->get('survey template'),
            hoverHelp    => $i18n->get('survey template help'),
        },
        showProgress => {
            fieldType    => 'yesNo',
            defaultValue => 0,
            tab          => 'properties',
            label        => $i18n->get('Show user their progress'),
            hoverHelp    => $i18n->get('Show user their progress help'),
        },
        showTimeLimit => {
            fieldType    => 'yesNo',
            defaultValue => 0,
            tab          => 'properties',
            label        => $i18n->get('Show user their time remaining'),
            hoverHelp    => $i18n->get('Show user their time remaining'),
        },
        timeLimit => {
            fieldType    => 'integer',
            defaultValue => 0,
            tab          => 'properties',
            label        => $i18n->get('timelimit'),
            hoverHelp    => $i18n->get('timelimit hoverHelp'),
        },
        doAfterTimeLimit => {
            fieldType    => 'selectBox',
            defaultValue => 'exitUrl',
            tab          => 'properties',
            hoverHelp    => $i18n->get('do after timelimit hoverHelp'),
            label        => $i18n->get('do after timelimit label'),
            options      => {
                                'exitUrl'       => $i18n->get('exit url label'),
                                'restartSurvey' => $i18n->get('restart survey label'),
                            },
        },
        groupToEditSurvey => {
            fieldType    => 'group',
            defaultValue => 4,
            label        => $i18n->get('Group to edit survey'),
            hoverHelp    => $i18n->get('Group to edit survey help'),
        },
        groupToTakeSurvey => {
            fieldType    => 'group',
            defaultValue => 2,
            label        => $i18n->get('Group to take survey'),
            hoverHelp    => $i18n->get('Group to take survey help'),
        },
        groupToViewReports => {
            fieldType    => 'group',
            defaultValue => 4,
            label        => $i18n->get('Group to view reports'),
            hoverHelp    => $i18n->get('Group to view reports help'),
        },
        exitURL => {
            fieldType    => 'text',
            defaultValue => undef,
            label        => $i18n->get('Survey Exit URL'),
            hoverHelp    => $i18n->get('Survey Exit URL help'),
        },
        maxResponsesPerUser => {
            fieldType    => 'integer',
            defaultValue => 1,
            label        => $i18n->get('Max user responses'),
            hoverHelp    => $i18n->get('Max user responses help'),
        },
        surveySummaryTemplateId => {
            tab          => 'display',
            fieldType    => 'template',
            label        => $i18n->get('Survey Summary Template'),
            hoverHelp    => $i18n->get('Survey Summary Template help'),
            defaultValue => '7F-BuEHi7t9bPi008H8xZQ',
            namespace    => 'Survey/Summary',
        },
        surveyTakeTemplateId => {
            tab          => 'display',
            fieldType    => 'template',
            label        => $i18n->get('Take Survey Template'),
            hoverHelp    => $i18n->get('Take Survey Template help'),
            defaultValue => 'd8jMMMRddSQ7twP4l1ZSIw',
            namespace    => 'Survey/Take',
        },
        surveyQuestionsId => {
            tab          => 'display',
            fieldType    => 'template',
            label        => $i18n->get('Questions Template'),
            hoverHelp    => $i18n->get('Questions Template help'),
            defaultValue => 'CxMpE_UPauZA3p8jdrOABw',
            namespace    => 'Survey/Take',
        },
        surveyEditTemplateId => {
            tab          => 'display',
            fieldType    => 'template',
            label        => $i18n->get('Survey Edit Template'),
            hoverHelp    => $i18n->get('Survey Edit Template help'),
            defaultValue => 'GRUNFctldUgop-qRLuo_DA',
            namespace    => 'Survey/Edit',
        },
        sectionEditTemplateId => {
            tab          => 'display',
            fieldType    => 'template',
            label        => $i18n->get('Section Edit Template'),
            hoverHelp    => $i18n->get('Section Edit Template help'),
            defaultValue => '1oBRscNIcFOI-pETrCOspA',
            namespace    => 'Survey/Edit',
        },
        questionEditTemplateId => {
            tab          => 'display',
            fieldType    => 'template',
            label        => $i18n->get('Question Edit Template'),
            hoverHelp    => $i18n->get('Question Edit Template help'),
            defaultValue => 'wAc4azJViVTpo-2NYOXWvg',
            namespace    => 'Survey/Edit',
        },
        answerEditTemplateId => {
            tab          => 'display',
            fieldType    => 'template',
            label        => $i18n->get('Answer Edit Template'),
            hoverHelp    => $i18n->get('Answer Edit Template help'),
            defaultValue => 'AjhlNO3wZvN5k4i4qioWcg',
            namespace    => 'Survey/Edit',
        },
        feedbackTemplateId => {
            tab          => 'display',
            fieldType    => 'template',
            defaultValue => 'nWNVoMLrMo059mDRmfOp9g',
            label        => $i18n->get('Feedback Template'),
            hoverHelp    => $i18n->get('Feedback Template help'),
            namespace    => 'Survey/Feedback',
        },
        overviewTemplateId => {
            tab          => 'display',
            fieldType    => 'template',
            defaultValue => 'PBtmpl0000000000000063',
            label        => $i18n->get('Overview Report Template'),
            hoverHelp    => $i18n->get('Overview Report Template help'),
            namespace    => 'Survey/Overview',
        },
        gradebookTemplateId => {
            tab          => 'display',
            fieldType    => 'template',
            label        => $i18n->get('Grabebook Report Template'),
            hoverHelp    => $i18n->get('Grabebook Report Template help'),
            defaultValue => 'PBtmpl0000000000000062',
            namespace    => 'Survey/Gradebook',
        },
        testResultsTemplateId => {
            tab          => 'display',
            fieldType    => 'template',
            label        => $i18n->get('Test Results Template'),
            hoverHelp    => $i18n->get('Test Results Template help'),
            defaultValue => 'S3zpVitAmhy58CAioH359Q',
            namespace    => 'Survey/TestResults',
        },
        surveyJSON => {
            fieldType    => 'text',
            defaultValue => '',
            autoGenerate => 0,
            noFormPost  => 1, 
        },
        onSurveyEndWorkflowId => {
            tab          => 'properties',
            defaultValue => undef,
            type         => 'WebGUI::Asset::Wobject::Survey',
            fieldType    => 'workflow',
            label        => 'Survey End Workflow',
            hoverHelp    => 'Workflow to run when user completes the Survey',
            none => 1,
        },
        quizModeSummary => {
            fieldType    => 'yesNo',
            defaultValue => 0,
            tab          => 'properties',
            label        => $i18n->get('Quiz mode summaries'),
            hoverHelp    => $i18n->get('Quiz mode summaries help'),
        },
        allowBackBtn => {
            fieldType    => 'yesNo',
            defaultValue => 0,
            tab          => 'properties',
            label        => $i18n->get('Allow back button'),
            hoverHelp    => $i18n->get('Allow back button help'),
        },
    );

    push @{$definition}, {
            assetName         => $i18n->get('assetName'),
            icon              => 'survey.gif',
            autoGenerateForms => 1,
            tableName         => 'Survey',
            className         => 'WebGUI::Asset::Wobject::Survey',
            properties        => \%properties
        };

    return $class->SUPER::definition( $session, $definition );
}

#-------------------------------------------------------------------

=head2 surveyJSON_update ( )

Convenience method that delegates to L<WebGUI::Asset::Wobject::Survey::SurveyJSON/update>
and automatically calls L<"persistSurveyJSON"> afterwards.

=cut

sub surveyJSON_update {
    my $self = shift;
    my $ret = $self->surveyJSON->update(@_);
    $self->persistSurveyJSON();
    return $ret;
}

#-------------------------------------------------------------------

=head2 surveyJSON_copy ( )

Convenience method that delegates to L<WebGUI::Asset::Wobject::Survey::SurveyJSON/copy>
and automatically calls L<"persistSurveyJSON"> afterwards.

=cut

sub surveyJSON_copy {
    my $self = shift;
    my $ret =$self->surveyJSON->copy(@_);
    $self->persistSurveyJSON();
    return $ret;
}

#-------------------------------------------------------------------

=head2 surveyJSON_remove ( )

Convenience method that delegates L<WebGUI::Asset::Wobject::Survey::SurveyJSON/remove>
and automatically calls L<"persistSurveyJSON"> afterwards.

=cut

sub surveyJSON_remove {
    my $self = shift;
    my $ret = $self->surveyJSON->remove(@_);
    $self->persistSurveyJSON();
    return $ret;
}

#-------------------------------------------------------------------

=head2 surveyJSON_newObject ( )

Convenience method that delegates L<WebGUI::Asset::Wobject::Survey::SurveyJSON/newObject>
and automatically calls L<"persistSurveyJSON"> afterwards.

=cut

sub surveyJSON_newObject {
    my $self = shift;
    my $ret = $self->surveyJSON->newObject(@_);
    $self->persistSurveyJSON();
    return $ret;
}

#-------------------------------------------------------------------

=head2 recordResponses ( )

Convenience method that delegates to L<WebGUI::Asset::Wobject::Survey::ResponseJSON/recordResponses>
and automatically calls L<"persistSurveyJSON"> afterwards.

=cut

sub recordResponses {
    my $self = shift;
    my $ret = $self->responseJSON->recordResponses(@_);
    $self->persistResponseJSON();
    return $ret;
}

#-------------------------------------------------------------------

=head2 surveyJSON ( [json] )

Lazy-loading mutator for the L<WebGUI::Asset::Wobject::Survey::SurveyJSON> property.

It is stored in the database as a serialized JSON-encoded string in the surveyJSON db field.

If you access and change surveyJSON you will need to manually call L<"persistSurveyJSON"> 
to have your changes persisted to the database. 

=head3 json (optional)

A serialized JSON-encoded string representing a SurveyJSON object. If provided, 
will be used to instantiate the SurveyJSON instance rather than querying the database.

=cut

sub surveyJSON {
    my $self = shift;
    my ($json) = validate_pos(@_, { type => SCALAR, optional => 1 });
    
    if (!$self->{_surveyJSON} || $json) {

        # See if we need to load surveyJSON from the database
        if ( !defined $json ) {
            $json = $self->get("surveyJSON");
        }

        # Instantiate the SurveyJSON instance, and store it
        $self->{_surveyJSON} = WebGUI::Asset::Wobject::Survey::SurveyJSON->new( $self->session, $json );
    }
        
    return $self->{_surveyJSON};
}

#-------------------------------------------------------------------

=head2 responseJSON ( [json], [responseId] )

Lazy-loading mutator for the L<WebGUI::Asset::Wobject::Survey::ResponseJSON> property.

It is stored in the database as a serialized JSON-encoded string in the responseJSON db field.

If you access and change responseJSON you will need to manually call L<"persistResponseJSON"> 
to have your changes persisted to the database. 

=head3 json (optional)

A serialized JSON-encoded string representing a ResponseJSON object. If provided, 
will be used to instantiate the ResponseJSON instance rather than querying the database.

=head3 responseId (optional)

A responseId to use when retrieving ResponseJSON from the database (defaults to the value returned by L<"responseId">)

=cut

sub responseJSON {
    my $self = shift;
    my ($json, $responseId) = validate_pos(@_, { type => SCALAR | UNDEF, optional => 1 }, { type => SCALAR, optional => 1});
    
    if (!defined $responseId) {
        $responseId = $self->responseId;
    }
     
    if (!$self->{_responseJSON} || $json) {

        # See if we need to load responseJSON from the database
        if (!defined $json) {
            $json = $self->session->db->quickScalar( 'select responseJSON from Survey_response where assetId = ? and Survey_responseId = ?', [ $self->getId, $responseId ] );
        }

        # Instantiate the ResponseJSON instance, and store it
        $self->{_responseJSON} = WebGUI::Asset::Wobject::Survey::ResponseJSON->new( $self->surveyJSON, $json );
    }
    
    return $self->{_responseJSON};
}

=head2 getGraphFormats 

Returns the list of supported Graph formats

=cut

sub getGraphFormats {
    return qw(text ps gif jpeg png svg svgz plain);
}

=head2 getGraphLayouts

Returns the list of supported Graph layouts

=cut

sub getGraphLayouts {
    return qw(dot neato twopi circo fdp);
}

#-------------------------------------------------------------------

=head2 graph ( )

Generates a graph visualisation to survey.svg using GraphViz.

=cut

sub graph {
    my $self = shift;
    my %args = validate(@_, { format => 1, layout => 1 });
    
    my $session = $self->session;

    eval 'use GraphViz';
    if ($@) {
        return;
    }
    
    my $format = $args{format};
    if (! grep {$_ eq $format} $self->getGraphFormats) {
        $session->log->warn("Invalid format: $format");
        return;
    }
    
    my $layout = $args{layout};
    if (! grep {$_ eq $layout} $self->getGraphLayouts) {
        $session->log->warn("Invalid layout: $layout");
        return;
    }
    
    my $filename = "survey.$format";
    my $storage = WebGUI::Storage->createTemp($session);
    $storage->addFileFromScalar($filename);
    my $path = $storage->getPath($filename);

    my $FONTSIZE = 10;
    my %COLOR = (
        bg                   => 'white',
        start                => 'CornflowerBlue',
        start_fill           => 'Green',
        section              => 'CornflowerBlue',
        section_fill         => 'LightYellow',
        question             => 'CornflowerBlue',
        question_fill        => 'LightBlue',
        start_edge           => 'Green',
        fall_through_edge    => 'CornflowerBlue',
        goto_edge            => 'DarkOrange',
        goto_expression_edge => 'DarkViolet',
    );

    # Create the GraphViz object used to generate the image
    # N.B. dot gives vertical layout, neato gives purdy circular
    my $g = GraphViz->new( bgcolor => $COLOR{bg}, fontsize => $FONTSIZE, layout => $layout); # overlap => 'orthoyx'

    $g->add_node(
        'Start',
        label     => 'Start',
        fontsize  => $FONTSIZE,
        shape     => 'ellipse',
        style     => 'filled',
        color     => $COLOR{start},
        fillcolor => $COLOR{start_fill},
    );

    my $very_first = 1;

    my $add_goto_edge = sub {
        my ( $obj, $id, $taillabel ) = @_;
        return unless $obj;

        if ( my $goto = $obj->{goto} ) {
            $g->add_edge(
                $id => $goto,
                taillabel => $taillabel || 'Jump To',
                labelfontcolor => $COLOR{goto_edge},
                labelfontsize  => $FONTSIZE,
                color          => $COLOR{goto_edge},
            );
        }
    };

    my $add_goto_expression_edges = sub {
        my ( $obj, $id, $taillabel ) = @_;
        return unless $obj;
        return unless $obj->{gotoExpression};

        my $rj = 'WebGUI::Asset::Wobject::Survey::ResponseJSON';

#        for my $gotoExpression ( split /\n/, $obj->{gotoExpression} ) {
#            if ( my $processed = $rj->parseGotoExpression( $session, $gotoExpression ) ) {
#                $g->add_edge(
#                    $id            => $processed->{target},
#                    taillabel      => $taillabel ? "$taillabel: $processed->{expression}" :  $processed->{expression},
#                    labelfontcolor => $COLOR{goto_expression_edge},
#                    labelfontsize  => $FONTSIZE,
#                    color          => $COLOR{goto_expression_edge},
#                );
#            }
#        }
    };

    my @fall_through;
    my $sNum = 0;
    foreach my $s ( @{ $self->surveyJSON->sections } ) {
        $sNum++;

        my $s_id = $s->{variable} || "S$sNum";
        $g->add_node(
            $s_id,
            label     => "$s_id\n($s->{questionsPerPage} questions per page)",
            fontsize  => $FONTSIZE,
            shape     => 'ellipse',
            style     => 'filled',
            color     => $COLOR{section},
            fillcolor => $COLOR{section_fill},
        );

        # See if this is the very first node
        if ($very_first) {
            $g->add_edge(
                'Start'        => $s_id,
                taillabel      => 'Begin Survey',
                labelfontcolor => $COLOR{start_edge},
                labelfontsize  => $FONTSIZE,
                color          => $COLOR{start_edge},
            );
            $very_first = 0;
        }

        # See if there are any fall_throughs waiting
        # if so, "next" == this section
        while ( my $f = pop @fall_through ) {
            $g->add_edge(
                $f->{from}     => $s_id,
                taillabel      => $f->{taillabel},
                labelfontcolor => $COLOR{fall_through_edge},
                labelfontsize  => $FONTSIZE,
                color          => $COLOR{fall_through_edge},
            );
        }

        # Add section-level goto and gotoExpression edges
        $add_goto_edge->( $s, $s_id );
        $add_goto_expression_edges->( $s, $s_id );

        my $qNum = 0;
        foreach my $q ( @{ $s->{questions} } ) {
            $qNum++;

            my $q_id = $q->{variable} || "S$sNum-Q$qNum";

            # Link Section to first Question
            if ( $qNum == 1 ) {
                $g->add_edge( $s_id => $q_id, style => 'dotted' );
            }

            # Add Question node
            $g->add_node(
                $q_id,
                label     => $q->{required} ? "$q_id *" : $q_id,
                fontsize  => $FONTSIZE,
                shape     => 'ellipse',
                style     => 'filled',
                color     => $COLOR{question},
                fillcolor => $COLOR{question_fill},
            );

            # See if there are any fall_throughs waiting
            # if so, "next" == this question
            while ( my $f = pop @fall_through ) {
                $g->add_edge(
                    $f->{from}     => $q_id,
                    taillabel      => $f->{taillabel},
                    labelfontcolor => $COLOR{fall_through_edge},
                    labelfontsize  => $FONTSIZE,
                    color          => $COLOR{fall_through_edge},
                );
            }

            # Add question-level goto and gotoExpression edges
            $add_goto_edge->( $q, $q_id );
            $add_goto_expression_edges->( $q, $q_id );

            my $aNum = 0;
            foreach my $a ( @{ $q->{answers} } ) {
                $aNum++;

                my $a_id = $a->{text} || "S$sNum-Q$qNum-A$aNum";

                $add_goto_expression_edges->( $a, $q_id, $a_id );
                if ( $a->{goto} ) {
                    $add_goto_edge->( $a, $q_id, $a_id );
                }
                else {

                    # Link this question to next question with Answer as taillabel
                    push @fall_through,
                        {
                        from      => $q_id,
                        taillabel => $a_id,
                        };
                }
            }
        }
    }

    # Render the image to a file
    my $method = "as_$format";
    $g->$method($path);
    
    if (wantarray) {
        return ( $storage, $filename);
    } else {
        return $storage->getUrl($filename);
    }
}

#-------------------------------------------------------------------

=head2 www_editSurvey ( )

Loads the initial edit survey page. All other edit actions are ajax calls from this page.

=cut

sub www_editSurvey {
    my $self = shift;
    
    return $self->session->privilege->insufficient()
        if !$self->session->user->isInGroup( $self->get('groupToEditSurvey') );

    return $self->processTemplate( {}, $self->get('surveyEditTemplateId') );
}

sub getAdminConsole {
    my $self = shift;
    my $ac = $self->SUPER::getAdminConsole;
    my $i18n = WebGUI::International->new($self->session, "Asset_Survey");
    my $edit = WebGUI::International->new($self->session, "WebGUI")->get(575);
    $ac->addSubmenuItem($self->session->url->page("func=edit"), $edit);
    $ac->addSubmenuItem($self->session->url->page("func=editSurvey"), "$edit Survey");
    $ac->addSubmenuItem($self->session->url->page("func=graph"), $i18n->get('survey visualization'));
    $ac->addSubmenuItem($self->session->url->page("func=editTestSuite"), $i18n->get("test suite"));
    return $ac;
}

#-------------------------------------------------------------------

=head2 www_graph ( )

Visualize the Survey in the requested format and layout

=cut

sub www_graph {
    my $self = shift;
    
    my $session = $self->session;
    
    return $self->session->privilege->insufficient()
        if !$self->session->user->isInGroup( $self->get('groupToEditSurvey') );

    my $i18n = WebGUI::International->new($session, "Asset_Survey");
    
    my $ac   = $self->getAdminConsole;
    
    eval 'use GraphViz';
    if ($@) {
        return $ac->render('Survey Visualization requires the GraphViz module', $i18n->get('survey visualization'));
    }
    
    my $format = $self->session->form->param('format');
    my $layout = $self->session->form->param('layout');
    
    my $f = WebGUI::HTMLForm->new($session);
    $f->hidden(
        name=>'func',
        value=>'graph'
    );
    $f->selectBox(
        name      => 'format',
        label     => $i18n->get('visualization format'),
        hoverHelp => $i18n->get('visualization format help'),
        options =>  { map { $_ => $_ } $self->getGraphFormats },
        defaultValue => [$format],
        sortByValue => 1,
    );
    $f->selectBox(
        name      => 'layout',
        label     => $i18n->get('visualization layout algorithm'),
        hoverHelp => $i18n->get('visualization layout algorithm help'),
        options =>  { map { $_ => $_ } $self->getGraphLayouts },
        defaultValue => [$layout],
        sortByValue => 1,
    );
    $f->submit(
        defaultValue => $i18n->get('generate'),
    );
    
    my $output;
    if ($format && $layout) {
        if (my $url = $self->graph( { format => $format, layout => $layout } )) {
            $output .= "<p>" . $i18n->get('visualization success') . qq{ <a href="$url">survey.$format</a></p>};
        }
    }
    return $ac->render($f->print . $output, $i18n->get('survey visualization'));
}

#-------------------------------------------------------------------

=head2 www_submitObjectEdit ( )

This is called when an edit is submitted to a survey object. The POST should contain the id and updated params
of the object, and also if the object is being deleted or copied.

In general, the id contains a section index, question index, and answer index, separated by dashes.
See L<WebGUI::Asset::Wobject::Survey::ResponseJSON/sectionIndex>. 

=cut

sub www_submitObjectEdit {
    my $self = shift;
    
    return $self->session->privilege->insufficient()
        unless $self->session->user->isInGroup( $self->get('groupToEditSurvey') );

    my $params = $self->session->form->paramsHashRef();

    # Id is made up of at most: sectionIndex-questionIndex-answerIndex
    my @address = split /-/, $params->{id};

    # See if any special actions were requested..
    if ( $params->{delete} ) {
        return $self->deleteObject( \@address );
    }
    elsif ( $params->{copy} ) {
        return $self->copyObject( \@address );
    }elsif( $params->{removetype} ){
        return $self->removeType(\@address);        
    }elsif( $params->{addtype} ){
        return $self->addType($params->{addtype},\@address);        
    }

    # Update the addressed object
    $self->surveyJSON_update( \@address, $params );

    # Return the updated Survey structure
    return $self->www_loadSurvey( { address => \@address } );
}

#-------------------------------------------------------------------

=head2 www_jumpTo

Allow survey editors to jump to a particular section or question in a
Survey by tricking Survey into thinking they've completed the survey up to that
point. This is useful for user-testing large Survey instances where you don't want 
to waste your time clicking through all of the initial questions to get to the one 
you want to look at. 

Note that calling this method will delete any existing survey responses for the
current user (although only survey builders can call this method so that shouldn't be
a problem).

=cut

sub www_jumpTo {
    my $self = shift;

    return $self->session->privilege->insufficient()
        if !$self->session->user->isInGroup( $self->get('groupToEditSurvey') );

    my $id = $self->session->form->param('id');

    # When the Edit Survey screen first loads the first section will have an id of 'undefined'
    # In this case, treat it the same as '0'
    $id = $id eq 'undefined' ? 0 : $id;

    $self->session->log->debug("www_jumpTo: $id");

    # Remove existing responses for current user
    $self->session->db->write( 'delete from Survey_response where assetId = ? and userId = ?',
        [ $self->getId, $self->session->user->userId() ] );

    # Break the $id down into sIndex and qIndex
    my ($sIndex, $qIndex) = split /-/, $id;

    # Go through items in surveyOrder until we find the item corresponding to $id
    my $currentIndex = 0;
    for my $address (@{ $self->responseJSON->surveyOrder }) {
        my ($order_sIndex, $order_qIndex) = @{$address}[0,1];

        # For starters, check that we're on the right Section 
        if ($sIndex ne $order_sIndex) {

            # Bad luck, try the next one..
            $currentIndex++;
            next;
        }

        # For a match, either qIndex must be empty (target is a Section), or
        # the qIndices must match
        if (!defined $qIndex || $qIndex eq $order_qIndex) {

            # Set the nextResponse to be the index we're up to
            $self->session->log->debug("Found id: $id at index: $currentIndex in surveyOrder");
            $self->responseJSON->nextResponse( $currentIndex );
            $self->persistResponseJSON(); # Manually persist ResponseJSON to the database
            return $self->www_takeSurvey;
        }

        # Keep looking..
        $currentIndex++;
    }

    # Search failed, so return the Edit Survey page instead.
    $self->session->log->debug("Unable to find id: $id");
    return $self->www_editSurvey;
}

#-------------------------------------------------------------------

=head2 removeType ( $address )

Remove the requested questionType, and then reloads the Survey.

=head3 $address

Specifies which questionType to delete.

=cut

sub removeType{
    my $self = shift;
    my $address = shift;
    $self->surveyJSON->removeType($address);
    return $self->www_loadSurvey( { address => $address } );
    
}

#-------------------------------------------------------------------

=head2 addType ( $name, $address )

Adds a new questionType, and then reloads the Survey.

=head3 $name

The name of the new question type.

=head3 $address

Specifies where to add the question.

=cut

sub addType{
    my $self = shift;
    my $name = shift;
    my $address = shift;
    $self->surveyJSON->addType($name,$address);
    $self->persistSurveyJSON();
    return $self->www_loadSurvey( { address => $address } );
}

#-------------------------------------------------------------------

=head2 copyObject ( )

Takes the address of a survey object and creates a copy.  The copy is placed at the end of this object's parent's list. 

Returns the address to the new object.

=head3 $address

See L<WebGUI::Asset::Wobject::Survey::SurveyJSON/Address Parameter>

=cut

sub copyObject {
    my ( $self, $address ) = @_;

    # Each object checks the ref and then either updates or passes it to the correct child.  
    # New objects will have an index of -1.
    $address = $self->surveyJSON_copy($address);

    # The parent address of the deleted object is returned.
    return $self->www_loadSurvey( { address => $address } );
}

#-------------------------------------------------------------------

=head2 deleteObject( $address )

Deletes the object matching the passed in address.

Returns the address to the parent object, or the very first section.

=head3 $address

See L<WebGUI::Asset::Wobject::Survey::SurveyJSON/Address Parameter>

=cut

sub deleteObject {
    my ( $self, $address ) = @_;

    # Each object checks the ref and then either updates or passes it to the correct child. 
    # New objects will have an index of -1.
    my $message = $self->surveyJSON_remove($address);

    # The parent address of the deleted object is returned.
    if ( @{$address} == 1 ) {
        $address->[0] = 0;
    }
    else {
        pop @{$address};
    }

    return $self->www_loadSurvey( { address => $address, message => $message } );
}

#-------------------------------------------------------------------

=head2 www_newObject()

Creates a new object from a POST param containing the new objects id concatenated on hyphens.

=cut

sub www_newObject {
    my $self = shift;

    return $self->session->privilege->insufficient()
        if !$self->session->user->isInGroup( $self->get('groupToEditSurvey') );

    my $ref;

    my $ids = $self->session->form->process('data');

    my @inAddress = split /-/, $ids;

    # Don't save after this as the new object should not stay in the survey
    my $address = $self->surveyJSON->newObject( \@inAddress );

    # The new temp object has an address of NEW, which means it is not a real final address.
    return $self->www_loadSurvey( { address => $address, message => undef } );

}

#-------------------------------------------------------------------

=head2 www_dragDrop

Takes two ids from a form POST. 
The "target" is the object being moved, the "before" is the object directly preceding the "target".

=cut

sub www_dragDrop {
    my $self = shift;

    return $self->session->privilege->insufficient()
        if !$self->session->user->isInGroup( $self->get('groupToEditSurvey') );

    my $p = from_json( $self->session->form->process('data') );

    my @tid = split /-/, $p->{target}->{id};
    my @bid = split /-/, $p->{before}->{id};

    my $target = $self->surveyJSON->getObject( \@tid );
    $self->surveyJSON_remove( \@tid, 1 );
    my $address = [0];
    if ( @tid == 1 ) {

        #sections can only be inserted after another section so chop off the question and answer portion of
        $#bid = 0;
        $bid[0] = -1 if ( !defined $bid[0] );

        #If target is being moved down, then before has just moved up do to the target being deleted
        $bid[0]-- if($tid[0] < $bid[0]);

        $address = $self->surveyJSON->insertObject( $target, [ $bid[0] ] );
    }
    elsif ( @tid == 2 ) {    #questions can be moved to any section, but a pushed to the end of a new section.
        if ( $bid[0] !~ /\d/ ) {
            $bid[0] = $tid[0];
            $bid[1] = $tid[1];
        }
        elsif ( @bid == 1 ) {    #moved to a new section or head of current section
            if ( $bid[0] !~ /\d/ ) {
                $bid[0] = $tid[0];
                $bid[1] = $tid[1];
            }
            if ( $bid[0] == $tid[0] ) {
                #moved to top of current section
                $bid[1] = -1;
            }
            else {
                #else move to the end of the selected section
                $bid[1] = $#{ $self->surveyJSON->questions( [ $bid[0] ] ) };
            }
        } ## end elsif ( @bid == 1 )
        else{   #Moved within the same section
            $bid[1]-- if($tid[1] < $bid[1]);
        }
        $address  = $self->surveyJSON->insertObject( $target, [ $bid[0], $bid[1] ] );
    } ## end elsif ( @tid == 2 )
    elsif ( @tid == 3 ) {    #answers can only be rearranged in the same question
        if ( @bid == 2 and $bid[1] == $tid[1] ) {#moved to the top of the question
            $bid[2] = -1;
            $address = $self->surveyJSON->insertObject( $target, [ $bid[0], $bid[1], $bid[2] ] );
        }
        elsif ( @bid == 3 ) {
            #If target is being moved down, then before has just moved up do to the target being deleted
            $bid[2]-- if($tid[2] < $bid[2]);
            $address = $self->surveyJSON->insertObject( $target, [ $bid[0], $bid[1], $bid[2] ] );
        }
        else {
            #else put it back where it was
            $address = $self->surveyJSON->insertObject( $target, \@tid );
        }
    }

    # Manually persist SuveryJSON since we have directly modified it
    $self->persistSurveyJSON();

    return $self->www_loadSurvey( { address => $address } );
}

#-------------------------------------------------------------------

=head2 www_loadSurvey( [options] )

For loading the survey during editing. 
Returns the survey meta list and the html data for editing a particular survey object.

=head3 options

Can either be a hashref containing the address to be edited.  And/or a the specific variables to be edited.  
If undef, the address is pulled form the form POST.

=cut

sub www_loadSurvey {
    my ( $self, $options ) = @_;
    my $editflag = 1;
    my $address = defined $options->{address} ? $options->{address} : undef;
    
    if ( !defined $address ) {
        if ( my $inAddress = $self->session->form->process('data') ) {
            if ( $inAddress eq q{-} ) {
                $editflag = 0;
                $address  = [0];
            }
            else {
                $address = [ split /-/, $inAddress ];
            }
        }
        else {
            $address = [0];
        }
    }
    my $var
        = defined $options->{var}
        ? $options->{var}
        : $self->surveyJSON->getEditVars($address);
    
    my $editHtml;
    if ( $var->{type} eq 'section' ) {
        $editHtml = $self->processTemplate( $var, $self->get('sectionEditTemplateId') );
    }
    elsif ( $var->{type} eq 'question' ) {
        $editHtml = $self->processTemplate( $var, $self->get('questionEditTemplateId') );
    }
    elsif ( $var->{type} eq 'answer' ) {
        $editHtml = $self->processTemplate( $var, $self->get('answerEditTemplateId') );
    }

    # Generate the list of valid goto targets
    my $gotoTargets = $self->surveyJSON->getGotoTargets;
    
    my %buttons;
    $buttons{question} = $address->[0];
    if ( @{$address} == 2 or @{$address} == 3 ) {
        $buttons{answer} = "$address->[0]-$address->[1]";
    }

    my $data = $self->surveyJSON->getDragDropList($address);
    my $html;
    my ( $scount, $qcount, $acount ) = ( -1, -1, -1 );
    my $lastType;
    my %lastId;
    my @ids;
    my ( $s, $q, $a ) = ( 0, 0, 0 );    #bools on if a button has already been created

    foreach (@{$data}) {
        if ( $_->{type} eq 'section' ) {
            $lastId{section} = ++$scount;
            if ( $lastType eq 'answer' ) {
                $a = 1;
            }
            elsif ( $lastType eq 'question' ) {
                $q = 1;
            }
            $html .= "<li id='$scount' class='section'>S" . ( $scount + 1 ) . ": $_->{text}<\/li>\n";
            push( @ids, $scount );
        }
        elsif ( $_->{type} eq 'question' ) {
            $lastId{question} = ++$qcount;
            if ( $lastType eq 'answer' ) {
                $a = 1;
            }
            $html .= "<li id='$scount-$qcount' class='question'>Q" . ( $qcount + 1 ) . ": $_->{text}<\/li>\n";
            push @ids, "$scount-$qcount";
            $lastType = 'question';
            $acount   = -1;
        }
        elsif ( $_->{type} eq 'answer' ) {
            $lastId{answer} = ++$acount;
            $html
                .= "<li id='$scount-$qcount-$acount' class='answer'>A"
                . ( $acount + 1 )
                . ": $_->{text}<\/li>\n";
            push @ids, "$scount-$qcount-$acount";
            $lastType = 'answer';
        }
    }
    $html = "<ul class='draglist'>$html</ul>";
    my $warnings = $self->surveyJSON->validateSurvey();
    
    my $return = {
        address  => $address,                    # the address of the focused object
        buttons  => \%buttons,                   # the data to create the Add buttons
        edithtml => $editflag ? $editHtml : q{}, # the html edit the object
        ddhtml   => $html,                       # the html to create the draggable html divs
        ids      => \@ids,                       # list of all ids passed in which are draggable (for adding events)
        type     => $var->{type},                # the object type
        gotoTargets => $gotoTargets,
        warnings => $warnings                    #List of warnings to display to the user
    };

    $self->session->http->setMimeType('application/json');

    return to_json($return);
}

#-------------------------------------------------------------------

=head2 prepareView ( )

See WebGUI::Asset::prepareView() for details.

=cut

sub prepareView {
    my $self = shift;
    $self->SUPER::prepareView();
    my $templateId = $self->get('templateId');
    if ( $self->session->form->process('overrideTemplateId') ne q{} ) {
        $templateId = $self->session->form->process('overrideTemplateId');
    }
    my $template = WebGUI::Asset::Template->new( $self->session, $templateId );
    $template->prepare;
    $self->{_viewTemplate} = $template;
    return;
}

#-------------------------------------------------------------------

=head2 purge

Completely remove from WebGUI.

=cut

sub purge {
    my $self = shift;
    $self->session->db->write( 'delete from Survey_response where assetId = ?',   [ $self->getId() ] );
    $self->session->db->write( 'delete from Survey_tempReport where assetId = ?', [ $self->getId() ] );
    $self->session->db->write( 'delete from Survey where assetId = ?',            [ $self->getId() ] );
    return $self->SUPER::purge;
}

#-------------------------------------------------------------------

=head2 purgeCache ( )

See WebGUI::Asset::purgeCache() for details.

=cut

sub purgeCache {
    my $self = shift;
    WebGUI::Cache->new( $self->session, 'view_' . $self->getId )->delete;
    return $self->SUPER::purgeCache;
}

#-------------------------------------------------------------------

=head2 view ( )

view defines all template variables, processes the template and
returns the output.

=cut

sub view {
    my $self    = shift;
    my $var     = $self->getMenuVars;
    
    my $responseDetails = $self->getResponseDetails();

    # Add lastResponse template vars
    for my $tv qw(endDate feedback complete restart timeout timeoutRestart) {
        $var->{"lastResponse\u$tv"} = $responseDetails->{$tv};
    }
    $var->{maxResponsesSubmitted} = !$self->canTakeSurvey();
    
    return $self->processTemplate( $var, undef, $self->{_viewTemplate} );
}

#-------------------------------------------------------------------

=head2 getMenuVars ( )

Returns the top menu template variables as a hashref.

=cut

sub getMenuVars {
    my $self = shift;

    return {
        edit_survey_url               => $self->getUrl('func=editSurvey'),
        take_survey_url               => $self->getUrl('func=takeSurvey'),
        delete_responses_url          => $self->getUrl('func=deleteResponses'),
        view_simple_results_url       => $self->getUrl('func=exportSimpleResults'),
        view_transposed_results_url   => $self->getUrl('func=exportTransposedResults'),
        view_statistical_overview_url => $self->getUrl('func=viewStatisticalOverview'),
        view_grade_book_url           => $self->getUrl('func=viewGradeBook'),
        user_canTakeSurvey            => $self->session->user->isInGroup( $self->get('groupToTakeSurvey') ),
        user_canViewReports           => $self->session->user->isInGroup( $self->get('groupToViewReports') ),
        user_canEditSurvey            => $self->session->user->isInGroup( $self->get('groupToEditSurvey') ),
    };
}

#-------------------------------------------------------------------

=head2 getResponseDetails ( [$responseId] )

Looks up details about a given response.

=head3 responseId

A specific responseId to use. If none given, the most recent completed response is used.

=cut

sub getResponseDetails {
    my $self = shift;
    my $responseId = shift;
    
    my ($lastResponseCompleteCode, $lastResponseEndDate, $rJSON);
    
    if ( $responseId ) {
        $self->session->log->debug("ResponseId provided: $responseId");
        ($lastResponseCompleteCode, $lastResponseEndDate, $rJSON) = $self->session->db->quickArray(
            'select isComplete, endDate, responseJSON from Survey_response where Survey_responseId = ?', [ $responseId ]
        );
    } else {
        my $userId = $self->session->user->userId();
        my $anonId 
            = $self->session->form->process('userid')
            || $self->session->http->getCookies->{Survey2AnonId}
            || undef;
        $anonId && $self->session->http->setCookie( Survey2AnonId => $anonId );
        my $ip = $self->session->env->getIp;
        my $string;

        if ( $anonId or $userId != 1 ) {
            $string = 'userId';
            if ($anonId) {
                $string = 'anonId';
                $userId = $anonId;
            }
            my $lastResponseId
                = $self->session->db->quickScalar(
                "select Survey_responseId from Survey_response where $string = ? and assetId = ? and isComplete = 0",
                [ $userId, $self->getId() ] );
            if ( !$lastResponseId ) {
                ($lastResponseCompleteCode, $lastResponseEndDate, $rJSON) = $self->session->db->quickArray(
                    "select isComplete, endDate, responseJSON from Survey_response where $string = ? and assetId = ? and isComplete > 0 order by endDate desc limit 1",
                    [ $userId, $self->getId() ]
                );
            }
        }
        elsif ( $userId == 1 ) {
            my $lastResponseId = $self->session->db->quickScalar(
                'select Survey_responseId from Survey_response where userId = ? and ipAddress = ? and assetId = ? and isComplete = 0',
                [ $userId, $ip, $self->getId() ]
            );
            if ( !$lastResponseId ) {
                ($lastResponseCompleteCode, $lastResponseEndDate, $rJSON) = $self->session->db->quickArray(
                    'select isComplete, endDate, responseJSON from Survey_response where userId = ? and ipAddress = ? and assetId = ? and isComplete > 0 order by endDate desc limit 1',
                    [ $userId, $ip, $self->getId() ]
                );
            }
        }
    }
    
    # Process the feedback text
    my $feedback;
    my $tags = {};
    if ($rJSON) {
        $rJSON = from_json($rJSON) || {};
        
        # All tags become template vars
        $tags = $rJSON->{tags} || {};
        $tags->{complete} = $lastResponseCompleteCode == 1;
        $tags->{restart} = $lastResponseCompleteCode == 2;
        $tags->{timeout} = $lastResponseCompleteCode == 3;
        $tags->{timeoutRestart} = $lastResponseCompleteCode == 4;
        $tags->{endDate} = $lastResponseEndDate && WebGUI::DateTime->new($self->session, $lastResponseEndDate)->toUserTimeZone;
        $feedback = $self->processTemplate($tags, $self->get('feedbackTemplateId') || 'nWNVoMLrMo059mDRmfOp9g');
    }
    return {
        completeCode => $lastResponseCompleteCode, 
        endDate => $tags->{endDate},
        feedback => $feedback,
        complete => $tags->{complete},
        restart => $tags->{restart},
        timeout => $tags->{timeout},
        timeoutRestart => $tags->{timeoutRestart},
    };
}

#-------------------------------------------------------------------

=head2 newByResponseId ( responseId )

Class method. Instantiates a Survey instance from the given L<"responseId">, and loads the
user response into the Survey instance.

=head3 responseId

An existing L<"responseId">. Will be loaded even if the response isComplete.

=cut

sub newByResponseId {
    my $class = shift;
    my ($session, $responseId) = validate_pos(@_, {isa => 'WebGUI::Session'}, { type => SCALAR });
    
    my ($assetId, $userId) = $session->db->quickArray('select assetId, userId from Survey_response where Survey_responseId = ?',
        [$responseId]);
    
    if (!$assetId) {
        $session->log->warn("ResponseId not bound to valid assetId: $responseId");
        return;
    }
    
    if (!$userId) {
        $session->log->warn("ResponseId not bound to valid userId: $responseId");
        return;
    }
    
    if (my $survey = $class->new($session, $assetId)) {
        # Set the responseId manually rather than calling $self->responseId so that we
        # can load a response regardless of whether it's marked isComplete
        $survey->{responseId} = $responseId;
        return $survey;
    } else {
        $session->log->warn("Unable to instantiate Asset for assetId: $assetId");
        return;
    }
}

#-------------------------------------------------------------------

=head2 www_takeSurvey

The take survey page does very little. It is a simple shell (controlled by surveyTakeTemplateId).

Survey questions are loaded asynchronously via javascript calls to L<"www_loadQuestions">.

=cut

sub www_takeSurvey {
    my $self = shift;
    
    my $out = $self->processTemplate( {}, $self->get('surveyTakeTemplateId') );
    return $self->processStyle($out);
}

#-------------------------------------------------------------------

=head2 www_deleteResponses

Deletes all responses from this survey instance.

=cut

sub www_deleteResponses {
    my $self = shift;

    return $self->session->privilege->insufficient()
        if !$self->session->user->isInGroup( $self->get('groupToEditSurvey') );

    $self->session->db->write( 'delete from Survey_response where assetId = ?', [ $self->getId ] );

    return;
}

#-------------------------------------------------------------------

=head2 www_submitQuestions

Handles questions submitted by the survey taker, adding them to their response.

=cut

sub www_submitQuestions {
    my $self = shift;

    if ( !$self->canTakeSurvey() ) {
        $self->session->log->debug('canTakeSurvey false, surveyEnd');
        return $self->surveyEnd();
    }

    my $responseId = $self->responseId();
    if ( !$responseId ) {
        $self->session->log->debug('No response id, surveyEnd');
        return $self->surveyEnd();
    }

    my $responses = $self->session->form->paramsHashRef();
    delete $responses->{func};
    
    return $self->submitQuestions($responses);
}

#-------------------------------------------------------------------

=head2 submitQuestions

Handles questions submitted by the survey taker, adding them to their response.

=cut

sub submitQuestions {
    my $self = shift;
    my $responses = shift;
    
    my $result = $self->recordResponses( $responses );
    
    # check for special actions
    if ( my $url = $result->{terminal} ) {
        $self->session->log->debug('Terminal, surveyEnd');
        return $self->surveyEnd( { exitUrl => $url } );
    } elsif ( exists $result->{exitUrl} ) {
        $self->session->log->debug('exitUrl triggered, surveyEnd');
        return $self->surveyEnd( { exitUrl => $result->{exitUrl} });
    } elsif ( my $restart = $result->{restart} ) {
        $self->session->log->debug('restart triggered');
        return $self->surveyEnd( { restart => $restart } );
    }

    return $self->www_loadQuestions();
}

#-------------------------------------------------------------------

=head2 www_goBack

Handles the Survey back button

=cut

sub www_goBack {
    my $self = shift;

    if ( !$self->canTakeSurvey() ) {
        $self->session->log->debug('canTakeSurvey false, surveyEnd');
        return $self->surveyEnd();
    }
    
    my $responseId = $self->responseId();
    if ( !$responseId ) {
        $self->session->log->debug('No response id, surveyEnd');
        return $self->surveyEnd();
    }
    
    if ( !$self->get('allowBackBtn') ) {
        $self->session->log->debug('allowBackBtn false, delegating to www_loadQuestions');
        return $self->www_loadQuestions();
    }

    $self->responseJSON->pop;
    $self->persistResponseJSON;

    return $self->www_loadQuestions();

}

#-------------------------------------------------------------------

=head2 getSummary

Returns a copy of the summary stored in JSON, and the output of
the survey summary template.

=cut

sub getSummary {
    my $self = shift;
    my $summary = $self->responseJSON->showSummary();
    my $out = $self->processTemplate( $summary, $self->get('surveySummaryTemplateId') );

    return ($summary,$out);
}

#-------------------------------------------------------------------

=head2 www_showFeedback

Displays feedback on demand for a given responseId

=cut

sub www_showFeedback {
    my $self            = shift;
    
    my $responseId = $self->session->form->param('responseId');
    
    # Only continue if we were given a responseId
    return if !$responseId;
    
    my $userId = $self->session->db->quickScalar('select userId from Survey_response where Survey_responseId = ?', [ $responseId ]);
    
    # Only continue if responseId gave us a legit userId
    return if !$userId;
    
    # Only continue if user owns the response
    return if $userId ne $self->session->user->userId;
    
    my $out = $self->getResponseDetails($responseId)->{feedback};
    return $self->session->style->process( $out, $self->get('styleTemplateId') );
}

#-------------------------------------------------------------------

=head2 www_loadQuestions

Determines which questions to display to the survey taker next, loads and returns them.

=cut

sub www_loadQuestions {
    my $self            = shift;
    my $wasRestarted    = shift;
    if ( !$self->canTakeSurvey() ) {
        $self->session->log->debug('canTakeSurvey false, surveyEnd');
        return $self->surveyEnd();
    }

    my $responseId = $self->responseId();
    if ( !$responseId ) {
        $self->session->log->debug('No responseId, surveyEnd');
        return $self->surveyEnd();
    }
    if ( $self->responseJSON->hasTimedOut( $self->get('timeLimit') ) ) {
        $self->session->log->debug('Response hasTimedOut, surveyEnd');
        return $self->surveyEnd( { timeout => 1 } );
    }

    if ( $self->responseJSON->surveyEnd() ) {
        $self->session->log->debug('Response surveyEnd, so calling surveyEnd');
        if ( $self->get('quizModeSummary') ) {
            if(! $self->session->form->param('shownsummary')){
                my ($summary,$html) = $self->getSummary();
                my $json = to_json( { type => 'summary', summary => $summary, html => $html });
                $self->session->http->setMimeType('application/json');
                return $json;
            }
        }
        return $self->surveyEnd();
    }

    my @questions;
    eval { @questions = $self->responseJSON->nextQuestions(); };
    
    my $section = $self->responseJSON->nextResponseSection();

    #return $self->prepareShowSurveyTemplate($section,$questions);
    $section->{id}              = $self->responseJSON->nextResponseSectionIndex();
    $section->{wasRestarted}    = $wasRestarted;

    my $text = $self->prepareShowSurveyTemplate( $section, \@questions );

    return $text;
}

#-------------------------------------------------------------------

=head2 surveyEnd ( [ $options ]  )

Marks the survey response as completed and carries out special actions such as restarting or exiting to an exitUrl

=head3 $options

The following options are supported

=over 3

=item timeout

Indicates that the survey has timed out. The doAfterTimeLimit setting controls whether the 
survey restarts or exits to the exitUrl.

=item restart

The survey should be restarted

=item exitUrl

Exit to the supplied url, or if no url is provided exit to the survey's exitUrl.

=back

=cut

sub surveyEnd {
    my $self   = shift;
    my %opts = validate(@_, { timeout => 0, restart => 0, exitUrl => 0 });
    
    # If an in-progress response exists, mark it as complete
    if ( my $responseId = $self->responseId ) {
        # Decide if we should flag any special actions such as restart or timeout
        my $restart = $opts{restart};
        my $timeoutRestart = $opts{timeout} && $self->get('doAfterTimeLimit') eq 'restartSurvey';
        my $timeout = $opts{timeout};
        
        # First thing to do is to end the current response (and flag why it happened)
        my $completeCode
            = $timeoutRestart ? 4
            : $timeout        ? 3
            : $restart        ? 2
            :                   1
            ;
        $self->session->log->debug("Completing survey response $responseId with completeCode: $completeCode");
            
        $self->session->db->setRow(
            'Survey_response',
            'Survey_responseId', {
                Survey_responseId => $responseId,
                endDate           => scalar time,
                isComplete        => $completeCode,
            }
        );
        
        # When restarting, we just need to uncache everything response-related
        if ( $restart || $timeoutRestart ) {
            $self->session->log->debug("Detaching from response $responseId as part of restart");
            delete $self->{_responseJSON};
            delete $self->{responseId};
            return $self->www_loadQuestions(1);
        }
        
         # Trigger workflow for everything else
        if ( my $workflowId = $self->get('onSurveyEndWorkflowId') ) {
            $self->session->log->debug("Triggering onSurveyEndWorkflowId workflow: $workflowId");
            WebGUI::Workflow::Instance->create(
                $self->session,
                {   workflowId => $workflowId,
                    methodName => 'newByResponseId',
                    className  => 'WebGUI::Asset::Wobject::Survey',
                    parameters => $responseId,
                }
            )->start;
        }
    }

    # If we get this far, it's time to forward users to an exitUrl
    my $exitUrl = $opts{exitUrl};
    undef $exitUrl if $exitUrl !~ /\w/;
    undef $exitUrl if $exitUrl eq 'undefined';
    $exitUrl = $exitUrl || $self->get('exitURL') || $self->getUrl || q{/};
    $exitUrl = $self->session->url->gateway($exitUrl) if($exitUrl !~ /^https?:/i);
    my $json = to_json( { type => 'forward', url => $exitUrl } );
    $self->session->http->setMimeType('application/json');
    return $json;
}

#-------------------------------------------------------------------

=head2 prepareShowSurveyTemplate

Sends the processed template and questions structure to the client

=cut

sub prepareShowSurveyTemplate {
    my ( $self, $section, $questions ) = @_;
    my %textArea    = ( 'TextArea', 1 );
    my %text        = ( 'Text', 1, 'Email', 1, 'Phone Number', 1, 'Text Date', 1, 'Currency', 1, 'Number', 1 );
    my %slider      = ( 'Slider', 1, 'Dual Slider - Range', 1, 'Multi Slider - Allocate', 1 );
    my %dateType    = ( 'Date',        1, 'Date Range', 1 );
    my %dateShort   = ( 'Year Month', 1 );
    my %country     = ( 'Country', 1 );
    my %fileUpload  = ( 'File Upload', 1 );
    my %hidden      = ( 'Hidden',      1 );

    foreach my $q (@$questions) {
        if    ( $fileUpload{ $q->{questionType} } ) { $q->{fileLoader}   = 1; }
        elsif ( $text{ $q->{questionType} } )       { $q->{textType}     = 1; }
        elsif ( $textArea{ $q->{questionType} } )   { $q->{textAreaType} = 1; }
        elsif ( $hidden{ $q->{questionType} } )     { $q->{hidden}       = 1; }
        elsif ( $self->surveyJSON->multipleChoiceTypes->{ $q->{questionType} } ) {
            $q->{multipleChoice} = 1;
            if ( $q->{maxAnswers} > 1 ) {
                $q->{maxMoreOne} = 1;
            }
        }
        elsif ( $dateType{ $q->{questionType} } ) {
            $q->{dateType} = 1;
        }
        elsif ( $dateShort{ $q->{questionType} } ) {
            $q->{dateShort} = 1;
            foreach my $a(@{$q->{answers}}){
                $a->{months} = [ 
                             {'month' => ''},
                             {'month' => 'January'},
                             {'month' => 'February'},
                             {'month' => 'March'},
                             {'month' => 'April'},
                             {'month' => 'May'},
                             {'month' => 'June'},
                             {'month' => 'July'},
                             {'month' => 'August'},
                             {'month' => 'September'},
                             {'month' => 'October'},
                             {'month' => 'November'},
                             {'month' => 'December'}
                            ];
            }
        }
        elsif ( $country{ $q->{questionType} } ) {
            $q->{country} = 1;
            use WebGUI::Form::Country;
            my @countries = map +{ 'country' => $_ }, WebGUI::Form::Country::getCountries();
            foreach my $a(@{$q->{answers}}){
                $a->{countries} = [ {'country' => ''}, @countries ];
            }
        }
        elsif ( $slider{ $q->{questionType} } ) {
            $q->{slider} = 1;
            if ( $q->{questionType} eq 'Dual Slider - Range' ) {
                $q->{dualSlider} = 1;
                $q->{a1}         = [ $q->{answers}->[0] ];
                $q->{a2}         = [ $q->{answers}->[1] ];
            }
        }

        if ( $q->{verticalDisplay} ) {
            $q->{verts} = '<p>';
            $q->{verte} = '</p>';
        }
    }
    $section->{questions}         = $questions;
    $section->{questionsAnswered} = $self->responseJSON->{questionsAnswered};
    $section->{totalQuestions}    = @{ $self->responseJSON->surveyOrder };
    $section->{showProgress}      = $self->get('showProgress');
    $section->{showTimeLimit}     = $self->get('showTimeLimit');
    $section->{minutesLeft}
        = int( ( ( $self->responseJSON->startTime() + ( 60 * $self->get('timeLimit') ) ) - time() ) / 60 );

    if(scalar @{$questions} == ($section->{totalQuestions} - $section->{questionsAnswered})){
        $section->{isLastPage} = 1
    }
    $section->{allowBackBtn} = $self->get('allowBackBtn');

    my $out = $self->processTemplate( $section, $self->get('surveyQuestionsId') );

    $self->session->http->setMimeType('application/json');
    return to_json( { type => 'displayquestions', section => $section, questions => $questions, html => $out } );
}

#-------------------------------------------------------------------

=head2 persistSurveyJSON ( )

Serializes the SurveyJSON instance and persists it to the database.

Calling this method is only required if you have directly accessed and modified 
the L<"surveyJSON"> object.

=cut

sub persistSurveyJSON {
    my $self = shift;

    my $data = $self->surveyJSON->freeze();
    $self->update({surveyJSON=>$data});
#    $self->session->db->write( 'update Survey set surveyJSON = ? where assetId = ?', [ $data, $self->getId ] );

    return;
}

#-------------------------------------------------------------------

=head3 persistResponseJSON

Turns the response object into JSON and saves it to the DB.  

=cut

sub persistResponseJSON {
    my $self = shift;
    my $data = $self->responseJSON->freeze();
    $self->session->db->write( 'update Survey_response set responseJSON = ? where Survey_responseId = ?', [ $data, $self->responseId ] );
    return;
}

#-------------------------------------------------------------------

=head2 responseIdCookies

Mutator for the responseIdCookies that determines whether cookies are used as
part of the L<"responseId"> lookup process.

Useful for disabling cookie operations during tests, since WebGUI::Test::getPage
currently does not support cookies.

=cut

sub responseIdCookies {
    my $self = shift;
    my ($x) = validate_pos(@_, {type => SCALAR, optional => 1});
    
    if (defined $x) {
        $self->{_responseIdCookies} = $x;
    }

    # Defaults to true..
    return defined $self->{_responseIdCookies} ? $self->{_responseIdCookies} : 1;
}

#-------------------------------------------------------------------

=head2 responseId( [userId] )

Accessor for the responseId property, which is the unique identifier for a single 
L<WebGUI::Asset::Wobject::Survey::ResponseJSON> instance. See also L<"responseJSON">.

The responseId of the current user is returned, or created if one does not already exist.
If the user is anonymous, the IP is used. Or an emailed or linked code can be used.

=head3 userId (optional)

If specified, this user is used rather than the current user 

=cut

sub responseId {
    my $self = shift;
    my ($userId) = validate_pos(@_, {type => SCALAR, optional => 1});
    
    my $user = WebGUI::User->new($self->session, $userId);

    if (!defined $self->{responseId}) {
        my $ip = $self->session->env->getIp;
        my $id = $userId || $self->session->user->userId;
        my $anonId = $self->session->form->process('userid');
        if ($self->responseIdCookies) {
            $anonId ||= $self->session->http->getCookies->{Survey2AnonId}; ## no critic
        }
        $anonId ||= undef;
        
        if ($self->responseIdCookies) {
            $anonId && $self->session->http->setCookie( Survey2AnonId => $anonId );
        }
    
        my ($responseId, $string);

        # if there is an anonid or id is for a WG user
        if ( $anonId or $id != 1 ) {
            $string = 'userId';
            if ($anonId) {
                $string = 'anonId';
                $id     = $anonId;
            }
            $responseId
                = $self->session->db->quickScalar(
                "select Survey_responseId from Survey_response where $string = ? and assetId = ? and isComplete = 0",
                [ $id, $self->getId() ] );
    
        }
        elsif ( $id == 1 ) {
            $responseId = $self->session->db->quickScalar(
                'select Survey_responseId from Survey_response where userId = ? and ipAddress = ? and assetId = ? and isComplete = 0',
                [ $id, $ip, $self->getId() ]
            );
        }
        if ( !$responseId ) {
            my $maxResponsesPerUser = $self->get('maxResponsesPerUser');
            my $takenCount;
    
            if ( $id == 1 ) {
                $takenCount = $self->takenCount( { userId => $id, ipAddress => $ip } );
            }
            else {
                $takenCount = $self->takenCount( { $string => $id } );
            }
            if ( $maxResponsesPerUser == 0 || $takenCount < $maxResponsesPerUser ) {
                $responseId = $self->session->db->setRow(
                    'Survey_response',
                    'Survey_responseId', {
                        Survey_responseId => 'new',
                        userId            => $id,
                        ipAddress         => $ip,
                        username          => $user ? $user->username : $self->session->user->username,
                        startDate         => scalar time,                      #WebGUI::DateTime->now->toDatabase,
                        endDate           => 0,                                #WebGUI::DateTime->now->toDatabase,
                        assetId           => $self->getId(),
                        anonId            => $anonId
                    }
                );

                # Store the newly created responseId
                $self->{responseId} = $responseId;
                
                # Manually persist ResponseJSON since we have changed $self->responseId
                $self->persistResponseJSON();
            }
            else {
                $self->session->log->debug("takenCount ($takenCount) >= maxResponsesPerUser ($maxResponsesPerUser)");
            }
        }
        $self->{responseId} = $responseId;
    }
    return $self->{responseId};
}

=head2 takenCount

Counts the number of existing responses
N.B. only counts responses with completeCode of 1 
(others codes indicate abnormal completion such as restart
and thus should not count towards tally)

=cut

sub takenCount {
    my $self = shift;
    my %opts = validate(@_, { userId => 0, anonId => 0, ipAddress => 0 });
    
    my $sql = 'select count(*) from Survey_response where';
    $sql .= ' assetId = ' . $self->session->db->quote($self->getId);
    $sql .= ' and isComplete = 1';
    for my $o qw(userId anonId ipAddress) {
        if (my $o_value = $opts{o}) {
            $sql .= " and $o = " . $self->session->db->quote($o_value);
        }
    }
    
    my $count = $self->session->db->quickScalar($sql);
    $self->session->log->debug($count);
    return $count;
}

#-------------------------------------------------------------------

=head2 canTakeSurvey

Determines if the current user has permissions to take the survey.

=cut

sub canTakeSurvey {
    my $self = shift;

    return $self->{canTake} if ( defined $self->{canTake} );

    if ( !$self->session->user->isInGroup( $self->get('groupToTakeSurvey') ) ) {
        return 0;
    }

    my $maxResponsesPerUser = $self->getValue('maxResponsesPerUser');
    my $ip                  = $self->session->env->getIp;
    my $userId              = $self->session->user->userId();
    my $takenCount          = 0;

    if ( $userId == 1 ) {
        $takenCount = $self->takenCount( { userId => $userId, ipAddress => $ip });
    }
    else {
        $takenCount = $self->takenCount( { userId => $userId });
    }

    # A maxResponsesPerUser value of 0 implies unlimited
    if ( $maxResponsesPerUser > 0 && $takenCount >= $maxResponsesPerUser ) {
        $self->{canTake} = 0;
    }
    else {
        $self->{canTake} = 1;
    }
    return $self->{canTake};
}

#-------------------------------------------------------------------

=head2 www_viewGradeBook (){

Returns the Grade Book screen.

=cut

sub www_viewGradeBook {
    my $self    = shift;
    my $db      = $self->session->db;
    
    return $self->session->privilege->insufficient()
        if !$self->session->user->isInGroup( $self->get('groupToViewReports') );

    my $var = $self->getMenuVars;

    $self->loadTempReportTable();

    my $paginator = WebGUI::Paginator->new($self->session,$self->getUrl('func=viewGradebook'));
    $paginator->setDataByQuery('select userId,username,ipAddress,Survey_responseId,startDate,endDate'
        . ' from Survey_response where assetId='
        . $db->quote($self->getId)
        . ' order by username,ipAddress,startDate');
    my $users = $paginator->getPageData;

    $var->{question_count} = $self->surveyJSON->questionCount;
    
    my @responseloop;
    foreach my $user (@{$users}) {
        my ($correctCount) = $db->quickArray('select count(*) from Survey_tempReport'
            . ' where Survey_responseId=? and isCorrect=1',[$user->{Survey_responseId}]);
        push @responseloop, {
            # response_url is left out because it looks like Survey doesn't have a viewIndividualSurvey feature
            # yet.
            #'response_url'=>$self->getUrl('func=viewIndividualSurvey;responseId='.$user->{Survey_responseId}),
            'response_user_name'=>($user->{userId} eq '1') ? $user->{ipAddress} : $user->{username},
            'response_count_correct' => $correctCount,
            'response_percent' => round(($correctCount/$var->{question_count})*100)
            };
    }
    $var->{response_loop} = \@responseloop;
    $paginator->appendTemplateVars($var);

    my $out = $self->processTemplate( $var, $self->get('gradebookTemplateId') );
    return $self->processStyle($out);
}

#-------------------------------------------------------------------

=head2 www_viewStatisticalOverview (){

Returns the Statistical Overview screen.

=cut

sub www_viewStatisticalOverview {
    my $self    = shift;
    my $db      = $self->session->db;

    return $self->session->privilege->insufficient()
        if !$self->session->user->isInGroup( $self->get('groupToViewReports') );

    $self->loadTempReportTable();
    my $survey  = $self->surveyJSON;
    my $var     = $self->getMenuVars;
    
    my $paginator = WebGUI::Paginator->new($self->session,$self->getUrl('func=viewStatisticalOverview'));
    my @questionloop;
    for ( my $sectionIndex = 0; $sectionIndex <= $#{ $survey->sections() }; $sectionIndex++ ) {
        for ( my $questionIndex = 0; $questionIndex <= $#{ $survey->questions([$sectionIndex]) }; $questionIndex++ ) {
        my $question        = $survey->question( [ $sectionIndex, $questionIndex ] );
        my $questionType    = $question->{questionType};
        my (@answerloop, $totalResponses);;

        if ($questionType eq 'Multiple Choice'){
            $totalResponses = $db->quickScalar('select count(*) from Survey_tempReport'
                . ' where sectionNumber=? and questionNumber=?',[$sectionIndex,$questionIndex]);

            for ( my $answerIndex = 0; $answerIndex <= $#{ $survey->answers([$sectionIndex,$questionIndex]) }; $answerIndex++ ) {
                my $numResponses = $db->quickScalar('select count(*) from Survey_tempReport'
                    . ' where sectionNumber=? and questionNumber=? and answerNumber=?',
                    [$sectionIndex,$questionIndex,$answerIndex]);
                my $responsePercent;
                if ($totalResponses) {
                    $responsePercent = round(($numResponses/$totalResponses)*100);
                } else {
                    $responsePercent = 0;
                }
                my @commentloop;
                my $comments = $db->read('select answerComment from Survey_tempReport'
                    . ' where sectionNumber=? and questionNumber=? and answerNumber=?',
                    [$sectionIndex,$questionIndex,$answerIndex]);
                while (my ($comment) = $comments->array) {
                    push @commentloop,{
                        'answer_comment'=>$comment
                        };
                }
                push @answerloop,{
                    'answer_isCorrect'=>$survey->answer( [ $sectionIndex, $questionIndex, $answerIndex ] )->{isCorrect},
                    'answer' => $survey->answer( [ $sectionIndex, $questionIndex, $answerIndex ] )->{text},
                    'answer_response_count' =>$numResponses,
                    'answer_response_percent' =>$responsePercent,
                    'comment_loop'=>\@commentloop
                    };
            }
        }
        else{
            my $responses = $db->read('select value,answerComment from Survey_tempReport'
                . ' where sectionNumber=? and questionNumber=?',
                [$sectionIndex,$questionIndex]);
            while (my $response = $responses->hashRef) {
                push @answerloop,{
                    'answer_value'      =>$response->{value},
                    'answer_comment'    =>$response->{answerComment}
                    };
            }
        }
        push @questionloop, {
            question                  => $question->{text},
            question_id               => "${sectionIndex}_$questionIndex",
            question_isMultipleChoice => ($questionType eq 'Multiple Choice'),
            question_response_total   => $totalResponses,
            answer_loop               => \@answerloop,
            questionallowComment      => $question->{allowComment}
        };
        }
    }
    $paginator->setDataByArrayRef(\@questionloop);
    @questionloop = @{$paginator->getPageData};

    $var->{question_loop} = \@questionloop;
    $paginator->appendTemplateVars($var);

    my $out = $self->processTemplate( $var, $self->get('overviewTemplateId') );
    return $self->processStyle($out);
}

#-------------------------------------------------------------------

=head2 www_exportSimpleResults ()

Exports transposed results in a tab deliniated file.

=cut

sub www_exportSimpleResults {
    my $self = shift;

    return $self->session->privilege->insufficient()
        if !$self->session->user->isInGroup( $self->get('groupToViewReports'));

    $self->loadTempReportTable();

    my $filename = $self->session->url->escape( $self->get('title') . '_results.tab' );
    my $content
        = $self->session->db->quickTab(
        'select * from Survey_tempReport t where t.assetId=? order by t.Survey_responseId, t.order',
        [ $self->getId() ] );
    return $self->export( $filename, $content );
}

#-------------------------------------------------------------------

=head2 www_exportTransposedResults ()

Returns transposed results as a tabbed file.

=cut

sub www_exportTransposedResults {
    my $self = shift;
    return $self->session->privilege->insufficient()
        if !$self->session->user->isInGroup( $self->get('groupToViewReports') );

    $self->loadTempReportTable();

    my $filename = $self->session->url->escape( $self->get('title') . '_transposedResults.tab' );
    my $content
        = $self->session->db->quickTab(
        'select r.userId, r.username, r.ipAddress, r.startDate, r.endDate, r.isComplete, t.*'
        . ' from Survey_tempReport t'
        . ' left join Survey_response r using(Survey_responseId)' 
        . ' where t.assetId=?'
        . ' order by r.userId, r.Survey_responseId, t.order',
        [ $self->getId() ] );
    return $self->export( $filename, $content );
}

#-------------------------------------------------------------------

=head2 export($filename,$content)

Exports the data in $content to $filename, then forwards the user to $filename.

=head3 $filename

The name of the file you want exported.

=head3 $content

The data you want exported (CSV, tab, whatever).

=cut

sub export {
    my $self     = shift;
    my $filename = shift;
    $filename =~ s/[^\w\d\.]/_/g;
    my $content = shift;

    # Create a temporary directory to store files if it doesn't already exist
    my $store    = WebGUI::Storage->createTemp( $self->session );
    my $tmpDir   = $store->getPath();
    my $filepath = $store->getPath($filename);
    if ( !open TEMP, ">$filepath" ) {
        return 'Error - Could not open temporary file for writing.  Please use the back button and try again';
    }
    print TEMP $content;
    close TEMP;
    my $fileurl = $store->getUrl($filename);

    $self->session->http->setRedirect($fileurl);

    return undef;
}

#-------------------------------------------------------------------

=head2 loadTempReportTable

Loads the responses from the survey into the Survey_tempReport table, so that other or custom reports can be ran against this data.

=cut

sub loadTempReportTable {
    my $self = shift;

    my $refs = $self->session->db->buildArrayRefOfHashRefs( 'select * from Survey_response where assetId = ?',
        [ $self->getId() ] );
    $self->session->db->write( 'delete from Survey_tempReport where assetId = ?', [ $self->getId() ] );
    for my $ref (@{$refs}) {
        $self->responseJSON( undef, $ref->{Survey_responseId} );
        my $count = 1;
        for my $q ( @{ $self->responseJSON->returnResponseForReporting() } ) {
            if ( @{ $q->{answers} } == 0 and $q->{comment} =~ /\w/ ) {
                $self->session->db->write(
                    'insert into Survey_tempReport VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)', [
                        $self->getId(),    $ref->{Survey_responseId}, $count++,           $q->{section},
                        $q->{sectionName}, $q->{question},            $q->{questionName}, $q->{questionComment},
                        undef,             undef,                     undef,              undef,
                        undef,             undef,                     undef
                    ]
                );
                next;
            }
            for my $a ( @{ $q->{answers} } ) {
                $self->session->db->write(
                    'insert into Survey_tempReport VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)', [
                        $self->getId(),    $ref->{Survey_responseId}, $count++,           $q->{section},
                        $q->{sectionName}, $q->{question},            $q->{questionName}, $q->{questionComment},
                        $a->{id},          $a->{value},               $a->{comment},      $a->{time},
                        $a->{isCorrect},   $a->{value},               undef
                    ]
                );
            }
        }
    }
    return 1;
}

#-------------------------------------------------------------------

=head2 www_editDefaultQuestions

Allows a user to edit the *site wide* default multiple choice questions displayed when adding questions to a survey.

=cut

sub www_editDefaultQuestions{
    my $self = shift;
    my $warning = shift;
    my $session = $self->session;
    my ($output);
    my $bundleId = $session->form->process("bundleId");

    if($bundleId eq 'new'){



    }

    if($warning){$output .= "$warning";}
#    $output .= $tabForm->print;
    

}


#-------------------------------------------------------------------

=head2 www_downloadDefaulQuestions

Sends the user a json file of the default question types, which can be imported to other WebGUI instances.

=cut

sub www_downloadDefaultQuestionTypes{
    my $self = shift;
    return $self->session->privilege->insufficient()
        if !$self->session->user->isInGroup( $self->get('groupToViewReports') );
    my $content = to_json($self->surveyJSON->{multipleChoiceTypes});
    return $self->export( "WebGUI-Survey-DefaultQuestionTypes.json", $content );
}






























#-------------------------------------------------------------------

=head2 www_deleteTest ( )

Deletes a test

=cut

sub www_deleteTest {
    my $self = shift;
    my $session = $self->session;
    
    return $self->session->privilege->insufficient()
        unless $self->session->user->isInGroup( $self->get('groupToEditSurvey') );
        
    my $test = WebGUI::Asset::Wobject::Survey::Test->new($session, $session->form->get("testId"));
    if (defined $test) {
        $test->delete;
    }
    return $self->www_editTestSuite;
}

#------------------------------------------------------------------

=head2 www_demoteTest ( )

Moves a Test down one position

=cut

sub www_demoteTest {
    my $self = shift;
    my $session = $self->session;
    
    return $self->session->privilege->insufficient()
        unless $self->session->user->isInGroup( $self->get('groupToEditSurvey') );
    
    my $test = WebGUI::Asset::Wobject::Survey::Test->new($session, $session->form->get("testId"));
    if (defined $test) {
        $test->demote;
    }
    return $self->www_editTestSuite;
}

#-------------------------------------------------------------------

=head2 www_editTestSuite ( $error )

Configure a set of tests

=head3 $error

Allows another method to pass an error into this method, to display to the user.

=cut

sub www_editTestSuite {
    my $self = shift;
    my $error   = shift;
    my $session = $self->session;
    
    return $self->session->privilege->insufficient()
        unless $self->session->user->isInGroup( $self->get('groupToEditSurvey') );
        
    if ($error) {
        $error = qq|<div class="error">$error</div>\n|;
    }
    my $i18n = WebGUI::International->new($session, "Asset_Survey");
    my $addmenu = '<div style="float: left; width: 200px; font-size: 11px;">';
    $addmenu .= sprintf '<a href="%s">%s</a>', $session->url->page('func=editTest'), $i18n->get('add a test');
    $addmenu .= '</div>';
    
    my $testsFound = 0;
    my $tests = '<table class="content"><tr><th></th><th>' . $i18n->get('test name') . '</th></tr><tbody class="tableData">';
    my $getATest = WebGUI::Asset::Wobject::Survey::Test->getAllIterator($session, { sequenceKeyValue => $self->getId } );
    my $icon = $session->icon;
    while (my $test = $getATest->()) {
        $testsFound++;
        my $id     = $test->getId;
        my $name = $test->get('name');
        $tests .= '<tr><td>'
               .  $icon->delete(  'func=deleteTest;testId='.$id, undef, $i18n->get('confirm delete test'))
               .  $icon->edit(    'func=editTest;testId='.$id)
               .  $icon->moveDown('func=demoteTest;testId='.$id)
               .  $icon->moveUp(  'func=promoteTest;testId='.$id)
               .  qq{<a href="} . $session->url->page("func=runTest;testId=$id") . qq{">Run Test</a>}
               .  '</td><td>'.$name.'</td></tr>';
    }
    $tests .= '</tbody></table><div style="clear: both;"></div>';
    
    my $out = $error . $addmenu;
    $out .= $tests if $testsFound;
    
    my $ac = $self->getAdminConsole;
    return $ac->render($out, 'Survey');
}

##-------------------------------------------------------------------
#
#=head2 www_editTestSuiteSave ( )
#
#Saves the results of www_editTestSuite()
#
#=cut
#
#sub www_editTestSuiteSave {
#    my $self = shift;
#    my $session = $self->session;
#    
#    return $self->session->privilege->insufficient()
#        unless $self->session->user->isInGroup( $self->get('groupToEditSurvey') );
#    my $session = shift;
#    return $session->privilege->insufficient() unless canView($session);
#    my $i18n = WebGUI::International->new($session, 'Survey');
#    return www_editTestSuite($session, $i18n->get('already active'))
#        if analysisActive($session);
#    my $workflow = WebGUI::Workflow->new($session, 'Survey000001');
#    return www_editTestSuite($session, $i18n->get('workflow deleted')) unless defined $workflow;
#    my $delta = $session->form->process('pauseInterval','integer');
#    my $activities = $workflow->getActivities();
#    ##Note, they're in order, and the order is known.
#    $activities->[0]->set('deltaInterval', $delta);
#    $activities->[1]->set('userId', $session->user->userId);
#    my $instance = WebGUI::Workflow::Instance->create($session, {
#        workflowId => $workflow->getId,
#        priority   => 1,
#    });
#    if (!defined $instance) {
#        return www_editTestSuite($session, $i18n->get('currently running')) if $session->stow->get('singletonWorkflowClash');
#        return www_editTestSuite($session, $i18n->get('error creating workflow'));
#    }
#    $instance->start('skipRealtime');
#    $session->db->write('update surveyStatus set startDate=NOW(), userId=?, endDate=?, running=1', [$session->user->userId, '']);
#    return www_editTestSuite($session);
#}


#-------------------------------------------------------------------

=head2 www_editTest ( )

Displays a form to edit the properties test.

=cut

sub www_editTest {
    my $self = shift;
    my $error = shift;
    my $session = $self->session;
    
    return $self->session->privilege->insufficient()
        unless $self->session->user->isInGroup( $self->get('groupToEditSurvey') );
    
    if ($error) {
        $error = qq|<div class="error">$error</div>\n|;
    }
    ##Make a Survey test to use to populate the form.
    my $testId = $session->form->get('testId'); 
    my $test;
    if ($testId) {
        $test = WebGUI::Asset::Wobject::Survey::Test->new($session, $testId);
    }
    else {
        ##We need a temporary test so that we can call dynamicForm, below
        $testId = 'new';
        $test = WebGUI::Asset::Wobject::Survey::Test->create($session, { assetId => $self->getId });
    }

    ##Build the form
	my $form = WebGUI::HTMLForm->new($session);
	$form->hidden( name=>"func",   value=>"editTestSave");
	$form->hidden( name=>"testId", value=>$testId);
	$form->hidden( name=>"assetId", value=>$self->getId);
    $form->dynamicForm([WebGUI::Asset::Wobject::Survey::Test->crud_definition($session)], 'properties', $test);
	$form->submit;

	my $i18n = WebGUI::International->new($session, 'Asset_Survey');
	my $ac   = $self->getAdminConsole;
	
    if ($testId eq 'new') {
        $test->delete;
    }
	return $ac->render($error.$form->print, $i18n->get('edit test'));
}

#-------------------------------------------------------------------

=head2 www_editTestSave ( )

Saves the results of www_editTest().

=cut

sub www_editTestSave {
    my $self = shift;
    my $session = $self->session;
    
    return $self->session->privilege->insufficient()
        unless $self->session->user->isInGroup( $self->get('groupToEditSurvey') );
    
    my $form    = $session->form;
    
#    eval {
#        'fooBarBaz' =~ qr/$regexp/;
#    };
#    if ($@) {
#        my $error = $@;
#        $error =~ s/at \S+?\.pm line \d+.*$//;
#        my $i18n = WebGUI::International->new($session, 'Asset_Survey');
#        $error = join ' ', $i18n->get('Regular Expression Error:'), $error;
#        return www_editTest($session, $error);
#    }

    my $testId = $form->get('testId');
    my $test;
    if ($testId eq 'new') {
        $test = WebGUI::Asset::Wobject::Survey::Test->create($session, { assetId => $self->getId });
    }
    else {
        $test = WebGUI::Asset::Wobject::Survey::Test->new($session, $testId);
    }
    $test->updateFromFormPost if $test;
    return $self->www_editTestSuite;
}


#------------------------------------------------------------------

=head2 www_promoteTest ( )

Moves a test up one position

=head3 session

A reference to the current session.

=cut

sub www_promoteTest {
    my $self = shift;
    my $session = $self->session;
    
    return $self->session->privilege->insufficient()
        unless $self->session->user->isInGroup( $self->get('groupToEditSurvey') );
    
    my $test = WebGUI::Asset::Wobject::Survey::Test->new($session, $session->form->get("testId"));
    if (defined $test) {
        $test->promote;
    }
	return $self->www_editTestSuite;
}

#-------------------------------------------------------------------

=head2 www_runTest ( )

Runs a test

=cut

sub www_runTest {
    my $self = shift;
    my $session = $self->session;
    
    return $self->session->privilege->insufficient()
        unless $self->session->user->isInGroup( $self->get('groupToEditSurvey') );
    
    my $id = $session->form->get("testId");
    
    my $test = WebGUI::Asset::Wobject::Survey::Test->new($session, $id)
        or return $self->www_editTestSuite('Unable to find test');
    
    my $result = $test->run or return $self->www_editTestSuite('Unable to run test');
    
    my $tap = $result->{tap} or return $self->www_editTestSuite('Unable to determine test result');
    
    use TAP::Parser;
    my $parser = TAP::Parser->new( { tap => $tap } );
    
    # Expose TAP::Parser and TAP::Parser::Result info as template variables
    my $var = {
        results => [],
    };
    
    while ( my $result = $parser->next ) {
        my $rvar = {};
        for my $key (qw(
            is_plan is_pragma is_test is_comment is_bailout is_version is_unknown
            raw
            type
            as_string
            is_ok
            has_directive
            has_todo
            has_skip
           )) { 
           $rvar->{$key} = $result->$key; 
        }
        push @{$var->{results}}, $rvar;
    }

    # add summary results
    for my $key (qw(
        passed
        failed
        actual_passed
        actual_failed
        todo
        todo_passed
        skipped
        plan
        tests_planned
        tests_run
        skip_all
        has_problems
        exit
        wait
        parse_errors
       )) { 
       $var->{$key} = $parser->$key; 
    }

    my $ac = $self->getAdminConsole;
    my $out = $self->processTemplate($var, $self->get('testResultsTemplateId') || 'S3zpVitAmhy58CAioH359Q');
    my $edit = WebGUI::International->new($self->session, "WebGUI")->get(575);
    $ac->addSubmenuItem($self->session->url->page("func=editTest;testId=$id"), "$edit Test");
    return $ac->render($out, 'Test Results');
}

##-------------------------------------------------------------------
#
#=head2 www_settings ( )
#
#Configure Test Suite settings.
#
#=cut
#
#sub www_settings {
#    my $self = shift;
#    my $error   = shift;
#    my $session = $self->session;
#    
#    return $self->session->privilege->insufficient()
#        unless $self->session->user->isInGroup( $self->get('groupToEditSurvey') );
#    
#    if ($error) {
#        $error = qq|<div class="error">$error</div>\n|;
#    }
#    my $i18n = WebGUI::International->new($session, "Asset_Survey");
#    my $f = WebGUI::HTMLForm->new($session);
#    $f->hidden(
#        name=>'func',
#        value=>'settingsSave'
#    );
#    $f->integer(
#        name      => 'pauseInterval',
#        value     => $session->form->get('pauseInterval') || $session->setting->get('surveyInterval') || 300,
#        label     => $i18n->get('default pause interval'),
#        hoverHelp => $i18n->get('default pause interval help'),
#    );
#    $f->yesNo(
#        name      => 'deleteDelta',
#        value     => $session->form->get('deleteDelta') || $session->setting->get('surveyDeleteDelta') || 0,
#        label     => $i18n->get('Delete Delta Table?'),
#        hoverHelp => $i18n->get('Delete Delta Table? help'),
#    );
#    $f->yesNo(
#        name      => 'enabled',
#        value     => $session->form->get('enabled') || $session->setting->get('surveyEnabled') || 0,
#        label     => $i18n->get('Enabled?'),
#        hoverHelp => $i18n->get('Enabled? help'),
#    );
#    $f->submit();
#    my $ac = WebGUI::AdminConsole->new($session,'survey');
#    $ac->addSubmenuItem($session->url->page('surveyfunc=editTestSuite'), $i18n->get('Test Suite'));
#    return $ac->render($error.$f->print, 'Test Suite Settings');
#}
#
##-------------------------------------------------------------------
#
#=head2 www_settingsSave ( session )
#
#Save Test Suite settings.
#
#=cut
#
#sub www_settingsSave {
#    my $self = shift;
#    my $session = $self->session;
#    
#    return $self->session->privilege->insufficient()
#    my $session = shift;
#    return $session->privilege->insufficient() unless canView($session);
#    my $form = $session->form;
#    $session->setting->set('surveyInterval',    $form->process('pauseInterval', 'integer'));
#    $session->setting->set('surveyDeleteDelta', $form->process('deleteDelta',   'yesNo'  ));
#    $session->setting->set('surveyEnabled',     $form->process('enabled',       'yesNo'  ));
#    return www_settings($session);
#}

1;
