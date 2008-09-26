package WebGUI::Asset::Wobject::Survey;

#-------------------------------------------------------------------
# WebGUI is Copyright 2001-2008 Plain Black Corporation.
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
use base 'WebGUI::Asset::Wobject';

use Data::Dumper;

#<tmpl if admin <tmpl_if canEditSurvey><a href="<tmpl_var editSUrvey_url>"><tmpl_var editSurvey_label></a></tmpl_if>
#-------------------------------------------------------------------
sub definition {
    my $class = shift;
    my $session = shift;
    my $definition = shift;
    my $i18n = WebGUI::International->new($session,'Asset_Survey');
    my %properties;
    tie %properties, 'Tie::IxHash';
    %properties = (
            templateId =>{
                fieldType=>"template",
                defaultValue=>'PBtmpl0000000000000061', 
                tab=>"display",
                namespace=>"Survey",
                hoverHelp=>"A Survey System",
                label=>"Template ID"
                },
            groupToTakeSurvey => {
                fieldType   => 'group',
                defaultValue    => 2,
                label => "Group to take survey",
                },
            groupToViewReports => {
                fieldType   => 'group',
                defaultValue    => 4,
                label => "Group to view reports",
                },
            exitURL => {
                fieldType   => 'text',
                defaultValue    => undef,
                label   => "Set the URL that the survey will exit to",
                hoverHelp=>"When the user finishes the survey, they will be sent to this URL.  Leave blank if no forwarding required.",
                },
            maxResponsesPerUser=>{
                fieldType   => 'integer',
                defaultValue    => 1,
                label => "Max user reponses",
                },
            overviewTemplateId=>{
                tab         => 'display',
                fieldType   => 'template',
                defaultValue    => 'PBtmpl0000000000000063',
                label => "Overview template id",
                namespace  => 'Survey/Overview',
                },
            gradebookTemplateId => {
                tab         => 'display',
                fieldType   => 'template',
                label => "Grabebook template id",
                defaultValue    => 'PBtmpl0000000000000062',
                namespace  => 'Survey/Gradebook',
                },
            responseTemplateId => {
                tab         => 'display',
                fieldType   => 'template',
                label => "Response template id",
                defaultValue    => 'PBtmpl0000000000000064',
                namespace  => 'Survey/Response',
                },
            surveyEditTemplateId => {
                tab         => 'display',
                fieldType   => 'template',
                label => "Survey edit template id",
                defaultValue    => 'GRUNFctldUgop-qRLuo_DA',
                namespace  => 'Survey/Edit',
                },
            surveyTakeTemplateId => {
                tab         => 'display',
                fieldType   => 'template',
                label => "Take survey template id",
                defaultValue    => 'd8jMMMRddSQ7twP4l1ZSIw',
                namespace  => 'Survey/Take',
                },
            surveyQuestionsId => {
                tab         => 'display',
                fieldType   => 'template',
                label => "Questions template id",
                defaultValue    => 'CxMpE_UPauZA3p8jdrOABw',
                namespace  => 'Survey/Take',
                },
            sectionEditTemplateId => {
                tab         => 'display',
                fieldType   => 'template',
                label => "Section Edit Tempalte",
                defaultValue    => '1oBRscNIcFOI-pETrCOspA',
                namespace  => 'Survey/Edit',
                },
        );

    push(@{$definition}, {
        assetName=>$i18n->get('assetName'),
        icon=>'survey.gif',
        autoGenerateForms=>1,
        tableName=>'Survey',
        className=>'WebGUI::Asset::Wobject::Survey',
        properties=>\%properties
        });
        return $class->SUPER::definition($session, $definition);
}

#-------------------------------------------------------------------
=head2 getEditForm

getEditForm is called when creating/editing the asset.  
This overloads the normal call to the super, to call the super call like normal and then add to the tab form.

=cut

#sub getEditForm { 
#    my $self = shift; 

#    my $tabform = $self->SUPER::getEditForm(@_); 

#    $tabform->getTab("properties")->hidden( 
#        -value => "editSurvey", 
#        -name => 'proceed' 
#    );

#    return $tabform; 
#    return $self->www_editSurvey(@_);
#}



#-------------------------------------------------------------------
sub processPropertiesFromFormPost {
    my $self = shift;
    $self->SUPER::processPropertiesFromFormPost;

    $self->loadSurveyJSON();
    if($#{$self->{_data}->{sections}} < 0){
$self->session->errorHandler->error("In Processing from Post\n");
        $self->{_data}->update(['NEW'],undef,$self->session->errorHandler);

$self->session->errorHandler->error("Processing from creation\n".Dumper $self->{_data});
    }
    $self->saveSurveyJSON();
}

#-------------------------------------------------------------------

=head2 loadSurveyJSON ( )

Loads the survey collateral into memory so that the survey objects can be created

=cut

sub loadSurveyJSON{
    my $self = shift;

    if(defined $self->{_data}){return;}#already loaded

    my $jsonHash = $self->session->db->quickScalar("select surveyJSON from Survey where assetId = ?",[$self->getId]);
#$self->session->errorHandler->error("LOADING\n".Dumper $jsonHash."\n\n");
    my $hashRef = {};
    $hashRef = decode_json($jsonHash) if defined $jsonHash;

    $self->{_data} = WebGUI::Asset::Wobject::Survey::SurveyJSON->new($hashRef,$self->session->errorHandler);

}

#-------------------------------------------------------------------

=head2 saveSurveyJSON ( )

Saves the survey collateral to the DB

=cut

sub saveSurveyJSON{
    my $self = shift;
    $self->{_data}->{log} = $self->session->errorHandler;
    my $data;
    $data = $self->{_data}->freeze();
$self->session->errorHandler->error("----------------SAving THIS DATA".Dumper $data);
    $data = encode_json($data);
    
    $self->session->db->write("update Survey set surveyJSON = ? where assetId = ?",[$data,$self->getId]);
}


#-------------------------------------------------------------------

=head2 www_editSurvey ( )

Loads the initial edit survey page.  All other edit actions are JSON calls from this page.

=cut

sub www_editSurvey {
    my $self = shift;

    my %var;
    my $out = $self->processTemplate(\%var,$self->get("surveyEditTemplateId"));

    return $out;
}


#-------------------------------------------------------------------
sub www_submitObjectEdit{
    my $self = shift;
$self->session->errorHandler->error("Submit Edit Object");
    
#    my $ref = @{decode_json($self->session->form->process("data"))};
    my $responses = $self->session->form->paramsHashRef();
    my @address = split/-/,$responses->{id};
#$self->session->errorHandler->error("Submit Edit Object".Dumper $responses);
    $self->loadSurveyJSON();
    if($responses->{delete}){
$self->session->errorHandler->error("Deleting ".join(',',@address));
        return $self->deleteObject(\@address);
    }
$self->session->errorHandler->error("Updating ".join(',',@address)."Which has $$responses{terminalUrl} as the tu");
    #each object checks the ref and then either updates or passes it to the correct child.  New objects will have an index of -1.
    my $message = $self->{_data}->update(\@address,$responses,$self->session->errorHandler);

#    $self->saveSurveyJSON();

#    return $self->www_loadSurvey({address => $ref->{ids},message=>$message});
    $self->saveSurveyJSON();
    return $self->www_loadSurvey();
}


#-------------------------------------------------------------------
sub deleteObject{
    my ($self,$address) = @_;

    $self->loadSurveyJSON();

    my $message = $self->{_data}->remove($address);#each object checks the ref and then either updates or passes it to the correct child.  New objects will have an index of -1.

    $self->saveSurveyJSON();

    #The last address in ideas is to a deleted object so that should not be returned.
    pop(@{$address});
    if(@$address < 1){
        $$address[0] = 0;
    }

    return $self->www_loadSurvey({address => $address, message=>$message});
}


#-------------------------------------------------------------------
sub www_newObject{
    my $self = shift;
    my $ref;
    
    $ref->{ids} = @{decode_json($self->session->form->process("data"))};
    
    $self->loadSurveyJSON();

    my $object = $self->{_data}->createTemp($ref);
   
    #The new temp object has an address of NEW, which means it is not a real final address. 
    push(@{$ref->{ids}},'NEW');

    return $self->www_loadSurvey({address => $ref->{ids}, message => undef, object => $object});
}


#-------------------------------------------------------------------
sub www_dragDrop{
    my $self = shift;
    my $p = decode_json($self->session->form->process("data"));

    my $target = $p->{'target'};#The item moved
    my $before = $p->{'before'};#The item directly in front of it, empty for first in list

    if($target->{'type'} eq 'section'){
        my $pid;

        my $tseqNum = $self->session->db->quickScalar("select sequenceNumber from Survey_section where Survey_sectionId = ?",[$target->{'id'}]);

        if($before->{'id'} eq ''){#before doens't exist, object was moved to the front
            $self->session->db->write("update Survey_section set sequenceNumber = sequenceNumber +1 where sequenceNumber < ? and assetId = ?",[$tseqNum,$self->getId]);
            $self->session->db->write("update Survey_section set sequenceNumber = 1 where Survey_sectionId = ?",[$target->{'id'}]);
        }else{#before exists
            $pid = $before->{'id'};
            if($before->{'type'} eq 'question'){
                $pid = my $section =  $self->session->db->quickScalar("select Survey_sectionId from Survey_question where Survey_questionId = ?",[$before->{'id'}]);
            }
            elsif($before->{'type'} eq 'answer'){
                $pid = my $section =  $self->session->db->quickScalar("
                    select sq.Survey_sectionId 
                    from Survey_answer sa, Survey_question sq 
                    where sa.Survey_answerId = ? and sa.Survey_questionId = sq.Survey_questionId",
                    [$before->{'id'}]);
            }
            my $bseqNum = $self->session->db->quickScalar("select sequenceNumber from Survey_section where Survey_sectionId = ?",[$pid]);
            if($tseqNum > $bseqNum){
                $self->session->db->write("
                    update Survey_section 
                    set sequenceNumber = sequenceNumber+1 
                    where sequenceNumber > ? and sequenceNumber < ? and assetId = ?",[$bseqNum, $tseqNum,$self->getId]);
                $self->session->db->write("update Survey_section set sequenceNumber = ? where Survey_sectionId = ?",[$bseqNum+1,$target->{'id'}]);
            }elsif($bseqNum > $tseqNum){
                $self->session->db->write("
                    update Survey_section 
                    set sequenceNumber = sequenceNumber-1 
                    where sequenceNumber > ? and sequenceNumber <= ? and assetId = ?",[$tseqNum, $bseqNum,$self->getId]);
                $self->session->db->write("update Survey_section set sequenceNumber = ? where Survey_sectionId = ?",[$bseqNum,$target->{'id'}]);
            } 
        }

            
    }

    elsif($target->{'type'} eq 'question'){
        if($before->{'id'} ne ''){
            my @tids = split(/\|\|\|\|/,$target->{'id'});
            my $tseqNum = $self->session->db->quickScalar("select sequenceNumber from Survey_question where Survey_questionId = ?",[$tids[1]]);
            if($before->{'type'} eq 'section' and $before->{'id'} eq $tids[0]){#moved to front of section question belongs to
                $self->session->db->write("update Survey_question set sequenceNumber = sequenceNumber +1 where sequenceNumber < ? and Survey_sectionId = ?",
                   [$tseqNum,$tids[0]]);
                $self->session->db->write("update Survey_question set sequenceNumber = 1 where Survey_questionId = ?",[$tids[1]]);
            }
            elsif($before->{'type'} eq 'section' and $before->{'id'} ne $tids[0]){#question moved to new section
                #move down 1 seqnumber all questions higher up in section
                $self->session->db->write("update Survey_question set sequenceNumber = sequenceNumber - 1 where sequenceNumber > ? and Survey_sectionId = ?",
                    [$tseqNum,$tids[0]]);
                #append question to last question in new section
                my $lastSeq = $self->session->db->quickScalar("select max(sequenceNumber) from Survey_question where Survey_sectionId = ?",[$$before{'id'}]);
                $self->session->db->write("update Survey_question set Survey_sectionId = ?, sequenceNumber = ? where Survey_questionId = ?",
                    [ $$before{'id'}, $lastSeq + 1, $tids[1] ]); 
                $target->{'id'} = $before->{'id'}."||||".$tids[1];
            }
            elsif($before->{'type'} eq 'question'){#will always have the same sectionid.
                my @bids = split(/\|\|\|\|/,$before->{'id'});
                my $bseqNum = $self->session->db->quickScalar("select sequenceNumber from Survey_question where Survey_questionId = ?",[$bids[1]]);
                if($bseqNum > $tseqNum){#target was in front of before so before + all in between moved up
                    $self->session->db->write("update Survey_question set sequenceNumber = sequenceNumber - 1 where sequenceNumber > ? and 
                        sequenceNumber <= ? and Survey_sectionId = ?",[$tseqNum,$bseqNum,$tids[0]]);
                    $self->session->db->write("update Survey_question set sequenceNumber = ? where Survey_questionId = ?",[$bseqNum,$tids[1]]);
                }else{
                    $self->session->db->write("update Survey_question set sequenceNumber = sequenceNumber + 1 where sequenceNumber > ? and 
                        sequenceNumber < ? and Survey_sectionId = ?",[$bseqNum,$tseqNum,$tids[0]]);
                    $self->session->db->write("update Survey_question set sequenceNumber = ? where Survey_questionId = ?",[$bseqNum+1,$tids[1]]);
                } 
                
            }
        }
    }

    else{#is an answer

        my @tids = split(/\|\|\|\|/,$target->{'id'});
        my @bids = split(/\|\|\|\|/,$before->{'id'});
        my $tseqNum = $self->session->db->quickScalar("select sequenceNumber from Survey_answer where Survey_answerId = ?",[$tids[2]]);
        if($before->{'type'} eq 'question' and $bids[1] eq $tids[1]){#answer has been moved to the front
            $self->session->db->write("update Survey_answer set sequenceNumber = sequenceNumber + 1 where Survey_questionId = ? and sequenceNumber < ?",[$tids[1],$tseqNum]); 
            $self->session->db->write("update Survey_answer set sequenceNumber = 1 where Survey_answerId = ?",[$tids[2]]); 
        }elsif($before->{'type'} eq 'answer'){#will always be in the same quesiton
            my $bseqNum = $self->session->db->quickScalar("select sequenceNumber from Survey_answer where Survey_answerId = ?",[$bids[2]]);
            if($tseqNum > $bseqNum){
                $self->session->db->write("update Survey_answer set sequenceNumber = sequenceNumber + 1 where Survey_questionId = ? 
                    and sequenceNumber > ? and sequenceNumber < ?",[$tids[1],$bseqNum,$tseqNum]); 
                $self->session->db->write("update Survey_answer set sequenceNumber = ? + 1 where Survey_answerId = ?",[$bseqNum,$tids[2]]); 
            }else{
                $self->session->db->write("update Survey_answer set sequenceNumber = sequenceNumber - 1 where Survey_questionId = ? 
                    and sequenceNumber <= ? and sequenceNumber > ?",[$tids[1],$bseqNum,$tseqNum]); 
                $self->session->db->write("update Survey_answer set sequenceNumber = ? where Survey_answerId = ?",[$bseqNum,$tids[2]]); 
            }
        }
    }

    return $self->www_loadSurvey($target->{'id'}); 
}
   
 
#-------------------------------------------------------------------
sub www_loadSurvey{
    my ($self,$options) = @_;
    
$self->session->errorHandler->error("Entering loadSurvey");
    $self->loadSurveyJSON();
$self->session->errorHandler->error("Loaded JSON");

    my $address = $options->{address} ? defined $options : [0];
    my $message = $options->{message} ? defined $options : '';
$self->session->errorHandler->error("Getting edit vars");
    my $var = $options->{var} ? defined $options : $self->{_data}->getEditVars($address);
$self->session->errorHandler->error("Got edit vars");
$self->session->errorHandler->error("Loaded beginning params ".@$address);
    my $editHtml;
    if($var->{type} eq 'section'){
        $var->{id} = join('-',@$address);
        $var->{displayed_id} = $address->[$#$address];
        if($var->{displayed_id} ne 'NEW'){$var->{displayed_id}++;}

        $editHtml = $self->processTemplate($var,$self->get("sectionEditTemplateId"));
    }

$self->session->errorHandler->error(Dumper $var);

    my @data;
    my %buttons;
    $self->{_data}->getDragDropList($address,\@data,$self->session->errorHandler);
    my $html;
    my ($scount,$qcount,$acount) = (0,0,0);
    my $lastType;
    my %lastId;
    my @ids;
    my ($s,$q,$a) = (0,0,0);#bools on if a button has already been created

    foreach (@data){
        if($_->{type} eq 'section'){
            if($lastType eq 'answer'){
                $html .= "<span id='newAnswer'></span><br>";
                $buttons{answer} = "$lastId{section}-$lastId{question}"; 
                $a = 1;
            }
            elsif($lastType eq 'question'){
                $html .= "<span id='newQuestion'></span><br>";
                $buttons{'question'} = "$lastId{section}-$lastId{question}"; 
                $q = 1;
            }
            $html .= "<li id='$scount' class='section'>S". ($scount + 1). ": $_->{text}<\/li><br>\n";
            push(@ids,$scount);
            $lastId{section} = $scount++;
            $lastType = 'section';
        }
        elsif($_->{type} eq 'question'){
            if($lastType eq 'answer'){
                $html .= "<span id='newAnswer'></span><br>";
                $buttons{answer} = "$lastId{section}-$lastId{question}"; 
                $a = 1;
            }
            $html .= "<li id='$scount-$qcount' class='question'>Q". ($qcount + 1). ": $_->{text}<\/li><br>\n";
            push(@ids,$qcount);
            $lastId{question} = $qcount++;
            $lastType = 'question';
        }
        elsif($_->{type} eq 'answer'){
            $html .= "<li id='$scount-$qcount-$acount' class='answer'>A". ($acount + 1). ": $_->{text}<\/li><br>\n";
            push(@ids,$acount);
            $lastId{answer} = $acount++;
            $lastType = 'answer';
        }
    }
    if($lastType eq 'answer'){
        if(!$a){
            $html .= "<span id='newAnswer'></span><br>";
            $buttons{'answer'} = "$lastId{section}-$lastId{question}"; 
        }
        if(!$b){
            $html .= "<span id='newQuestion'></span><br>";
            $buttons{'question'} = "$lastId{section}-$lastId{question}"; 
        }
        if(!$s){
            $html .= "<span id='newSection'></span><br>";
            $buttons{'section'} = "$lastId{section}"; 
        }
    }
    elsif($lastType eq 'question'){
        if(!$b){
            $html .= "<span id='newQuestion'></span><br>";
            $buttons{'question'} = "$lastId{section}-$lastId{question}"; 
        }
        if(!$s){
            $html .= "<span id='newSection'></span><br>";
            $buttons{'section'} = "$lastId{section}"; 
        }
    }
    elsif($lastType eq 'section'){
        if(!$b){
            $html .= "<span id='newQuestion'></span><br>";
            $buttons{'question'} = "$lastId{section}-$lastId{question}"; 
        }
        if(!$s){
            $html .= "<span id='newSection'></span><br>";
            $buttons{'section'} = "$lastId{section}"; 
        }
    }
#$self->session->errorHandler->error($html);

    #address is the address of the focused object
    #buttons are the data to create the Add buttons
    #edithtml is the html edit the object
    #ddhtml is the html to create the draggable html divs
    #ids is a list of all ids passed in which are draggable (for adding events)
    #type is the object type
    my $return = {"address",$address,"buttons",\%buttons,"edithtml",$editHtml,"ddhtml",$html,"ids",\@ids,"type",$var->{type}};
    $self->session->errorHandler->error(encode_json($return));
$self->session->errorHandler->error("Returning from loadSurvey");
    return encode_json($return);
}

#-------------------------------------------------------------------
sub getSpecificSection{
    my $self = shift;
    my $Id = shift;
    my $responseId = shift;
    my $section =  $self->session->db->quickHashRef(
        "select * from Survey_section where Survey_sectionId = ?",
        [ $Id ]);
    if($responseId){
        $section = $self->fillSectionTextVariables($responseId,$section);
    }

    return $section;
}
#-------------------------------------------------------------------
sub getSpecificQuestion{
    my $self = shift;
    my $Id = shift;
    return $self->session->db->quickHashRef(
        "select * from Survey_question where Survey_questionId = ?",
        [ $Id ]);
}
#-------------------------------------------------------------------
sub getSpecificAnswer{
    my $self = shift;
    my $Id = shift;
    return $self->session->db->quickHashRef(
        "select * from Survey_answer where Survey_answerId = ?",
        [ $Id ]);
}

#-------------------------------------------------------------------
sub getAnswers{
    my $self = shift;
    my $qId = shift;
    if(! $qId){ return;}
    return $self->session->db->buildArrayRefOfHashRefs(
        "select substr(answerText,1,40) as text, Survey_answerId, Survey_questionId
         from Survey_answer
         where Survey_questionId = ?
         order by sequenceNumber ASC"
        ,[ $qId ]);
}

#-------------------------------------------------------------------
sub getQuestions{
    my $self = shift;
    my $sId = shift;
    if(! $sId){ return;}
    return $self->session->db->buildArrayRefOfHashRefs(
        "select substr(questionText,1,40) as text, Survey_questionId, Survey_sectionId
         from Survey_question 
         where Survey_sectionId = ?
         order by sequenceNumber ASC"
        ,[ $sId ]);
}




#-------------------------------------------------------------------
sub getSections{
    my $self = shift;
    return $self->session->db->buildArrayRefOfHashRefs(
        "select Survey_sectionId, sectionName 
         from Survey_section 
         where assetId = ?
         order by sequenceNumber ASC"
        ,[ $self->getId() ]);
}

#-------------------------------------------------------------------
sub getFirstSection{
    my $self = shift;
    $self->session->errorHandler->warn("In get first section with assid as ".$self->getId());
    return $self->session->db->quickScalar(
        "select Survey_sectionId from Survey_section where assetId = ? order by sequenceNumber asc",
        [ $self->getId() ]);
}

#-------------------------------------------------------------------
sub insertSection{
    my $self = shift;
    my $data = shift;#array ref
    $self->session->db->write("insert into Survey_section values(?,?,?,?,?,?,?,?,?,?,?,?,?,?)",$data);
}


#-------------------------------------------------------------------

=head2 prepareView ( )

See WebGUI::Asset::prepareView() for details.

=cut

sub prepareView {
    my $self = shift;
    $self->SUPER::prepareView();
    my $templateId = $self->get("templateId");
        if ($self->session->form->process("overrideTemplateId") ne "") {
                $templateId = $self->session->form->process("overrideTemplateId");
        }
    my $template = WebGUI::Asset::Template->new($self->session, $templateId);
    $template->prepare;
    $self->{_viewTemplate} = $template;
}

#-------------------------------------------------------------------

sub purge {
        my $self = shift;
        $self->session->db->write("delete from Survey_answer where assetId = ?",[$self->getId()]);
        $self->session->db->write("delete from Survey_question where assetId = ?",[$self->getId()]);
        $self->session->db->write("delete from Survey_section where assetId = ?",[$self->getId()]);
        $self->session->db->write("delete from Survey_response where assetId = ?",[$self->getId()]);
        $self->session->db->write("delete from Survey_questionResponse where assetId = ?",[$self->getId()]);
        return $self->SUPER::purge;
}

#-------------------------------------------------------------------

=head2 purgeCache ( )

See WebGUI::Asset::purgeCache() for details.

=cut

sub purgeCache {
    my $self = shift;
    WebGUI::Cache->new($self->session,"view_".$self->getId)->delete;
    $self->SUPER::purgeCache;
}

#-------------------------------------------------------------------

sub purgeRevision {
        my $self = shift;
        return $self->SUPER::purgeRevision;
}

#-------------------------------------------------------------------

=head2 view ( )

view defines all template variables, processes the template and
returns the output.

=cut

sub view {
    my $self = shift;
    my %var;
    $var{'edit_survey_url'} = $self->getUrl('func=editSurvey');
    $var{'take_survey_url'} = $self->getUrl('func=takeSurvey');
    $var{'user_canTakeSurvey'} = $self->session->user->isInGroup($self->get("groupToTakeSurvey"));

    $var{'user_canTakeSurvey'} = 1;

    my $out = $self->processTemplate(\%var,undef,$self->{_viewTemplate});

    return $out;
}


#-------------------------------------------------------------------

=head2 www_view ( )

See WebGUI::Asset::Wobject::www_view() for details.

=cut

sub www_view {
    my $self = shift;
    $self->SUPER::www_view(@_);
}


#-------------------------------------------------------------------
sub www_takeSurvey{
    my $self = shift;
    my %var;
$self->session->errorHandler->warn("\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n");
#    my $out = $self->processStyle($self->processTemplate(\%var,$self->get("surveyEditTemplateId")));
    my $out = $self->processTemplate(\%var,$self->get("surveyTakeTemplateId"));
    my $responseId = $self->getResponseId();
#    if(!$responseId){return $self->surveyEnd();}
    return $out;
}





#handles questions that were submitted
#-------------------------------------------------------------------
sub www_submitQuestions{
    my $self=shift;
    #can user take survey    
    if(!$self->canTakeSurvey()){
       # return encode_json({"type","FAIL LOGIN"});
        return $self->surveyEnd();
    }
    
    my $responseId = $self->getResponseId();
    if(!$responseId){return $self->surveyEnd();}
    
    $self->session->errorHandler->warn("\n\nIn submitQuestions with reponseId $responseId");

    my $responses = $self->session->form->paramsHashRef();

    delete $$responses{'func'};

###########

#  GO THROUGH ALL RESPONSES LOOKING FOR VERBATIMS AND ADD THEM ACCORDINGLY

#######

    my @goodResponses = keys %$responses;#load everything.  

    if(@goodResponses == 0){##nothing to load
        return $self->www_loadQuestions($responseId);
    }

    my $sql = "select max(answerOrder) from Survey_questionResponse where Survey_responseId = ?";
    my $lastOrder = $self->session->db->quickScalar($sql, [$responseId]);


    #handle comments
    foreach my $r(@goodResponses){
        if($r =~ /(.*?)comment$/){
            my $t = $1;
$self->session->errorHandler->warn("Inserting a comment: key is $r regex key is $t responseid is $responseId and value is ".$$responses{$r});
            $self->session->db->write("insert into Survey_questionResponseComment values(?,?,?,?)",[$self->getId(),$responseId,$t,$$responses{$r}]);
        }
    }

    if(!$lastOrder){$lastOrder = 0;}

    #get order of responses ##Comments will be ignored in this query as they use an id of the questionId concatted with 'comment' which will never match a Survey_answerId
    my $orderOf = $self->session->db->buildArrayRefOfHashRefs("select distinct(a.Survey_answerId), q.questionType 
        from Survey_answer a, Survey_question q where a.Survey_answerId in (".
        (join (',',map("?",@goodResponses))).
        ") and a.Survey_questionId = q.Survey_questionId order by q.sequenceNumber ASC",
       \@goodResponses);
use Data::Dumper;
$self->session->errorHandler->warn("OrderOf".Dumper $orderOf);
$self->session->errorHandler->warn("goodReponses".Dumper @goodResponses);
    
    my $files = 0;
 
    for my $id(@$orderOf){
        #if a file upload, write to disk 
        my $path;
        if($id->{'questionType'} eq 'File Upload'){
            $files = 1;
            my $storage = WebGUI::Storage->create($self->session);
            my $filename = $storage->addFileFromFormPost( $id->{'Survey_answerId'} );
            $path = $storage->getPath($filename);
        }
$self->session->errorHandler->warn("Inserting a response ".$id->{'Survey_answerId'}." $responseId, $path, ".$$responses{$id->{'Survey_answerId'}});
        $self->session->db->write("insert into Survey_questionResponse 
            select ?, Survey_sectionId, Survey_questionId, Survey_answerId, ?, ?, ?, now(), ?, ? from Survey_answer where Survey_answerId = ?",
            [$self->getId(), $responseId, $$responses{ $id->{'Survey_answerId'} }, '', $path, ++$lastOrder, $id->{'Survey_answerId'}]);
    }
    if($files){
        ##special case, need to check for more questions in section, if not, more current up one
        my $lastA = $self->getLastAnswerInfo($responseId);
        my $questionId = $self->getNextQuestionId($lastA->{'Survey_questionId'});
        if(!$questionId){
            my $currentSection = $self->getCurrentSection($responseId);
            $currentSection = $self->getNextSection($currentSection);
            if($currentSection){
                $self->setCurrentSection($responseId,$currentSection);
            }
        }
        return;
    }
    return $self->www_loadQuestions($responseId);
}






#finds the questions to display next and builds the data structre to hold them
#-------------------------------------------------------------------
sub www_loadQuestions{
    my $self=shift;
    my $responseId = shift;
    
    $self->session->errorHandler->warn("\n\n\n\n\t\t\t\t\t\t\t\t\t---In loadQuestions with responseId $responseId");
    
    if(!$self->canTakeSurvey()){
        return $self->surveyEnd();
#        return encode_json({"type","FAIL LOGIN"});
    }
   
    my $fromSubmit = 0;
 
    if($responseId){
$self->session->errorHandler->warn("Setting fromSubmit to true");
        $fromSubmit = 1;
    }else{
        $responseId = $self->getResponseId();
        if(!$responseId){
            return $self->surveyEnd();
        }
    }

    my $currentSection = $self->getCurrentSection($responseId);
    if(!$currentSection){
        $currentSection = $self->getFirstSection();
    }

$self->session->errorHandler->warn("Current Section is $currentSection");

    my $lastAfj = $self->getLastAnswerInfoForJump($responseId);

$self->session->errorHandler->warn("Last Answer for jump was for section: ".$lastAfj->{'Survey_sectionId'});

    if(exists $lastAfj->{'Survey_sectionId'} and $lastAfj->{'Survey_sectionId'} eq $currentSection){
        my ($sectionId,$questionId) = $self->getJumpTo($lastAfj->{'Survey_answerId'});
        if($sectionId){
            my $section = $self->getSpecificSection($sectionId,$responseId);
            my $questions = $self->getQuestionsAndAnswers($responseId,$section,$questionId); 
            $self->setCurrentSection($responseId,$sectionId);
$self->session->errorHandler->warn("Jump");
            return $self->showQuestions($section,$questions);
        }
$self->session->errorHandler->warn("No Jump");
    }


    my ($section,$questions,$questionId);

    my $lastA = $self->getLastAnswerInfo($responseId);
$self->session->errorHandler->warn("Last Answer was for section: ".$lastA->{'Survey_sectionId'});

    #if we're called from submit, see if there are anymore questions in section, show them, else go to next section.  If not called, then show this section.
    $section = $self->getSpecificSection($currentSection,$responseId);
    if(exists $lastA->{'Survey_sectionId'} and $lastA->{'Survey_sectionId'} eq $currentSection){
        $questionId = $self->getNextQuestionId($lastA->{'Survey_questionId'});
    }

    if($section->{'randomizeQuestions'} and $self->sectionHasQuestions($section->{'Survey_sectionId'})){#check to see if any questions are left in section to ask
$self->session->errorHandler->warn("Random Questions Section ".$section->{'sequenceNumber'});
        my $questionsAnsweredInSection = $self->questionsAnsweredInSection($section->{'Survey_sectionId'},$responseId);
        my $questionsInSection = $self->questionsInSection($section->{'Survey_sectionId'});
        if($questionsInSection == $questionsAnsweredInSection){
$self->session->errorHandler->warn("1");
            if($section->{'terminal'}){
$self->session->errorHandler->warn("1-1");
                return $self->surveyEnd($responseId,$section->{'terminalURL'});
            }
            my $nextSection = $self->getNextSection($section->{'Survey_sectionId'});
            if(! $nextSection){
$self->session->errorHandler->warn("1-2");
                return $self->surveyEnd($responseId,$section->{'terminalURL'});
            }else{
$self->session->errorHandler->warn("1-3");
                $self->setCurrentSection($responseId,$nextSection);
                return $self->www_loadQuestions();#We don't pass in the responseId so that it we think it is refresh and are not looking for previous questions in this section
            }
        }
$self->session->errorHandler->warn("2");
        $questions = $self->getRandomQuestionsAndAnswers($section,$responseId);
    }
    elsif($fromSubmit){
$self->session->errorHandler->warn("Not Random");
        if(!$questionId and $section->{'terminal'}){
$self->session->errorHandler->warn("1");
            return $self->surveyEnd($responseId,$section->{'terminalURL'});
        }elsif(!$questionId){
$self->session->errorHandler->warn("2");
            $currentSection = $self->getNextSection($currentSection);
            if(!$currentSection){ 
$self->session->errorHandler->warn("2-2 with $responseId");
                return $self->surveyEnd($responseId,$section->{'terminalURL'});
            }else{
$self->session->errorHandler->warn("2-3");
                $self->setCurrentSection($responseId,$currentSection);
#                return $self->www_loadQuestions($responseId);
                return $self->www_loadQuestions();
#                $section = $self->getSpecificSection($currentSection);
#                $questions = $self->getQuestionsAndAnswers($responseId,$section);
            }
        }else{
$self->session->errorHandler->warn("3");
            $section = $self->getSpecificSection($currentSection,$responseId);
            $questions = $self->getQuestionsAndAnswers($responseId,$section,$questionId);
        }
    }else{
$self->session->errorHandler->warn("4");
        if($questionId){
$self->session->errorHandler->warn("4-5");
            $questions = $self->getQuestionsAndAnswers($responseId,$section,$questionId);
        }else{
$self->session->errorHandler->warn("4-6");
            $questions = $self->getQuestionsAndAnswers($responseId,$section);
        }
        if($self->sectionHasQuestions($currentSection) and @$questions == 0){
$self->session->errorHandler->warn("5");
            if($section->{'terminal'}){
$self->session->errorHandler->warn("5-1");
                return $self->surveyEnd($responseId,$section->{'terminalURL'});
            }
$self->session->errorHandler->warn("5-2");
            $currentSection = $self->getNextSection($currentSection);
            $section = $self->getSpecificSection($currentSection,$responseId);
            $questions = $self->getQuestionsAndAnswers($responseId,$section);
        }
    }

$self->session->errorHandler->warn("6");
    $self->setCurrentSection($responseId,$currentSection);
    return $self->showQuestions($section,$questions); 

}




sub sectionHasQuestions{
    my $self=shift;
    my $sectionId = shift;
    return $self->session->db->quickScalar("select '1' from Survey_question where Survey_sectionId = ? limit 1",[$sectionId]);
}

#called when the survey is over.
sub surveyEnd{
    my $self = shift;
    my $responseId = shift;
    my $url = shift;
$self->session->errorHandler->warn("--SurveyEnd There wasn't a responseId $responseId");
#    $self->session->db->write("update Survey_response set endDate = ? and isComplete = 1 where Survey_responseId = ?",[WebGUI::DateTime->now->toDatabase,$responseId]);
    $self->session->db->setRow("Survey_response","Survey_responseId",{
                Survey_responseId=>$responseId,
                endDate=>WebGUI::DateTime->now->toDatabase,
                isComplete=>1
            });
    if($url !~ /\w/){ $url = 0; }
    if($url eq "undefined"){ $url = 0; }
    if(!$url){
        $url = $self->session->db->quickScalar("select exitURL from Survey where assetId = ? order by revisionDate desc limit 1",[$self->getId()]);
        if(!$url){
            $url = "/";
        }
    }
$self->session->errorHandler->warn("-------SurveyEnd $url");
    return encode_json({"type","forward","url",$url});
}



#sends the processed template and questions structure to the client
sub showQuestions{
    my ($self,$section,$questions) = @_;
    my %multipleChoice = ('Multiple Choice',1,'Gender',1,'Yes/No',1,'True/False',1,'Ideology',1, 'Race',1,'Party',1,'Education',1
        ,'Scale',1,'Agree/Disagree',1,'Oppose/Support',1,'Importance',1, 'Likelihood',1,'Certainty',1,'Satisfaction',1,'Confidence',1,
        'Effectiveness',1,'Concern',1,'Risk',1,'Threat',1,'Security',1);
    my %text = ('Text',1, 'Email',1, 'Phone Number',1, 'Text Date',1, 'Currency',1);
    my %slider = ('Slider',1, 'Dual Slider - Range',1, 'Multi Slider - Allocate',1);
    my %dateType = ('Date',1,'Date Range',1);
    my %fileUpload = ('File Upload',1);
    my %hidden = ('Hidden',1);

    foreach my $q(@$questions){

        if($fileUpload{$$q{'questionType'}}){ $q->{'fileLoader'} = 1; } 
        elsif($text{$$q{'questionType'}}){ $q->{'text'} = 1; }
        elsif($hidden{$$q{'questionType'}}){ $q->{'hidden'} = 1; }
        elsif($multipleChoice{$$q{'questionType'}}){ 
            $q->{'multipleChoice'} = 1; 
            if($$q{'maxAnswers'} > 1){
                $q->{'maxMoreOne'} = 1; 
            }
        }
        elsif($dateType{$$q{'questionType'}}){ 
            $q->{'dateType'} = 1; 
        }
        elsif($slider{$$q{'questionType'}}){ 
            $q->{'slider'} = 1;
            if($$q{'questionType'} eq 'Dual Slider - Range'){
                $q->{'dualSlider'} = 1;
                $q->{'a1'} = [$q->{'answers'}->[0]];
                $q->{'a2'} = [$q->{'answers'}->[1]];
            }
        }
 
        if($$q{'verticalDisplay'}){ $$q{'verts'} = "<p>"; $$q{'verte'} = "</p>"; }
    }

    $section->{'questions'} = $questions;
    my $survey = $self->get('surveyQuestionsId');
 
#$self->session->errorHandler->warn(Dumper $section);
#$self->session->errorHandler->warn(Dumper $survey);
    my $out = $self->processTemplate($section,$self->get("surveyQuestionsId"));

use Data::Dumper;
$self->session->errorHandler->warn("Sending Back");
#$self->session->errorHandler->warn("$out");

    return encode_json({"type","displayquestions","section",$section,"questions",$questions,"html",$out});
}
#Answer text for inserting into quesiton text
sub getPreviousAnswer{
    my ($self,$responseId,$var) = @_;
    $var =~ s/^\[\[//g;
    $var =~ s/\]\]$//g;
$self->session->errorHandler->warn("getPreviousAnswer for $var");
    my $ref = $self->session->db->buildArrayRefOfHashRefs("select a.answerText, qa.response from Survey_questionResponse qa, Survey_question q, Survey_answer a 
        where q.questionVariable = ? and q.Survey_questionId = a.Survey_questionId and a.Survey_answerId = qa.Survey_answerId 
        and qa.Survey_responseId = ? and qa.response != '' and qa.response is not null limit 1",[$var,$responseId]);
    my $string;
use Data::Dumper;
$self->session->errorHandler->warn("getPreviousAnswer ".Dumper $ref);
    if(@$ref < 1){
        $string = "PREVIOUS ANSWSER";
    }else{
        if($$ref[0]->{'answerText'} ne ""){
            $string = $$ref[0]->{'answerText'};
        }else{
            $string = $$ref[0]->{'response'};
        }
    }
$self->session->errorHandler->warn("getPreviousAnswer returning $string");
    return $string;
}
sub getRandomText{
    my ($self,$responseId,$var) = @_;
    $var =~ s/^\[\[\%//g;
    $var =~ s/\]\]$//g;
    my $response = $self->getResponse($responseId);
    my %rands;
    my $rstring = $response->{'randomWords'};
    if($rstring){
        %rands = %{decode_json($response->{'randomWords'})};
    }
    if(! exists($rands{$var})){
        my $string = $self->session->db->quickScalar("select randomizedWords from Survey_question where questionVariable = ?",[$var]);
        my @data = split/\n/,$string;        
        my $picked = int(rand(scalar @data));
        $rands{$var} = $data[$picked];
        my $temp = encode_json(\%rands);
        $self->session->db->write("update Survey_response set randomWords = ? where Survey_responseId = ?",[$temp,$responseId]);
    }
    return $rands{$var};
}
sub fillSectionTextVariables{
    my $self = shift;
    my $responseId = shift;
    my $section = shift;
    $section->{'sectionText'} =~ s/(\[\[[^\%]*?\]\])/$self->getPreviousAnswer($responseId,$1)/eg;
    $section->{'sectionText'} =~ s/(\[\[\%.*?\]\])/$self->getRandomText($responseId,$1)/eg;
$self->session->errorHandler->warn("Found $1 in ".$$section{'sectionText'});
    return $section;
}
sub fillQuestionTextVariables{
    my $self = shift;
    my $responseId = shift;
    my $questions = shift;

    foreach my $q(@$questions){
        $q->{'questionText'} =~ s/(\[\[[^\%]*?\]\])/$self->getPreviousAnswer($responseId,$1)/eg;
        $q->{'questionText'} =~ s/(\[\[\%.*?\]\])/$self->getRandomText($responseId,$1)/eg;
$self->session->errorHandler->warn("Found $1 in ".$$q{'sequenceNumber'});
    }
    return $questions;
}
    
sub getRandomQuestionsAndAnswers{
    my ($self,$section,$responseId) = @_;
    my @completed = $self->session->db->buildArray("select Survey_questionId from Survey_questionResponse where Survey_sectionId = ? and Survey_responseId = ?",
        [$section->{'Survey_sectionId'},$responseId]);
    my $placeHolders;
$self->session->errorHandler->warn('In get random questions');
    my @params;
    if(@completed > 0){
        map($placeHolders .= "?,",@completed);
        chop($placeHolders);#get rid of trailing comma  
    }else{
        $placeHolders = "?";
        push(@completed,'');
    }
$self->session->errorHandler->warn($placeHolders);
    
$self->session->errorHandler->warn('Random build survey section'.$section->{'Survey_sectionId'});
    push(@params,$section->{'Survey_sectionId'});
    push(@params, @completed);
    push(@params,$section->{'questionsPerPage'});
$self->session->errorHandler->warn(join(',',@params));

    my $questions =  $self->session->db->buildArrayRefOfHashRefs("
        select q.* 
        from Survey_question q
        where q.Survey_sectionId = ? and q.Survey_questionId not in ($placeHolders)
        order by RAND()
        LIMIT ?
        ",\@params);

    $questions = $self->getAnswersForQuestions($questions);

    $questions = $self->fillQuestionTextVariables($responseId,$questions);

    return $questions;
}
sub getAnswersForQuestions{
    my ($self,$questions) = @_;
    for(my $i=0; $i<=$#$questions; $i++){
        my $sql = "select a.* 
            from Survey_answer a
            where a.Survey_questionId = ?";
        if($$questions[$i]{'randomizeAnswers'} eq '0'){
            $sql .= " order by a.sequenceNumber ASC";
        } 
        else{
            $sql .= " order by RAND()";
        }
        $$questions[$i]{'answers'} =  $self->session->db->buildArrayRefOfHashRefs( $sql ,[$$questions[$i]{'Survey_questionId'}] );
    }
    return $questions;
}
sub getQuestionsAndAnswers{
    my ($self,$responseId,$section,$questionId) = @_;
    my $qNeeded = $section->{'questionsPerPage'};
    my $ref;
    my $seqNum = $self->session->db->quickScalar("select sequenceNumber from Survey_question where Survey_questionId = ?",[$questionId]);
    if(!$seqNum){$seqNum = 1;}
    my $questions =  $self->session->db->buildArrayRefOfHashRefs("
        select q.* 
        from Survey_question q
        where q.Survey_sectionId = ? and q.sequenceNumber >= ? and q.sequenceNumber < ?
        order by q.sequenceNumber ASC
        ",[$section->{'Survey_sectionId'},$seqNum,$seqNum+$section->{'questionsPerPage'}]);

    $questions = $self->getAnswersForQuestions($questions);

    $questions = $self->fillQuestionTextVariables($responseId,$questions);

    return $questions;
}
  
sub getNextQuestionId{
    my ($self,$qid) = @_;
    return $self->session->db->quickScalar("select q1.Survey_questionId from Survey_question q, Survey_question q1 
        where q.Survey_questionId = ? and q.assetId = q1.assetId and q.Survey_sectionId = q1.Survey_sectionId and q.sequenceNumber + 1 = q1.sequenceNumber",
        [$qid]); 
}

sub getNextRandomQuestions{
    my ($self,$section,$questions) = @_;
}

sub getNextSection{
    my ($self,$sid) = @_;
    my $section;

    my $var = $self->session->db->quickScalar("select goto from Survey_section 
        where Survey_sectionId = ?", [$sid]);
    my @array = split/\s*\,\s*/,$var;
    my $picked = int(rand(scalar @array));

    $section =  $self->session->db->quickScalar("select s1.Survey_sectionId from Survey_section s1 
        where s1.sectionVariable = ?",[$array[$picked]]);

    if(!$section){
        $section =  $self->session->db->quickScalar("select s1.Survey_sectionId from Survey_section s, Survey_section s1 
            where s.assetId = ? and s.Survey_sectionId = ? and s1.assetId = ? and s1.sequenceNumber = s.sequenceNumber + 1",
                [$self->getId(), $sid, $self->getId()]);
    }
    return $section;
}

sub questionsAnsweredInSection{
    my ($self,$sid,$rid) = @_;
    return $self->session->db->quickScalar("select count(distinct(Survey_questionId)) 
        from Survey_questionResponse where Survey_responseId = ? and Survey_sectionId = ?",[$rid,$sid]);
}

sub questionsInSection{
    my ($self,$sid) = @_;
    return $self->session->db->quickScalar("select count(*) from Survey_question where Survey_sectionId = ?",[$sid]);
}

#last answer not skipped
sub getLastAnswerInfoForJump{
    my ($self,$rId) = @_;
    return $self->session->db->quickHashRef("
        select r.Survey_sectionId, r.Survey_questionId, r.Survey_answerId,q.sequenceNumber
        from Survey_section s, Survey_question q, Survey_answer a, Survey_questionResponse r
        where r.Survey_responseId = ? and r.Survey_answerId = a.Survey_answerId and a.Survey_questionId = q.Survey_questionId and r.response != '' and 
            q.Survey_sectionId = s.Survey_sectionId and r.answerOrder = (select max(r1.answerOrder) from Survey_questionResponse r1 where r1.Survey_responseId = ? 
            and r1.response != '') LIMIT 1",
        [$rId,$rId]);
}
#last answer, skipped or not
sub getLastAnswerInfo{
    my ($self,$rId) = @_;
    return $self->session->db->quickHashRef("
        select r.Survey_sectionId, r.Survey_questionId, r.Survey_answerId,q.sequenceNumber
        from Survey_section s, Survey_question q, Survey_answer a, Survey_questionResponse r
        where r.Survey_responseId = ? and r.Survey_answerId = a.Survey_answerId and a.Survey_questionId = q.Survey_questionId and  
            q.Survey_sectionId = s.Survey_sectionId and r.answerOrder = (select max(r1.answerOrder) from Survey_questionResponse r1 where r1.Survey_responseId = ?) LIMIT 1",
        [$rId,$rId]);
}

sub getJumpTo{
    my ($self,$aId) = @_;
    my $string = $self->session->db->quickScalar("select gotoQuestion from Survey_answer where Survey_answerId = ?",[$aId]);
    if($string !~ /\w/ or $string eq "undefined"){
$self->session->errorHandler->warn("No string or undefined $string");
        return;
    }
    my @array = split/\s*\,\s*/,$string;

    my $picked = int(rand(scalar @array));

$self->session->errorHandler->warn("Jupm was ".$array[$picked]." and picked was $picked");
    my $ref = $self->session->db->buildArrayRefOfHashRefs("
        select Survey_sectionId, Survey_questionId 
        from Survey_question
        where questionVariable = ? 
        ",[$array[$picked]]);
    if(@$ref == 0){
        $ref = $self->session->db->buildArrayRefOfHashRefs("
            select Survey_sectionId 
            from Survey_section
            where sectionVariable = ? 
            ",[$array[$picked]]);
    }
    if(@$ref > 0){
$self->session->errorHandler->warn("JUMPING To ".$array[$picked]);
        return ($ref->[0]->{'Survey_sectionId'},$ref->[0]->{'Survey_questionId'});
    }
$self->session->errorHandler->warn("Jump ended");
    return;
}

sub getCurrentSection{
    my $self = shift;
    my $responseId = shift;
    return $self->session->db->quickScalar("select currentSection from Survey_response where Survey_responseId = ?",[$responseId]);
}

sub setCurrentSection{
    my $self = shift;
    my $responseId = shift;
    my $newSectionId = shift;
    $self->session->db->write('update Survey_response set currentSection = ? where Survey_responseId = ?',[$newSectionId, $responseId]);
}
sub getResponse{
    my ($self,$responseId) = @_;
    my $ref = $self->session->db->buildArrayRefOfHashRefs("select * from Survey_response where Survey_responseId = ?",[$responseId]);
    return $ref->[0];
}

sub getResponseId{
    my $self = shift;

    my $ip = $self->session->env->getIp;
    my $id = $self->session->user->userId();
    my $anonId = $self->session->form->process("id");
    

    my $responseId;

    my  $string;
    if($anonId or $id != 1){
$self->session->errorHandler->warn("Response - 1");
        $string = 'userId';
        if($anonId){
$self->session->errorHandler->warn("Response - 1-1");
            $string = 'anonId';
            $id = $anonId;
        }
        $responseId = $self->session->db->quickScalar("select Survey_responseId from Survey_response where $string = ? and assetId = ? and isComplete = 0",
            [$id,$self->getId()]);
    }elsif($id == 1){
$self->session->errorHandler->warn("Response - 2");
        $responseId = $self->session->db->quickScalar("select Survey_responseId from Survey_response where userId = ? and ipAddress = ? and assetId = ? and isComplete = 0",
            [$id,$ip,$self->getId()]);
    }

    if(! $responseId){
$self->session->errorHandler->warn("Response - 3");
    
        my $allowedTakes = $self->session->db->quickScalar("select maxResponsesPerUser from Survey where assetId = ? order by revisionDate desc limit 1",[$self->getId()]);
        my $haveTaken;
        if($id ==1 ){
$self->session->errorHandler->warn("Response - 4");
            $haveTaken = $self->session->db->quickScalar("select count(*) from Survey_response where userId = ? and ipAddress = ? and assetId = ?",
            [$id,$ip,$self->getId()]);
        }else{
$self->session->errorHandler->warn("Response - 5");
            $haveTaken = $self->session->db->quickScalar("select count(*) from Survey_response where $string = ? and assetId = ?",
                [$id,$self->getId()]);
        }

        if($haveTaken < $allowedTakes){
$self->session->errorHandler->warn("Response - 6");
            $responseId = $self->session->db->setRow("Survey_response","Survey_responseId",{
                Survey_responseId=>"new",
                userId=>$id,
                ipAddress=>$ip,
                username=>$self->session->user->username,
                startDate=>WebGUI::DateTime->now->toDatabase,
                endDate=>WebGUI::DateTime->now->toDatabase,
                assetId=>$self->getId(),
                anonId=>$anonId
            });
        }else{
$self->session->errorHandler->warn("No responses left max=$allowedTakes used up=$haveTaken");
}
    }
    $self->session->errorHandler->warn("Survey Response was ".$responseId);
    return $responseId;
}



sub canTakeSurvey{
    my $self = shift;
    
    if(!$self->session->user->isInGroup($self->get("groupToTakeSurvey"))){
        return 0;
    }

    #Does user have too many finished survey responses
    my $maxTakes = $self->getValue("maxResponsesPerUser");
    my $ip = $self->session->env->getIp;
    my $id = $self->session->user->userId();
    my $takenCount = 0; 


    if($id == 1){
        $takenCount = $self->session->db->quickScalar("select count(*) from Survey_response where userId = ? and ipAddress = ? and assetId = ? 
                and isComplete = ?",[$id,$ip,$self->getId(),1]);
    }else{
        $takenCount = $self->session->db->quickScalar("select count(*) from Survey_response where userId = ? and assetId = ? and isComplete = ?",[$id,$self->getId(),1]);
    }

    $self->session->errorHandler->warn("userid is ".$id."\t and ip is ".$ip);
    $self->session->errorHandler->warn("max ".$maxTakes." taken ".$takenCount);

    if($takenCount >= $maxTakes){
        return 0;
    }

    return 1;         
}


#-------------------------------------------------------------------
sub createDefaultAnswers{
    my ($self,$sid,$qid,$type) = @_;
    $self->session->db->write("delete from Survey_answer where Survey_questionId = ?",[$qid]);
    if($type eq 'Gender'){
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 1, undef, 'Male', 1, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 2, undef, 'Female', 0, undef, undef,undef,undef,0,20,2]);

    }elsif($type eq 'Yes/No'){
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 1, undef, 'Yes', 1, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 2, undef, 'No', 0, undef, undef,undef,undef,0,20,2]);

    }elsif($type eq 'True/False'){
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 1, undef, 'True', 1, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 2, undef, 'False', 0, undef, undef,undef,undef,0,20,2]);

    }elsif($type eq 'Agree/Disagree'){
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 1, undef, 'Strongly disagree', 1, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 2, undef, '', 2, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 3, undef, '', 3, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 4, undef, '', 4, 
            undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 5, undef, '', 5, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 6, undef, '', 6, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 7, undef, 'Strongly agree', 7, undef, undef,undef,undef,0,20,2]);

    }elsif($type eq 'Oppose/Support'){
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 1, undef, 'Strongly oppose', 1, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 2, undef, '', 2, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 3, undef, '', 3, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 4, undef, '', 4, 
            undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 5, undef, '', 5, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 6, undef, '', 6, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 7, undef, 'Strongly support', 7, undef, undef,undef,undef,0,20,2]);

    }elsif($type eq 'Importance'){
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 1, undef, 'Not at all important', 0, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 2, undef, '', 1, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 3, undef, '', 2, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 4, undef, '', 3, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 5, undef, '', 4, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 6, undef, '', 5, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 7, undef, '', 6, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 8, undef, '', 7, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 9, undef, '', 8, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 10, undef, '', 9, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 11, undef, 'Extremely important', 10, undef, undef,undef,undef,0,20,2]);
    
    }elsif($type eq 'Likelihood'){
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 1, undef, 'Not at all likely', 0, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 2, undef, '', 1, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 3, undef, '', 2, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 4, undef, '', 3, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 5, undef, '', 4, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 6, undef, '', 5, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 7, undef, '', 6, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 8, undef, '', 7, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 9, undef, '', 8, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 10, undef, '', 9, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 11, undef, 'Extremely likely', 10, undef, undef,undef,undef,0,20,2]);

    }elsif($type eq 'Certainty'){
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 1, undef, 'Not at all certain', 0, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 2, undef, '', 1, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 3, undef, '', 2, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 4, undef, '', 3, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 5, undef, '', 4, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 6, undef, '', 5, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 7, undef, '', 6, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 8, undef, '', 7, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 9, undef, '', 8, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 10, undef, '', 9, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 11, undef, 'Extremely certain', 10, undef, undef,undef,undef,0,20,2]);

    }elsif($type eq 'Satisfaction'){
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 1, undef, 'Not at all satisfied', 0, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 2, undef, '', 1, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 3, undef, '', 2, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 4, undef, '', 3, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 5, undef, '', 4, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 6, undef, '', 5, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 7, undef, '', 6, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 8, undef, '', 7, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 9, undef, '', 8, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 10, undef, '', 9, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 11, undef, 'Completely satisfied', 10, undef, undef,undef,undef,0,20,2]);

    }elsif($type eq 'Confidence'){
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 1, undef, 'Not at all confident', 0, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 2, undef, '', 1, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 3, undef, '', 2, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 4, undef, '', 3, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 5, undef, '', 4, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 6, undef, '', 5, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 7, undef, '', 6, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 8, undef, '', 7, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 9, undef, '', 8, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 10, undef, '', 9, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 11, undef, 'Extremely confident', 10, undef, undef,undef,undef,0,20,2]);

    }elsif($type eq 'Effectiveness'){
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 1, undef, 'Not at all effective', 0, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 2, undef, '', 1, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 3, undef, '', 2, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 4, undef, '', 3, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 5, undef, '', 4, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 6, undef, '', 5, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 7, undef, '', 6, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 8, undef, '', 7, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 9, undef, '', 8, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 10, undef, '', 9, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 11, undef, 'Extremely effective', 10, undef, undef,undef,undef,0,20,2]);

    }elsif($type eq 'Concern'){
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 1, undef, 'Not at all concerned', 0, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 2, undef, '', 1, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 3, undef, '', 2, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 4, undef, '', 3, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 5, undef, '', 4, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 6, undef, '', 5, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 7, undef, '', 6, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 8, undef, '', 7, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 9, undef, '', 8, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 10, undef, '', 9, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 11, undef, 'Extremely concerned', 10, undef, undef,undef,undef,0,20,2]);

    }elsif($type eq 'Risk'){
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 1, undef, 'No risk', 0, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 2, undef, '', 1, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 3, undef, '', 2, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 4, undef, '', 3, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 5, undef, '', 4, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 6, undef, '', 5, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 7, undef, '', 6, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 8, undef, '', 7, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 9, undef, '', 8, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 10, undef, '', 9, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 11, undef, 'Extreme risk', 10, undef, undef,undef,undef,0,20,2]);

    }elsif($type eq 'Threat'){
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 1, undef, 'No threat', 0, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 2, undef, '', 1, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 3, undef, '', 2, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 4, undef, '', 3, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 5, undef, '', 4, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 6, undef, '', 5, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 7, undef, '', 6, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 8, undef, '', 7, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 9, undef, '', 8, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 10, undef, '', 9, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 11, undef, 'Extreme threat', 10, undef, undef,undef,undef,0,20,2]);

    }elsif($type eq 'Security'){
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 1, undef, 'Not at all secure', 0, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 2, undef, '', 1, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 3, undef, '', 2, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 4, undef, '', 3, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 5, undef, '', 4, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 6, undef, '', 5, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 7, undef, '', 6, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 8, undef, '', 7, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 9, undef, '', 8, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 10, undef, '', 9, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 11, undef, 'Extremely secure', 10, undef, undef,undef,undef,0,20,2]);


    }elsif($type eq 'Ideology'){
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 1, undef, 'Strongly liberal', 1, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 2, undef, 'Liberal', 2, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 3, undef, 'Somewhat liberal', 3, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 4, undef, 'Middle of the road', 4, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 5, undef, 'Slightly conservative', 5, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 6, undef, 'Conservative', 6, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 7, undef, 'Strongly conservative', 7, undef, undef,undef,undef,0,20,2]);

    }elsif($type eq 'Race'){
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 1, undef, 'American Indian', 1, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 2, undef, 'Asian', 2, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 3, undef, 'Black', 3, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 4, undef, 'Hispanic', 4, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 5, undef, 'White non-Hispanic', 5, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 6, undef, 'Something else (verbatim)', 6, undef, undef,undef,undef,0,,20,2]);

    }elsif($type eq 'Party'){
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 1, undef, 'Democratic party', 1, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 2, undef, 'Republican party (or GOP)', 2, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 3, undef, 'Independant party', 3, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 4, undef, 'Other party (verbatim)', 4, undef, undef,undef,undef,1,,20,2]);

    }elsif($type eq 'Education'){
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 1, undef, 'Elementary or some high school', 1, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 2, undef, 'High school/GED', 2, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 3, undef, 'Some college/vocational school', 3, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 4, undef, 'College graduate', 4, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 5, undef, 'Some graduate work', 5, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 6, undef, 'Master\'s degree', 6, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 7, undef, 'Doctorate (of any type)', 7, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 8, undef, 'Other degree (verbatim)', 8, undef, undef,undef,undef,1,,20,2]);
       
    }elsif($type eq 'Text'){
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 1, undef, undef, undef, undef, undef,undef,undef,0,20,2]);
    
    }elsif($type eq 'Email'){
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 1, undef, 'Email:', undef, undef, undef,undef,undef,0,20,2]);
    
    }elsif($type eq 'Phone Number'){
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 1, undef, 'Phone Number:', undef, undef, undef,undef,undef,0,20,2]);
    
    }elsif($type eq 'Text Date'){
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 1, undef, 'Date:', undef, undef, undef,undef,undef,0,20,2]);
    
    }elsif($type eq 'Currency'){
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 1, undef, 'Currency Amount:', undef, undef, undef,undef,undef,0,20,2]);
    
    }elsif($type eq 'Slider'){
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 1, undef, undef, undef, undef, 1,10,1,0,20,2]);
    
    }elsif($type eq 'Dual Slider - Range'){
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 1, undef, undef, undef, undef, 0,10,1,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 2, undef, undef, undef, undef, 0,10,1,0,20,2]);
    
    }elsif($type eq 'Multi Slider - Allocate'){
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 1, undef, undef, undef, undef, 0,10,1,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 2, undef, undef, undef, undef, 0,10,1,0,20,2]);

    }elsif($type eq 'Date'){
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 1, undef, undef, undef, undef, undef,undef,undef,0,20,2]);
    
    }elsif($type eq 'Date Range'){
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 1, undef, undef, undef, undef, undef,undef,undef,0,20,2]);
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 2, undef, undef, undef, undef, undef,undef,undef,0,20,2]);
        
    }elsif($type eq 'File Upload'){
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 1, undef, undef, undef, undef, undef,undef,undef,0,20,2]);
    
    }elsif($type eq 'Hidden'){
        $self->AnswersInsert([$self->getId(),$sid,$qid,$self->session->id->generate(), 1, undef, undef, undef, undef, undef,undef,undef,0,20,2]);
    }
    
}
sub AnswersInsert{
    my ($self,$array) = @_;
    $self->session->db->write("insert into Survey_answer values (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)",$array);
}


1;
